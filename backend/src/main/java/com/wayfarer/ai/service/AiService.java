package com.wayfarer.ai.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.ai.dto.AssistantDtos.Answer;
import com.wayfarer.ai.dto.PlanDtos.AssistantRequest;
import com.wayfarer.ai.dto.PlanDtos.Plan;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.RecommendationRequest;
import com.wayfarer.ai.dto.PlanDtos.TravelPlanRequest;
import com.wayfarer.ai.repository.AiLogRepository;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.itinerary.service.ItineraryService;
import com.wayfarer.notification.service.NotificationService;
import com.wayfarer.security.AuthUser;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/** Use cases behind /api/ai/*: validates input, runs the planner or assistant, and records usage for the admin console. */
@Service
public class AiService {
    private final PlannerService planner;
    private final RequestParser parser;
    private final AssistantService assistant;
    private final RetrievalService retrieval;
    private final ItineraryService itineraries;
    private final DestinationRepository destinations;
    private final AttractionRepository attractions;
    private final AccommodationRepository accommodations;
    private final AiLogRepository log;
    private final NotificationService notifications;
    private final LlmClient llm;
    private final ObjectMapper json;

    public AiService(PlannerService planner, RequestParser parser, AssistantService assistant, RetrievalService retrieval, ItineraryService itineraries,
                     DestinationRepository destinations, AttractionRepository attractions, AccommodationRepository accommodations, AiLogRepository log,
                     NotificationService notifications, LlmClient llm, ObjectMapper json) {
        this.planner = planner;
        this.parser = parser;
        this.assistant = assistant;
        this.retrieval = retrieval;
        this.itineraries = itineraries;
        this.destinations = destinations;
        this.attractions = attractions;
        this.accommodations = accommodations;
        this.log = log;
        this.notifications = notifications;
        this.llm = llm;
        this.json = json;
    }

    public Map<String, Object> status() {
        boolean on = llm.configured();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("llmConfigured", on);
        m.put("plannerMode", on ? "llm-assisted" : "rules");
        m.put("assistantMode", on ? "llm" : "retrieval-only");
        m.put("explanation", on ? "Language-model assistance is enabled; results are still grounded in stored records."
            : "No language-model key is configured. Planning uses a deterministic rules engine and answers are extracted from stored guides.");
        return m;
    }

    private void usage(AuthUser user, String kind, String mode, long started, boolean ok) {
        log.usage(user == null ? null : user.id(), kind, mode, "llm".equals(mode) ? "anthropic" : null, System.currentTimeMillis() - started, ok);
    }

    /** Natural-language or structured request to a grounded plan; optionally saved as a trip. */
    public Map<String, Object> travelPlan(TravelPlanRequest b, AuthUser user) {
        long started = System.currentTimeMillis();
        if (b.prompt() == null && b.structured() == null) throw ApiException.unprocessable("VALIDATION_ERROR", "Provide a prompt or structured request");
        if (b.shouldSave() && user == null) throw ApiException.unauthorized("UNAUTHENTICATED", "Sign in to save an itinerary");

        List<RequestParser.Slug> dests = destinations.listAllSlugs().stream().map(d -> new RequestParser.Slug(Rows.str(d, "slug"), Rows.str(d, "name"))).toList();
        RequestParser.Parsed parsed;
        if (b.prompt() != null) {
            parsed = parser.understand(b.prompt(), dests);
            if (b.structured() != null) parsed = new RequestParser.Parsed(parsed.request().mergedWith(b.structured()).normalized(), parsed.mode(), parsed.note());
        } else {
            parsed = new RequestParser.Parsed(b.structured().normalized(), "rules", null);
        }
        PlanRequest r = parsed.request();
        List<String> missing = new ArrayList<>();
        if (r.destination() == null) missing.add("destination");
        if (r.days() == null) missing.add("days");
        if (!missing.isEmpty()) {
            usage(user, "travel-plan", parsed.mode(), started, false);
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("status", "needs_more_info");
            out.put("understood", r);
            out.put("missing", missing);
            out.put("questions", missing.stream().map(m -> "destination".equals(m) ? "Which destination would you like to visit?" : "How many days will you travel?").toList());
            out.put("availableDestinations", dests.stream().map(d -> Map.of("slug", d.slug(), "name", d.name())).toList());
            return out;
        }
        Plan plan = planner.polishSummary(planner.generate(r));
        UUID itineraryId = null;
        if (b.shouldSave()) {
            itineraryId = itineraries.savePlan(user.id(), plan, r, b.startDate(), false);
            notifications.notify(user.id(), "itinerary", "Itinerary saved", "\"" + plan.title() + "\" was saved to your trips.", Map.of("itineraryId", itineraryId));
        }
        usage(user, "travel-plan", plan.mode(), started, true);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("status", "ok");
        out.put("understood", r);
        out.put("understoodBy", parsed.mode());
        out.put("parserNote", parsed.note());
        out.put("plan", plan);
        out.put("itineraryId", itineraryId);
        return out;
    }

    public Answer ask(AssistantRequest b, AuthUser user) {
        long started = System.currentTimeMillis();
        Answer out = assistant.answer(b.question(), b.destination());
        usage(user, "assistant", out.mode(), started, out.grounded());
        if (user != null) {
            try {
                String sources = json.writeValueAsString(out.sources().stream().map(s -> Map.of("slug", s.slug(), "title", s.title())).toList());
                log.conversation(user.id(), b.question(), out.answer(), sources, out.mode());
            } catch (JsonProcessingException e) {
                // logging must never fail the answer
            }
        }
        return out;
    }

    /** Interest-ranked places and stays for a destination. Rule-based ranking, not a machine-learning prediction. */
    public Map<String, Object> recommend(RecommendationRequest b) {
        Map<String, Object> dest = destinations.findByIdOrSlug(b.destination()).orElseThrow(() -> ApiException.notFound("Destination"));
        List<String> interests = b.interests() == null ? List.of() : b.interests();
        int children = b.children() == null ? 0 : b.children();
        List<Map<String, Object>> scored = attractions.allForDestination(Rows.uuid(dest, "id")).stream().map(p -> {
            @SuppressWarnings("unchecked") List<String> tags = (List<String>) p.get("tags");
            List<String> hits = interests.stream().filter(i -> i.equals(p.get("category")) || tags.contains(i)).toList();
            double price = p.get("price_usd") == null ? -1 : ((Number) p.get("price_usd")).doubleValue();
            double score = hits.size() * 3 + (children > 0 && Boolean.TRUE.equals(p.get("family_friendly")) ? 2 : 0) + (price == 0 ? 0.5 : 0);
            Map<String, Object> m = new LinkedHashMap<>(Map.of("id", p.get("id"), "name", p.get("name"), "kind", p.get("kind"), "category", p.get("category"),
                "family_friendly", p.get("family_friendly"), "is_demo", p.get("is_demo"), "tags", p.get("tags")));
            m.put("price_usd", p.get("price_usd"));
            m.put("image", p.get("image"));
            m.put("score", score);
            m.put("matchedInterests", hits);
            return m;
        }).sorted(Comparator.comparingDouble((Map<String, Object> m) -> (double) m.get("score")).reversed()).limit(8).toList();
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("method", "rules");
        out.put("destination", Map.of("id", dest.get("id"), "name", dest.get("name"), "slug", dest.get("slug")));
        out.put("places", scored);
        out.put("accommodations", accommodations.recommend(Rows.uuid(dest, "id"), b.budgetPerNightUsd()));
        out.put("note", "Ranked by interest match from stored records. This is rule-based ranking, not a machine-learning prediction.");
        return out;
    }

    public Map<String, Object> sources() { return retrieval.sources(); }
}

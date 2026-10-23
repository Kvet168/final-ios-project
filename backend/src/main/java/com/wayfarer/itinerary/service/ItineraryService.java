package com.wayfarer.itinerary.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.ai.dto.PlanDtos.Plan;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import com.wayfarer.ai.service.PlannerService;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.common.Text;
import com.wayfarer.itinerary.dto.ItineraryDtos.CreateRequest;
import com.wayfarer.itinerary.dto.ItineraryDtos.DayEdit;
import com.wayfarer.itinerary.dto.ItineraryDtos.PatchRequest;
import com.wayfarer.itinerary.repository.ItineraryRepository;
import com.wayfarer.notification.service.NotificationService;
import com.wayfarer.security.AuthUser;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Saved trips: ownership rules, manual editing, re-pricing and regeneration. Plan generation itself lives in {@link PlannerService}. */
@Service
public class ItineraryService {
    private final ItineraryRepository itineraries;
    private final DestinationRepository destinations;
    private final AccommodationRepository accommodations;
    private final PlannerService planner;
    private final NotificationService notifications;
    private final AuditService audit;
    private final ObjectMapper json;

    public ItineraryService(ItineraryRepository itineraries, DestinationRepository destinations, AccommodationRepository accommodations, PlannerService planner,
                            NotificationService notifications, AuditService audit, ObjectMapper json) {
        this.itineraries = itineraries;
        this.destinations = destinations;
        this.accommodations = accommodations;
        this.planner = planner;
        this.notifications = notifications;
        this.audit = audit;
        this.json = json;
    }

    /* ------------------------------------------------------------ read */

    /** The itinerary row plus its days. */
    public Map<String, Object> load(UUID id) {
        Map<String, Object> it = itineraries.findDetail(id).orElseThrow(() -> ApiException.notFound("Itinerary"));
        List<Map<String, Object>> items = itineraries.items(id);
        List<PlannedDay> days = new ArrayList<>();
        for (int d = 1; d <= Rows.integer(it, "num_days"); d++) {
            final int day = d;
            List<PlannedItem> its = items.stream().filter(x -> Rows.integer(x, "day_index") == day).map(x -> new PlannedItem(
                (UUID) x.get("attraction_id"), Rows.str(x, "name"), Rows.str(x, "kind"), Rows.str(x, "category"), ((Number) x.get("lat")).doubleValue(),
                ((Number) x.get("lng")).doubleValue(), Rows.str(x, "image"), Rows.integer(x, "start_min"), Rows.integer(x, "duration_min"),
                Rows.integer(x, "travel_min_from_prev"), Rows.dec(x, "est_cost_usd").doubleValue(), x.get("reason") == null ? "" : Rows.str(x, "reason"),
                Boolean.TRUE.equals(x.get("is_demo")), Boolean.TRUE.equals(x.get("hours_verified")))).toList();
            days.add(new PlannedDay(day, its, round2(its.stream().mapToDouble(PlannedItem::costUsd).sum())));
        }
        Map<String, Object> out = new LinkedHashMap<>(it);
        out.put("days", days);
        return out;
    }

    /** Owners can read and write their trips; anyone can read a curated template. */
    private Map<String, Object> accessible(UUID id, AuthUser user, boolean write) {
        Map<String, Object> it = itineraries.findRaw(id).orElseThrow(() -> ApiException.notFound("Itinerary"));
        boolean mine = user != null && user.id().equals(it.get("user_id"));
        if (write && !mine) throw ApiException.notFound("Itinerary");
        if (!write && !mine && !Boolean.TRUE.equals(it.get("is_template"))) throw ApiException.notFound("Itinerary");
        return it;
    }

    public Map<String, Object> get(UUID id, AuthUser user) {
        accessible(id, user, false);
        return load(id);
    }

    public Map<String, Object> list(UUID userId) { return Map.of("items", itineraries.listForUser(userId)); }

    /* ------------------------------------------------------------ write */

    @Transactional
    public Map<String, Object> create(UUID userId, CreateRequest r) {
        Map<String, Object> dest = destinations.findByIdOrSlug(r.destination()).orElseThrow(() -> ApiException.notFound("Destination"));
        int days = r.days();
        UUID id = itineraries.insertManual(new MapSqlParameterSource().addValue("u", userId).addValue("d", dest.get("id"))
            .addValue("title", r.title() != null ? r.title() : days + "-day trip").addValue("start", r.startDate()).addValue("days", days)
            .addValue("adults", r.adults() == null ? 1 : r.adults()).addValue("children", r.children() == null ? 0 : r.children())
            .addValue("budget", r.budgetUsd() == null ? null : BigDecimal.valueOf(r.budgetUsd()))
            .addValue("interests", Text.pgArray(r.interests() == null ? List.of() : r.interests())).addValue("pace", r.pace() == null ? "balanced" : r.pace()));
        return load(id);
    }

    @Transactional
    public Map<String, Object> patch(UUID id, AuthUser user, PatchRequest b, boolean startDatePresent, boolean budgetPresent) {
        Map<String, Object> it = accessible(id, user, true);
        itineraries.updateFields(id, b.title(), startDatePresent, b.startDate(), b.adults(), b.children(), budgetPresent, b.budgetUsd());
        if (b.days() != null) for (DayEdit d : b.days()) rebuildDay(id, d.day(), d.items().stream().map(s -> s.attractionId()).toList());
        recalculate(id);
        notifications.notify(user.id(), "itinerary", "Itinerary updated", "Your trip \"" + (b.title() != null ? b.title() : it.get("title")) + "\" was changed and its estimate recalculated.",
            Map.of("itineraryId", id));
        return load(id);
    }

    @Transactional
    public void delete(UUID id, AuthUser user) {
        accessible(id, user, true);
        itineraries.delete(id);
        audit.record(user.id(), "itinerary.delete", "itinerary", id, Map.of());
    }

    @Transactional
    public Map<String, Object> generate(UUID id, AuthUser user, Integer day) {
        Map<String, Object> it = accessible(id, user, true);
        if (day != null) regenerateDay(id, day);
        else for (int d = 1; d <= Rows.integer(it, "num_days"); d++) regenerateDay(id, d);
        recalculate(id);
        return load(id);
    }

    @Transactional
    public Map<String, Object> recalculate(UUID id, AuthUser user) {
        accessible(id, user, true);
        Map<String, Object> totals = new LinkedHashMap<>(recalculate(id));
        totals.put("assumptions", List.of("Prices are stored indicative USD values; see itinerary assumptions."));
        return totals;
    }

    /** Copies a curated template (or your own trip) into your trips. */
    @Transactional
    public Map<String, Object> copy(UUID id, AuthUser user) {
        accessible(id, user, false);
        UUID copy = itineraries.copyHeader(id, user.id());
        itineraries.copyItems(id, copy);
        return load(copy);
    }

    /** Persists a generated plan as a trip (or a curated template when `template`). */
    @Transactional
    public UUID savePlan(UUID userIdOrNull, Plan plan, PlanRequest req, LocalDate startDate, boolean template) {
        String assumptions;
        try {
            assumptions = json.writeValueAsString(plan.assumptions());
        } catch (JsonProcessingException e) {
            assumptions = "[]";
        }
        UUID id = itineraries.insertPlanned(new MapSqlParameterSource().addValue("u", userIdOrNull).addValue("d", plan.destination().id())
            .addValue("title", plan.title()).addValue("summary", plan.summary()).addValue("start", startDate).addValue("days", plan.days().size())
            .addValue("adults", req.adults()).addValue("children", req.children())
            .addValue("budget", plan.budget().budgetUsd() == null ? null : BigDecimal.valueOf(plan.budget().budgetUsd()))
            .addValue("interests", Text.pgArray(req.interests())).addValue("pace", req.pace()).addValue("by", template ? "curated" : plan.mode())
            .addValue("acc", plan.lodging() == null ? null : plan.lodging().id()).addValue("total", BigDecimal.valueOf(plan.budget().totalUsd()))
            .addValue("assumptions", assumptions).addValue("template", template));
        for (PlannedDay d : plan.days()) {
            int pos = 0;
            for (PlannedItem i : d.items()) itineraries.insertItem(id, d.day(), pos++, i.attractionId(), i.startMin(), i.durationMin(), i.travelMinFromPrev(), i.costUsd(), i.reason());
        }
        return id;
    }

    /* ------------------------------------------------------------ editing and pricing */

    /** Re-schedules a day from an ordered list of attraction ids (edit, reorder, replace, remove) and re-prices it. */
    void rebuildDay(UUID itineraryId, int day, List<UUID> attractionIds) {
        Map<String, Object> it = itineraries.findRaw(itineraryId).orElseThrow(() -> ApiException.notFound("Itinerary"));
        if (day < 1 || day > Rows.integer(it, "num_days")) throw ApiException.unprocessable("INVALID_DAY", "Day is outside the itinerary");
        if (attractionIds.stream().distinct().count() != attractionIds.size()) throw ApiException.unprocessable("DUPLICATE_STOP", "A place can only appear once per day");
        List<PlannedItem> scheduled = planner.scheduleStops(Rows.uuid(it, "destination_id"), attractionIds, Rows.integer(it, "adults"), Rows.integer(it, "children"));
        itineraries.deleteDay(itineraryId, day);
        int pos = 0;
        for (PlannedItem i : scheduled) itineraries.insertItem(itineraryId, day, pos++, i.attractionId(), i.startMin(), i.durationMin(), i.travelMinFromPrev(), i.costUsd(), i.reason());
    }

    void regenerateDay(UUID itineraryId, int day) {
        Map<String, Object> it = itineraries.findRaw(itineraryId).orElseThrow(() -> ApiException.notFound("Itinerary"));
        if (day < 1 || day > Rows.integer(it, "num_days")) throw ApiException.unprocessable("INVALID_DAY", "Day is outside the itinerary");
        List<UUID> other = itineraries.attractionIds(itineraryId, null, day), current = itineraries.attractionIds(itineraryId, day, null);
        UUID accId = (UUID) it.get("accommodation_id");
        PlannedDay planned = planner.regenerateDay(it, day, other, current, accId == null ? null : accommodations.findLocation(accId).orElse(null));
        itineraries.deleteDay(itineraryId, day);
        int pos = 0;
        for (PlannedItem i : planned.items()) itineraries.insertItem(itineraryId, day, pos++, i.attractionId(), i.startMin(), i.durationMin(), i.travelMinFromPrev(), i.costUsd(), i.reason());
    }

    /** Re-prices every stop for the current party size and recomputes the trip total. */
    Map<String, Object> recalculate(UUID itineraryId) {
        Map<String, Object> it = itineraries.findRaw(itineraryId).orElseThrow(() -> ApiException.notFound("Itinerary"));
        int adults = Rows.integer(it, "adults"), children = Rows.integer(it, "children"), numDays = Rows.integer(it, "num_days");
        for (Map<String, Object> i : itineraries.itemPrices(itineraryId)) {
            double price = i.get("price_usd") == null ? 0 : ((Number) i.get("price_usd")).doubleValue();
            double c = "restaurant".equals(i.get("kind")) ? price * (adults + children * 0.6) : price * adults + price * 0.5 * children;
            itineraries.setItemCost(i.get("id"), round2(c));
        }
        double dailyBudget = ((Number) destinations.findById(Rows.uuid(it, "destination_id")).orElseThrow().get("daily_budget_usd")).doubleValue();
        Map<String, Object> lodging = it.get("accommodation_id") == null ? null : accommodations.findPricing((UUID) it.get("accommodation_id")).orElse(null);
        int rooms = Math.max(1, (int) Math.ceil(adults / 2.0)), nights = Math.max(0, numDays - 1);
        double lodgingUsd = lodging == null ? 0 : round2(num(lodging, "from_price_usd") * rooms * (1 + num(lodging, "tax_rate") + num(lodging, "service_fee_rate")) * nights);
        double activities = itineraries.sumItemCosts(itineraryId);
        double transport = round2(Math.max(4, Math.min(20, dailyBudget * 0.12)) * numDays);
        double breakfast = lodging != null && Boolean.TRUE.equals(lodging.get("breakfast_included")) ? 0 : round2(3.0 * (adults + children) * numDays);
        double total = round2(lodgingUsd + activities + transport + breakfast);
        itineraries.setTotal(itineraryId, total);
        Double budget = it.get("budget_usd") == null ? null : ((Number) it.get("budget_usd")).doubleValue();
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("totalUsd", total);
        out.put("lodgingUsd", lodgingUsd);
        out.put("activitiesAndMealsUsd", round2(activities));
        out.put("transportUsd", transport);
        out.put("breakfastAllowanceUsd", breakfast);
        out.put("withinBudget", budget == null ? null : total <= budget);
        out.put("budgetUsd", budget);
        return out;
    }

    private static double num(Map<String, Object> m, String k) { return ((Number) m.get(k)).doubleValue(); }

    private static double round2(double v) { return Math.round((v + Math.ulp(1.0)) * 100.0) / 100.0; }

    /** JSON body helper: tells PATCH whether a nullable field was explicitly sent. */
    public static boolean has(JsonNode body, String field) { return body != null && body.has(field); }
}

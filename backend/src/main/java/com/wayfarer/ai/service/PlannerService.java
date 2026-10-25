package com.wayfarer.ai.service;

import com.wayfarer.ai.dto.PlanDtos.Lodging;
import com.wayfarer.ai.dto.PlanDtos.Plan;
import com.wayfarer.ai.dto.PlanDtos.PlanBudget;
import com.wayfarer.ai.dto.PlanDtos.PlanDestination;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Builds grounded itineraries from stored records with a deterministic rules engine. When a language model is configured it may only
 * rewrite the summary sentence; structure, prices and hours always come from the database.
 */
@Service
public class PlannerService {
    private static final Logger log = LoggerFactory.getLogger(PlannerService.class);

    private final DestinationRepository destinations;
    private final AttractionRepository attractions;
    private final AccommodationRepository accommodations;
    private final LlmClient llm;

    public PlannerService(DestinationRepository destinations, AttractionRepository attractions, AccommodationRepository accommodations, LlmClient llm) {
        this.destinations = destinations;
        this.attractions = attractions;
        this.accommodations = accommodations;
        this.llm = llm;
    }

    private List<Place> pool(UUID destinationId) { return attractions.allForDestination(destinationId).stream().map(Place::from).toList(); }

    private record LodgingChoice(Map<String, Object> row, Lodging lodging, int rooms) {}

    private LodgingChoice chooseLodging(UUID destinationId, PlanRequest req, int nights, Double budgetUsd) {
        if (nights < 1) return null;
        List<Map<String, Object>> rows = accommodations.pricedForDestination(destinationId);
        if (rows.isEmpty()) return null;
        int rooms = Math.max(1, (int) Math.ceil(req.adults() / 2.0));
        Comparator<Map<String, Object>> byRatingThenPrice = (a, b) -> {
            int c = Double.compare(num(b, "rating_avg"), num(a, "rating_avg"));
            return c != 0 ? c : Double.compare(num(a, "from_price_usd"), num(b, "from_price_usd"));
        };
        Map<String, Object> chosen = rows.get(0);
        if (budgetUsd != null) {
            double lodgingBudget = (budgetUsd * 0.5) / nights;
            List<Map<String, Object>> ok = rows.stream().filter(r -> loaded(r, rooms) <= lodgingBudget).toList();
            if (!ok.isEmpty()) {
                List<Map<String, Object>> fam = req.children() > 0 ? ok.stream().filter(r -> Boolean.TRUE.equals(r.get("family_friendly"))).toList() : ok;
                chosen = (fam.isEmpty() ? ok : fam).stream().sorted(byRatingThenPrice).findFirst().orElseThrow();
            }
        } else {
            List<Map<String, Object>> fam = req.children() > 0 ? rows.stream().filter(r -> Boolean.TRUE.equals(r.get("family_friendly"))).toList() : rows;
            chosen = (fam.isEmpty() ? rows : fam).stream().sorted((a, b) -> Double.compare(num(b, "rating_avg"), num(a, "rating_avg"))).findFirst().orElseThrow();
        }
        double nightly = loaded(chosen, rooms);
        Lodging l = new Lodging(Rows.uuid(chosen, "id"), Rows.str(chosen, "name"), nightly, nights, Money.round2(nightly * nights),
            Boolean.TRUE.equals(chosen.get("breakfast_included")), Boolean.TRUE.equals(chosen.get("is_demo")));
        return new LodgingChoice(chosen, l, rooms);
    }

    private static double loaded(Map<String, Object> r, int rooms) {
        return Money.round2(num(r, "from_price_usd") * rooms * (1 + num(r, "tax_rate") + num(r, "service_fee_rate")));
    }

    private static double num(Map<String, Object> r, String k) { return ((Number) r.get(k)).doubleValue(); }

    public Plan generate(PlanRequest raw) {
        PlanRequest req = raw.normalized();
        if (req.destination() == null) throw ApiException.unprocessable("MISSING_DESTINATION", "Which destination would you like to visit?");
        if (req.days() == null) throw ApiException.unprocessable("MISSING_DURATION", "How many days is your trip?");
        Map<String, Object> dest = destinations.findByIdOrSlug(req.destination()).orElseThrow(() -> ApiException.notFound("Destination"));
        UUID destId = Rows.uuid(dest, "id");
        List<Place> pool = pool(destId);
        if (pool.isEmpty()) throw ApiException.unprocessable("NO_DATA", "We do not have attractions stored for " + dest.get("name") + " yet.");

        int days = req.days(), nights = Math.max(0, days - 1);
        Double totalBudget = req.budgetUsd() == null ? null : (req.budgetIsPerDay() ? req.budgetUsd() * days : req.budgetUsd());
        LodgingChoice lod = chooseLodging(destId, req, nights, totalBudget);
        DayScheduler.Anchor hotel = lod == null ? null : new DayScheduler.Anchor(num(lod.row, "lat"), num(lod.row, "lng"));

        Set<UUID> used = new HashSet<>();
        List<PlannedDay> planned = new ArrayList<>();
        DayScheduler.Slot slot = DayScheduler.slot(req.pace());
        for (int d = 1; d <= days; d++) planned.add(DayScheduler.buildDay(d, pool, used, req, hotel, slot));

        int people = req.adults() + req.children();
        double transportPerDay = Money.round2(Math.max(4, Math.min(20, num(dest, "daily_budget_usd") * 0.12)));
        List<PlannedItem> all = planned.stream().flatMap(d -> d.items().stream()).toList();
        double activitiesUsd = Money.round2(all.stream().filter(i -> !"restaurant".equals(i.kind())).mapToDouble(PlannedItem::costUsd).sum());
        double mealsPlanned = Money.round2(all.stream().filter(i -> "restaurant".equals(i.kind())).mapToDouble(PlannedItem::costUsd).sum());
        boolean breakfastIncluded = lod != null && lod.lodging.breakfastIncluded();
        double breakfastAllowance = breakfastIncluded ? 0 : Money.round2(3.0 * people * days);
        double foodUsd = Money.round2(mealsPlanned + breakfastAllowance);
        double transportUsd = Money.round2(transportPerDay * days);
        double lodgingUsd = lod == null ? 0 : lod.lodging.totalUsd();
        double total = Money.round2(lodgingUsd + activitiesUsd + foodUsd + transportUsd);
        List<Double> perDay = new ArrayList<>();
        for (int i = 0; i < planned.size(); i++) {
            perDay.add(Money.round2(planned.get(i).costUsd() + transportPerDay + (breakfastIncluded ? 0 : 3.0 * people) + (i < nights ? lodgingUsd / Math.max(1, nights) : 0)));
        }

        List<String> warnings = new ArrayList<>();
        List<Integer> emptyDays = planned.stream().filter(d -> d.items().isEmpty()).map(PlannedDay::day).toList();
        if (!emptyDays.isEmpty()) warnings.add("We only hold " + pool.size() + " listings for " + dest.get("name") + ", so day " + String.join(", ", emptyDays.stream().map(String::valueOf).toList()) + " has no suggestions yet.");
        Boolean withinBudget = totalBudget == null ? null : total <= totalBudget;
        if (totalBudget != null && !withinBudget) warnings.add("The estimate (" + trim(total) + " USD) is above your budget (" + trim(totalBudget) + " USD). Try fewer paid activities, a cheaper stay or fewer days.");
        if (all.stream().anyMatch(PlannedItem::isDemo)) warnings.add("Some stops are educational demo listings whose prices and hours are sample values.");

        List<String> assumptions = List.of(
            "Prices are the stored indicative values in USD; children are charged at 50% for activities and 60% for meals.",
            "Lodging: " + (lod != null ? nights + " night(s) at " + lod.lodging.name() + ", " + lod.rooms + " room(s), base nightly rate plus taxes and fees" : "not included") + ".",
            "Transport allowance of " + trim(transportPerDay) + " USD per day (tuk-tuk / ride-hailing estimate).",
            breakfastAllowance > 0 ? "Breakfast allowance of 3 USD per person per day because the stay does not include breakfast." : "Breakfast is included with the stay.",
            "Travel times between stops are straight-line estimates at ~22 km/h; they do not use live traffic.",
            "Opening hours are indicative unless marked verified; check locally before you go.");

        String title = days + " day" + (days > 1 ? "s" : "") + " in " + dest.get("name");
        String interests = req.interests().isEmpty() ? "" : " focused on " + String.join(", ", req.interests());
        String summary = "A " + req.pace() + " " + days + "-day plan for " + req.adults() + " adult" + (req.adults() > 1 ? "s" : "")
            + (req.children() > 0 ? " and " + req.children() + " child" + (req.children() > 1 ? "ren" : "") : "") + interests + ". Estimated total " + trim(total) + " USD.";

        return new Plan(title, summary, new PlanDestination(destId, Rows.str(dest, "slug"), Rows.str(dest, "name"), num(dest, "lat"), num(dest, "lng")), planned,
            lod == null ? null : lod.lodging, new PlanBudget(lodgingUsd, activitiesUsd, foodUsd, transportUsd, total, totalBudget, withinBudget, perDay),
            assumptions, warnings, "rules", "Built by WAYFARER's deterministic rules engine from stored database records. This is not an AI language-model output.");
    }

    /** Optional model pass: rewrite only the summary text, never the structured data. Falls back silently. */
    public Plan polishSummary(Plan plan) {
        if (!llm.configured()) return plan;
        try {
            String stops = String.join("\n", plan.days().stream().map(d -> "Day " + d.day() + ": " + String.join(", ", d.items().stream().map(PlannedItem::name).toList())).toList());
            String text = llm.complete("Write a warm, factual 2-sentence summary of this itinerary. Mention only the places listed. Do not add prices, hours or places.",
                plan.title() + "\n" + stops, 200, Duration.ofSeconds(8));
            if (!text.isBlank()) return plan.withSummary(text, "llm", "Structure and costs come from stored database records; the summary text was written by a language model.");
        } catch (Exception e) {
            log.warn("LLM summary failed, keeping rules summary: {}", e.getMessage());
        }
        return plan;
    }

    /** Schedules an ordered list of stops back to back (manual edits): travel time, opening hours and lunch time are respected. */
    public List<PlannedItem> scheduleStops(UUID destinationId, List<UUID> ids, int adults, int children) {
        Map<UUID, Place> byId = new java.util.HashMap<>();
        attractions.byIdsInDestination(ids, destinationId).forEach(r -> byId.put((UUID) r.get("id"), Place.from(r)));
        if (byId.size() != ids.size()) throw ApiException.unprocessable("UNKNOWN_PLACE", "One or more places do not exist in this destination");
        List<PlannedItem> out = new ArrayList<>();
        int cursor = DayScheduler.DAY_START;
        Place prev = null;
        for (UUID id : ids) {
            Place p = byId.get(id);
            int travel = prev == null ? 0 : DayScheduler.travelMin(prev, p);
            int start = cursor + travel;
            if (p.opensMin() != null && start < p.opensMin()) start = p.opensMin();
            if (p.isRestaurant() && start < 12 * 60 && !out.isEmpty()) start = 12 * 60;
            out.add(new PlannedItem(p.id(), p.name(), p.kind(), p.category(), p.lat(), p.lng(), p.image(), start, p.durationMin(), travel,
                DayScheduler.costFor(p, adults, children), "Added by you", p.isDemo(), p.hoursVerified()));
            cursor = start + p.durationMin();
            prev = p;
        }
        return out;
    }

    /** Builds a fresh day for an existing trip, preferring stops not used elsewhere (and not the day's current ones). */
    @SuppressWarnings("unchecked")
    public PlannedDay regenerateDay(Map<String, Object> itinerary, int day, List<UUID> usedOnOtherDays, List<UUID> currentOnThisDay, Map<String, Object> hotelLocation) {
        UUID destId = Rows.uuid(itinerary, "destination_id");
        List<Place> pool = pool(destId);
        PlanRequest req = new PlanRequest(destId.toString(), Rows.integer(itinerary, "num_days"), Rows.integer(itinerary, "adults"), Rows.integer(itinerary, "children"),
            itinerary.get("budget_usd") == null ? null : ((Number) itinerary.get("budget_usd")).doubleValue(), false,
            (List<String>) itinerary.get("interests"), Rows.str(itinerary, "pace"));
        DayScheduler.Anchor hotel = hotelLocation == null ? null : new DayScheduler.Anchor(num(hotelLocation, "lat"), num(hotelLocation, "lng"));
        DayScheduler.Slot slot = DayScheduler.slot(req.pace());
        Set<UUID> excluded = new HashSet<>(usedOnOtherDays);
        excluded.addAll(currentOnThisDay);
        PlannedDay built = DayScheduler.buildDay(day, pool, excluded, req, hotel, slot);
        if (built.items().isEmpty()) built = DayScheduler.buildDay(day, pool, new HashSet<>(usedOnOtherDays), req, hotel, slot);
        return built;
    }

    /** Whole numbers print without a decimal point, like the plan text elsewhere ("1500", "86.5"). */
    private static String trim(double v) { return v == Math.rint(v) ? String.valueOf((long) v) : String.valueOf(v); }
}

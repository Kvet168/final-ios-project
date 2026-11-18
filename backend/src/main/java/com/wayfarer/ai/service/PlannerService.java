package com.wayfarer.ai.service;

import com.wayfarer.ai.dto.PlanDtos.Lodging;
import com.wayfarer.ai.dto.PlanDtos.Plan;
import com.wayfarer.ai.dto.PlanDtos.PlanBudget;
import com.wayfarer.ai.dto.PlanDtos.PlanDestination;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import com.wayfarer.ai.dto.PlanDtos.Transfer;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Geo;
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

    /** [legNights] nights are needed in this city; [totalNights] and [budgetUsd] (the whole trip) set the nightly ceiling. */
    private LodgingChoice chooseLodging(UUID destinationId, String destinationSlug, PlanRequest req, int legNights, int totalNights, Double budgetUsd) {
        if (legNights < 1) return null;
        List<Map<String, Object>> rows = accommodations.pricedForDestination(destinationId);
        if (rows.isEmpty()) return null;
        int rooms = Math.max(1, (int) Math.ceil(req.adults() / 2.0));
        Comparator<Map<String, Object>> byRatingThenPrice = (a, b) -> {
            int c = Double.compare(num(b, "rating_avg"), num(a, "rating_avg"));
            return c != 0 ? c : Double.compare(num(a, "from_price_usd"), num(b, "from_price_usd"));
        };
        Map<String, Object> chosen = rows.get(0);
        if (budgetUsd != null) {
            double lodgingBudget = (budgetUsd * 0.5) / Math.max(1, totalNights);
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
        Lodging l = new Lodging(Rows.uuid(chosen, "id"), Rows.str(chosen, "name"), nightly, legNights, Money.round2(nightly * legNights),
            Boolean.TRUE.equals(chosen.get("breakfast_included")), Boolean.TRUE.equals(chosen.get("is_demo")), destinationSlug);
        return new LodgingChoice(chosen, l, rooms);
    }

    private static double loaded(Map<String, Object> r, int rooms) {
        return Money.round2(num(r, "from_price_usd") * rooms * (1 + num(r, "tax_rate") + num(r, "service_fee_rate")));
    }

    private static double num(Map<String, Object> r, String k) { return ((Number) r.get(k)).doubleValue(); }

    /** Average intercity speed and a bus-fare rate: documented estimates, not live timetables or prices. */
    private static final double INTERCITY_KMH = 50, INTERCITY_USD_PER_KM = 0.03;

    /** Fare estimate for the whole party over [roadKm] (children pay half). Also used when a saved trip is re-priced for a new party size. */
    public static double transferCost(double roadKm, int adults, int children) {
        return Money.round2(Math.max(2.0, roadKm * INTERCITY_USD_PER_KM) * (adults + 0.5 * children));
    }

    /** Getting between two cities: road distance (straight line times the detour factor), time and a fare estimate for the whole party. */
    static Transfer transfer(Map<String, Object> from, Map<String, Object> to, int adults, int children) {
        double straight = Geo.haversineKm(num(from, "lat"), num(from, "lng"), num(to, "lat"), num(to, "lng"));
        double roadKm = Math.round(straight * Geo.DETOUR_FACTOR);
        int minutes = (int) Math.round(roadKm / INTERCITY_KMH * 60);
        return new Transfer(Rows.str(from, "name"), roadKm, minutes, transferCost(roadKm, adults, children));
    }

    /** Days per city: the traveller's split when it adds up, otherwise as even as possible with the extra days going to the first cities. */
    static int[] allocateDays(int days, int cities, List<Integer> requested) {
        int[] out = new int[cities];
        if (requested != null && requested.size() == cities && requested.stream().allMatch(x -> x != null && x >= 1) && requested.stream().mapToInt(Integer::intValue).sum() == days) {
            for (int i = 0; i < cities; i++) out[i] = requested.get(i);
            return out;
        }
        for (int i = 0; i < cities; i++) out[i] = days / cities + (i < days % cities ? 1 : 0);
        return out;
    }

    private static String hoursMinutes(int minutes) {
        int h = minutes / 60, m = minutes % 60;
        return h == 0 ? m + " min" : m == 0 ? h + " h" : h + " h " + m + " min";
    }

    private static String joinNames(List<String> names, String last) {
        if (names.size() <= 1) return String.join("", names);
        return String.join(", ", names.subList(0, names.size() - 1)) + " " + last + " " + names.get(names.size() - 1);
    }

    public Plan generate(PlanRequest raw) {
        PlanRequest req = raw.normalized();
        List<String> keys = req.allDestinations();
        if (keys.isEmpty()) throw ApiException.unprocessable("MISSING_DESTINATION", "Which destination would you like to visit?");
        if (req.days() == null) throw ApiException.unprocessable("MISSING_DURATION", "How many days is your trip?");
        int days = req.days();

        List<Map<String, Object>> dests = new ArrayList<>();
        Set<UUID> seen = new HashSet<>();
        for (String k : keys) {
            Map<String, Object> d = destinations.findByIdOrSlug(k).orElseThrow(() -> ApiException.notFound("Destination"));
            if (seen.add(Rows.uuid(d, "id"))) dests.add(d);
        }
        List<String> warnings = new ArrayList<>();
        boolean explicitSplit = dests.size() == keys.size();
        if (dests.size() > days) {
            List<String> dropped = dests.subList(days, dests.size()).stream().map(d -> Rows.str(d, "name")).toList();
            warnings.add("A " + days + "-day trip has room for " + days + " cit" + (days == 1 ? "y" : "ies") + ", so " + joinNames(dropped, "and") + " was left out. Add days to include "
                + (dropped.size() == 1 ? "it" : "them") + ".");
            dests = new ArrayList<>(dests.subList(0, days));
            explicitSplit = false;
        }
        int n = dests.size();
        int[] legDays = allocateDays(days, n, explicitSplit ? req.daysPerDestination() : null);
        int totalNights = Math.max(0, days - 1);
        Double totalBudget = req.budgetUsd() == null ? null : (req.budgetIsPerDay() ? req.budgetUsd() * days : req.budgetUsd());
        int people = req.adults() + req.children();

        Set<UUID> used = new HashSet<>();
        List<PlannedDay> planned = new ArrayList<>();
        List<PlanDestination> infos = new ArrayList<>();
        List<Lodging> lodgings = new ArrayList<>();
        List<LodgingChoice> choices = new ArrayList<>();
        List<Double> perDay = new ArrayList<>();
        List<String> transferNotes = new ArrayList<>(), localTransport = new ArrayList<>();
        Map<String, Integer> poolSizes = new java.util.LinkedHashMap<>();
        DayScheduler.Slot slot = DayScheduler.slot(req.pace());
        double transportUsd = 0, breakfastUsd = 0, lodgingUsd = 0;
        int dayNo = 1;

        for (int i = 0; i < n; i++) {
            Map<String, Object> dest = dests.get(i);
            UUID destId = Rows.uuid(dest, "id");
            String name = Rows.str(dest, "name");
            List<Place> pool = pool(destId);
            if (pool.isEmpty()) throw ApiException.unprocessable("NO_DATA", "We do not have attractions stored for " + name + " yet.");
            poolSizes.put(name, pool.size());
            PlanDestination info = new PlanDestination(destId, Rows.str(dest, "slug"), name, num(dest, "lat"), num(dest, "lng"));
            infos.add(info);

            // Every city but the last is slept in for each of its days; the last city has no night after the final day.
            int legNights = i < n - 1 ? legDays[i] : Math.max(0, legDays[i] - 1);
            LodgingChoice lod = chooseLodging(destId, info.slug(), req, legNights, totalNights, totalBudget);
            choices.add(lod);
            if (lod != null) lodgings.add(lod.lodging);
            DayScheduler.Anchor hotel = lod == null ? null : new DayScheduler.Anchor(num(lod.row, "lat"), num(lod.row, "lng"));
            boolean breakfastIncluded = lod != null && lod.lodging.breakfastIncluded();
            double transportPerDay = Money.round2(Math.max(4, Math.min(20, num(dest, "daily_budget_usd") * 0.12)));
            localTransport.add(name + " " + trim(transportPerDay));

            Transfer tr = i == 0 ? null : transfer(dests.get(i - 1), dest, req.adults(), req.children());
            if (tr != null) {
                transferNotes.add("Transfer " + tr.fromName() + " to " + name + ": about " + trim(tr.km()) + " km by road, around " + hoursMinutes(tr.minutes())
                    + " (estimate), about " + trim(tr.costUsd()) + " USD for the party as a bus fare estimate; no live timetables.");
                if (tr.minutes() >= 240) {
                    warnings.add("Getting from " + tr.fromName() + " to " + name + " takes about " + hoursMinutes(tr.minutes()) + " by road, so day " + dayNo
                        + " starts late and has fewer stops. A flight or an early start may suit you better.");
                }
            }
            for (int k = 0; k < legDays[i]; k++, dayNo++) {
                Transfer dayTransfer = k == 0 ? tr : null;
                PlannedDay built = DayScheduler.buildDay(dayNo, pool, used, req, hotel, slot, dayTransfer == null ? 0 : dayTransfer.minutes()).in(info, dayTransfer);
                planned.add(built);
                double breakfast = breakfastIncluded ? 0 : 3.0 * people;
                double lodgingToday = lod != null && k < legNights ? lod.lodging.nightlyUsd() : 0;
                double transferToday = dayTransfer == null ? 0 : dayTransfer.costUsd();
                transportUsd += transportPerDay + transferToday;
                breakfastUsd += breakfast;
                perDay.add(Money.round2(built.costUsd() + transportPerDay + breakfast + lodgingToday + transferToday));
            }
            lodgingUsd += lod == null ? 0 : lod.lodging.totalUsd();
        }

        List<PlannedItem> all = planned.stream().flatMap(d -> d.items().stream()).toList();
        double activitiesUsd = Money.round2(all.stream().filter(i -> !"restaurant".equals(i.kind())).mapToDouble(PlannedItem::costUsd).sum());
        double mealsPlanned = Money.round2(all.stream().filter(i -> "restaurant".equals(i.kind())).mapToDouble(PlannedItem::costUsd).sum());
        double foodUsd = Money.round2(mealsPlanned + breakfastUsd);
        transportUsd = Money.round2(transportUsd);
        lodgingUsd = Money.round2(lodgingUsd);
        double total = Money.round2(lodgingUsd + activitiesUsd + foodUsd + transportUsd);

        // Days with nothing planned: expected on a long transfer day, otherwise the city is short of listings.
        Map<String, List<Integer>> emptyByCity = new java.util.LinkedHashMap<>();
        for (PlannedDay d : planned) {
            boolean longTransfer = d.transfer() != null && d.transfer().minutes() >= 360;
            if (d.items().isEmpty() && !longTransfer) emptyByCity.computeIfAbsent(d.destination().name(), x -> new ArrayList<>()).add(d.day());
        }
        emptyByCity.forEach((city, ds) -> warnings.add("We only hold " + poolSizes.get(city) + " listings for " + city + ", so day "
            + String.join(", ", ds.stream().map(String::valueOf).toList()) + " has no suggestions yet."));
        Boolean withinBudget = totalBudget == null ? null : total <= totalBudget;
        if (totalBudget != null && !withinBudget) warnings.add("The estimate (" + trim(total) + " USD) is above your budget (" + trim(totalBudget) + " USD). Try fewer paid activities, a cheaper stay or fewer days.");

        List<String> assumptions = new ArrayList<>();
        assumptions.add("Prices are the stored indicative values in USD; children are charged at 50% for activities and 60% for meals.");
        if (n == 1) {
            LodgingChoice lod = choices.get(0);
            assumptions.add("Lodging: " + (lod != null ? totalNights + " night(s) at " + lod.lodging.name() + ", " + lod.rooms + " room(s), base nightly rate plus taxes and fees" : "not included") + ".");
            assumptions.add("Transport allowance of " + localTransport.get(0).substring(infos.get(0).name().length() + 1) + " USD per day (tuk-tuk / ride-hailing estimate).");
        } else {
            List<String> stays = new ArrayList<>();
            for (int i = 0; i < n; i++) {
                LodgingChoice lod = choices.get(i);
                stays.add(lod == null ? "no stay in " + infos.get(i).name() : lod.lodging.nights() + " night(s) at " + lod.lodging.name() + " in " + infos.get(i).name() + " (" + lod.rooms + " room(s))");
            }
            assumptions.add("Lodging: " + String.join("; ", stays) + ", base nightly rates plus taxes and fees.");
            assumptions.add("Local transport allowance in USD per day: " + String.join(", ", localTransport) + " (tuk-tuk / ride-hailing estimate).");
            assumptions.addAll(transferNotes);
        }
        assumptions.add(breakfastUsd > 0 ? "Breakfast allowance of 3 USD per person per day wherever the stay does not include breakfast." : "Breakfast is included with the stay.");
        assumptions.add("Travel times between stops are straight-line estimates at ~22 km/h; they do not use live traffic.");
        assumptions.add("Opening hours are indicative unless marked verified; check locally before you go.");

        List<String> names = infos.stream().map(PlanDestination::name).toList();
        String title = days + " day" + (days > 1 ? "s" : "") + " in " + joinNames(names, "&");
        String interests = req.interests().isEmpty() ? "" : " focused on " + String.join(", ", req.interests());
        String party = req.adults() + " adult" + (req.adults() > 1 ? "s" : "") + (req.children() > 0 ? " and " + req.children() + " child" + (req.children() > 1 ? "ren" : "") : "");
        String summary = "A " + req.pace() + " " + days + "-day plan " + (n > 1 ? "across " + joinNames(names, "and") + " " : "") + "for " + party + interests + ". Estimated total " + trim(total) + " USD.";

        return new Plan(title, summary, infos.get(0), planned, lodgings.isEmpty() ? null : lodgings.get(0),
            new PlanBudget(lodgingUsd, activitiesUsd, foodUsd, transportUsd, total, totalBudget, withinBudget, perDay),
            assumptions, warnings, "rules", null, infos, lodgings);
    }

    /** Optional model pass: rewrite only the summary text, never the structured data. Falls back silently. */
    public Plan polishSummary(Plan plan) {
        if (!llm.configured()) return plan;
        try {
            String stops = String.join("\n", plan.days().stream().map(d -> "Day " + d.day() + (d.destination() == null ? "" : " (" + d.destination().name() + ")") + ": "
                + String.join(", ", d.items().stream().map(PlannedItem::name).toList())).toList());
            String text = llm.complete("Write a warm, factual 2-sentence summary of this itinerary. Mention only the places listed. Do not add prices, hours or places.",
                plan.title() + "\n" + stops, 200, Duration.ofSeconds(8));
            if (!text.isBlank()) return plan.withSummary(text, "llm", null);
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

    /**
     * Builds a fresh day for an existing trip in the day's own city, preferring stops not used elsewhere (and not the day's current ones).
     * [startOffsetMin] keeps the late start of a day that begins with a transfer.
     */
    @SuppressWarnings("unchecked")
    public PlannedDay regenerateDay(Map<String, Object> itinerary, int day, UUID destId, int startOffsetMin, List<UUID> usedOnOtherDays, List<UUID> currentOnThisDay, Map<String, Object> hotelLocation) {
        List<Place> pool = pool(destId);
        PlanRequest req = new PlanRequest(destId.toString(), Rows.integer(itinerary, "num_days"), Rows.integer(itinerary, "adults"), Rows.integer(itinerary, "children"),
            itinerary.get("budget_usd") == null ? null : ((Number) itinerary.get("budget_usd")).doubleValue(), false,
            (List<String>) itinerary.get("interests"), Rows.str(itinerary, "pace"));
        DayScheduler.Anchor hotel = hotelLocation == null ? null : new DayScheduler.Anchor(num(hotelLocation, "lat"), num(hotelLocation, "lng"));
        DayScheduler.Slot slot = DayScheduler.slot(req.pace());
        Set<UUID> excluded = new HashSet<>(usedOnOtherDays);
        excluded.addAll(currentOnThisDay);
        PlannedDay built = DayScheduler.buildDay(day, pool, excluded, req, hotel, slot, startOffsetMin);
        if (built.items().isEmpty()) built = DayScheduler.buildDay(day, pool, new HashSet<>(usedOnOtherDays), req, hotel, slot, startOffsetMin);
        return built;
    }

    /** Whole numbers print without a decimal point, like the plan text elsewhere ("1500", "86.5"). */
    private static String trim(double v) { return v == Math.rint(v) ? String.valueOf((long) v) : String.valueOf(v); }
}

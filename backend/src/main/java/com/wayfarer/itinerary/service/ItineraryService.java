package com.wayfarer.itinerary.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.ai.dto.PlanDtos.Plan;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import com.wayfarer.ai.dto.PlanDtos.PlanDestination;
import com.wayfarer.ai.dto.PlanDtos.Lodging;
import com.wayfarer.ai.dto.PlanDtos.Transfer;
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
        Map<Integer, Map<String, Object>> dayRows = new java.util.HashMap<>();
        itineraries.days(id).forEach(r -> dayRows.put(Rows.integer(r, "day_index"), r));
        for (int d = 1; d <= Rows.integer(it, "num_days"); d++) {
            final int day = d;
            List<PlannedItem> its = items.stream().filter(x -> Rows.integer(x, "day_index") == day).map(x -> new PlannedItem(
                (UUID) x.get("attraction_id"), Rows.str(x, "name"), Rows.str(x, "kind"), Rows.str(x, "category"), ((Number) x.get("lat")).doubleValue(),
                ((Number) x.get("lng")).doubleValue(), Rows.str(x, "image"), Rows.integer(x, "start_min"), Rows.integer(x, "duration_min"),
                Rows.integer(x, "travel_min_from_prev"), Rows.dec(x, "est_cost_usd").doubleValue(), x.get("reason") == null ? "" : Rows.str(x, "reason"),
                Boolean.TRUE.equals(x.get("is_demo")), Boolean.TRUE.equals(x.get("hours_verified")))).toList();
            Map<String, Object> row = dayRows.get(day);
            PlanDestination where = row == null ? null : new PlanDestination((UUID) row.get("destination_id"), Rows.str(row, "destination_slug"), Rows.str(row, "destination_name"),
                num(row, "dest_lat"), num(row, "dest_lng"));
            Transfer transfer = row == null || row.get("transfer_from") == null ? null
                : new Transfer(Rows.str(row, "transfer_from"), num(row, "transfer_km"), Rows.integer(row, "transfer_min"), num(row, "transfer_cost_usd"));
            days.add(new PlannedDay(day, its, round2(its.stream().mapToDouble(PlannedItem::costUsd).sum()), where, transfer));
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
        for (int d = 1; d <= days; d++) itineraries.insertDay(id, d, (UUID) dest.get("id"), null, null, null, 0, 0);
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
        itineraries.copyDays(id, copy);
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
        List<Lodging> stays = plan.lodgings() != null ? plan.lodgings() : plan.lodging() == null ? List.of() : List.of(plan.lodging());
        Map<String, Integer> nightsUsed = new java.util.HashMap<>();
        for (PlannedDay d : plan.days()) {
            PlanDestination where = d.destination() != null ? d.destination() : plan.destination();
            // The stay for this night: the city's stay for as many nights as it was chosen for (none after the last day).
            Lodging stay = stays.stream().filter(l -> l.destination() == null || l.destination().equals(where.slug())).findFirst().orElse(null);
            UUID acc = stay != null && nightsUsed.merge(where.slug(), 1, Integer::sum) <= stay.nights() ? stay.id() : null;
            Transfer t = d.transfer();
            itineraries.insertDay(id, d.day(), where.id(), acc, t == null ? null : t.fromName(), t == null ? null : t.km(), t == null ? 0 : t.minutes(), t == null ? 0 : t.costUsd());
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
        Map<String, Object> row = dayRow(itineraryId, it, day);
        List<PlannedItem> scheduled = planner.scheduleStops((UUID) row.get("destination_id"), attractionIds, Rows.integer(it, "adults"), Rows.integer(it, "children"));
        itineraries.deleteDay(itineraryId, day);
        int pos = 0;
        for (PlannedItem i : scheduled) itineraries.insertItem(itineraryId, day, pos++, i.attractionId(), i.startMin(), i.durationMin(), i.travelMinFromPrev(), i.costUsd(), i.reason());
    }

    void regenerateDay(UUID itineraryId, int day) {
        Map<String, Object> it = itineraries.findRaw(itineraryId).orElseThrow(() -> ApiException.notFound("Itinerary"));
        if (day < 1 || day > Rows.integer(it, "num_days")) throw ApiException.unprocessable("INVALID_DAY", "Day is outside the itinerary");
        List<UUID> other = itineraries.attractionIds(itineraryId, null, day), current = itineraries.attractionIds(itineraryId, day, null);
        Map<String, Object> row = dayRow(itineraryId, it, day);
        UUID destId = (UUID) row.get("destination_id");
        // The day is anchored to the stay used in its city (the last day of a trip has no night of its own).
        UUID accId = row.get("accommodation_id") != null ? (UUID) row.get("accommodation_id") : itineraries.stayIn(itineraryId, destId).orElse(null);
        PlannedDay planned = planner.regenerateDay(it, day, destId, Rows.integer(row, "transfer_min"), other, current, accId == null ? null : accommodations.findLocation(accId).orElse(null));
        itineraries.deleteDay(itineraryId, day);
        int pos = 0;
        for (PlannedItem i : planned.items()) itineraries.insertItem(itineraryId, day, pos++, i.attractionId(), i.startMin(), i.durationMin(), i.travelMinFromPrev(), i.costUsd(), i.reason());
    }

    /** The itinerary's day rows; a trip saved before cities were tracked per day is read as one city with the trip's stay. */
    private List<Map<String, Object>> dayRows(UUID itineraryId, Map<String, Object> it) {
        List<Map<String, Object>> rows = itineraries.days(itineraryId);
        if (!rows.isEmpty()) return rows;
        Map<String, Object> dest = destinations.findById((UUID) it.get("destination_id")).orElseThrow();
        List<Map<String, Object>> out = new ArrayList<>();
        for (int d = 1; d <= Rows.integer(it, "num_days"); d++) {
            Map<String, Object> r = new LinkedHashMap<>();
            r.put("day_index", d);
            r.put("destination_id", it.get("destination_id"));
            r.put("accommodation_id", d < Rows.integer(it, "num_days") ? it.get("accommodation_id") : null);
            r.put("transfer_min", 0);
            r.put("transfer_cost_usd", java.math.BigDecimal.ZERO);
            r.put("daily_budget_usd", dest.get("daily_budget_usd"));
            out.add(r);
        }
        return out;
    }

    private Map<String, Object> dayRow(UUID itineraryId, Map<String, Object> it, int day) {
        return dayRows(itineraryId, it).stream().filter(r -> Rows.integer(r, "day_index") == day).findFirst().orElseThrow(() -> ApiException.notFound("Itinerary day"));
    }

    /** Re-prices every stop, stay and transfer for the current party size and recomputes the trip total. */
    Map<String, Object> recalculate(UUID itineraryId) {
        Map<String, Object> it = itineraries.findRaw(itineraryId).orElseThrow(() -> ApiException.notFound("Itinerary"));
        int adults = Rows.integer(it, "adults"), children = Rows.integer(it, "children");
        for (Map<String, Object> i : itineraries.itemPrices(itineraryId)) {
            double price = i.get("price_usd") == null ? 0 : ((Number) i.get("price_usd")).doubleValue();
            double c = "restaurant".equals(i.get("kind")) ? price * (adults + children * 0.6) : price * adults + price * 0.5 * children;
            itineraries.setItemCost(i.get("id"), round2(c));
        }
        int rooms = Math.max(1, (int) Math.ceil(adults / 2.0)), people = adults + children;
        Map<UUID, Map<String, Object>> pricing = new java.util.HashMap<>();
        Map<UUID, UUID> cityStay = new java.util.HashMap<>();
        double lodgingUsd = 0, transport = 0, breakfast = 0;
        for (Map<String, Object> row : dayRows(itineraryId, it)) {
            UUID destId = (UUID) row.get("destination_id");
            int day = Rows.integer(row, "day_index");
            UUID night = (UUID) row.get("accommodation_id");
            UUID stayId = night != null ? night : cityStay.computeIfAbsent(destId, k -> itineraries.stayIn(itineraryId, k).orElse(null));
            Map<String, Object> stay = stayId == null ? null : pricing.computeIfAbsent(stayId, k -> accommodations.findPricing(k).orElse(null));
            if (night != null && stay != null) lodgingUsd += num(stay, "from_price_usd") * rooms * (1 + num(stay, "tax_rate") + num(stay, "service_fee_rate"));
            if (stay == null || !Boolean.TRUE.equals(stay.get("breakfast_included"))) breakfast += 3.0 * people;
            transport += Math.max(4, Math.min(20, num(row, "daily_budget_usd") * 0.12));
            if (row.get("transfer_from") != null) {
                double fare = PlannerService.transferCost(num(row, "transfer_km"), adults, children);
                itineraries.setTransferCost(itineraryId, day, fare);
                transport += fare;
            }
        }
        lodgingUsd = round2(lodgingUsd);
        transport = round2(transport);
        breakfast = round2(breakfast);
        double activities = itineraries.sumItemCosts(itineraryId);
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

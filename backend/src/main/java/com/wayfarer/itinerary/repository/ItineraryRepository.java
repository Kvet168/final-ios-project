package com.wayfarer.itinerary.repository;

import com.wayfarer.common.Db;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class ItineraryRepository {
    private final Db db;

    public ItineraryRepository(Db db) { this.db = db; }

    public List<Map<String, Object>> templates(int limit) {
        return db.list("SELECT i.id, i.title, i.summary, i.num_days, i.est_total_usd, i.interests, d.name AS destination_name, d.cover_image "
            + "FROM itineraries i JOIN destinations d ON d.id = i.destination_id WHERE i.is_template ORDER BY i.est_total_usd LIMIT :l", Map.of("l", limit));
    }

    public List<Map<String, Object>> listForUser(UUID userId) {
        return db.list("SELECT i.id, i.title, i.summary, i.num_days, i.start_date, i.est_total_usd, i.budget_usd, i.generated_by, i.updated_at, d.name AS destination_name, d.cover_image "
            + "FROM itineraries i JOIN destinations d ON d.id = i.destination_id WHERE i.user_id = :u ORDER BY i.updated_at DESC", Map.of("u", userId));
    }

    public Optional<Map<String, Object>> findDetail(UUID id) {
        return db.one("SELECT i.*, d.name AS destination_name, d.slug AS destination_slug, d.lat AS dest_lat, d.lng AS dest_lng, a.name AS accommodation_name "
            + "FROM itineraries i JOIN destinations d ON d.id = i.destination_id LEFT JOIN accommodations a ON a.id = i.accommodation_id WHERE i.id = :id", Map.of("id", id));
    }

    public Optional<Map<String, Object>> findRaw(UUID id) { return db.one("SELECT * FROM itineraries WHERE id = :id", Map.of("id", id)); }

    public List<Map<String, Object>> items(UUID id) {
        return db.list("SELECT ii.day_index, ii.position, ii.attraction_id, ii.start_min, ii.duration_min, ii.travel_min_from_prev, ii.est_cost_usd, ii.reason, "
            + "a.name, a.kind, a.category, a.lat, a.lng, a.image, a.is_demo, a.hours_verified, a.price_usd FROM itinerary_items ii JOIN attractions a ON a.id = ii.attraction_id "
            + "WHERE ii.itinerary_id = :id ORDER BY ii.day_index, ii.position", Map.of("id", id));
    }

    public UUID insertManual(MapSqlParameterSource p) {
        return (UUID) db.one("INSERT INTO itineraries(user_id, destination_id, title, start_date, num_days, adults, children, budget_usd, interests, pace, generated_by) "
            + "VALUES (:u, :d, :title, :start, :days, :adults, :children, :budget, CAST(:interests AS text[]), :pace, 'manual') RETURNING id", p).orElseThrow().get("id");
    }

    public UUID insertPlanned(MapSqlParameterSource p) {
        return (UUID) db.one("INSERT INTO itineraries(user_id, destination_id, title, summary, start_date, num_days, adults, children, budget_usd, interests, pace, generated_by, "
            + "accommodation_id, est_total_usd, assumptions, is_template) VALUES (:u, :d, :title, :summary, :start, :days, :adults, :children, :budget, CAST(:interests AS text[]), :pace, "
            + ":by, :acc, :total, CAST(:assumptions AS jsonb), :template) RETURNING id", p).orElseThrow().get("id");
    }

    public void insertItem(UUID itineraryId, int day, int position, UUID attractionId, int startMin, int durationMin, int travelMin, double cost, String reason) {
        db.update("INSERT INTO itinerary_items(itinerary_id, day_index, position, attraction_id, start_min, duration_min, travel_min_from_prev, est_cost_usd, reason) "
            + "VALUES (:i, :d, :p, :a, :s, :dur, :t, :c, :r)", Db.params().addValue("i", itineraryId).addValue("d", day).addValue("p", position).addValue("a", attractionId)
            .addValue("s", startMin).addValue("dur", durationMin).addValue("t", travelMin).addValue("c", BigDecimal.valueOf(cost)).addValue("r", reason));
    }

    public void deleteDay(UUID itineraryId, int day) { db.update("DELETE FROM itinerary_items WHERE itinerary_id = :i AND day_index = :d", Map.of("i", itineraryId, "d", day)); }

    public List<UUID> attractionIds(UUID itineraryId, Integer onlyDay, Integer exceptDay) {
        String where = onlyDay != null ? " AND day_index = :day" : exceptDay != null ? " AND day_index <> :day" : "";
        Map<String, Object> p = new java.util.HashMap<>(Map.of("i", itineraryId));
        if (onlyDay != null) p.put("day", onlyDay);
        if (exceptDay != null) p.put("day", exceptDay);
        return db.list("SELECT attraction_id FROM itinerary_items WHERE itinerary_id = :i" + where, p).stream().map(r -> (UUID) r.get("attraction_id")).toList();
    }

    public List<Map<String, Object>> itemPrices(UUID itineraryId) {
        return db.list("SELECT ii.id, a.price_usd, a.kind FROM itinerary_items ii JOIN attractions a ON a.id = ii.attraction_id WHERE ii.itinerary_id = :i", Map.of("i", itineraryId));
    }

    public void setItemCost(Object itemId, double cost) { db.update("UPDATE itinerary_items SET est_cost_usd = :c WHERE id = :id", Map.of("c", BigDecimal.valueOf(cost), "id", itemId)); }

    public double sumItemCosts(UUID itineraryId) {
        return ((Number) db.one("SELECT COALESCE(SUM(est_cost_usd), 0) AS s FROM itinerary_items WHERE itinerary_id = :i", Map.of("i", itineraryId)).orElseThrow().get("s")).doubleValue();
    }

    public void setTotal(UUID itineraryId, double total) { db.update("UPDATE itineraries SET est_total_usd = :t, updated_at = now() WHERE id = :id", Map.of("t", BigDecimal.valueOf(total), "id", itineraryId)); }

    public void updateFields(UUID id, String title, boolean setStart, java.time.LocalDate start, Integer adults, Integer children, boolean setBudget, Double budget) {
        db.update("UPDATE itineraries SET title = COALESCE(:title, title), start_date = CASE WHEN :setStart THEN :start ELSE start_date END, adults = COALESCE(:adults, adults), "
            + "children = COALESCE(:children, children), budget_usd = CASE WHEN :setBudget THEN :budget ELSE budget_usd END, updated_at = now() WHERE id = :id",
            Db.params().addValue("id", id).addValue("title", title).addValue("setStart", setStart).addValue("start", start).addValue("adults", adults)
                .addValue("children", children).addValue("setBudget", setBudget).addValue("budget", budget == null ? null : BigDecimal.valueOf(budget)));
    }

    public void delete(UUID id) { db.update("DELETE FROM itineraries WHERE id = :id", Map.of("id", id)); }

    public UUID copyHeader(UUID sourceId, UUID newOwner) {
        return (UUID) db.one("INSERT INTO itineraries(user_id, destination_id, title, summary, num_days, adults, children, budget_usd, interests, pace, generated_by, accommodation_id, est_total_usd, assumptions) "
            + "SELECT :u, destination_id, title, summary, num_days, adults, children, budget_usd, interests, pace, 'manual', accommodation_id, est_total_usd, assumptions FROM itineraries WHERE id = :id RETURNING id",
            Map.of("u", newOwner, "id", sourceId)).orElseThrow().get("id");
    }

    public void copyItems(UUID sourceId, UUID targetId) {
        db.update("INSERT INTO itinerary_items(itinerary_id, day_index, position, attraction_id, start_min, duration_min, travel_min_from_prev, est_cost_usd, reason) "
            + "SELECT :t, day_index, position, attraction_id, start_min, duration_min, travel_min_from_prev, est_cost_usd, reason FROM itinerary_items WHERE itinerary_id = :s",
            Map.of("t", targetId, "s", sourceId));
    }
}

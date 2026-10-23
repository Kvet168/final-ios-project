package com.wayfarer.catalog.repository;

import com.wayfarer.catalog.dto.PlaceQuery;
import com.wayfarer.common.Db;
import com.wayfarer.common.Text;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class AttractionRepository {
    private final Db db;

    public AttractionRepository(Db db) { this.db = db; }

    public Optional<Map<String, Object>> findByIdOrSlug(String key) {
        boolean byId = Db.isUuid(key);
        return db.one("SELECT t.*, d.name AS destination_name, d.slug AS destination_slug FROM attractions t JOIN destinations d ON d.id = t.destination_id "
            + "WHERE " + (byId ? "t.id = :k" : "t.slug = :k") + " AND t.deleted_at IS NULL", Map.of("k", byId ? UUID.fromString(key) : key));
    }

    /** Top places for a destination page: everything except restaurants, most expensive first. */
    public List<Map<String, Object>> topForDestination(UUID destinationId, int limit) {
        return db.list("SELECT id, slug, kind, category, name, image, price_usd, duration_min, lat, lng, is_demo FROM attractions "
            + "WHERE destination_id = :id AND deleted_at IS NULL AND kind <> 'restaurant' ORDER BY price_usd DESC NULLS LAST LIMIT :l", Map.of("id", destinationId, "l", limit));
    }

    public List<Map<String, Object>> categoryCounts() {
        return db.list("SELECT category, COUNT(*)::int AS count FROM attractions WHERE deleted_at IS NULL GROUP BY category ORDER BY count DESC");
    }

    /** Lists places of one destination (destinationId set) or across the catalogue (destination key in the query). */
    public List<Map<String, Object>> search(PlaceQuery q, UUID destinationId) {
        MapSqlParameterSource ps = Db.params();
        List<String> where = new ArrayList<>(List.of("t.deleted_at IS NULL"));
        if (destinationId != null) { ps.addValue("dest", destinationId); where.add("t.destination_id = :dest"); }
        else if (q.destination() != null) {
            if (Db.isUuid(q.destination())) { ps.addValue("dest", UUID.fromString(q.destination())); where.add("t.destination_id = :dest"); }
            else { ps.addValue("dest", q.destination()); where.add("d.slug = :dest"); }
        }
        if (q.kind() != null) { ps.addValue("kind", q.kind()); where.add("t.kind = :kind"); }
        if (q.category() != null) { ps.addValue("cat", q.category()); where.add("t.category = :cat"); }
        if (q.q() != null && !q.q().isBlank()) { ps.addValue("q", Text.like(q.q())); where.add("t.name ILIKE :q"); }
        if (Boolean.TRUE.equals(q.familyFriendly())) where.add("t.family_friendly");
        String order = switch (q.sort()) {
            case "price_asc" -> "t.price_usd NULLS LAST";
            case "price_desc" -> "t.price_usd DESC NULLS LAST";
            case "duration" -> "t.duration_min";
            default -> "t.name";
        };
        ps.addValue("limit", q.pageSize()).addValue("offset", (q.page() - 1) * q.pageSize());
        return db.list("SELECT t.id, t.slug, t.kind, t.category, t.name, t.description, t.lat, t.lng, t.image, t.image_credit, t.price_usd, t.duration_min, "
            + "t.opens_min, t.closes_min, t.hours_verified, t.tips, t.tags, t.family_friendly, t.is_demo, d.name AS destination_name, d.slug AS destination_slug, "
            + "COUNT(*) OVER () AS total_count FROM attractions t JOIN destinations d ON d.id = t.destination_id WHERE " + String.join(" AND ", where)
            + " ORDER BY " + order + " LIMIT :limit OFFSET :offset", ps);
    }

    public List<Map<String, Object>> allForDestination(UUID destinationId) {
        return db.list("SELECT id, slug, name, kind, category, description, lat, lng, image, price_usd, duration_min, opens_min, closes_min, "
            + "hours_verified, tags, family_friendly, is_demo FROM attractions WHERE destination_id = :d AND deleted_at IS NULL", Map.of("d", destinationId));
    }

    public List<Map<String, Object>> byIdsInDestination(List<UUID> ids, UUID destinationId) {
        if (ids.isEmpty()) return List.of();
        return db.list("SELECT id, slug, name, kind, category, description, lat, lng, image, price_usd, duration_min, opens_min, closes_min, hours_verified, tags, "
            + "family_friendly, is_demo FROM attractions WHERE id IN (:ids) AND destination_id = :d AND deleted_at IS NULL", Map.of("ids", ids, "d", destinationId));
    }

    /** Assistant cards: sights (or restaurants when `food`), best-illustrated first. */
    public List<Map<String, Object>> cardsForDestination(UUID destinationId, boolean food, int limit) {
        return db.list("SELECT name, category, image, price_usd FROM attractions WHERE destination_id = :d AND deleted_at IS NULL AND ((kind = 'restaurant') = :food) "
            + "ORDER BY (image IS NOT NULL) DESC, (price_usd = 0) DESC, name LIMIT :l", Map.of("d", destinationId, "food", food, "l", limit));
    }

    public List<Map<String, Object>> gazetteer(String likeTerm) {
        return db.list("(SELECT 'destination' AS type, id, slug, name, country AS subtitle, lat, lng FROM destinations WHERE deleted_at IS NULL AND name ILIKE :q ORDER BY name LIMIT 5) "
            + "UNION ALL (SELECT 'attraction', t.id, t.slug, t.name, d.name, t.lat, t.lng FROM attractions t JOIN destinations d ON d.id = t.destination_id WHERE t.deleted_at IS NULL AND t.name ILIKE :q ORDER BY t.name LIMIT 8) "
            + "UNION ALL (SELECT 'accommodation', a.id, a.slug, a.name, d.name, a.lat, a.lng FROM accommodations a JOIN destinations d ON d.id = a.destination_id WHERE a.deleted_at IS NULL AND a.name ILIKE :q ORDER BY a.name LIMIT 8)",
            Map.of("q", likeTerm));
    }
}

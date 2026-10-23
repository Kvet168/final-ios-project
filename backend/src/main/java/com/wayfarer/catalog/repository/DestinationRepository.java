package com.wayfarer.catalog.repository;

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
public class DestinationRepository {
    private static final String CARD_COLUMNS = "id, slug, name, country, short_description, cover_image, image_credit, daily_budget_usd, tags";

    private final Db db;

    public DestinationRepository(Db db) { this.db = db; }

    public Optional<Map<String, Object>> findByIdOrSlug(String key) {
        boolean byId = Db.isUuid(key);
        return db.one("SELECT * FROM destinations WHERE " + (byId ? "id = :k" : "slug = :k") + " AND deleted_at IS NULL",
            Map.of("k", byId ? UUID.fromString(key) : key));
    }

    public Optional<Map<String, Object>> findById(UUID id) {
        return db.one("SELECT * FROM destinations WHERE id = :id AND deleted_at IS NULL", Map.of("id", id));
    }

    public List<Map<String, Object>> listAllSlugs() {
        return db.list("SELECT slug, name, country FROM destinations WHERE deleted_at IS NULL ORDER BY name");
    }

    public List<Map<String, Object>> search(String q, String country, String tag, Boolean international, Boolean featured, String orderBy, int limit, int offset) {
        MapSqlParameterSource ps = Db.params();
        List<String> where = new ArrayList<>(List.of("deleted_at IS NULL"));
        if (q != null && !q.isBlank()) {
            ps.addValue("q", Text.like(q));
            where.add("(name ILIKE :q OR country ILIKE :q OR short_description ILIKE :q)");
        }
        if (country != null) { ps.addValue("country", country); where.add("country = :country"); }
        if (tag != null) { ps.addValue("tag", tag); where.add(":tag = ANY(tags)"); }
        if (international != null) where.add("is_international = " + international);
        if (Boolean.TRUE.equals(featured)) where.add("is_featured");
        ps.addValue("limit", limit).addValue("offset", offset);
        return db.list("SELECT id, slug, name, country, region, is_international, short_description, lat, lng, cover_image, image_credit, daily_budget_usd, currency, tags, is_featured, "
            + "(SELECT COUNT(*)::int FROM accommodations a WHERE a.destination_id = destinations.id AND a.deleted_at IS NULL) AS accommodation_count, "
            + "(SELECT COUNT(*)::int FROM attractions t WHERE t.destination_id = destinations.id AND t.deleted_at IS NULL) AS place_count, "
            + "COUNT(*) OVER () AS total_count FROM destinations WHERE " + String.join(" AND ", where)
            + " ORDER BY " + orderBy + ", name LIMIT :limit OFFSET :offset", ps);
    }

    /** Facts the assistant answers from (best period, transport, practical tips, budget). */
    public List<Map<String, Object>> assistantFacts() {
        return db.list("SELECT id, slug, name, country, short_description, best_period, transport_info, practical_info, daily_budget_usd, cover_image FROM destinations WHERE deleted_at IS NULL");
    }

    public List<Map<String, Object>> featured(int limit) {
        return db.list("SELECT " + CARD_COLUMNS + " FROM destinations WHERE deleted_at IS NULL AND is_featured ORDER BY popularity DESC LIMIT :l", Map.of("l", limit));
    }

    public List<Map<String, Object>> trending(int limit) {
        return db.list("SELECT " + CARD_COLUMNS + " FROM destinations WHERE deleted_at IS NULL ORDER BY popularity DESC LIMIT :l", Map.of("l", limit));
    }

    public List<Map<String, Object>> images(UUID id) {
        return db.list("SELECT url, caption, credit FROM destination_images WHERE destination_id = :id ORDER BY position", Map.of("id", id));
    }

    public List<Map<String, Object>> related(UUID id) {
        return db.list("SELECT r.id, r.slug, r.name, r.country, r.cover_image, r.lat, r.lng, r.short_description, r.daily_budget_usd FROM related_destinations rd "
            + "JOIN destinations r ON r.id = rd.related_id WHERE rd.destination_id = :id AND r.deleted_at IS NULL", Map.of("id", id));
    }

    public List<Map<String, Object>> guides(UUID id) {
        return db.list("SELECT slug, title, category FROM travel_documents WHERE destination_id = :id OR destination_id IS NULL "
            + "ORDER BY (destination_id IS NULL), title LIMIT 8", Map.of("id", id));
    }

    public Map<String, Object> counts() {
        return db.one("SELECT (SELECT COUNT(*) FROM destinations WHERE deleted_at IS NULL) AS destinations, "
            + "(SELECT COUNT(*) FROM accommodations WHERE deleted_at IS NULL) AS accommodations, "
            + "(SELECT COUNT(*) FROM attractions WHERE deleted_at IS NULL) AS places", Map.of()).orElseThrow();
    }

    public boolean slugExists(String slug) { return db.exists("SELECT 1 FROM destinations WHERE slug = :s", Map.of("s", slug)); }

    public Map<String, Object> insert(MapSqlParameterSource p) {
        return db.one("INSERT INTO destinations(slug, name, country, region, is_international, short_description, long_description, lat, lng, cover_image, "
            + "daily_budget_usd, currency, tags, is_featured, is_demo) VALUES (:slug, :name, :country, :region, :intl, :shortDesc, :longDesc, :lat, :lng, :cover, "
            + ":budget, :currency, CAST(:tags AS text[]), :featured, false) RETURNING *", p).orElseThrow();
    }

    /** @param assignments SQL fragments like "name = :name" built from a whitelist by the service. */
    public Optional<Map<String, Object>> update(UUID id, List<String> assignments, MapSqlParameterSource p) {
        p.addValue("id", id);
        return db.one("UPDATE destinations SET " + String.join(", ", assignments) + " WHERE id = :id AND deleted_at IS NULL RETURNING *", p);
    }

    public boolean softDelete(UUID id) {
        return db.update("UPDATE destinations SET deleted_at = now() WHERE id = :id AND deleted_at IS NULL", Map.of("id", id)) > 0;
    }
}

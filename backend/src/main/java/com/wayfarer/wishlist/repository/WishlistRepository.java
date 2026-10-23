package com.wayfarer.wishlist.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
public class WishlistRepository {
    /** Table to check when a kind of item is saved (the schema keeps ref_id polymorphic, so existence is verified here). */
    private static final Map<String, String> TABLES = Map.of("destination", "destinations", "accommodation", "accommodations", "attraction", "attractions");

    private final Db db;

    public WishlistRepository(Db db) { this.db = db; }

    public static boolean isKind(String kind) { return TABLES.containsKey(kind); }

    public List<Map<String, Object>> list(UUID userId) {
        return db.list("SELECT w.kind, w.ref_id, w.created_at, COALESCE(d.name, a.name, t.name) AS name, COALESCE(d.slug, a.slug, t.slug) AS slug, "
            + "COALESCE(d.cover_image, a.cover_image, t.image) AS image FROM wishlist_items w "
            + "LEFT JOIN destinations d ON w.kind = 'destination' AND d.id = w.ref_id "
            + "LEFT JOIN accommodations a ON w.kind = 'accommodation' AND a.id = w.ref_id "
            + "LEFT JOIN attractions t ON w.kind = 'attraction' AND t.id = w.ref_id WHERE w.user_id = :u ORDER BY w.created_at DESC", Map.of("u", userId));
    }

    public boolean targetExists(String kind, UUID id) {
        return db.exists("SELECT 1 FROM " + TABLES.get(kind) + " WHERE id = :id AND deleted_at IS NULL", Map.of("id", id));
    }

    public void add(UUID userId, String kind, UUID refId) {
        db.update("INSERT INTO wishlist_items(user_id, kind, ref_id) VALUES (:u, :k, :r) ON CONFLICT DO NOTHING", Map.of("u", userId, "k", kind, "r", refId));
    }

    public void remove(UUID userId, String kind, UUID refId) {
        db.update("DELETE FROM wishlist_items WHERE user_id = :u AND kind = :k AND ref_id = :r", Map.of("u", userId, "k", kind, "r", refId));
    }

    public List<Map<String, Object>> searchHistory(UUID userId) {
        return db.list("SELECT query, MAX(created_at) AS last_used FROM search_history WHERE user_id = :u GROUP BY query ORDER BY last_used DESC LIMIT 10", Map.of("u", userId));
    }

    public void recordSearch(UUID userId, String query) { db.update("INSERT INTO search_history(user_id, query) VALUES (:u, :q)", Map.of("u", userId, "q", query)); }
}

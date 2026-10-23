package com.wayfarer.review.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class ReviewRepository {
    private final Db db;

    public ReviewRepository(Db db) { this.db = db; }

    public List<Map<String, Object>> published(UUID accommodationId, int limit, int offset) {
        return db.list("SELECT r.id, r.rating, r.title, r.body, r.is_demo, r.created_at, u.name AS author, (r.booking_id IS NOT NULL) AS verified_stay, COUNT(*) OVER () AS total_count "
            + "FROM reviews r JOIN users u ON u.id = r.user_id WHERE r.accommodation_id = :a AND r.status = 'published' ORDER BY r.created_at DESC LIMIT :l OFFSET :o",
            Map.of("a", accommodationId, "l", limit, "o", offset));
    }

    public boolean exists(UUID accommodationId, UUID userId) { return db.exists("SELECT 1 FROM reviews WHERE accommodation_id = :a AND user_id = :u", Map.of("a", accommodationId, "u", userId)); }

    public Map<String, Object> insert(UUID accommodationId, UUID userId, UUID bookingId, int rating, String title, String body) {
        return db.one("INSERT INTO reviews(accommodation_id, user_id, booking_id, rating, title, body) VALUES (:a, :u, :b, :r, :t, :body) RETURNING id, rating, title, body, created_at",
            Db.params().addValue("a", accommodationId).addValue("u", userId).addValue("b", bookingId).addValue("r", rating).addValue("t", title).addValue("body", body)).orElseThrow();
    }

    public List<Map<String, Object>> forUser(UUID userId) {
        return db.list("SELECT r.id, r.rating, r.title, r.body, r.status, r.created_at, a.name AS accommodation_name, a.slug AS accommodation_slug "
            + "FROM reviews r JOIN accommodations a ON a.id = r.accommodation_id WHERE r.user_id = :u ORDER BY r.created_at DESC", Map.of("u", userId));
    }

    public List<Map<String, Object>> moderationList(String status, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("l", limit).addValue("o", offset);
        String where = "true";
        if (status != null) { ps.addValue("s", status); where = "r.status = :s"; }
        return db.list("SELECT r.id, r.rating, r.title, r.body, r.status, r.is_demo, r.created_at, a.name AS accommodation_name, u.name AS author, COUNT(*) OVER () AS total_count "
            + "FROM reviews r JOIN accommodations a ON a.id = r.accommodation_id JOIN users u ON u.id = r.user_id WHERE " + where + " ORDER BY r.created_at DESC LIMIT :l OFFSET :o", ps);
    }

    /** @return the accommodation the review belongs to, when it exists. */
    public Optional<UUID> setStatus(UUID id, String status) {
        return db.one("UPDATE reviews SET status = :s WHERE id = :id RETURNING accommodation_id", Map.of("s", status, "id", id)).map(r -> (UUID) r.get("accommodation_id"));
    }
}

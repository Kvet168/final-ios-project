package com.wayfarer.notification.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
public class NotificationRepository {
    private final Db db;

    public NotificationRepository(Db db) { this.db = db; }

    public void insert(UUID userId, String type, String title, String body, String dataJson) {
        db.update("INSERT INTO notifications(user_id, type, title, body, data) VALUES (:u, :t, :title, :body, CAST(:d AS jsonb))",
            Db.params().addValue("u", userId).addValue("t", type).addValue("title", title).addValue("body", body).addValue("d", dataJson));
    }

    public List<Map<String, Object>> latest(UUID userId, int limit) {
        return db.list("SELECT id, type, title, body, data, read_at, created_at FROM notifications WHERE user_id = :u ORDER BY created_at DESC LIMIT " + limit, Map.of("u", userId));
    }

    public boolean markRead(UUID id, UUID userId) {
        return db.update("UPDATE notifications SET read_at = COALESCE(read_at, now()) WHERE id = :id AND user_id = :u", Map.of("id", id, "u", userId)) > 0;
    }

    public void markAllRead(UUID userId) { db.update("UPDATE notifications SET read_at = now() WHERE user_id = :u AND read_at IS NULL", Map.of("u", userId)); }
}

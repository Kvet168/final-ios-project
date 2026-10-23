package com.wayfarer.auth.repository;

import com.wayfarer.common.Db;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
public class PasswordResetRepository {
    private final Db db;

    public PasswordResetRepository(Db db) { this.db = db; }

    public void insert(UUID userId, String tokenHash, int minutes) {
        db.update("INSERT INTO password_resets(user_id, token_hash, expires_at) VALUES (:u, :h, now() + make_interval(mins => :m))", Map.of("u", userId, "h", tokenHash, "m", minutes));
    }

    public Optional<Map<String, Object>> findUsableForUpdate(String tokenHash) {
        return db.one("SELECT id, user_id FROM password_resets WHERE token_hash = :h AND used_at IS NULL AND expires_at > now() FOR UPDATE", Map.of("h", tokenHash));
    }

    public void markUsed(Object id) { db.update("UPDATE password_resets SET used_at = now() WHERE id = :id", Map.of("id", id)); }
}

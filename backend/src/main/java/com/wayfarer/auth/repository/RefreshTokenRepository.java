package com.wayfarer.auth.repository;

import com.wayfarer.common.Db;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Refresh tokens are stored as SHA-256 hashes, grouped in families so reuse of a rotated token can revoke the whole chain. */
@Repository
public class RefreshTokenRepository {
    private final Db db;

    public RefreshTokenRepository(Db db) { this.db = db; }

    public void insert(UUID userId, UUID familyId, String tokenHash, Instant expiresAt) {
        db.update("INSERT INTO refresh_tokens(user_id, family_id, token_hash, expires_at) VALUES (:u, :f, :h, :exp)",
            Db.params().addValue("u", userId).addValue("f", familyId).addValue("h", tokenHash).addValue("exp", java.sql.Timestamp.from(expiresAt)));
    }

    public Optional<Map<String, Object>> findForUpdate(String tokenHash) {
        return db.one("SELECT t.id, t.user_id, t.family_id, t.revoked_at, t.expires_at < now() AS expired, u.email, u.role, u.deleted_at "
            + "FROM refresh_tokens t JOIN users u ON u.id = t.user_id WHERE t.token_hash = :h FOR UPDATE OF t", Map.of("h", tokenHash));
    }

    public void revoke(Object id) { db.update("UPDATE refresh_tokens SET revoked_at = now() WHERE id = :id", Map.of("id", id)); }

    public void revokeByHash(String tokenHash) { db.update("UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = :h AND revoked_at IS NULL", Map.of("h", tokenHash)); }

    public void revokeFamily(Object familyId) { db.update("UPDATE refresh_tokens SET revoked_at = now() WHERE family_id = :f AND revoked_at IS NULL", Map.of("f", familyId)); }

    public void revokeAllForUser(Object userId) { db.update("UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = :u AND revoked_at IS NULL", Map.of("u", userId)); }
}

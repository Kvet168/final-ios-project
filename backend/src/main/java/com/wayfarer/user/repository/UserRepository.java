package com.wayfarer.user.repository;

import com.wayfarer.common.Db;
import com.wayfarer.common.Text;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class UserRepository {
    private final Db db;

    public UserRepository(Db db) { this.db = db; }

    public Optional<Map<String, Object>> findActiveByEmail(String email) {
        return db.one("SELECT * FROM users WHERE lower(email) = lower(:e) AND deleted_at IS NULL", Map.of("e", email));
    }

    public Optional<Map<String, Object>> findActiveById(UUID id) { return db.one("SELECT * FROM users WHERE id = :id AND deleted_at IS NULL", Map.of("id", id)); }

    public Optional<Map<String, Object>> findById(UUID id) { return db.one("SELECT * FROM users WHERE id = :id", Map.of("id", id)); }

    /** Used on every authenticated request so role changes and account deletion apply immediately. */
    public Optional<Map<String, Object>> findAuthInfo(UUID id) { return db.one("SELECT email, role FROM users WHERE id = :id AND deleted_at IS NULL", Map.of("id", id)); }

    public Optional<Map<String, Object>> findByIdentity(String provider, String subject) {
        return db.one("SELECT u.* FROM user_identities i JOIN users u ON u.id = i.user_id WHERE i.provider = :p AND i.subject = :s AND u.deleted_at IS NULL",
            Map.of("p", provider, "s", subject));
    }

    public void linkIdentity(UUID userId, String provider, String subject, String email) {
        db.update("INSERT INTO user_identities(user_id, provider, subject, email) VALUES (:u, :p, :s, :e) ON CONFLICT (provider, subject) DO NOTHING",
            Db.params().addValue("u", userId).addValue("p", provider).addValue("s", subject).addValue("e", email));
    }

    public boolean emailTaken(String email) { return findActiveByEmail(email).isPresent(); }

    public Map<String, Object> insertCustomer(String email, String passwordHash, String name, String phone) {
        return db.one("INSERT INTO users(email, password_hash, name, phone, role) VALUES (:e, :h, :n, :p, 'customer') RETURNING *",
            Db.params().addValue("e", email).addValue("h", passwordHash).addValue("n", name).addValue("p", phone)).orElseThrow();
    }

    public Map<String, Object> updateProfile(UUID id, String name, String phone, String currency) {
        return db.one("UPDATE users SET name = COALESCE(:n, name), phone = COALESCE(:p, phone), preferred_currency = COALESCE(:c, preferred_currency) WHERE id = :id RETURNING *",
            Db.params().addValue("n", name).addValue("p", phone).addValue("c", currency).addValue("id", id)).orElseThrow();
    }

    public void setPassword(UUID id, String hash) { setPassword(id, hash, false); }

    public void setPassword(UUID id, String hash, boolean mustChange) {
        db.update("UPDATE users SET password_hash = :h, must_change_password = :m WHERE id = :id", Map.of("h", hash, "m", mustChange, "id", id));
    }

    /** Partner owner account created by an administrator: must pick a new password at first sign-in. */
    public Map<String, Object> insertPartnerUser(String email, String passwordHash, String name, String phone) {
        return insertManagedUser(email, passwordHash, name, phone, "partner", true);
    }

    /** Administrator-provisioned user account (admin, staff, customer, partner). */
    public Map<String, Object> insertManagedUser(String email, String passwordHash, String name, String phone, String role, boolean mustChangePassword) {
        return db.one("INSERT INTO users(email, password_hash, name, phone, role, must_change_password) VALUES (:e, :h, :n, :p, :r, :m) RETURNING *",
            Db.params().addValue("e", email).addValue("h", passwordHash).addValue("n", name).addValue("p", phone).addValue("r", role).addValue("m", mustChangePassword)).orElseThrow();
    }

    /** Soft delete and anonymise personal data; bookings and payments stay for financial records. */
    public Map<String, Object> setAvatar(UUID id, String url) {
        return db.one("UPDATE users SET avatar_url = :u WHERE id = :id AND deleted_at IS NULL RETURNING *", Db.params().addValue("u", url).addValue("id", id)).orElseThrow();
    }

    public boolean hasIdentity(UUID id) { return db.exists("SELECT 1 FROM user_identities WHERE user_id = :id", Map.of("id", id)); }

    public void anonymise(UUID id) {
        for (String t : new String[] {"user_identities", "wishlist_items", "notifications", "search_history", "ai_conversations", "password_resets"})
            db.update("DELETE FROM " + t + " WHERE user_id = :id", Map.of("id", id));
        db.update("DELETE FROM itineraries WHERE user_id = :id", Map.of("id", id));
        db.update("UPDATE users SET deleted_at = now(), email = :e, name = 'Deleted user', phone = NULL, avatar_url = NULL, password_hash = '-' WHERE id = :id",
            Map.of("e", "deleted+" + id + "@wayfarer.invalid", "id", id));
    }

    public Optional<Map<String, Object>> setRole(UUID id, String role) {
        return db.one("UPDATE users SET role = :r WHERE id = :id AND deleted_at IS NULL RETURNING id, email, name, role", Map.of("r", role, "id", id));
    }

    public List<Map<String, Object>> search(String q, String role, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("limit", limit).addValue("offset", offset);
        StringBuilder where = new StringBuilder("deleted_at IS NULL");
        if (q != null && !q.isBlank()) { ps.addValue("q", Text.like(q)); where.append(" AND (email ILIKE :q OR name ILIKE :q)"); }
        if (role != null) { ps.addValue("role", role); where.append(" AND role = :role"); }
        return db.list("SELECT id, email, name, phone, role, is_demo, must_change_password, created_at, COUNT(*) OVER () AS total_count FROM users WHERE " + where
            + " ORDER BY created_at DESC LIMIT :limit OFFSET :offset", ps);
    }

    public boolean currencyExists(String code) { return db.exists("SELECT 1 FROM currencies WHERE code = :c", Map.of("c", code)); }
}

package com.wayfarer.payment.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class PaymentRepository {
    private final Db db;

    public PaymentRepository(Db db) { this.db = db; }

    public Optional<Map<String, Object>> findByIdempotencyKey(String key) { return db.one("SELECT * FROM payments WHERE idempotency_key = :k", Map.of("k", key)); }

    public Optional<Map<String, Object>> findOpenForBooking(UUID bookingId) {
        return db.one("SELECT * FROM payments WHERE booking_id = :b AND status IN ('PENDING','SUCCESS') LIMIT 1", Map.of("b", bookingId));
    }

    public Optional<Map<String, Object>> findSuccessful(UUID bookingId) { return db.one("SELECT * FROM payments WHERE booking_id = :b AND status = 'SUCCESS' LIMIT 1", Map.of("b", bookingId)); }

    public Optional<Map<String, Object>> findForUser(UUID id, UUID userId) { return db.one("SELECT * FROM payments WHERE id = :id AND user_id = :u", Map.of("id", id, "u", userId)); }

    public Optional<Map<String, Object>> findByProviderRefForUpdate(String ref) { return db.one("SELECT * FROM payments WHERE provider_ref = :r FOR UPDATE", Map.of("r", ref)); }

    public Map<String, Object> insert(MapSqlParameterSource p) {
        return db.one("INSERT INTO payments(booking_id, user_id, amount_usd, status, provider, provider_ref, idempotency_key, simulated, method) "
            + "VALUES (:b, :u, :amt, 'PENDING', :prov, :ref, :key, :sim, :method) RETURNING *", p).orElseThrow();
    }

    public List<Map<String, Object>> events(UUID paymentId) { return db.list("SELECT type, created_at FROM payment_events WHERE payment_id = :id ORDER BY id", Map.of("id", paymentId)); }

    /** @return false when the provider event id was already stored (duplicate delivery). */
    public boolean insertEvent(UUID paymentId, String providerEventId, String type, String payloadJson) {
        return db.update("INSERT INTO payment_events(payment_id, provider_event_id, type, payload) VALUES (:p, :e, :t, CAST(:pl AS jsonb)) ON CONFLICT (provider_event_id) DO NOTHING",
            Map.of("p", paymentId, "e", providerEventId, "t", type, "pl", payloadJson)) > 0;
    }

    public void setStatus(UUID id, String status, String failureReason) {
        db.update("UPDATE payments SET status = :s, failure_reason = :r WHERE id = :id", Db.params().addValue("s", status).addValue("r", failureReason).addValue("id", id));
    }

    public void cancelPending(UUID bookingId) { db.update("UPDATE payments SET status = 'CANCELLED' WHERE booking_id = :b AND status = 'PENDING'", Map.of("b", bookingId)); }

    public void markRefunded(UUID id) {
        db.update("UPDATE payments SET status = 'REFUNDED', refunded_usd = amount_usd WHERE id = :id", Map.of("id", id));
        db.update("INSERT INTO payment_events(payment_id, provider_event_id, type, payload) VALUES (:p, :e, 'refund.simulated', CAST(:pl AS jsonb)) ON CONFLICT (provider_event_id) DO NOTHING",
            Map.of("p", id, "e", "evt_refund_" + id, "pl", "{\"simulated\":true}"));
    }

    public Optional<Map<String, Object>> summary(UUID id) { return db.one("SELECT id, status, simulated, failure_reason FROM payments WHERE id = :id", Map.of("id", id)); }

    public List<Map<String, Object>> search(String status, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("limit", limit).addValue("offset", offset);
        String where = "true";
        if (status != null) { ps.addValue("s", status); where = "p.status = :s"; }
        return db.list("SELECT p.id, p.amount_usd, p.refunded_usd, p.status, p.method, p.provider, p.provider_ref, p.simulated, p.failure_reason, p.created_at, "
            + "b.reference, b.guest_name, b.guest_email, b.subtotal_usd, b.taxes_usd, b.fees_usd, a.name AS accommodation_name, pt.name AS partner_name, "
            + "COUNT(*) OVER () AS total_count FROM payments p JOIN bookings b ON b.id = p.booking_id "
            + "JOIN accommodations a ON a.id = b.accommodation_id LEFT JOIN partners pt ON pt.id = a.partner_id "
            + "WHERE " + where + " ORDER BY p.created_at DESC LIMIT :limit OFFSET :offset", ps);
    }

    public void claim(UUID id, String note) {
        db.update("UPDATE payments SET claimed_at = now(), claim_note = :n WHERE id = :id AND status = 'PENDING' AND method = 'qr'", Db.params().addValue("id", id).addValue("n", note));
    }

    public void markConfirmed(UUID id, UUID confirmedBy) {
        db.update("UPDATE payments SET status = 'SUCCESS', confirmed_by = :c, failure_reason = NULL WHERE id = :id", Map.of("id", id, "c", confirmedBy));
    }

    public Optional<Map<String, Object>> lockById(UUID id) { return db.one("SELECT * FROM payments WHERE id = :id FOR UPDATE", Map.of("id", id)); }

    /** The payment, only if its booking belongs to a property of this partner user. */
    public boolean belongsToPartner(UUID paymentId, UUID partnerUserId) {
        return db.exists("SELECT 1 FROM payments p JOIN bookings b ON b.id = p.booking_id JOIN accommodations a ON a.id = b.accommodation_id JOIN partners pt ON pt.id = a.partner_id "
            + "WHERE p.id = :p AND pt.user_id = :u", Map.of("p", paymentId, "u", partnerUserId));
    }

    /** Payments for a partner's properties (QR payments by default are the ones awaiting the partner's confirmation). */
    public List<Map<String, Object>> searchForPartner(UUID partnerUserId, String status, String method, int limit, int offset) {
        org.springframework.jdbc.core.namedparam.MapSqlParameterSource ps = Db.params().addValue("u", partnerUserId).addValue("l", limit).addValue("o", offset);
        StringBuilder where = new StringBuilder("pt.user_id = :u");
        if (status != null) { ps.addValue("s", status); where.append(" AND p.status = :s"); }
        if (method != null) { ps.addValue("m", method); where.append(" AND p.method = :m"); }
        return db.list("SELECT p.id, p.amount_usd, p.status, p.method, p.provider_ref, p.claimed_at, p.claim_note, p.failure_reason, p.created_at, b.reference, b.guest_name, b.check_in, b.check_out, "
            + "b.subtotal_usd, b.taxes_usd, b.fees_usd, a.name AS accommodation_name, COUNT(*) OVER () AS total_count FROM payments p JOIN bookings b ON b.id = p.booking_id JOIN accommodations a ON a.id = b.accommodation_id "
            + "JOIN partners pt ON pt.id = a.partner_id WHERE " + where + " ORDER BY (p.status = 'PENDING' AND p.claimed_at IS NOT NULL) DESC, p.created_at DESC LIMIT :l OFFSET :o", ps);
    }
}

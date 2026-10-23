package com.wayfarer.booking.repository;

import com.wayfarer.common.Db;
import com.wayfarer.common.Text;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class BookingRepository {
    private static final String LIST_SELECT = "SELECT b.id, b.reference, b.status, b.check_in, b.check_out, b.nights, b.rooms, b.adults, b.children, b.total_usd, "
        + "b.free_cancel_until, b.hold_expires_at, b.created_at, b.is_demo, a.name AS accommodation_name, a.slug AS accommodation_slug, a.cover_image, r.name AS room_name ";

    private final Db db;

    public BookingRepository(Db db) { this.db = db; }

    public Map<String, Object> insert(MapSqlParameterSource p) {
        return db.one("INSERT INTO bookings(reference, user_id, accommodation_id, room_type_id, check_in, check_out, nights, rooms, adults, children, "
            + "guest_name, guest_email, guest_phone, special_requests, status, subtotal_usd, taxes_usd, fees_usd, total_usd, cancellation_policy, free_cancel_until, hold_expires_at) "
            + "VALUES (:ref, :u, :acc, :rt, :ci, :co, :nights, :rooms, :adults, :children, :gn, :ge, :gp, :sr, 'PENDING_CONFIRMATION', :sub, :tax, :fee, :total, :policy, :free, :hold) RETURNING *", p).orElseThrow();
    }

    public void insertItem(UUID bookingId, java.time.LocalDate night, java.math.BigDecimal rate, int rooms) {
        db.update("INSERT INTO booking_items(booking_id, night, rate_usd, rooms) VALUES (:b, :n, :r, :rooms)", Map.of("b", bookingId, "n", night, "r", rate, "rooms", rooms));
    }

    public void insertEvent(UUID bookingId, String from, String to, UUID actorId, String note) {
        db.update("INSERT INTO booking_status_events(booking_id, from_status, to_status, actor_id, note) VALUES (:b, :f, :t, :a, :n)",
            Db.params().addValue("b", bookingId).addValue("f", from).addValue("t", to).addValue("a", actorId).addValue("n", note));
    }

    /** Optimistic status change: empty when another request already moved the booking. */
    public Optional<Map<String, Object>> updateStatus(UUID id, String from, String to) {
        return db.one("UPDATE bookings SET status = :to WHERE id = :id AND status = :from RETURNING user_id, reference", Map.of("to", to, "id", id, "from", from));
    }

    public Optional<Map<String, Object>> findForUpdate(UUID id) { return db.one("SELECT * FROM bookings WHERE id = :id FOR UPDATE", Map.of("id", id)); }

    public Optional<Map<String, Object>> findById(UUID id) { return db.one("SELECT * FROM bookings WHERE id = :id", Map.of("id", id)); }

    public Optional<Map<String, Object>> findStatusForUpdate(UUID id) { return db.one("SELECT id, status, user_id, reference, accommodation_id FROM bookings WHERE id = :id FOR UPDATE", Map.of("id", id)); }

    public Optional<Map<String, Object>> findDetail(UUID id) {
        return db.one("SELECT b.*, a.name AS accommodation_name, a.slug AS accommodation_slug, a.address, a.cover_image, a.partner_id, "
            + "r.name AS room_name, d.name AS destination_name, a.is_demo AS accommodation_is_demo FROM bookings b "
            + "JOIN accommodations a ON a.id = b.accommodation_id JOIN room_types r ON r.id = b.room_type_id JOIN destinations d ON d.id = a.destination_id WHERE b.id = :id", Map.of("id", id));
    }

    public List<Map<String, Object>> nights(UUID id) { return db.list("SELECT night, rate_usd FROM booking_items WHERE booking_id = :id ORDER BY night", Map.of("id", id)); }

    public List<Map<String, Object>> events(UUID id) {
        return db.list("SELECT from_status, to_status, note, created_at FROM booking_status_events WHERE booking_id = :id ORDER BY id", Map.of("id", id));
    }

    public List<Map<String, Object>> payments(UUID id) {
        return db.list("SELECT id, amount_usd, refunded_usd, status, provider, provider_ref, simulated, failure_reason, created_at FROM payments WHERE booking_id = :id ORDER BY created_at", Map.of("id", id));
    }

    public List<Map<String, Object>> listForUser(UUID userId, String status) {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("u", userId);
        if (status != null) p.put("s", status);
        return db.list(LIST_SELECT + "FROM bookings b JOIN accommodations a ON a.id = b.accommodation_id JOIN room_types r ON r.id = b.room_type_id "
            + "WHERE b.user_id = :u" + (status != null ? " AND b.status = :s" : "") + " ORDER BY b.created_at DESC LIMIT 100", p);
    }

    /** Bookings that still need the property or room: unpaid holds, confirmed or in-house stays that have not ended. */
    public boolean hasActiveForAccommodation(UUID accommodationId) {
        return db.exists("SELECT 1 FROM bookings WHERE accommodation_id = :a AND status IN ('PENDING_CONFIRMATION','CONFIRMED','CHECKED_IN') AND check_out >= current_date LIMIT 1", Map.of("a", accommodationId));
    }

    public boolean hasActiveForRoom(UUID roomTypeId) {
        return db.exists("SELECT 1 FROM bookings WHERE room_type_id = :r AND status IN ('PENDING_CONFIRMATION','CONFIRMED','CHECKED_IN') AND check_out >= current_date LIMIT 1", Map.of("r", roomTypeId));
    }

    public void extendHold(UUID bookingId, int hours) {
        db.update("UPDATE bookings SET hold_expires_at = GREATEST(COALESCE(hold_expires_at, now()), now() + make_interval(hours => :h)) WHERE id = :id AND status = 'PENDING_CONFIRMATION'", Map.of("h", hours, "id", bookingId));
    }

    public boolean userHasActive(UUID userId) {
        return db.exists("SELECT 1 FROM bookings WHERE user_id = :id AND status IN ('PENDING_CONFIRMATION','CONFIRMED','CHECKED_IN')", Map.of("id", userId));
    }

    public boolean userHasStayed(UUID userId, UUID accommodationId) {
        return stayFor(userId, accommodationId).isPresent();
    }

    /** The user's most recent booking that makes them eligible to review the property. */
    public Optional<Map<String, Object>> stayFor(UUID userId, UUID accommodationId) {
        return db.one("SELECT id FROM bookings WHERE user_id = :u AND accommodation_id = :a AND status IN ('CONFIRMED','CHECKED_IN','COMPLETED') ORDER BY created_at DESC LIMIT 1",
            Map.of("u", userId, "a", accommodationId));
    }

    public List<Map<String, Object>> expiredHolds(int limit) {
        return db.list("SELECT id, room_type_id, user_id, reference FROM bookings WHERE status = 'PENDING_CONFIRMATION' AND hold_expires_at < now() ORDER BY hold_expires_at LIMIT " + limit);
    }

    public void clearHold(UUID id) { db.update("UPDATE bookings SET hold_expires_at = NULL WHERE id = :id", Map.of("id", id)); }

    /** Staff and partner listings. `accommodationIds` null = no property restriction. */
    public List<Map<String, Object>> search(String status, String q, List<UUID> accommodationIds, boolean partnerShape, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("limit", limit).addValue("offset", offset);
        List<String> where = new ArrayList<>(List.of("true"));
        if (status != null) { ps.addValue("status", status); where.add("b.status = :status"); }
        if (q != null && !q.isBlank()) { ps.addValue("q", Text.like(q)); where.add("(b.reference ILIKE :q OR b.guest_name ILIKE :q OR b.guest_email ILIKE :q)"); }
        if (accommodationIds != null) {
            if (accommodationIds.isEmpty()) return List.of();
            ps.addValue("acc", accommodationIds);
            where.add("b.accommodation_id IN (:acc)");
        }
        String cols = partnerShape
            ? "b.id, b.reference, b.status, b.guest_name, b.check_in, b.check_out, b.nights, b.rooms, b.adults, b.children, b.total_usd, a.name AS accommodation_name, r.name AS room_name"
            : "b.id, b.reference, b.status, b.guest_name, b.guest_email, b.check_in, b.check_out, b.total_usd, b.created_at, b.is_demo, a.name AS accommodation_name";
        return db.list("SELECT " + cols + ", COUNT(*) OVER () AS total_count FROM bookings b JOIN accommodations a ON a.id = b.accommodation_id "
            + (partnerShape ? "JOIN room_types r ON r.id = b.room_type_id " : "") + "WHERE " + String.join(" AND ", where)
            + " ORDER BY " + (partnerShape ? "b.check_in" : "b.created_at") + " DESC LIMIT :limit OFFSET :offset", ps);
    }
}

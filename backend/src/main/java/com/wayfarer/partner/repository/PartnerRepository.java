package com.wayfarer.partner.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Partners own accommodations; a partner user may only see and edit those. */
@Repository
public class PartnerRepository {
    private final Db db;

    public PartnerRepository(Db db) { this.db = db; }

    public boolean isOwner(Object partnerId, UUID userId) { return db.exists("SELECT 1 FROM partners WHERE id = :p AND user_id = :u", Map.of("p", partnerId, "u", userId)); }

    public List<UUID> accommodationIds(UUID userId) {
        return db.list("SELECT a.id FROM accommodations a JOIN partners p ON p.id = a.partner_id WHERE p.user_id = :u AND a.deleted_at IS NULL", Map.of("u", userId))
            .stream().map(r -> (UUID) r.get("id")).toList();
    }

    public List<Map<String, Object>> accommodations(List<UUID> idsOrNullForAll) {
        String filter = "";
        Map<String, Object> p = new java.util.HashMap<>();
        if (idsOrNullForAll != null) {
            if (idsOrNullForAll.isEmpty()) return List.of();
            filter = " AND a.id IN (:ids)";
            p.put("ids", idsOrNullForAll);
        }
        return db.list("SELECT a.id, a.slug, a.name, a.stars, a.type, a.rating_avg, a.review_count, a.from_price_usd, a.cover_image, "
            + "(SELECT json_agg(json_build_object('id', r.id, 'name', r.name, 'base_price_usd', r.base_price_usd, 'total_units', r.total_units, 'cover_image', r.cover_image) ORDER BY r.base_price_usd) "
            + "FROM room_types r WHERE r.accommodation_id = a.id AND r.deleted_at IS NULL) AS rooms, "
            + "(SELECT json_agg(json_build_object('id', i.id, 'url', i.url, 'caption', i.caption) ORDER BY i.position, i.id) FROM accommodation_images i WHERE i.accommodation_id = a.id) AS images "
            + "FROM accommodations a WHERE a.deleted_at IS NULL" + filter + " ORDER BY a.name", p);
    }

    public Object occupancyPct(List<UUID> idsOrNull, java.time.LocalDate from, java.time.LocalDate to) {
        Map<String, Object> p = new java.util.HashMap<>(Map.of("from", from, "to", to));
        String filter = "";
        if (idsOrNull != null) {
            if (idsOrNull.isEmpty()) return null;
            filter = " AND rt.accommodation_id IN (:ids)";
            p.put("ids", idsOrNull);
        }
        return db.one("SELECT ROUND(100.0 * (1 - SUM(ri.units_available)::numeric / NULLIF(SUM(rt.total_units), 0)), 1) AS pct FROM room_inventory ri "
            + "JOIN room_types rt ON rt.id = ri.room_type_id WHERE ri.night >= :from AND ri.night < :to" + filter, p).map(r -> r.get("pct")).orElse(null);
    }

    public List<Map<String, Object>> bookingsByStatus(List<UUID> idsOrNull) {
        Map<String, Object> p = new java.util.HashMap<>();
        String filter = "";
        if (idsOrNull != null) {
            if (idsOrNull.isEmpty()) return List.of();
            filter = " WHERE accommodation_id IN (:ids)";
            p.put("ids", idsOrNull);
        }
        return db.list("SELECT status, COUNT(*)::int AS count, COALESCE(SUM(total_usd), 0) AS total_usd FROM bookings" + filter + " GROUP BY status", p);
    }

    public boolean ownsRoomType(UUID roomTypeId, UUID userId) {
        return db.exists("SELECT 1 FROM room_types r JOIN accommodations a ON a.id = r.accommodation_id JOIN partners p ON p.id = a.partner_id WHERE r.id = :r AND p.user_id = :u",
            Map.of("r", roomTypeId, "u", userId));
    }

    public Optional<UUID> partnerIdForUser(UUID userId) {
        return db.one("SELECT id FROM partners WHERE user_id = :u LIMIT 1", Map.of("u", userId)).map(r -> (UUID) r.get("id"));
    }

    public boolean ownsAccommodation(UUID accommodationId, UUID userId) {
        return db.exists("SELECT 1 FROM accommodations a JOIN partners p ON p.id = a.partner_id WHERE a.id = :a AND p.user_id = :u AND a.deleted_at IS NULL", Map.of("a", accommodationId, "u", userId));
    }

    /** Guest reviews of the given properties (null = all). Read-only for partners. */
    public List<Map<String, Object>> reviews(List<UUID> idsOrNull, int limit, int offset) {
        Map<String, Object> p = new java.util.HashMap<>(Map.of("l", limit, "o", offset));
        String filter = "";
        if (idsOrNull != null) {
            if (idsOrNull.isEmpty()) return List.of();
            filter = " AND r.accommodation_id IN (:ids)";
            p.put("ids", idsOrNull);
        }
        return db.list("SELECT r.id, r.rating, r.title, r.body, r.status, r.created_at, a.name AS accommodation_name, split_part(u.name, ' ', 1) AS author, COUNT(*) OVER () AS total_count "
            + "FROM reviews r JOIN accommodations a ON a.id = r.accommodation_id JOIN users u ON u.id = r.user_id WHERE r.status = 'published'" + filter
            + " ORDER BY r.created_at DESC LIMIT :l OFFSET :o", p);
    }

    public UUID insert(UUID userId, String name, String phone) {
        return (UUID) db.one("INSERT INTO partners(user_id, name, contact_phone) VALUES (:u, :n, :p) RETURNING id",
            Db.params().addValue("u", userId).addValue("n", name).addValue("p", phone)).orElseThrow().get("id");
    }

    /** Admin view: one row per partner with owner contact and portfolio counts. */
    public List<Map<String, Object>> list(String likeTerm, int limit, int offset) {
        org.springframework.jdbc.core.namedparam.MapSqlParameterSource ps = Db.params().addValue("l", limit).addValue("o", offset);
        String where = "u.deleted_at IS NULL";
        if (likeTerm != null) { ps.addValue("q", likeTerm); where += " AND (p.name ILIKE :q OR u.email ILIKE :q OR u.name ILIKE :q)"; }
        return db.list("SELECT p.id, p.name, p.contact_phone, p.created_at, u.id AS user_id, u.name AS owner_name, u.email AS owner_email, u.must_change_password, "
            + "(p.payment_qr_media_id IS NOT NULL) AS qr_configured, "
            + "(SELECT COUNT(*)::int FROM accommodations a WHERE a.partner_id = p.id AND a.deleted_at IS NULL) AS hotels, "
            + "(SELECT COUNT(*)::int FROM room_types r JOIN accommodations a ON a.id = r.accommodation_id WHERE a.partner_id = p.id AND a.deleted_at IS NULL AND r.deleted_at IS NULL) AS rooms, "
            + "(SELECT COUNT(*)::int FROM bookings b JOIN accommodations a ON a.id = b.accommodation_id WHERE a.partner_id = p.id) AS bookings, "
            + "COUNT(*) OVER () AS total_count FROM partners p JOIN users u ON u.id = p.user_id WHERE " + where + " ORDER BY p.created_at DESC LIMIT :l OFFSET :o", ps);
    }

    public Optional<Map<String, Object>> findDetail(UUID id) {
        return db.one("SELECT p.id, p.name, p.contact_phone, p.created_at, p.payment_account_name, p.payment_bank, p.payment_note, (p.payment_qr_media_id IS NOT NULL) AS qr_configured, "
            + "p.payment_qr_media_id, u.id AS user_id, u.name AS owner_name, u.email AS owner_email, u.must_change_password FROM partners p JOIN users u ON u.id = p.user_id WHERE p.id = :id", Map.of("id", id));
    }

    public Optional<Map<String, Object>> findByUser(UUID userId) {
        return db.one("SELECT p.id, p.name, p.contact_phone, p.payment_qr_media_id, p.payment_account_name, p.payment_bank, p.payment_note, p.updated_at "
            + "FROM partners p WHERE p.user_id = :u", Map.of("u", userId));
    }

    public void updateProfile(UUID partnerId, String name, String phone, UUID qrMediaId, String accountName, String bank, String note) {
        db.update("UPDATE partners SET name = COALESCE(:n, name), contact_phone = :p, payment_qr_media_id = :q, payment_account_name = :a, payment_bank = :b, payment_note = :note WHERE id = :id",
            Db.params().addValue("id", partnerId).addValue("n", name).addValue("p", phone).addValue("q", qrMediaId).addValue("a", accountName).addValue("b", bank).addValue("note", note));
    }

    public List<Map<String, Object>> hotelsOf(UUID partnerId) {
        return db.list("SELECT a.id, a.slug, a.name, a.type, a.stars, a.from_price_usd, a.rating_avg, a.review_count, d.name AS destination_name, "
            + "(SELECT COUNT(*)::int FROM room_types r WHERE r.accommodation_id = a.id AND r.deleted_at IS NULL) AS rooms FROM accommodations a JOIN destinations d ON d.id = a.destination_id "
            + "WHERE a.partner_id = :p AND a.deleted_at IS NULL ORDER BY a.name", Map.of("p", partnerId));
    }

    /** The partner user who owns the property (null for catalogue properties nobody owns). */
    public Optional<UUID> ownerUserOfAccommodation(UUID accommodationId) {
        return db.one("SELECT p.user_id FROM accommodations a JOIN partners p ON p.id = a.partner_id WHERE a.id = :a", Map.of("a", accommodationId)).map(r -> (UUID) r.get("user_id"));
    }

    /** The QR payment settings of the partner who owns the property, if a QR code has been uploaded. */
    public Optional<Map<String, Object>> qrFor(UUID accommodationId) {
        return db.one("SELECT p.id AS partner_id, p.name AS partner_name, p.user_id, p.payment_qr_media_id, p.payment_account_name, p.payment_bank, p.payment_note "
            + "FROM accommodations a JOIN partners p ON p.id = a.partner_id WHERE a.id = :a AND p.payment_qr_media_id IS NOT NULL", Map.of("a", accommodationId));
    }
}

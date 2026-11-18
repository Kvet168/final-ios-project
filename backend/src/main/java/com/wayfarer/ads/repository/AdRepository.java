package com.wayfarer.ads.repository;

import com.wayfarer.common.Db;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Text;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

/** All SQL for advertising: businesses, packages, campaigns, payments, settings and daily stats. */
@Repository
public class AdRepository {
    /** Statuses that hold a placement slot (the money is expected or in, so the slot is reserved). */
    public static final String HOLDING = "'awaiting_payment','payment_review','scheduled','active'";
    /** "Today" in Cambodia, so a campaign starts and ends at local midnight whatever the server clock. */
    public static final String TODAY = "(now() AT TIME ZONE 'Asia/Phnom_Penh')::date";

    private final Db db;

    public AdRepository(Db db) { this.db = db; }

    /* ---------------- businesses ---------------- */

    public Optional<Map<String, Object>> businessByUser(UUID userId) {
        return db.one("SELECT b.*, d.name AS destination_name FROM businesses b LEFT JOIN destinations d ON d.id = b.destination_id WHERE b.user_id = :u", Map.of("u", userId));
    }

    public Optional<Map<String, Object>> businessById(UUID id) {
        return db.one("SELECT b.*, u.email AS owner_email, u.name AS owner_name FROM businesses b JOIN users u ON u.id = b.user_id WHERE b.id = :id", Map.of("id", id));
    }

    public Optional<Map<String, Object>> partnerByUser(UUID userId) {
        return db.one("SELECT id, name, contact_phone FROM partners WHERE user_id = :u", Map.of("u", userId));
    }

    public UUID insertBusiness(UUID userId, UUID partnerId, String name, String category, String phone, String status) {
        return (UUID) db.one("INSERT INTO businesses (user_id, partner_id, name, category, phone, verification_status, verified_at) VALUES (:u, :p, :n, :c, :ph, :s, "
            + "CASE WHEN :s = 'verified' THEN now() END) RETURNING id",
            Db.params().addValue("u", userId).addValue("p", partnerId).addValue("n", name).addValue("c", category).addValue("ph", phone).addValue("s", status)).orElseThrow().get("id");
    }

    public void updateBusiness(UUID id, String name, String nameKm, String category, String description, String descriptionKm, String phone, String website, String address,
                               UUID destinationId, String logoUrl) {
        db.update("UPDATE businesses SET name = :n, name_km = :nk, category = :c, description = :d, description_km = :dk, phone = :ph, website = :w, address = :a, "
            + "destination_id = :dest, logo_url = :logo WHERE id = :id",
            Db.params().addValue("id", id).addValue("n", name).addValue("nk", nameKm).addValue("c", category).addValue("d", description).addValue("dk", descriptionKm)
                .addValue("ph", phone).addValue("w", website).addValue("a", address).addValue("dest", destinationId).addValue("logo", logoUrl));
    }

    public void setVerification(UUID id, String status, String note, UUID actor) {
        db.update("UPDATE businesses SET verification_status = :s, verification_note = :n, verified_by = :a, verified_at = CASE WHEN :s = 'verified' THEN now() ELSE verified_at END WHERE id = :id",
            Db.params().addValue("id", id).addValue("s", status).addValue("n", note).addValue("a", actor));
    }

    public Map<String, Object> searchBusinesses(String status, String q, int page, int size) {
        MapSqlParameterSource p = Db.params().addValue("s", status).addValue("q", q == null || q.isBlank() ? null : Text.like(q)).addValue("l", size).addValue("o", (page - 1) * size);
        return Pages.of(db.list("SELECT b.id, b.name, b.name_km, b.category, b.phone, b.verification_status, b.verification_note, b.verified_at, b.created_at, u.email AS owner_email, u.name AS owner_name, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns c WHERE c.business_id = b.id) AS campaigns, "
            + "(SELECT COALESCE(SUM(py.amount_usd), 0) FROM ad_payments py WHERE py.business_id = b.id AND py.status = 'verified') AS spent_usd, COUNT(*) OVER () AS total_count "
            + "FROM businesses b JOIN users u ON u.id = b.user_id WHERE (CAST(:s AS text) IS NULL OR b.verification_status = :s) "
            + "AND (CAST(:q AS text) IS NULL OR b.name ILIKE :q OR u.email ILIKE :q OR u.name ILIKE :q) ORDER BY (b.verification_status = 'pending') DESC, b.created_at DESC LIMIT :l OFFSET :o", p), page, size);
    }

    /* ---------------- packages and settings ---------------- */

    public List<Map<String, Object>> packages(boolean activeOnly) {
        return db.list("SELECT * FROM ad_packages" + (activeOnly ? " WHERE is_active" : "") + " ORDER BY sort_order, unit_price_usd");
    }

    public Optional<Map<String, Object>> packageById(UUID id) { return db.one("SELECT * FROM ad_packages WHERE id = :id", Map.of("id", id)); }

    public void updatePackage(UUID id, String nameEn, String nameKm, String descEn, String descKm, BigDecimal price, int days, int min, int max, int cap, boolean active, int sort) {
        db.update("UPDATE ad_packages SET name_en = :ne, name_km = :nk, description_en = :de, description_km = :dk, unit_price_usd = :p, days_per_unit = :d, min_units = :mn, max_units = :mx, "
            + "slot_capacity = :c, is_active = :a, sort_order = :s WHERE id = :id",
            Db.params().addValue("id", id).addValue("ne", nameEn).addValue("nk", nameKm).addValue("de", descEn == null ? "" : descEn).addValue("dk", descKm == null ? "" : descKm)
                .addValue("p", price).addValue("d", days).addValue("mn", min).addValue("mx", max).addValue("c", cap).addValue("a", active).addValue("s", sort));
    }

    public UUID insertPackage(String code, String placement, String unit, String nameEn, String nameKm, String descEn, String descKm, BigDecimal price, int days, int min, int max, int cap,
                              boolean active, int sort) {
        return (UUID) db.one("INSERT INTO ad_packages (code, placement, unit, name_en, name_km, description_en, description_km, unit_price_usd, days_per_unit, min_units, max_units, slot_capacity, is_active, sort_order) "
            + "VALUES (:code, :pl, :u, :ne, :nk, :de, :dk, :p, :d, :mn, :mx, :c, :a, :s) RETURNING id",
            Db.params().addValue("code", code).addValue("pl", placement).addValue("u", unit).addValue("ne", nameEn).addValue("nk", nameKm).addValue("de", descEn == null ? "" : descEn)
                .addValue("dk", descKm == null ? "" : descKm).addValue("p", price).addValue("d", days).addValue("mn", min).addValue("mx", max).addValue("c", cap).addValue("a", active).addValue("s", sort))
            .orElseThrow().get("id");
    }

    public Map<String, String> settings() {
        Map<String, String> m = new HashMap<>();
        for (Map<String, Object> r : db.list("SELECT key, value FROM ad_settings")) m.put((String) r.get("key"), (String) r.get("value"));
        return m;
    }

    public void putSetting(String key, String value) {
        db.update("INSERT INTO ad_settings (key, value) VALUES (:k, :v) ON CONFLICT (key) DO UPDATE SET value = :v, updated_at = now()", Map.of("k", key, "v", value == null ? "" : value));
    }

    public BigDecimal khrPerUsd() {
        return (BigDecimal) db.one("SELECT per_usd FROM currencies WHERE code = 'KHR'", Map.of()).orElseThrow().get("per_usd");
    }

    public Optional<Map<String, Object>> destinationBySlug(String slug) { return db.one("SELECT id, slug, name FROM destinations WHERE slug = :s AND deleted_at IS NULL", Map.of("s", slug)); }

    public int countDestinations(Collection<UUID> ids) {
        if (ids.isEmpty()) return 0;
        return ((Number) db.one("SELECT COUNT(*) AS n FROM destinations WHERE id IN (:ids) AND deleted_at IS NULL", Map.of("ids", ids)).orElseThrow().get("n")).intValue();
    }

    public boolean accommodationBelongsToPartner(UUID accommodationId, UUID partnerId) {
        return partnerId != null && db.exists("SELECT 1 FROM accommodations WHERE id = :a AND partner_id = :p AND deleted_at IS NULL", Map.of("a", accommodationId, "p", partnerId));
    }

    /* ---------------- campaigns ---------------- */

    private static final String CAMPAIGN_SELECT = "SELECT c.*, p.name_en AS package_name_en, p.name_km AS package_name_km, p.unit AS package_unit, b.name AS business_name, b.verification_status AS business_status, "
        + "COALESCE(s.impressions, 0)::int AS impressions, COALESCE(s.clicks, 0)::int AS clicks, "
        + "(SELECT py.status FROM ad_payments py WHERE py.campaign_id = c.id ORDER BY py.created_at DESC LIMIT 1) AS payment_status "
        + "FROM ad_campaigns c JOIN ad_packages p ON p.id = c.package_id JOIN businesses b ON b.id = c.business_id "
        + "LEFT JOIN (SELECT campaign_id, SUM(impressions) AS impressions, SUM(clicks) AS clicks FROM ad_stats_daily GROUP BY campaign_id) s ON s.campaign_id = c.id ";

    public Optional<Map<String, Object>> campaign(UUID id) { return db.one(CAMPAIGN_SELECT + "WHERE c.id = :id", Map.of("id", id)); }

    public Optional<Map<String, Object>> campaignForUpdate(UUID id) {
        return db.one("SELECT * FROM ad_campaigns WHERE id = :id FOR UPDATE", Map.of("id", id));
    }

    public List<Map<String, Object>> campaignsOf(UUID businessId) {
        return db.list(CAMPAIGN_SELECT + "WHERE c.business_id = :b ORDER BY c.created_at DESC", Map.of("b", businessId));
    }

    public Map<String, Object> searchCampaigns(String status, String placement, String q, int page, int size) {
        MapSqlParameterSource p = Db.params().addValue("s", status).addValue("pl", placement).addValue("q", q == null || q.isBlank() ? null : Text.like(q)).addValue("l", size).addValue("o", (page - 1) * size);
        return Pages.of(db.list("SELECT x.*, COUNT(*) OVER () AS total_count FROM (" + CAMPAIGN_SELECT + ") x "
            + "WHERE (CAST(:s AS text) IS NULL OR x.status = :s) AND (CAST(:pl AS text) IS NULL OR x.placement = :pl) AND (CAST(:q AS text) IS NULL OR x.title_en ILIKE :q OR x.business_name ILIKE :q) "
            + "ORDER BY (x.status IN ('pending_review','payment_review')) DESC, x.created_at DESC LIMIT :l OFFSET :o", p), page, size);
    }

    public UUID insertCampaign(Map<String, Object> v) {
        return (UUID) db.one("INSERT INTO ad_campaigns (business_id, package_id, placement, status, title_en, title_km, body_en, body_km, offer_en, offer_km, article_en, article_km, image_url, cta_url, "
            + "accommodation_id, target_destination_ids, keywords, festival_name_en, festival_name_km, start_date, end_date, units, price_usd, renewed_from, review_note) "
            + "VALUES (:business_id, :package_id, :placement, :status, :title_en, :title_km, :body_en, :body_km, :offer_en, :offer_km, :article_en, :article_km, :image_url, :cta_url, "
            + ":accommodation_id, CAST(:targets AS uuid[]), CAST(:keywords AS text[]), :festival_name_en, :festival_name_km, :start_date, :end_date, :units, :price_usd, :renewed_from, :review_note) RETURNING id", v)
            .orElseThrow().get("id");
    }

    public void updateCampaignContent(UUID id, Map<String, Object> v) {
        Map<String, Object> p = new HashMap<>(v);
        p.put("id", id);
        db.update("UPDATE ad_campaigns SET package_id = :package_id, placement = :placement, title_en = :title_en, title_km = :title_km, body_en = :body_en, body_km = :body_km, offer_en = :offer_en, offer_km = :offer_km, "
            + "article_en = :article_en, article_km = :article_km, image_url = :image_url, cta_url = :cta_url, accommodation_id = :accommodation_id, target_destination_ids = CAST(:targets AS uuid[]), "
            + "keywords = CAST(:keywords AS text[]), festival_name_en = :festival_name_en, festival_name_km = :festival_name_km, start_date = :start_date, end_date = :end_date, units = :units, price_usd = :price_usd, "
            + "status = 'draft', review_note = NULL WHERE id = :id", p);
    }

    public void setStatus(UUID id, String status) { db.update("UPDATE ad_campaigns SET status = :s WHERE id = :id", Map.of("id", id, "s", status)); }

    public void setReview(UUID id, String status, String note, UUID reviewer) {
        db.update("UPDATE ad_campaigns SET status = :s, review_note = :n, reviewed_by = :r, reviewed_at = now() WHERE id = :id", Db.params().addValue("id", id).addValue("s", status).addValue("n", note).addValue("r", reviewer));
    }

    public void setDates(UUID id, LocalDate start, LocalDate end, String status) {
        db.update("UPDATE ad_campaigns SET start_date = :s, end_date = :e, status = :st WHERE id = :id", Map.of("id", id, "s", start, "e", end, "st", status));
    }

    /** Highest number of campaigns of this package that already hold a slot on any single day of the range. Callers hold the package lock. */
    public int peakLoad(UUID packageId, LocalDate start, LocalDate end, UUID excludeCampaign) {
        Map<String, Object> r = db.one("SELECT COALESCE(MAX(n), 0)::int AS peak FROM (SELECT COUNT(*) AS n FROM generate_series(CAST(:s AS date), CAST(:e AS date), interval '1 day') g(d) "
            + "JOIN ad_campaigns x ON x.package_id = :p AND x.id <> :ex AND x.status IN (" + HOLDING + ") AND x.start_date <= g.d::date AND x.end_date >= g.d::date GROUP BY g.d) t",
            Db.params().addValue("s", start).addValue("e", end).addValue("p", packageId).addValue("ex", excludeCampaign == null ? new UUID(0, 0) : excludeCampaign)).orElseThrow();
        return ((Number) r.get("peak")).intValue();
    }

    /** Serialises capacity decisions per package (released at the end of the surrounding transaction). */
    public void lockPackage(UUID packageId) { db.one("SELECT pg_advisory_xact_lock(hashtextextended(CAST(:p AS text), 0))", Map.of("p", packageId.toString())); }

    public List<Map<String, Object>> dailyLoad(int days) {
        return db.list("SELECT p.id AS package_id, p.code, p.name_en, p.name_km, p.slot_capacity, g.d::date AS day, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns x WHERE x.package_id = p.id AND x.status IN (" + HOLDING + ") AND x.start_date <= g.d::date AND x.end_date >= g.d::date) AS used "
            + "FROM ad_packages p CROSS JOIN generate_series(" + TODAY + ", " + TODAY + " + (CAST(:n AS int) - 1), interval '1 day') g(d) WHERE p.is_active ORDER BY p.sort_order, g.d", Map.of("n", days));
    }

    /* ---------------- lifecycle ---------------- */

    public int activateDue() {
        return db.update("UPDATE ad_campaigns SET status = 'active' WHERE status = 'scheduled' AND start_date <= " + TODAY + " AND end_date >= " + TODAY, Map.of());
    }

    public int expireDue() {
        return db.update("UPDATE ad_campaigns SET status = 'expired' WHERE status IN ('scheduled','active') AND end_date < " + TODAY, Map.of());
    }

    public List<Map<String, Object>> cancelStaleUnpaid(int holdDays) {
        return db.list("UPDATE ad_campaigns SET status = 'cancelled', review_note = 'Cancelled: payment was not made in time' WHERE (status = 'awaiting_payment' AND reviewed_at < now() - make_interval(days => :d)) "
            + "OR (status IN ('awaiting_payment','payment_review') AND end_date < " + TODAY + ") RETURNING id", Map.of("d", holdDays));
    }

    public void closeOpenPayments(UUID campaignId, String status) {
        db.update("UPDATE ad_payments SET status = :s WHERE campaign_id = :c AND status IN ('pending','claimed') ", Map.of("c", campaignId, "s", status));
    }

    /* ---------------- payments ---------------- */

    public Optional<Map<String, Object>> payment(UUID id) {
        return db.one("SELECT py.*, c.title_en AS campaign_title, c.status AS campaign_status, b.name AS business_name, u.email AS business_email FROM ad_payments py "
            + "JOIN ad_campaigns c ON c.id = py.campaign_id JOIN businesses b ON b.id = py.business_id JOIN users u ON u.id = b.user_id WHERE py.id = :id", Map.of("id", id));
    }

    public Optional<Map<String, Object>> paymentForUpdate(UUID id) { return db.one("SELECT * FROM ad_payments WHERE id = :id FOR UPDATE", Map.of("id", id)); }

    public Optional<Map<String, Object>> openPayment(UUID campaignId) {
        return db.one("SELECT * FROM ad_payments WHERE campaign_id = :c AND status IN ('pending','claimed') ORDER BY created_at DESC LIMIT 1", Map.of("c", campaignId));
    }

    public UUID insertPayment(UUID campaignId, UUID businessId, String reference, String method, String currency, BigDecimal usd, BigDecimal local, BigDecimal fx) {
        return (UUID) db.one("INSERT INTO ad_payments (campaign_id, business_id, reference, method, currency, amount_usd, amount_local, fx_rate) VALUES (:c, :b, :r, :m, :cur, :usd, :loc, :fx) RETURNING id",
            Db.params().addValue("c", campaignId).addValue("b", businessId).addValue("r", reference).addValue("m", method).addValue("cur", currency).addValue("usd", usd).addValue("loc", local).addValue("fx", fx))
            .orElseThrow().get("id");
    }

    public void claimPayment(UUID id, String txn, String proof) {
        db.update("UPDATE ad_payments SET status = 'claimed', bank_txn_ref = :t, proof_url = :p, claimed_at = now() WHERE id = :id", Db.params().addValue("id", id).addValue("t", txn).addValue("p", proof));
    }

    public void decidePayment(UUID id, String status, String reason, UUID actor) {
        db.update("UPDATE ad_payments SET status = :s, reject_reason = :r, verified_by = :a, verified_at = now() WHERE id = :id", Db.params().addValue("id", id).addValue("s", status).addValue("r", reason).addValue("a", actor));
    }

    public List<Map<String, Object>> paymentsOf(UUID businessId) {
        return db.list("SELECT py.*, c.title_en AS campaign_title FROM ad_payments py JOIN ad_campaigns c ON c.id = py.campaign_id WHERE py.business_id = :b ORDER BY py.created_at DESC", Map.of("b", businessId));
    }

    public Map<String, Object> searchPayments(String status, int page, int size) {
        MapSqlParameterSource p = Db.params().addValue("s", status).addValue("l", size).addValue("o", (page - 1) * size);
        return Pages.of(db.list("SELECT py.*, c.title_en AS campaign_title, b.name AS business_name, u.email AS business_email, COUNT(*) OVER () AS total_count FROM ad_payments py "
            + "JOIN ad_campaigns c ON c.id = py.campaign_id JOIN businesses b ON b.id = py.business_id JOIN users u ON u.id = b.user_id "
            + "WHERE (CAST(:s AS text) IS NULL OR py.status = :s) ORDER BY (py.status = 'claimed') DESC, py.created_at DESC LIMIT :l OFFSET :o", p), page, size);
    }

    /* ---------------- serving and tracking ---------------- */

    /**
     * Active campaigns for one placement. Fair rotation: the campaign shown least today comes first (random among equals), so
     * every paying business gets a similar share however many are booked. Only verified businesses are served.
     */
    public List<Map<String, Object>> serve(String placement, UUID destinationId, String q, int limit) {
        MapSqlParameterSource p = Db.params().addValue("pl", placement).addValue("dest", destinationId).addValue("q", q == null || q.isBlank() ? null : Text.like(q)).addValue("raw", q == null ? "" : q.trim()).addValue("l", limit);
        return db.list("SELECT c.id, c.placement, c.title_en, c.title_km, c.body_en, c.body_km, c.offer_en, c.offer_km, c.image_url, c.cta_url, c.festival_name_en, c.festival_name_km, c.start_date, c.end_date, "
            + "(c.article_en IS NOT NULL AND c.article_en <> '') AS has_article, a.slug AS accommodation_slug, "
            + "b.name AS business_name, b.name_km AS business_name_km, b.category AS business_category, b.phone AS business_phone, b.logo_url AS business_logo "
            + "FROM ad_campaigns c JOIN businesses b ON b.id = c.business_id LEFT JOIN accommodations a ON a.id = c.accommodation_id AND a.deleted_at IS NULL "
            + "LEFT JOIN ad_stats_daily s ON s.campaign_id = c.id AND s.day = " + TODAY + " "
            + "WHERE c.placement = :pl AND c.status IN ('scheduled','active') AND c.start_date <= " + TODAY + " AND c.end_date >= " + TODAY + " AND b.verification_status = 'verified' "
            + "AND (CAST(:dest AS uuid) IS NULL OR cardinality(c.target_destination_ids) = 0 OR CAST(:dest AS uuid) = ANY(c.target_destination_ids)) "
            + "AND (CAST(:q AS text) IS NULL OR c.title_en ILIKE :q OR c.title_km ILIKE :q OR b.name ILIKE :q OR b.name_km ILIKE :q OR b.category ILIKE :q OR a.name ILIKE :q "
            + "OR EXISTS (SELECT 1 FROM unnest(c.keywords) k WHERE lower(CAST(:raw AS text)) LIKE '%' || lower(k) || '%')) "
            + "ORDER BY COALESCE(s.impressions, 0), random() LIMIT :l", p);
    }

    public Optional<Map<String, Object>> servedArticle(UUID id) {
        return db.one("SELECT c.id, c.title_en, c.title_km, c.body_en, c.body_km, c.article_en, c.article_km, c.image_url, c.cta_url, c.start_date, c.end_date, a.slug AS accommodation_slug, "
            + "b.name AS business_name, b.name_km AS business_name_km, b.category AS business_category, b.phone AS business_phone, b.website AS business_website, b.address AS business_address "
            + "FROM ad_campaigns c JOIN businesses b ON b.id = c.business_id LEFT JOIN accommodations a ON a.id = c.accommodation_id "
            + "WHERE c.id = :id AND c.status IN ('scheduled','active') AND c.start_date <= " + TODAY + " AND c.end_date >= " + TODAY + " AND b.verification_status = 'verified'", Map.of("id", id));
    }

    /** Counts only for campaigns that are live today, so replayed ids of expired or unpaid campaigns do nothing. */
    public void track(UUID campaignId, int impressions, int clicks) {
        db.update("INSERT INTO ad_stats_daily (campaign_id, day, impressions, clicks) SELECT c.id, " + TODAY + ", :i, :k FROM ad_campaigns c WHERE c.id = :c AND c.status IN ('scheduled','active') "
            + "AND c.start_date <= " + TODAY + " AND c.end_date >= " + TODAY + " ON CONFLICT (campaign_id, day) DO UPDATE SET impressions = ad_stats_daily.impressions + :i, clicks = ad_stats_daily.clicks + :k",
            Map.of("c", campaignId, "i", impressions, "k", clicks));
    }

    /* ---------------- analytics ---------------- */

    public List<Map<String, Object>> dailyStats(UUID campaignId) {
        return db.list("SELECT day, impressions, clicks FROM ad_stats_daily WHERE campaign_id = :c ORDER BY day", Map.of("c", campaignId));
    }

    public List<Map<String, Object>> businessDaily(UUID businessId, int days) {
        return db.list("SELECT g.d::date AS day, COALESCE(SUM(s.impressions), 0)::int AS impressions, COALESCE(SUM(s.clicks), 0)::int AS clicks "
            + "FROM generate_series(" + TODAY + " - (CAST(:n AS int) - 1), " + TODAY + ", interval '1 day') g(d) LEFT JOIN (SELECT s.* FROM ad_stats_daily s JOIN ad_campaigns c ON c.id = s.campaign_id WHERE c.business_id = :b) s ON s.day = g.d::date "
            + "GROUP BY g.d ORDER BY g.d", Map.of("b", businessId, "n", days));
    }

    public Map<String, Object> businessTotals(UUID businessId) {
        return db.one("SELECT COALESCE((SELECT SUM(s.impressions) FROM ad_stats_daily s JOIN ad_campaigns c ON c.id = s.campaign_id WHERE c.business_id = :b), 0)::bigint AS impressions, "
            + "COALESCE((SELECT SUM(s.clicks) FROM ad_stats_daily s JOIN ad_campaigns c ON c.id = s.campaign_id WHERE c.business_id = :b), 0)::bigint AS clicks, "
            + "COALESCE((SELECT SUM(amount_usd) FROM ad_payments WHERE business_id = :b AND status = 'verified'), 0) AS spent_usd, "
            + "COALESCE((SELECT SUM(amount_usd) FROM ad_payments WHERE business_id = :b AND status IN ('pending','claimed')), 0) AS pending_usd, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE business_id = :b AND status = 'active') AS active_campaigns, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE business_id = :b AND status = 'scheduled') AS scheduled_campaigns, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE business_id = :b AND status = 'expired') AS expired_campaigns, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE business_id = :b) AS total_campaigns", Map.of("b", businessId)).orElseThrow();
    }

    public Map<String, Object> adminTotals() {
        return db.one("SELECT COALESCE((SELECT SUM(amount_usd) FROM ad_payments WHERE status = 'verified'), 0) AS revenue_usd, "
            + "COALESCE((SELECT SUM(amount_usd) FROM ad_payments WHERE status = 'verified' AND verified_at >= date_trunc('month', now())), 0) AS revenue_month_usd, "
            + "COALESCE((SELECT SUM(amount_usd) FROM ad_payments WHERE status IN ('pending','claimed')), 0) AS outstanding_usd, "
            + "COALESCE((SELECT SUM(impressions) FROM ad_stats_daily), 0)::bigint AS impressions, COALESCE((SELECT SUM(clicks) FROM ad_stats_daily), 0)::bigint AS clicks, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE status = 'active') AS active_campaigns, (SELECT COUNT(*)::int FROM ad_campaigns WHERE status = 'scheduled') AS scheduled_campaigns, "
            + "(SELECT COUNT(*)::int FROM ad_campaigns WHERE status = 'expired') AS expired_campaigns, (SELECT COUNT(*)::int FROM ad_campaigns WHERE status = 'pending_review') AS to_review, "
            + "(SELECT COUNT(*)::int FROM ad_payments WHERE status = 'claimed') AS payments_to_verify, (SELECT COUNT(*)::int FROM businesses WHERE verification_status = 'pending') AS businesses_to_verify, "
            + "(SELECT COUNT(*)::int FROM businesses WHERE verification_status = 'verified') AS verified_businesses", Map.of()).orElseThrow();
    }

    public List<Map<String, Object>> revenueDaily(int days) {
        return db.list("SELECT g.d::date AS day, COALESCE(SUM(py.amount_usd), 0) AS revenue_usd FROM generate_series(" + TODAY + " - (CAST(:n AS int) - 1), " + TODAY + ", interval '1 day') g(d) "
            + "LEFT JOIN ad_payments py ON py.status = 'verified' AND (py.verified_at AT TIME ZONE 'Asia/Phnom_Penh')::date = g.d::date GROUP BY g.d ORDER BY g.d", Map.of("n", days));
    }

    public List<Map<String, Object>> revenueByPackage() {
        return db.list("SELECT p.code, p.name_en, p.name_km, COALESCE(SUM(py.amount_usd), 0) AS revenue_usd, COUNT(py.id)::int AS payments FROM ad_packages p "
            + "LEFT JOIN ad_campaigns c ON c.package_id = p.id LEFT JOIN ad_payments py ON py.campaign_id = c.id AND py.status = 'verified' GROUP BY p.id ORDER BY p.sort_order");
    }

    public List<Map<String, Object>> topCampaigns(int limit) {
        return db.list("SELECT c.id, c.title_en, c.placement, c.status, b.name AS business_name, COALESCE(SUM(s.impressions), 0)::int AS impressions, COALESCE(SUM(s.clicks), 0)::int AS clicks "
            + "FROM ad_campaigns c JOIN businesses b ON b.id = c.business_id LEFT JOIN ad_stats_daily s ON s.campaign_id = c.id GROUP BY c.id, b.name HAVING COALESCE(SUM(s.impressions), 0) > 0 "
            + "ORDER BY COALESCE(SUM(s.clicks), 0) DESC, COALESCE(SUM(s.impressions), 0) DESC LIMIT :l", Map.of("l", limit));
    }
}

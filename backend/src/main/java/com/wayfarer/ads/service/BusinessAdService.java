package com.wayfarer.ads.service;

import com.wayfarer.ads.dto.AdDtos.BusinessProfileRequest;
import com.wayfarer.ads.dto.AdDtos.BusinessRegisterRequest;
import com.wayfarer.ads.dto.AdDtos.CampaignRequest;
import com.wayfarer.ads.dto.AdDtos.ClaimRequest;
import com.wayfarer.ads.dto.AdDtos.PaymentRequest;
import com.wayfarer.ads.dto.AdDtos.QuoteRequest;
import com.wayfarer.ads.dto.AdDtos.RenewRequest;
import com.wayfarer.ads.repository.AdRepository;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.auth.dto.AuthDtos.AuthResponse;
import com.wayfarer.auth.service.AuthService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.common.Text;
import com.wayfarer.media.service.MediaService;
import com.wayfarer.security.AuthUser;
import com.wayfarer.user.repository.UserRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Everything a business owner does: profile, quotes, campaigns, paying and reading results. Every record is checked to belong to the caller's business. */
@Service
public class BusinessAdService {
    public static final ZoneId ZONE = ZoneId.of("Asia/Phnom_Penh");
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String REF_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final Set<String> EDITABLE = Set.of("draft", "rejected");
    private static final Set<String> CANCELLABLE = Set.of("draft", "pending_review", "rejected", "awaiting_payment");

    private final AdRepository ads;
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final AuthService auth;
    private final MediaService media;
    private final AuditService audit;

    public BusinessAdService(AdRepository ads, UserRepository users, PasswordEncoder encoder, AuthService auth, MediaService media, AuditService audit) {
        this.ads = ads;
        this.users = users;
        this.encoder = encoder;
        this.auth = auth;
        this.media = media;
        this.audit = audit;
    }

    public static LocalDate today() { return LocalDate.now(ZONE); }

    /* ---------------- account and profile ---------------- */

    @Transactional
    public AuthResponse register(BusinessRegisterRequest r) {
        if (users.emailTaken(r.email())) throw ApiException.conflict("EMAIL_TAKEN", "An account with this email already exists");
        Map<String, Object> u = users.insertManagedUser(r.email().trim(), encoder.encode(r.password()), r.ownerName().trim(), r.phone(), "business", false);
        UUID id = Rows.uuid(u, "id");
        UUID businessId = ads.insertBusiness(id, null, r.businessName().trim(), r.category(), r.phone(), "pending");
        audit.record(id, "business.register", "business", businessId, Map.of("name", r.businessName()));
        return auth.issueSession(u);
    }

    /** The caller's business. A hotel partner (created by an administrator) gets a verified business on first use. */
    @Transactional
    public Map<String, Object> business(AuthUser u) {
        var found = ads.businessByUser(u.id());
        if (found.isPresent()) return found.get();
        if ("partner".equals(u.role())) {
            Map<String, Object> p = ads.partnerByUser(u.id()).orElseThrow(() -> ApiException.forbidden("NO_BUSINESS", "No business profile for this account"));
            ads.insertBusiness(u.id(), Rows.uuid(p, "id"), Rows.str(p, "name"), "hotel", Rows.str(p, "contact_phone"), "verified");
            return ads.businessByUser(u.id()).orElseThrow();
        }
        throw ApiException.forbidden("NO_BUSINESS", "No business profile for this account");
    }

    @Transactional
    public Map<String, Object> updateProfile(AuthUser u, BusinessProfileRequest r) {
        Map<String, Object> b = business(u);
        String logo = media.requireSafeImageUrl(u.id(), r.logoUrl());
        ads.updateBusiness(Rows.uuid(b, "id"), r.name().trim(), blank(r.nameKm()), r.category(), blank(r.description()), blank(r.descriptionKm()), blank(r.phone()), safeLink(r.website()),
            blank(r.address()), r.destinationId(), logo);
        audit.record(u.id(), "business.update", "business", b.get("id"), Map.of());
        return ads.businessByUser(u.id()).orElseThrow();
    }

    public Map<String, Object> packages() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("items", ads.packages(true));
        out.put("khrPerUsd", ads.khrPerUsd());
        out.put("today", today());
        return out;
    }

    /* ---------------- quotes ---------------- */

    public Map<String, Object> quote(AuthUser u, QuoteRequest r) {
        Map<String, Object> pkg = activePackage(r.packageId());
        Map<String, Object> q = price(pkg, r.units(), r.startDate());
        int peak = ads.peakLoad(Rows.uuid(pkg, "id"), r.startDate(), (LocalDate) q.get("endDate"), null);
        q.put("capacity", pkg.get("slot_capacity"));
        q.put("booked", peak);
        q.put("available", peak < Rows.integer(pkg, "slot_capacity"));
        q.put("amountKhr", khr((BigDecimal) q.get("priceUsd")));
        q.put("khrPerUsd", ads.khrPerUsd());
        return q;
    }

    private Map<String, Object> price(Map<String, Object> pkg, int units, LocalDate start) {
        requireUnits(pkg, units);
        if (start.isBefore(today())) throw ApiException.unprocessable("START_IN_PAST", "Choose a start date from today onwards");
        if (start.isAfter(today().plusDays(365))) throw ApiException.unprocessable("START_TOO_FAR", "Campaigns can be booked up to a year ahead");
        int days = units * Rows.integer(pkg, "days_per_unit");
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("units", units);
        m.put("days", days);
        m.put("startDate", start);
        m.put("endDate", start.plusDays(days - 1L));
        m.put("unitPriceUsd", pkg.get("unit_price_usd"));
        m.put("priceUsd", Rows.round2(Rows.dec(pkg, "unit_price_usd").multiply(BigDecimal.valueOf(units))));
        return m;
    }

    private static void requireUnits(Map<String, Object> pkg, int units) {
        if (units < Rows.integer(pkg, "min_units") || units > Rows.integer(pkg, "max_units")) {
            throw ApiException.unprocessable("INVALID_DURATION", "This package can be booked for " + pkg.get("min_units") + " to " + pkg.get("max_units") + " " + pkg.get("unit") + "(s)");
        }
    }

    private Map<String, Object> activePackage(UUID id) {
        Map<String, Object> pkg = ads.packageById(id).orElseThrow(() -> ApiException.notFound("Package"));
        if (!Boolean.TRUE.equals(pkg.get("is_active"))) throw ApiException.conflict("PACKAGE_UNAVAILABLE", "This package is not on sale right now");
        return pkg;
    }

    /** Riel amount, rounded up to the configured step (default 100 KHR) so the business never underpays by rounding. */
    private BigDecimal khr(BigDecimal usd) {
        BigDecimal step = new BigDecimal(ads.settings().getOrDefault("khr_rounding", "100"));
        return usd.multiply(ads.khrPerUsd()).divide(step, 0, RoundingMode.CEILING).multiply(step).setScale(0, RoundingMode.UNNECESSARY);
    }

    /* ---------------- campaigns ---------------- */

    public Map<String, Object> campaigns(AuthUser u) {
        Map<String, Object> b = business(u);
        return Map.of("items", ads.campaignsOf(Rows.uuid(b, "id")).stream().map(BusinessAdService::decorate).toList());
    }

    public Map<String, Object> campaign(AuthUser u, UUID id) {
        Map<String, Object> b = business(u);
        Map<String, Object> c = owned(b, id);
        Map<String, Object> out = new LinkedHashMap<>(decorate(c));
        out.put("daily", ads.dailyStats(id));
        out.put("openPayment", ads.openPayment(id).orElse(null));
        return out;
    }

    @Transactional
    public Map<String, Object> create(AuthUser u, CampaignRequest r) {
        Map<String, Object> b = business(u);
        Map<String, Object> pkg = activePackage(r.packageId());
        Map<String, Object> values = values(u, b, pkg, r, "draft");
        UUID id = ads.insertCampaign(values);
        audit.record(u.id(), "ads.campaign.create", "ad_campaign", id, Map.of("package", pkg.get("code")));
        if (Boolean.TRUE.equals(r.submit())) submitInternal(b, id);
        return campaign(u, id);
    }

    @Transactional
    public Map<String, Object> update(AuthUser u, UUID id, CampaignRequest r) {
        Map<String, Object> b = business(u);
        Map<String, Object> c = owned(b, id);
        if (!EDITABLE.contains(Rows.str(c, "status"))) throw ApiException.conflict("NOT_EDITABLE", "Only drafts and rejected campaigns can be edited. Cancel it and create a new one, or renew it.");
        Map<String, Object> pkg = activePackage(r.packageId());
        ads.updateCampaignContent(id, values(u, b, pkg, r, "draft"));
        audit.record(u.id(), "ads.campaign.update", "ad_campaign", id, Map.of());
        if (Boolean.TRUE.equals(r.submit())) submitInternal(b, id);
        return campaign(u, id);
    }

    @Transactional
    public Map<String, Object> submit(AuthUser u, UUID id) {
        Map<String, Object> b = business(u);
        owned(b, id);
        submitInternal(b, id);
        return campaign(u, id);
    }

    private void submitInternal(Map<String, Object> b, UUID id) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!EDITABLE.contains(Rows.str(c, "status"))) throw ApiException.conflict("NOT_SUBMITTABLE", "This campaign was already submitted");
        if (!"verified".equals(b.get("verification_status"))) {
            throw ApiException.conflict("BUSINESS_NOT_VERIFIED", "Your business is " + b.get("verification_status") + ". You can submit campaigns once our team has verified it.");
        }
        if (Rows.date(c, "start_date").isBefore(today())) throw ApiException.unprocessable("START_IN_PAST", "The start date has passed. Edit the campaign and pick a new date.");
        Map<String, Object> pkg = activePackage(Rows.uuid(c, "package_id"));
        requireCapacity(pkg, Rows.date(c, "start_date"), Rows.date(c, "end_date"), id);
        ads.setReview(id, "pending_review", null, null);
    }

    @Transactional
    public Map<String, Object> cancel(AuthUser u, UUID id) {
        Map<String, Object> b = business(u);
        owned(b, id);
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow();
        if (!CANCELLABLE.contains(Rows.str(c, "status"))) throw ApiException.conflict("NOT_CANCELLABLE", "A campaign that is paid or being verified cannot be cancelled here. Contact support.");
        ads.closeOpenPayments(id, "cancelled");
        ads.setStatus(id, "cancelled");
        audit.record(u.id(), "ads.campaign.cancel", "ad_campaign", id, Map.of());
        return campaign(u, id);
    }

    /** A renewal of an approved campaign keeps its approved content, so it goes straight to payment. */
    @Transactional
    public Map<String, Object> renew(AuthUser u, UUID id, RenewRequest r) {
        Map<String, Object> b = business(u);
        Map<String, Object> src = owned(b, id);
        if (!Set.of("active", "expired", "scheduled").contains(Rows.str(src, "status"))) throw ApiException.conflict("NOT_RENEWABLE", "Only a campaign that has run (or is running) can be renewed");
        if (!"verified".equals(b.get("verification_status"))) throw ApiException.conflict("BUSINESS_NOT_VERIFIED", "Your business must be verified to renew a campaign");
        Map<String, Object> pkg = activePackage(Rows.uuid(src, "package_id"));
        int units = r != null && r.units() != null ? r.units() : Rows.integer(src, "units");
        LocalDate fallback = Rows.date(src, "end_date").plusDays(1);
        LocalDate start = r != null && r.startDate() != null ? r.startDate() : (fallback.isBefore(today()) ? today() : fallback);
        Map<String, Object> q = price(pkg, units, start);
        LocalDate end = (LocalDate) q.get("endDate");
        requireCapacity(pkg, start, end, null);

        Map<String, Object> v = new LinkedHashMap<>();
        v.put("business_id", b.get("id"));
        v.put("package_id", pkg.get("id"));
        v.put("placement", pkg.get("placement"));
        v.put("status", "awaiting_payment");
        for (String k : List.of("title_en", "title_km", "body_en", "body_km", "offer_en", "offer_km", "article_en", "article_km", "image_url", "cta_url", "accommodation_id", "festival_name_en", "festival_name_km")) v.put(k, src.get(k));
        v.put("targets", pgUuids(uuids(src.get("target_destination_ids"))));
        v.put("keywords", Text.pgArray(strings(src.get("keywords"))));
        v.put("start_date", start);
        v.put("end_date", end);
        v.put("units", units);
        v.put("price_usd", q.get("priceUsd"));
        v.put("renewed_from", id);
        v.put("review_note", "Renewal of an approved campaign");
        UUID nid = ads.insertCampaign(v);
        ads.setReview(nid, "awaiting_payment", "Renewal of an approved campaign", null);
        audit.record(u.id(), "ads.campaign.renew", "ad_campaign", nid, Map.of("from", id));
        return campaign(u, nid);
    }

    private Map<String, Object> values(AuthUser u, Map<String, Object> b, Map<String, Object> pkg, CampaignRequest r, String status) {
        Map<String, Object> q = price(pkg, r.units(), r.startDate());
        String placement = Rows.str(pkg, "placement");
        if ("sponsored_article".equals(placement) && blank(r.articleEn()) == null) throw ApiException.unprocessable("ARTICLE_REQUIRED", "A sponsored article needs its article text");
        if ("festival".equals(placement) && blank(r.festivalNameEn()) == null) throw ApiException.unprocessable("FESTIVAL_REQUIRED", "Name the festival or holiday this campaign is for");
        List<UUID> targets = r.targetDestinationIds() == null ? List.of() : r.targetDestinationIds().stream().distinct().toList();
        if (!targets.isEmpty() && ads.countDestinations(targets) != targets.size()) throw ApiException.unprocessable("UNKNOWN_DESTINATION", "One of the target locations does not exist");
        if (r.accommodationId() != null && !ads.accommodationBelongsToPartner(r.accommodationId(), (UUID) b.get("partner_id"))) {
            throw ApiException.unprocessable("NOT_YOUR_PROPERTY", "You can only link a stay that belongs to your hotel partner account");
        }
        Map<String, Object> v = new LinkedHashMap<>();
        v.put("business_id", b.get("id"));
        v.put("package_id", pkg.get("id"));
        v.put("placement", placement);
        v.put("status", status);
        v.put("title_en", r.titleEn().trim());
        v.put("title_km", blank(r.titleKm()));
        v.put("body_en", blank(r.bodyEn()));
        v.put("body_km", blank(r.bodyKm()));
        v.put("offer_en", blank(r.offerEn()));
        v.put("offer_km", blank(r.offerKm()));
        v.put("article_en", blank(r.articleEn()));
        v.put("article_km", blank(r.articleKm()));
        v.put("image_url", media.requireSafeImageUrl(u.id(), r.imageUrl()));
        v.put("cta_url", safeLink(r.ctaUrl()));
        v.put("accommodation_id", r.accommodationId());
        v.put("targets", pgUuids(targets));
        v.put("keywords", Text.pgArray(r.keywords() == null ? List.of() : r.keywords().stream().map(String::trim).filter(s -> !s.isEmpty()).distinct().toList()));
        v.put("festival_name_en", blank(r.festivalNameEn()));
        v.put("festival_name_km", blank(r.festivalNameKm()));
        v.put("start_date", q.get("startDate"));
        v.put("end_date", q.get("endDate"));
        v.put("units", r.units());
        v.put("price_usd", q.get("priceUsd"));
        v.put("renewed_from", null);
        v.put("review_note", null);
        return v;
    }

    /** Placement capacity: the package may not be over-booked on any day of the range. */
    public void requireCapacity(Map<String, Object> pkg, LocalDate start, LocalDate end, UUID exclude) {
        UUID pid = Rows.uuid(pkg, "id");
        ads.lockPackage(pid);
        if (ads.peakLoad(pid, start, end, exclude) >= Rows.integer(pkg, "slot_capacity")) {
            throw ApiException.conflict("PLACEMENT_FULL", "This placement is fully booked for part of those dates. Choose other dates or another package.");
        }
    }

    /* ---------------- payments ---------------- */

    public Map<String, Object> paymentInfo() {
        Map<String, String> s = ads.settings();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("khqrImageUrl", blank(s.get("khqr_image_url")));
        m.put("accountName", s.get("account_name"));
        m.put("bankName", s.get("bank_name"));
        m.put("accountNumber", blank(s.get("account_number")));
        m.put("instructions", s.get("transfer_instructions"));
        m.put("khrPerUsd", ads.khrPerUsd());
        return m;
    }

    @Transactional
    public Map<String, Object> startPayment(AuthUser u, UUID campaignId, PaymentRequest r) {
        Map<String, Object> b = business(u);
        owned(b, campaignId);
        Map<String, Object> c = ads.campaignForUpdate(campaignId).orElseThrow();
        if (!"awaiting_payment".equals(c.get("status"))) throw ApiException.conflict("NOT_PAYABLE", "This campaign is not waiting for payment");
        Map<String, Object> open = ads.openPayment(campaignId).orElse(null);
        if (open != null && "claimed".equals(open.get("status"))) throw ApiException.conflict("PAYMENT_UNDER_REVIEW", "Your payment is being verified");
        if (open != null) ads.closeOpenPayments(campaignId, "cancelled");
        BigDecimal usd = Rows.dec(c, "price_usd"), fx = ads.khrPerUsd();
        BigDecimal local = "KHR".equals(r.currency()) ? khr(usd) : usd;
        if (usd.signum() == 0) throw ApiException.conflict("NOTHING_TO_PAY", "This campaign is free; it is activated by our team");
        UUID id = ads.insertPayment(campaignId, Rows.uuid(b, "id"), newReference(), r.method(), r.currency(), usd, local, fx);
        audit.record(u.id(), "ads.payment.start", "ad_payment", id, Map.of("method", r.method(), "currency", r.currency()));
        Map<String, Object> out = new LinkedHashMap<>(ads.payment(id).orElseThrow());
        out.put("instructions", paymentInfo());
        return out;
    }

    @Transactional
    public Map<String, Object> claimPayment(AuthUser u, UUID paymentId, ClaimRequest r) {
        Map<String, Object> b = business(u);
        Map<String, Object> p = ads.paymentForUpdate(paymentId).orElseThrow(() -> ApiException.notFound("Payment"));
        if (!b.get("id").equals(p.get("business_id"))) throw ApiException.notFound("Payment");
        if (!"pending".equals(p.get("status"))) throw ApiException.conflict("NOT_CLAIMABLE", "This payment was already submitted or closed");
        String proof = media.requireSafeImageUrl(u.id(), r.proofUrl());
        try {
            ads.claimPayment(paymentId, r.bankTxnRef().trim(), proof);
        } catch (DuplicateKeyException e) {
            throw ApiException.conflict("TXN_REUSED", "That bank transaction reference was already used for another payment");
        }
        ads.setStatus(Rows.uuid(p, "campaign_id"), "payment_review");
        audit.record(u.id(), "ads.payment.claim", "ad_payment", paymentId, Map.of());
        return ads.payment(paymentId).orElseThrow();
    }

    public Map<String, Object> payments(AuthUser u) {
        Map<String, Object> b = business(u);
        return Map.of("items", ads.paymentsOf(Rows.uuid(b, "id")));
    }

    /* ---------------- results ---------------- */

    public Map<String, Object> analytics(AuthUser u) {
        Map<String, Object> b = business(u);
        UUID id = Rows.uuid(b, "id");
        Map<String, Object> t = new LinkedHashMap<>(ads.businessTotals(id));
        long imp = ((Number) t.get("impressions")).longValue(), clk = ((Number) t.get("clicks")).longValue();
        t.put("ctr", imp == 0 ? 0 : Math.round(clk * 10000.0 / imp) / 100.0);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("totals", t);
        out.put("daily", ads.businessDaily(id, 30));
        out.put("campaigns", ads.campaignsOf(id).stream().map(BusinessAdService::decorate).toList());
        return out;
    }

    /* ---------------- helpers ---------------- */

    private Map<String, Object> owned(Map<String, Object> business, UUID campaignId) {
        Map<String, Object> c = ads.campaign(campaignId).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!business.get("id").equals(c.get("business_id"))) throw ApiException.notFound("Campaign");
        return c;
    }

    /** Adds click-through rate and what the owner may do next. */
    public static Map<String, Object> decorate(Map<String, Object> c) {
        Map<String, Object> m = new LinkedHashMap<>(c);
        int imp = ((Number) c.getOrDefault("impressions", 0)).intValue(), clk = ((Number) c.getOrDefault("clicks", 0)).intValue();
        m.put("ctr", imp == 0 ? 0 : Math.round(clk * 10000.0 / imp) / 100.0);
        String s = Rows.str(c, "status");
        m.put("can_edit", EDITABLE.contains(s));
        m.put("can_cancel", CANCELLABLE.contains(s));
        m.put("can_renew", Set.of("active", "expired", "scheduled").contains(s));
        m.put("can_pay", "awaiting_payment".equals(s));
        return m;
    }

    private static String newReference() {
        StringBuilder sb = new StringBuilder("WF-AD-");
        for (int i = 0; i < 8; i++) sb.append(REF_CHARS.charAt(RANDOM.nextInt(REF_CHARS.length())));
        return sb.toString();
    }

    static String blank(String s) { return s == null || s.isBlank() ? null : s.trim(); }

    /** Only https links or phone links can be attached to an advertisement, so a campaign cannot carry script or another scheme. */
    static String safeLink(String s) {
        String v = blank(s);
        if (v == null) return null;
        String l = v.toLowerCase();
        if (l.startsWith("https://") || l.matches("^tel:\\+?[0-9 -]{6,20}$")) return v;
        throw ApiException.unprocessable("INVALID_LINK", "Use a link that starts with https:// (or tel:+855...)");
    }

    private static String pgUuids(List<UUID> ids) { return Text.pgArray(ids.stream().map(UUID::toString).toList()); }

    @SuppressWarnings("unchecked")
    private static List<UUID> uuids(Object o) { return o == null ? List.of() : new ArrayList<>((List<UUID>) o); }

    @SuppressWarnings("unchecked")
    private static List<String> strings(Object o) { return o == null ? List.of() : new ArrayList<>((List<String>) o); }
}

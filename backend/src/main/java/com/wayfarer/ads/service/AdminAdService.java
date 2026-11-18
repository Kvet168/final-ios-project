package com.wayfarer.ads.service;

import com.wayfarer.ads.dto.AdDtos.NewPackageRequest;
import com.wayfarer.ads.dto.AdDtos.PackageRequest;
import com.wayfarer.ads.dto.AdDtos.SettingsRequest;
import com.wayfarer.ads.dto.AdDtos.VerifyPaymentRequest;
import com.wayfarer.ads.repository.AdRepository;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.media.service.MediaService;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Staff and administrator side: verify businesses, review campaigns, verify payments, manage packages, placements and revenue. */
@Service
public class AdminAdService {
    private static final Set<String> VERIFICATION = Set.of("verified", "rejected", "suspended", "pending");

    private final AdRepository ads;
    private final BusinessAdService business;
    private final MediaService media;
    private final AuditService audit;

    public AdminAdService(AdRepository ads, BusinessAdService business, MediaService media, AuditService audit) {
        this.ads = ads;
        this.business = business;
        this.media = media;
        this.audit = audit;
    }

    /* ---------------- businesses ---------------- */

    public Map<String, Object> businesses(String status, String q, int page, int size) {
        return ads.searchBusinesses(blank(status), q, Pages.clampPage(page), Pages.clampSize(size, 100));
    }

    public Map<String, Object> businessDetail(UUID id) {
        Map<String, Object> b = ads.businessById(id).orElseThrow(() -> ApiException.notFound("Business"));
        Map<String, Object> out = new LinkedHashMap<>(b);
        out.put("campaigns", ads.campaignsOf(id));
        out.put("payments", ads.paymentsOf(id));
        return out;
    }

    @Transactional
    public Map<String, Object> verifyBusiness(UUID actor, UUID id, String status, String note) {
        if (!VERIFICATION.contains(status)) throw ApiException.unprocessable("VALIDATION_ERROR", "Unknown status");
        ads.businessById(id).orElseThrow(() -> ApiException.notFound("Business"));
        if (("rejected".equals(status) || "suspended".equals(status)) && (note == null || note.isBlank())) throw ApiException.unprocessable("REASON_REQUIRED", "Give the business a reason");
        ads.setVerification(id, status, note, actor);
        if ("suspended".equals(status)) pauseLive(id);
        audit.record(actor, "business." + status, "business", id, Map.of("note", note == null ? "" : note));
        return ads.businessById(id).orElseThrow();
    }

    /** A suspended business stops being served immediately. */
    private void pauseLive(UUID businessId) {
        for (Map<String, Object> c : ads.campaignsOf(businessId)) {
            if (Set.of("active", "scheduled").contains(Rows.str(c, "status"))) ads.setStatus(Rows.uuid(c, "id"), "paused");
        }
    }

    /* ---------------- campaigns ---------------- */

    public Map<String, Object> campaigns(String status, String placement, String q, int page, int size) {
        return ads.searchCampaigns(blank(status), blank(placement), q, Pages.clampPage(page), Pages.clampSize(size, 100));
    }

    public Map<String, Object> campaignDetail(UUID id) {
        Map<String, Object> c = ads.campaign(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        Map<String, Object> out = new LinkedHashMap<>(BusinessAdService.decorate(c));
        out.put("daily", ads.dailyStats(id));
        out.put("payments", ads.paymentsOf(Rows.uuid(c, "business_id")).stream().filter(p -> id.equals(p.get("campaign_id"))).toList());
        out.put("business", ads.businessById(Rows.uuid(c, "business_id")).orElse(null));
        return out;
    }

    @Transactional
    public Map<String, Object> approve(UUID actor, UUID id, String note) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!"pending_review".equals(c.get("status"))) throw ApiException.conflict("NOT_PENDING", "Only campaigns waiting for review can be approved");
        Map<String, Object> b = ads.businessById(Rows.uuid(c, "business_id")).orElseThrow();
        if (!"verified".equals(b.get("verification_status"))) throw ApiException.conflict("BUSINESS_NOT_VERIFIED", "Verify the business first");
        Map<String, Object> pkg = ads.packageById(Rows.uuid(c, "package_id")).orElseThrow();
        if (Rows.date(c, "end_date").isBefore(BusinessAdService.today())) throw ApiException.conflict("DATES_PASSED", "The campaign dates have passed. Ask the business to pick new dates.");
        business.requireCapacity(pkg, Rows.date(c, "start_date"), Rows.date(c, "end_date"), id);
        if (Rows.dec(c, "price_usd").signum() == 0) {
            ads.setReview(id, activeOrScheduled(c), note, actor);
        } else {
            ads.setReview(id, "awaiting_payment", note, actor);
        }
        audit.record(actor, "ads.campaign.approve", "ad_campaign", id, Map.of());
        return campaignDetail(id);
    }

    @Transactional
    public Map<String, Object> reject(UUID actor, UUID id, String reason) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!"pending_review".equals(c.get("status"))) throw ApiException.conflict("NOT_PENDING", "Only campaigns waiting for review can be rejected");
        ads.setReview(id, "rejected", reason, actor);
        audit.record(actor, "ads.campaign.reject", "ad_campaign", id, Map.of("reason", reason));
        return campaignDetail(id);
    }

    @Transactional
    public Map<String, Object> pause(UUID actor, UUID id, String note) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!Set.of("active", "scheduled").contains(Rows.str(c, "status"))) throw ApiException.conflict("NOT_RUNNING", "Only a running or scheduled campaign can be paused");
        ads.setReview(id, "paused", note, actor);
        audit.record(actor, "ads.campaign.pause", "ad_campaign", id, Map.of());
        return campaignDetail(id);
    }

    @Transactional
    public Map<String, Object> resume(UUID actor, UUID id) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!"paused".equals(c.get("status"))) throw ApiException.conflict("NOT_PAUSED", "This campaign is not paused");
        Map<String, Object> pkg = ads.packageById(Rows.uuid(c, "package_id")).orElseThrow();
        business.requireCapacity(pkg, Rows.date(c, "start_date"), Rows.date(c, "end_date"), id);
        ads.setStatus(id, activeOrScheduled(c));
        audit.record(actor, "ads.campaign.resume", "ad_campaign", id, Map.of());
        return campaignDetail(id);
    }

    @Transactional
    public Map<String, Object> cancel(UUID actor, UUID id, String reason) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (Set.of("expired", "cancelled").contains(Rows.str(c, "status"))) throw ApiException.conflict("ALREADY_CLOSED", "This campaign is already closed");
        ads.closeOpenPayments(id, "cancelled");
        ads.setReview(id, "cancelled", reason, actor);
        audit.record(actor, "ads.campaign.cancel", "ad_campaign", id, Map.of("reason", reason == null ? "" : reason));
        return campaignDetail(id);
    }

    /** Moves the campaign to a new start date, keeping its length (so the price paid stays right) and checking placement capacity. */
    @Transactional
    public Map<String, Object> reschedule(UUID actor, UUID id, LocalDate start) {
        Map<String, Object> c = ads.campaignForUpdate(id).orElseThrow(() -> ApiException.notFound("Campaign"));
        if (!Set.of("awaiting_payment", "payment_review", "scheduled", "active", "paused").contains(Rows.str(c, "status"))) throw ApiException.conflict("NOT_SCHEDULABLE", "This campaign cannot be rescheduled");
        long length = ChronoUnit.DAYS.between(Rows.date(c, "start_date"), Rows.date(c, "end_date"));
        LocalDate end = start.plusDays(length);
        if (end.isBefore(BusinessAdService.today())) throw ApiException.unprocessable("DATES_PASSED", "The new dates are already over");
        Map<String, Object> pkg = ads.packageById(Rows.uuid(c, "package_id")).orElseThrow();
        business.requireCapacity(pkg, start, end, id);
        String status = Rows.str(c, "status");
        if (Set.of("scheduled", "active").contains(status)) status = start.isAfter(BusinessAdService.today()) ? "scheduled" : "active";
        ads.setDates(id, start, end, status);
        audit.record(actor, "ads.campaign.reschedule", "ad_campaign", id, Map.of("start", start.toString(), "end", end.toString()));
        return campaignDetail(id);
    }

    private static String activeOrScheduled(Map<String, Object> c) {
        return Rows.date(c, "start_date").isAfter(BusinessAdService.today()) ? "scheduled" : "active";
    }

    /** Capacity used per package for the next days, for the placement planner. */
    public Map<String, Object> placements(int days) {
        int n = Math.max(7, Math.min(60, days));
        Map<String, Map<String, Object>> byPackage = new LinkedHashMap<>();
        for (Map<String, Object> r : ads.dailyLoad(n)) {
            String code = Rows.str(r, "code");
            Map<String, Object> p = byPackage.computeIfAbsent(code, k -> {
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("packageId", r.get("package_id"));
                m.put("code", code);
                m.put("nameEn", r.get("name_en"));
                m.put("nameKm", r.get("name_km"));
                m.put("capacity", r.get("slot_capacity"));
                m.put("days", new java.util.ArrayList<Map<String, Object>>());
                return m;
            });
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> list = (List<Map<String, Object>>) p.get("days");
            list.add(Map.of("day", r.get("day"), "used", r.get("used")));
        }
        return Map.of("items", byPackage.values());
    }

    /* ---------------- payments ---------------- */

    public Map<String, Object> payments(String status, int page, int size) {
        return ads.searchPayments(blank(status), Pages.clampPage(page), Pages.clampSize(size, 100));
    }

    /**
     * Verification is a deliberate act: the reviewer types the amount that actually arrived in the bank account and it must match what the
     * server expected (riel within the rounding step). The amount, the bank reference and the unique payment reference are all server-held, so
     * a business cannot change what it owes, and one bank receipt cannot pay two campaigns.
     */
    @Transactional
    public Map<String, Object> verifyPayment(UUID actor, UUID id, VerifyPaymentRequest r) {
        Map<String, Object> p = ads.paymentForUpdate(id).orElseThrow(() -> ApiException.notFound("Payment"));
        if (!"claimed".equals(p.get("status"))) throw ApiException.conflict("NOT_CLAIMED", "Only a payment the business has submitted can be verified");
        BigDecimal expected = Rows.dec(p, "amount_local"), tolerance = "KHR".equals(p.get("currency")) ? new BigDecimal(ads.settings().getOrDefault("khr_rounding", "100")) : new BigDecimal("0.01");
        if (r.receivedAmount().subtract(expected).abs().compareTo(tolerance) > 0) {
            throw new ApiException(org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY, "AMOUNT_MISMATCH",
                "The amount received does not match. Expected " + expected.stripTrailingZeros().toPlainString() + " " + p.get("currency") + ".", Map.of("expected", expected, "currency", p.get("currency")));
        }
        Map<String, Object> c = ads.campaignForUpdate(Rows.uuid(p, "campaign_id")).orElseThrow();
        if (!Set.of("payment_review", "awaiting_payment").contains(Rows.str(c, "status"))) throw ApiException.conflict("CAMPAIGN_CLOSED", "The campaign is no longer waiting for payment");
        ads.decidePayment(id, "verified", r.note(), actor);
        if (Rows.date(c, "end_date").isBefore(BusinessAdService.today())) {
            ads.setStatus(Rows.uuid(c, "id"), "expired");
        } else {
            ads.setStatus(Rows.uuid(c, "id"), activeOrScheduled(c));
        }
        audit.record(actor, "ads.payment.verify", "ad_payment", id, Map.of("amount", r.receivedAmount().toPlainString(), "currency", String.valueOf(p.get("currency"))));
        return ads.payment(id).orElseThrow();
    }

    @Transactional
    public Map<String, Object> rejectPayment(UUID actor, UUID id, String reason) {
        Map<String, Object> p = ads.paymentForUpdate(id).orElseThrow(() -> ApiException.notFound("Payment"));
        if (!"claimed".equals(p.get("status"))) throw ApiException.conflict("NOT_CLAIMED", "Only a payment the business has submitted can be rejected");
        ads.decidePayment(id, "rejected", reason, actor);
        ads.setStatus(Rows.uuid(p, "campaign_id"), "awaiting_payment");
        audit.record(actor, "ads.payment.reject", "ad_payment", id, Map.of("reason", reason));
        return ads.payment(id).orElseThrow();
    }

    /* ---------------- packages and settings ---------------- */

    public Map<String, Object> packages() { return Map.of("items", ads.packages(false), "khrPerUsd", ads.khrPerUsd()); }

    @Transactional
    public Map<String, Object> updatePackage(UUID actor, UUID id, PackageRequest r) {
        if (r.minUnits() > r.maxUnits()) throw ApiException.unprocessable("VALIDATION_ERROR", "The minimum duration cannot be longer than the maximum");
        ads.packageById(id).orElseThrow(() -> ApiException.notFound("Package"));
        ads.updatePackage(id, r.nameEn().trim(), r.nameKm().trim(), r.descriptionEn(), r.descriptionKm(), r.unitPriceUsd(), r.daysPerUnit(), r.minUnits(), r.maxUnits(), r.slotCapacity(), r.active(), r.sortOrder());
        audit.record(actor, "ads.package.update", "ad_package", id, Map.of("price", r.unitPriceUsd().toPlainString(), "days", r.daysPerUnit(), "capacity", r.slotCapacity(), "active", r.active()));
        return ads.packageById(id).orElseThrow();
    }

    @Transactional
    public Map<String, Object> createPackage(UUID actor, NewPackageRequest r) {
        PackageRequest d = r.details();
        if (d.minUnits() > d.maxUnits()) throw ApiException.unprocessable("VALIDATION_ERROR", "The minimum duration cannot be longer than the maximum");
        UUID id;
        try {
            id = ads.insertPackage(r.code(), r.placement(), r.unit(), d.nameEn().trim(), d.nameKm().trim(), d.descriptionEn(), d.descriptionKm(), d.unitPriceUsd(), d.daysPerUnit(), d.minUnits(), d.maxUnits(), d.slotCapacity(), d.active(), d.sortOrder());
        } catch (org.springframework.dao.DuplicateKeyException e) {
            throw ApiException.conflict("CODE_TAKEN", "A package with this code already exists");
        }
        audit.record(actor, "ads.package.create", "ad_package", id, Map.of("code", r.code()));
        return ads.packageById(id).orElseThrow();
    }

    public Map<String, Object> settings() {
        Map<String, Object> m = new LinkedHashMap<>(business.paymentInfo());
        m.put("khrRounding", ads.settings().getOrDefault("khr_rounding", "100"));
        return m;
    }

    @Transactional
    public Map<String, Object> updateSettings(UUID actor, SettingsRequest r) {
        if (r.khqrImageUrl() != null) ads.putSetting("khqr_image_url", media.requireSafeImageUrl(actor, r.khqrImageUrl()) == null ? "" : r.khqrImageUrl().trim());
        if (r.accountName() != null) ads.putSetting("account_name", r.accountName().trim());
        if (r.bankName() != null) ads.putSetting("bank_name", r.bankName().trim());
        if (r.accountNumber() != null) ads.putSetting("account_number", r.accountNumber().trim());
        if (r.transferInstructions() != null) ads.putSetting("transfer_instructions", r.transferInstructions().trim());
        if (r.khrRounding() != null) ads.putSetting("khr_rounding", r.khrRounding());
        audit.record(actor, "ads.settings.update", "ad_settings", null, Map.of());
        return settings();
    }

    /* ---------------- analytics ---------------- */

    public Map<String, Object> analytics() {
        Map<String, Object> t = new LinkedHashMap<>(ads.adminTotals());
        long imp = ((Number) t.get("impressions")).longValue(), clk = ((Number) t.get("clicks")).longValue();
        t.put("ctr", imp == 0 ? 0 : Math.round(clk * 10000.0 / imp) / 100.0);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("totals", t);
        out.put("revenueDaily", ads.revenueDaily(30));
        out.put("revenueByPackage", ads.revenueByPackage());
        out.put("topCampaigns", ads.topCampaigns(8));
        return out;
    }

    private static String blank(String s) { return s == null || s.isBlank() ? null : s; }
}

package com.wayfarer.partner.service;

import com.wayfarer.admin.dto.AdminDtos.InventoryRequest;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.domain.BookingStatus;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.booking.service.BookingService;
import com.wayfarer.booking.service.InventoryService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.media.service.MediaService;
import com.wayfarer.partner.dto.PartnerDtos.ProfileRequest;
import com.wayfarer.partner.repository.PartnerRepository;
import com.wayfarer.payment.repository.PaymentRepository;
import com.wayfarer.payment.service.PaymentService;
import com.wayfarer.security.AuthUser;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Partner portal use cases other than property editing ({@link PropertyService}): their organisation and QR payment settings,
 * bookings and check-in, stock and prices, QR payment confirmation, analytics and guest reviews. Everything is scoped to the caller's own properties.
 */
@Service
public class PartnerService {
    private final PartnerRepository partners;
    private final BookingRepository bookingRepository;
    private final BookingService bookings;
    private final InventoryService inventory;
    private final PaymentRepository payments;
    private final PaymentService paymentService;
    private final MediaService media;
    private final AuditService audit;

    public PartnerService(PartnerRepository partners, BookingRepository bookingRepository, BookingService bookings, InventoryService inventory, PaymentRepository payments,
                          PaymentService paymentService, MediaService media, AuditService audit) {
        this.partners = partners;
        this.bookingRepository = bookingRepository;
        this.bookings = bookings;
        this.inventory = inventory;
        this.payments = payments;
        this.paymentService = paymentService;
        this.media = media;
        this.audit = audit;
    }

    private List<UUID> scope(AuthUser u) { return partners.accommodationIds(u.id()); }

    /* ------------------------------------------------------------ organisation and QR payment settings */

    public Map<String, Object> profile(AuthUser u) {
        Map<String, Object> p = partners.findByUser(u.id()).orElseThrow(() -> ApiException.forbidden("NO_PARTNER_ACCOUNT", "This account is not linked to a partner organisation."));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("id", p.get("id"));
        out.put("name", p.get("name"));
        out.put("contactPhone", p.get("contact_phone"));
        out.put("accountName", p.get("payment_account_name"));
        out.put("bank", p.get("payment_bank"));
        out.put("note", p.get("payment_note"));
        out.put("qrMediaId", p.get("payment_qr_media_id"));
        out.put("qrImageUrl", p.get("payment_qr_media_id") == null ? null : MediaService.urlFor((UUID) p.get("payment_qr_media_id")));
        out.put("acceptsQr", p.get("payment_qr_media_id") != null);
        return out;
    }

    /** Replaces the organisation details and QR payment settings (omitted optional fields are cleared). */
    @Transactional
    public Map<String, Object> updateProfile(AuthUser u, ProfileRequest r) {
        Map<String, Object> p = partners.findByUser(u.id()).orElseThrow(() -> ApiException.forbidden("NO_PARTNER_ACCOUNT", "This account is not linked to a partner organisation."));
        media.requireOwnedMedia(u.id(), r.qrMediaId());
        if (r.qrMediaId() != null && (r.accountName() == null || r.accountName().isBlank())) {
            throw ApiException.unprocessable("VALIDATION_ERROR", "Enter the account name that appears on the QR code so guests can check it before paying");
        }
        partners.updateProfile(Rows.uuid(p, "id"), r.name() == null ? null : r.name().trim(), blankToNull(r.contactPhone()), r.qrMediaId(), blankToNull(r.accountName()), blankToNull(r.bank()), blankToNull(r.note()));
        audit.record(u.id(), "partner.profile_update", "partner", p.get("id"), Map.of("qr", r.qrMediaId() != null));
        return profile(u);
    }

    private static String blankToNull(String s) { return s == null || s.isBlank() ? null : s.trim(); }

    /* ------------------------------------------------------------ properties (read) */

    public Map<String, Object> accommodations(AuthUser u) { return Map.of("items", partners.accommodations(scope(u))); }

    /* ------------------------------------------------------------ bookings */

    public Map<String, Object> bookings(AuthUser u, String status, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(bookingRepository.search(status, null, scope(u), true, size, Pages.offset(p, size)), p, size);
    }

    public Map<String, Object> transition(AuthUser u, UUID bookingId, BookingStatus to, String note) {
        if (to != BookingStatus.CHECKED_IN && to != BookingStatus.COMPLETED) throw ApiException.unprocessable("VALIDATION_ERROR", "Partners can set CHECKED_IN or COMPLETED");
        return bookings.staffTransition(bookingId, to, u.id(), note, scope(u), "partner");
    }

    /* ------------------------------------------------------------ stock and prices */

    public Map<String, Object> inventory(AuthUser u, UUID roomTypeId, InventoryRequest r) {
        if (!partners.ownsRoomType(roomTypeId, u.id())) throw ApiException.notFound("Room type");
        return inventory.updateRange(u, roomTypeId, r.from(), r.to(), r.units(), r.priceUsd());
    }

    /* ------------------------------------------------------------ payments (QR) */

    public Map<String, Object> payments(AuthUser u, String status, String method, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(payments.searchForPartner(u.id(), status, method, size, Pages.offset(p, size)), p, size);
    }

    public Map<String, Object> confirmPayment(AuthUser u, UUID paymentId) { return paymentService.confirmQr(u.id(), paymentId); }

    public Map<String, Object> rejectPayment(AuthUser u, UUID paymentId, String reason) { return paymentService.rejectQr(u.id(), paymentId, reason); }

    /* ------------------------------------------------------------ analytics and reviews */

    public Map<String, Object> analytics(AuthUser u) {
        List<UUID> ids = scope(u);
        LocalDate today = LocalDate.now();
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("occupancyPctNext30Days", partners.occupancyPct(ids, today, today.plusDays(30)));
        out.put("bookingsByStatus", partners.bookingsByStatus(ids));
        out.put("note", "Occupancy is derived from stored room inventory; demo figures only.");
        return out;
    }

    public Map<String, Object> reviews(AuthUser u, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(partners.reviews(scope(u), size, Pages.offset(p, size)), p, size);
    }

}

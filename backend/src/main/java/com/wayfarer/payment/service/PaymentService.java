package com.wayfarer.payment.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.domain.BookingStatus;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.booking.service.BookingService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.config.AppProperties;
import com.wayfarer.media.service.MediaService;
import com.wayfarer.notification.service.NotificationService;
import com.wayfarer.partner.repository.PartnerRepository;
import com.wayfarer.payment.dto.PaymentDtos.WebhookEvent;
import com.wayfarer.payment.repository.PaymentRepository;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Payment provider abstraction. In 'mock' mode WAYFARER simulates a card processor: no real money moves and every record
 * is flagged simulated. The client never reports success; only a signed webhook (or the server-side simulator) does.
 */
@Service
public class PaymentService {
    private static final SecureRandom RANDOM = new SecureRandom();

    private final PaymentRepository payments;
    private final BookingRepository bookings;
    private final BookingService bookingService;
    private final NotificationService notifications;
    private final AuditService audit;
    private final AppProperties props;
    private final ObjectMapper json;
    private final PartnerRepository partners;

    public PaymentService(PaymentRepository payments, BookingRepository bookings, BookingService bookingService, NotificationService notifications,
                          AuditService audit, AppProperties props, ObjectMapper json, PartnerRepository partners) {
        this.partners = partners;
        this.payments = payments;
        this.bookings = bookings;
        this.bookingService = bookingService;
        this.notifications = notifications;
        this.audit = audit;
        this.props = props;
        this.json = json;
    }

    private static String hex(int bytes) {
        byte[] b = new byte[bytes];
        RANDOM.nextBytes(b);
        return HexFormat.of().withUpperCase().formatHex(b);
    }

    @Transactional
    public Map<String, Object> createIntent(UUID userId, UUID bookingId, String idempotencyKey, String method) {
        bookingService.expireStaleHolds();
        Map<String, Object> b = bookings.findForUpdate(bookingId).orElse(null);
        if (b == null || !userId.equals(b.get("user_id"))) throw ApiException.notFound("Booking");
        Map<String, Object> same = payments.findByIdempotencyKey(idempotencyKey).orElse(null);
        if (same != null) {
            if (!bookingId.equals(same.get("booking_id")) || !userId.equals(same.get("user_id"))) {
                throw ApiException.conflict("IDEMPOTENCY_KEY_REUSED", "Idempotency key was used for a different request.");
            }
            return same;
        }
        if (!"PENDING_CONFIRMATION".equals(b.get("status"))) throw ApiException.conflict("BOOKING_NOT_PAYABLE", "A booking in status " + b.get("status") + " cannot be paid.");
        boolean qr = "qr".equals(method);
        if (qr && partners.qrFor(Rows.uuid(b, "accommodation_id")).isEmpty()) {
            throw ApiException.conflict("QR_NOT_AVAILABLE", "This property does not accept QR payments yet. Pay by card instead.");
        }
        Map<String, Object> open = payments.findOpenForBooking(bookingId).orElse(null);
        if (open != null) {
            boolean sameMethod = method.equals(open.get("method"));
            boolean switchable = "PENDING".equals(open.get("status")) && open.get("claimed_at") == null;
            if (sameMethod || !switchable) return open;
            payments.setStatus(Rows.uuid(open, "id"), "CANCELLED", "switched_payment_method");
        }
        boolean mock = !qr && props.payment().isMock();
        Map<String, Object> p = payments.insert(new MapSqlParameterSource().addValue("b", bookingId).addValue("u", userId).addValue("amt", b.get("total_usd"))
            .addValue("prov", qr ? "khqr" : mock ? "card" : props.payment().mode()).addValue("ref", (qr ? "QR-" : "SIM-") + hex(8)).addValue("key", idempotencyKey)
            .addValue("sim", mock).addValue("method", method));
        audit.record(userId, "payment.intent", "payment", p.get("id"), Map.of("bookingId", bookingId, "amount_usd", p.get("amount_usd"), "method", method));
        return p;
    }

    public Map<String, Object> get(UUID userId, UUID paymentId) {
        Map<String, Object> p = payments.findForUser(paymentId, userId).orElseThrow(() -> ApiException.notFound("Payment"));
        Map<String, Object> out = new LinkedHashMap<>(p);
        out.put("events", payments.events(paymentId));
        return out;
    }

    /** Applies a provider event. Idempotent: the same provider event id is processed once. */
    @Transactional
    public Map<String, Object> applyWebhookEvent(WebhookEvent ev) {
        Map<String, Object> p = payments.findByProviderRefForUpdate(ev.payment_ref()).orElseThrow(() -> ApiException.notFound("Payment"));
        UUID paymentId = Rows.uuid(p, "id");
        String payload;
        try {
            payload = json.writeValueAsString(ev);
        } catch (JsonProcessingException e) {
            payload = "{}";
        }
        if (!payments.insertEvent(paymentId, ev.id(), ev.type(), payload)) return result(true, Rows.str(p, "status"));
        if (!"PENDING".equals(p.get("status"))) return result(false, Rows.str(p, "status"));    // already final; event logged only

        Map<String, Object> b = bookings.findForUpdate(Rows.uuid(p, "booking_id")).orElseThrow();
        UUID bookingId = Rows.uuid(b, "id"), userId = Rows.uuid(b, "user_id");
        boolean sim = Boolean.TRUE.equals(p.get("simulated"));

        if ("payment.succeeded".equals(ev.type())) {
            if (ev.amount_usd() == null || ev.amount_usd().subtract(Rows.dec(p, "amount_usd")).abs().compareTo(new BigDecimal("0.001")) > 0) {
                payments.setStatus(paymentId, "FAILED", "amount_mismatch");
                audit.record(null, "payment.amount_mismatch", "payment", paymentId, Map.of("expected", p.get("amount_usd"), "got", String.valueOf(ev.amount_usd())));
                return result(false, "FAILED");
            }
            if (!"PENDING_CONFIRMATION".equals(b.get("status"))) {
                payments.setStatus(paymentId, "FAILED", "booking_not_payable");
                return result(false, "FAILED");
            }
            payments.setStatus(paymentId, "SUCCESS", null);
            bookingService.transition(bookingId, BookingStatus.PENDING_CONFIRMATION, BookingStatus.CONFIRMED, null,
                "Payment " + p.get("provider_ref") + " verified");
            bookingService.clearHold(bookingId);
            notifications.notify(userId, "payment", "Payment received", "Payment for booking " + b.get("reference") + " succeeded"
                + ". Your booking is confirmed.", Map.of("bookingId", bookingId));
            audit.record(null, "payment.success", "payment", paymentId, Map.of("bookingId", bookingId));
            return result(false, "SUCCESS");
        }
        String status = "payment.cancelled".equals(ev.type()) ? "CANCELLED" : "FAILED";
        payments.setStatus(paymentId, status, ev.reason());
        notifications.notify(userId, "payment", "Payment " + status.toLowerCase(), "Payment for booking " + b.get("reference") + " "
            + ("FAILED".equals(status) ? "failed" : "was cancelled") + ". The booking is not confirmed; you can retry before the hold expires.", Map.of("bookingId", bookingId));
        audit.record(null, "payment." + status.toLowerCase(), "payment", paymentId, Map.of("reason", String.valueOf(ev.reason())));
        return result(false, status);
    }

    private static Map<String, Object> result(boolean duplicate, String status) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("duplicate", duplicate);
        m.put("status", status);
        return m;
    }

    /** Demo-mode stand-in for the provider: builds the event a real provider would send and runs it through the same pipeline. */
    public Map<String, Object> simulate(UUID userId, UUID paymentId, String outcome) {
        if (!props.payment().isMock()) throw ApiException.forbidden("SIMULATION_DISABLED", "Payment simulation is disabled in this environment");
        Map<String, Object> p = payments.findForUser(paymentId, userId).orElseThrow(() -> ApiException.notFound("Payment"));
        if ("qr".equals(p.get("method"))) throw ApiException.conflict("NOT_SIMULATABLE", "QR payments are confirmed by the property, not simulated.");
        String type = switch (outcome) {
            case "success" -> "payment.succeeded";
            case "fail" -> "payment.failed";
            case "cancel" -> "payment.cancelled";
            default -> throw ApiException.unprocessable("VALIDATION_ERROR", "outcome must be success, fail or cancel");
        };
        WebhookEvent ev = new WebhookEvent("evt_" + hex(8).toLowerCase(), type, Rows.str(p, "provider_ref"), Rows.dec(p, "amount_usd"),
            "fail".equals(outcome) ? "card_declined" : null);
        Map<String, Object> out = new LinkedHashMap<>(applyWebhookEvent(ev));
        out.put("payment", payments.summary(paymentId).orElseThrow());
        return out;
    }

    /* ------------------------------------------------------------ QR payments (guest pays the partner directly) */

    /** What the guest needs to pay by QR: the property's code, account details, the exact amount and the booking reference to quote. */
    public Map<String, Object> qrInfo(UUID userId, UUID bookingId) {
        Map<String, Object> b = bookings.findById(bookingId).orElseThrow(() -> ApiException.notFound("Booking"));
        if (!userId.equals(b.get("user_id"))) throw ApiException.notFound("Booking");
        Map<String, Object> out = new LinkedHashMap<>();
        Map<String, Object> qr = partners.qrFor(Rows.uuid(b, "accommodation_id")).orElse(null);
        out.put("available", qr != null);
        out.put("amountUsd", b.get("total_usd"));
        out.put("reference", b.get("reference"));
        if (qr != null) {
            out.put("partnerName", qr.get("partner_name"));
            out.put("qrImageUrl", MediaService.urlFor((UUID) qr.get("payment_qr_media_id")));
            out.put("accountName", qr.get("payment_account_name"));
            out.put("bank", qr.get("payment_bank"));
            out.put("note", qr.get("payment_note"));
            out.put("instructions", "Scan the code, pay exactly " + b.get("total_usd") + " USD and put " + b.get("reference") + " in the payment note. Then tap I have paid.");
        }
        return out;
    }

    /** Guest reports the QR payment as done. The hold is extended so the property has time to check its account. */
    @Transactional
    public Map<String, Object> claim(UUID userId, UUID paymentId, String note) {
        Map<String, Object> p = payments.findForUser(paymentId, userId).orElseThrow(() -> ApiException.notFound("Payment"));
        if (!"qr".equals(p.get("method"))) throw ApiException.conflict("NOT_QR", "Only QR payments need this step.");
        if (!"PENDING".equals(p.get("status"))) throw ApiException.conflict("NOT_PENDING", "This payment is already " + String.valueOf(p.get("status")).toLowerCase() + ".");
        Map<String, Object> b = bookings.findForUpdate(Rows.uuid(p, "booking_id")).orElseThrow();
        if (!"PENDING_CONFIRMATION".equals(b.get("status"))) throw ApiException.conflict("BOOKING_NOT_PAYABLE", "The hold on this booking has ended. Please book again.");
        payments.claim(paymentId, note == null ? null : note.trim());
        bookings.extendHold(Rows.uuid(b, "id"), 12);
        partners.ownerUserOfAccommodation(Rows.uuid(b, "accommodation_id")).ifPresent(owner -> notifications.notify(owner, "payment", "QR payment to confirm",
            "Guest " + b.get("guest_name") + " says they paid " + p.get("amount_usd") + " USD for booking " + b.get("reference") + ". Check your account, then confirm in Payments.",
            Map.of("bookingId", b.get("id"), "paymentId", paymentId)));
        audit.record(userId, "payment.qr_claim", "payment", paymentId, Map.of("bookingId", b.get("id")));
        return payments.summary(paymentId).orElseThrow();
    }

    /** The partner has seen the money arrive: the payment succeeds and the booking is confirmed. */
    @Transactional
    public Map<String, Object> confirmQr(UUID partnerUser, UUID paymentId) {
        if (!payments.belongsToPartner(paymentId, partnerUser)) throw ApiException.notFound("Payment");
        Map<String, Object> p = payments.lockById(paymentId).orElseThrow();
        if (!"qr".equals(p.get("method"))) throw ApiException.conflict("NOT_QR", "Only QR payments are confirmed here.");
        if (!"PENDING".equals(p.get("status"))) throw ApiException.conflict("ALREADY_PROCESSED", "This payment is already " + String.valueOf(p.get("status")).toLowerCase() + ".");
        Map<String, Object> b = bookings.findForUpdate(Rows.uuid(p, "booking_id")).orElseThrow();
        if (!"PENDING_CONFIRMATION".equals(b.get("status"))) throw ApiException.conflict("BOOKING_NOT_PAYABLE", "The booking is " + b.get("status") + " so this payment cannot confirm it.");
        payments.markConfirmed(paymentId, partnerUser);
        payments.insertEvent(paymentId, "evt_qr_confirm_" + paymentId, "payment.succeeded", "{\"confirmedBy\":\"" + partnerUser + "\"}");
        bookingService.transition(Rows.uuid(b, "id"), BookingStatus.PENDING_CONFIRMATION, BookingStatus.CONFIRMED, partnerUser, "Payment received by the property via QR");
        bookingService.clearHold(Rows.uuid(b, "id"));
        notifications.notify(Rows.uuid(b, "user_id"), "payment", "Payment received", "The property confirmed your QR payment for booking " + b.get("reference") + ". Your booking is confirmed.", Map.of("bookingId", b.get("id")));
        audit.record(partnerUser, "payment.qr_confirm", "payment", paymentId, Map.of("bookingId", b.get("id")));
        return payments.summary(paymentId).orElseThrow();
    }

    /** The partner did not receive the money: the payment fails, the booking stays held so the guest can retry. */
    @Transactional
    public Map<String, Object> rejectQr(UUID partnerUser, UUID paymentId, String reason) {
        if (!payments.belongsToPartner(paymentId, partnerUser)) throw ApiException.notFound("Payment");
        Map<String, Object> p = payments.lockById(paymentId).orElseThrow();
        if (!"qr".equals(p.get("method"))) throw ApiException.conflict("NOT_QR", "Only QR payments are handled here.");
        if (!"PENDING".equals(p.get("status"))) throw ApiException.conflict("ALREADY_PROCESSED", "This payment is already " + String.valueOf(p.get("status")).toLowerCase() + ".");
        Map<String, Object> b = bookings.findById(Rows.uuid(p, "booking_id")).orElseThrow();
        String why = reason == null || reason.isBlank() ? "Payment not found in the property's account" : reason.trim();
        payments.setStatus(paymentId, "FAILED", why);
        payments.insertEvent(paymentId, "evt_qr_reject_" + paymentId, "payment.failed", "{\"rejectedBy\":\"" + partnerUser + "\"}");
        notifications.notify(Rows.uuid(b, "user_id"), "payment", "Payment not confirmed", "The property could not find your QR payment for booking " + b.get("reference") + ": " + why
            + ". You can try again before the hold ends.", Map.of("bookingId", b.get("id")));
        audit.record(partnerUser, "payment.qr_reject", "payment", paymentId, Map.of("reason", why));
        return payments.summary(paymentId).orElseThrow();
    }
}

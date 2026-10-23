package com.wayfarer.booking.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.domain.BookingStatus;
import com.wayfarer.booking.dto.BookingDtos.CreateBookingRequest;
import com.wayfarer.booking.dto.BookingDtos.QuoteRequest;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.booking.repository.InventoryRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.config.AppProperties;
import com.wayfarer.notification.dto.UserPush;
import com.wayfarer.notification.service.NotificationService;
import com.wayfarer.partner.repository.PartnerRepository;
import com.wayfarer.payment.repository.PaymentRepository;
import com.wayfarer.security.AuthUser;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

/** Booking use cases: quote, create, read, cancel, expire holds, and the state machine every status change goes through. */
@Service
public class BookingService {
    private static final Logger log = LoggerFactory.getLogger(BookingService.class);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final BookingRepository bookings;
    private final InventoryRepository inventory;
    private final PaymentRepository payments;
    private final PartnerRepository partners;
    private final StayQuoteService quotes;
    private final NotificationService notifications;
    private final AuditService audit;
    private final AppProperties props;
    private final ApplicationEventPublisher events;
    private final TransactionTemplate tx;

    public BookingService(BookingRepository bookings, InventoryRepository inventory, PaymentRepository payments, PartnerRepository partners, StayQuoteService quotes,
                          NotificationService notifications, AuditService audit, AppProperties props, ApplicationEventPublisher events, TransactionTemplate tx) {
        this.bookings = bookings;
        this.inventory = inventory;
        this.payments = payments;
        this.partners = partners;
        this.quotes = quotes;
        this.notifications = notifications;
        this.audit = audit;
        this.props = props;
        this.events = events;
        this.tx = tx;
    }

    private static String reference() {
        byte[] b = new byte[5];
        RANDOM.nextBytes(b);
        return "WF-" + HexFormat.of().withUpperCase().formatHex(b);
    }

    public Map<String, Object> cancellationInfo(Map<String, Object> b) {
        BookingStatus s = BookingStatus.valueOf(Rows.str(b, "status"));
        Instant until = (Instant) b.get("free_cancel_until");
        boolean cancellable = s.isCancellable();
        return Map.of("cancellable", cancellable, "freeCancellation", cancellable && until != null && until.isAfter(Instant.now()));
    }

    @Transactional(readOnly = true)
    public Map<String, Object> quote(QuoteRequest r) {
        StayQuote q = quotes.quote(r.roomTypeId(), r.checkIn(), r.checkOut(), r.roomsOrDefault(), false);
        Map<String, Object> out = q.toMap();
        out.put("roomName", q.room().get("name"));
        out.put("accommodationName", q.room().get("accommodation_name"));
        out.put("cancellationPolicy", q.room().get("cancellation_policy"));
        return out;
    }

    /** Moves a booking one legal step and records the event. Fails with STALE_STATE if another request moved it first. */
    public void transition(UUID bookingId, BookingStatus from, BookingStatus to, UUID actorId, String note) {
        if (!from.canMoveTo(to)) throw ApiException.conflict("ILLEGAL_TRANSITION", "A booking cannot move from " + from + " to " + to + ".");
        Map<String, Object> row = bookings.updateStatus(bookingId, from.name(), to.name())
            .orElseThrow(() -> ApiException.conflict("STALE_STATE", "Booking state changed; please refresh and retry."));
        bookings.insertEvent(bookingId, from.name(), to.name(), actorId, note);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("bookingId", bookingId);
        data.put("reference", row.get("reference"));
        data.put("from", from.name());
        data.put("to", to.name());
        events.publishEvent(new UserPush((UUID) row.get("user_id"), "booking.status", data));
    }

    @Transactional
    public Map<String, Object> create(UUID userId, CreateBookingRequest in) {
        expireStaleHolds();
        int rooms = in.roomsOrDefault();
        StayQuote q = quotes.quote(in.roomTypeId(), in.checkIn(), in.checkOut(), rooms, true);
        Map<String, Object> room = q.room();
        int maxAdults = Rows.integer(room, "max_adults") * rooms, maxChildren = Rows.integer(room, "max_children") * rooms;
        if (in.adults() > maxAdults || in.childrenOrDefault() > maxChildren) {
            throw ApiException.unprocessable("CAPACITY_EXCEEDED", "This room type fits up to " + room.get("max_adults") + " adults and "
                + room.get("max_children") + " children per room.");
        }
        if (!q.available()) throw ApiException.conflict("NO_AVAILABILITY", q.reason() != null ? q.reason() : "No availability for the selected dates.");
        if (inventory.take(in.roomTypeId(), in.checkIn(), in.checkOut(), rooms) != q.nights()) {
            throw ApiException.conflict("NO_AVAILABILITY", "Those rooms were just taken. Please search again.");
        }

        int freeHours = Rows.integer(room, "free_cancel_hours");
        Instant freeUntil = freeHours > 0 ? in.checkIn().atTime(LocalTime.of(14, 0)).toInstant(ZoneOffset.UTC).minusSeconds(freeHours * 3600L) : null;
        Instant holdUntil = Instant.now().plusSeconds(props.holdMinutes() * 60L);
        Map<String, Object> b = bookings.insert(
            new MapSqlParameterSource()
                .addValue("ref", reference()).addValue("u", userId).addValue("acc", room.get("accommodation_id")).addValue("rt", in.roomTypeId())
                .addValue("ci", in.checkIn()).addValue("co", in.checkOut()).addValue("nights", q.nights()).addValue("rooms", rooms)
                .addValue("adults", in.adults()).addValue("children", in.childrenOrDefault())
                .addValue("gn", in.guestName().trim()).addValue("ge", in.guestEmail().trim()).addValue("gp", in.guestPhone()).addValue("sr", in.specialRequests())
                .addValue("sub", q.subtotal()).addValue("tax", q.taxes()).addValue("fee", q.fees()).addValue("total", q.total())
                .addValue("policy", room.get("cancellation_policy"))
                .addValue("free", freeUntil == null ? null : java.sql.Timestamp.from(freeUntil)).addValue("hold", java.sql.Timestamp.from(holdUntil)));
        UUID bookingId = Rows.uuid(b, "id");
        for (StayQuote.Night n : q.nightly()) bookings.insertItem(bookingId, n.night(), n.rate(), rooms);
        bookings.insertEvent(bookingId, null, "PENDING_CONFIRMATION", userId, "Room held until " + holdUntil + " pending payment");
        notifications.notify(userId, "booking", "Booking received", "Your booking " + b.get("reference") + " at " + room.get("accommodation_name")
            + " is held for " + props.holdMinutes() + " minutes. Complete payment to confirm it.", Map.of("bookingId", bookingId));
        audit.record(userId, "booking.create", "booking", bookingId, Map.of("reference", b.get("reference"), "total_usd", b.get("total_usd")));
        return b;
    }

    @Transactional
    public Map<String, Object> list(UUID userId, String status) {
        expireStaleHolds();
        List<Map<String, Object>> items = bookings.listForUser(userId, status).stream().map(b -> {
            Map<String, Object> m = new LinkedHashMap<>(b);
            m.putAll(cancellationInfo(b));
            return m;
        }).toList();
        return Map.of("items", items);
    }

    @Transactional
    public Map<String, Object> detail(UUID id, AuthUser viewer) {
        expireStaleHolds();
        Map<String, Object> b = bookings.findDetail(id).orElseThrow(() -> ApiException.notFound("Booking"));
        if ("partner".equals(viewer.role())) {
            Object partnerId = b.get("partner_id");
            if (partnerId == null || !partners.isOwner(partnerId, viewer.id())) throw ApiException.notFound("Booking");
        } else if (!viewer.isStaff() && !viewer.id().equals(b.get("user_id"))) {
            throw ApiException.notFound("Booking");    // never reveal other users' bookings
        }
        Map<String, Object> out = new LinkedHashMap<>(Rows.without(b, "partner_id"));
        out.putAll(cancellationInfo(b));
        out.put("nights_detail", bookings.nights(id));
        out.put("events", bookings.events(id));
        out.put("payments", bookings.payments(id));
        return out;
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> receipt(UUID id, AuthUser viewer) {
        Map<String, Object> b = detail(id, viewer);
        Map<String, Object> paid = ((List<Map<String, Object>>) b.get("payments")).stream()
            .filter(p -> List.of("SUCCESS", "REFUNDED").contains(p.get("status"))).findFirst()
            .orElseThrow(() -> ApiException.conflict("NO_PAYMENT", "A receipt is available once a payment has succeeded."));
        int rooms = Rows.integer(b, "rooms");
        List<Map<String, Object>> lines = new ArrayList<>();
        for (Map<String, Object> n : (List<Map<String, Object>>) b.get("nights_detail")) {
            lines.add(Map.of("label", "Room night " + n.get("night"), "amountUsd", Rows.dec(n, "rate_usd").multiply(BigDecimal.valueOf(rooms))));
        }
        lines.add(Map.of("label", "Taxes", "amountUsd", b.get("taxes_usd")));
        lines.add(Map.of("label", "Service fee", "amountUsd", b.get("fees_usd")));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("receiptNumber", "RCT-" + b.get("reference"));
        out.put("issuedFor", b.get("guest_name"));
        out.put("reference", b.get("reference"));
        out.put("property", b.get("accommodation_name"));
        out.put("room", b.get("room_name"));
        out.put("checkIn", b.get("check_in"));
        out.put("checkOut", b.get("check_out"));
        out.put("nights", b.get("nights"));
        out.put("rooms", b.get("rooms"));
        out.put("lineItems", lines);
        out.put("totalUsd", b.get("total_usd"));
        out.put("paymentStatus", paid.get("status"));
        out.put("paymentReference", paid.get("provider_ref"));
        out.put("simulated", paid.get("simulated"));
        if (Boolean.TRUE.equals(paid.get("simulated"))) out.put("notice", "SIMULATED PAYMENT - no real money was transferred. This receipt is for demonstration only.");
        return out;
    }

    @Transactional
    public Map<String, Object> cancel(UUID bookingId, UUID actorId, boolean asStaff) {
        Map<String, Object> b = bookings.findForUpdate(bookingId).orElseThrow(() -> ApiException.notFound("Booking"));
        if (!asStaff && !actorId.equals(b.get("user_id"))) throw ApiException.notFound("Booking");
        BookingStatus status = BookingStatus.valueOf(Rows.str(b, "status"));
        if (!status.isCancellable()) throw ApiException.conflict("NOT_CANCELLABLE", "A booking in status " + status + " cannot be cancelled.");
        boolean free = Boolean.TRUE.equals(cancellationInfo(b).get("freeCancellation"));
        Map<String, Object> pay = payments.findSuccessful(bookingId).orElse(null);

        transition(bookingId, status, BookingStatus.CANCELLED, actorId, free ? "Cancelled within free-cancellation window" : "Cancelled after free-cancellation window");
        inventory.release(bookingId, Rows.uuid(b, "room_type_id"));
        payments.cancelPending(bookingId);

        boolean refunded = false;
        if (pay != null && free) {
            transition(bookingId, BookingStatus.CANCELLED, BookingStatus.REFUND_PENDING, actorId, "Refund initiated (simulated provider)");
            payments.markRefunded(Rows.uuid(pay, "id"));
            transition(bookingId, BookingStatus.REFUND_PENDING, BookingStatus.REFUNDED, actorId, "Refund completed (simulated; no real money moved)");
            refunded = true;
        }
        notifications.notify(Rows.uuid(b, "user_id"), "booking", "Booking cancelled", refunded
            ? "Booking " + b.get("reference") + " was cancelled and a simulated refund of $" + pay.get("amount_usd") + " was recorded."
            : "Booking " + b.get("reference") + " was cancelled." + (pay != null ? " It was outside the free-cancellation window, so no refund applies." : ""),
            Map.of("bookingId", bookingId));
        audit.record(actorId, "booking.cancel", "booking", bookingId, Map.of("refunded", refunded, "free", free));
        return Map.of("booking", bookings.findById(bookingId).orElseThrow(), "refunded", refunded);
    }

    /** Releases rooms for unpaid bookings whose hold elapsed. Runs every minute and lazily before booking reads. */
    @Scheduled(fixedDelay = 60_000, initialDelay = 30_000)
    public int expireStaleHolds() {
        List<Map<String, Object>> stale = bookings.expiredHolds(50);
        for (Map<String, Object> b : stale) {
            try {
                tx.executeWithoutResult(s -> {
                    UUID id = Rows.uuid(b, "id");
                    transition(id, BookingStatus.PENDING_CONFIRMATION, BookingStatus.EXPIRED, null, "Payment hold elapsed");
                    inventory.release(id, Rows.uuid(b, "room_type_id"));
                    payments.cancelPending(id);
                    notifications.notify(Rows.uuid(b, "user_id"), "booking", "Booking expired",
                        "Booking " + b.get("reference") + " expired because payment was not completed. The room was released.", Map.of("bookingId", id));
                });
            } catch (ApiException e) {
                log.debug("hold {} already handled: {}", b.get("id"), e.code());
            }
        }
        return stale.size();
    }

    /**
     * Staff or partner moves a stay forward on site (check-in, completion). `propertyIds` limits a partner to their own properties; null = unrestricted.
     */
    @Transactional
    public Map<String, Object> staffTransition(UUID bookingId, BookingStatus to, UUID actorId, String note, List<UUID> propertyIds, String actorLabel) {
        if (to != BookingStatus.CHECKED_IN && to != BookingStatus.COMPLETED && to != BookingStatus.CONFIRMED) {
            throw ApiException.unprocessable("USE_CANCEL", "Only check-in, completion or confirmation can be set here. Use cancel for cancellations.");
        }
        Map<String, Object> b = bookings.findStatusForUpdate(bookingId).orElseThrow(() -> ApiException.notFound("Booking"));
        if (propertyIds != null && !propertyIds.contains((UUID) b.get("accommodation_id"))) throw ApiException.notFound("Booking");
        transition(bookingId, BookingStatus.valueOf(Rows.str(b, "status")), to, actorId, note == null ? "Updated by " + actorLabel : note);
        String verb = to == BookingStatus.CHECKED_IN ? "checked in" : to == BookingStatus.COMPLETED ? "completed" : "confirmed";
        notifications.notify(Rows.uuid(b, "user_id"), "booking", "Booking " + verb, "Booking " + b.get("reference") + " is now " + to.name().replace('_', ' ').toLowerCase() + ".",
            Map.of("bookingId", bookingId));
        audit.record(actorId, "booking.transition", "booking", bookingId, Map.of("to", to.name(), "by", actorLabel));
        return Map.of("id", bookingId, "status", to);
    }

    /** Hook for payment confirmation: clears the hold once paid. */
    public void clearHold(UUID bookingId) { bookings.clearHold(bookingId); }
}

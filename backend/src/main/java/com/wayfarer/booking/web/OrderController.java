package com.wayfarer.booking.web;

import com.wayfarer.booking.domain.BookingStatus;
import com.wayfarer.booking.dto.BookingDtos.CreateBookingRequest;
import com.wayfarer.booking.dto.BookingDtos.StatusRequest;
import com.wayfarer.booking.service.BookingService;
import com.wayfarer.common.ApiException;
import com.wayfarer.security.AuthUser;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * The course's "orders" resource. An order is a booking: these routes use the same service and rules as /api/bookings.
 * Customers manage their own orders; staff and admin can move any order through the status lifecycle.
 */
@RestController
@RequestMapping("/api/orders")
@Tag(name = "Orders")
public class OrderController {
    private final BookingService bookings;

    public OrderController(BookingService bookings) { this.bookings = bookings; }

    @GetMapping
    public Map<String, Object> list(@RequestParam(required = false) String status) { return bookings.list(CurrentUser.require().id(), status); }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CreateBookingRequest r) { return bookings.create(CurrentUser.require().id(), r); }

    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable UUID id) { return bookings.detail(id, CurrentUser.require()); }

    /** Staff/admin: any legal transition. Customers: only CANCELLED, on their own order. Illegal moves return 409. */
    @PatchMapping("/{id}/status")
    public Map<String, Object> updateStatus(@PathVariable UUID id, @Valid @RequestBody StatusRequest r) {
        AuthUser u = CurrentUser.require();
        if (r.status() == BookingStatus.CANCELLED) {
            bookings.cancel(id, u.id(), u.isStaff());
        } else if (u.isStaff()) {
            bookings.staffTransition(id, r.status(), u.id(), r.note(), null, "staff");
        } else {
            throw ApiException.forbidden("FORBIDDEN", "Only staff can set this status. You can cancel your own order.");
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("id", id);
        out.put("status", r.status());
        return out;
    }

    /** Cancels the order (frees the rooms, refunds when inside the free-cancellation window). The record is kept for audit. */
    @DeleteMapping("/{id}")
    public Map<String, Object> delete(@PathVariable UUID id) {
        AuthUser u = CurrentUser.require();
        return bookings.cancel(id, u.id(), u.isStaff());
    }
}

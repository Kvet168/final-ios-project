package com.wayfarer.booking.web;

import com.wayfarer.booking.dto.BookingDtos.CreateBookingRequest;
import com.wayfarer.booking.dto.BookingDtos.QuoteRequest;
import com.wayfarer.booking.service.BookingService;
import com.wayfarer.payment.service.PaymentService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/bookings")
@Tag(name = "Bookings")
public class BookingController {
    private final BookingService bookings;
    private final PaymentService payments;

    public BookingController(BookingService bookings, PaymentService payments) {
        this.bookings = bookings;
        this.payments = payments;
    }

    @PostMapping("/quote")
    public Map<String, Object> quote(@Valid @RequestBody QuoteRequest r) { return bookings.quote(r); }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CreateBookingRequest r) { return bookings.create(CurrentUser.require().id(), r); }

    @GetMapping
    public Map<String, Object> list(@RequestParam(required = false) String status) { return bookings.list(CurrentUser.require().id(), status); }

    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable UUID id) { return bookings.detail(id, CurrentUser.require()); }

    /** The property's payment QR code, account details and the exact amount, when the property accepts QR payments. */
    @GetMapping("/{id}/pay-qr")
    public Map<String, Object> payQr(@PathVariable UUID id) { return payments.qrInfo(CurrentUser.require().id(), id); }

    @PostMapping("/{id}/cancel")
    public Map<String, Object> cancel(@PathVariable UUID id) { return bookings.cancel(id, CurrentUser.require().id(), false); }

    @GetMapping("/{id}/receipt")
    public Map<String, Object> receipt(@PathVariable UUID id) { return bookings.receipt(id, CurrentUser.require()); }
}

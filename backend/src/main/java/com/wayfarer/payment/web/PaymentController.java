package com.wayfarer.payment.web;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.common.ApiException;
import com.wayfarer.config.AppProperties;
import com.wayfarer.payment.dto.PaymentDtos.ClaimRequest;
import com.wayfarer.payment.dto.PaymentDtos.IntentRequest;
import com.wayfarer.payment.dto.PaymentDtos.SimulateRequest;
import com.wayfarer.payment.dto.PaymentDtos.WebhookEvent;
import com.wayfarer.payment.service.PaymentService;
import com.wayfarer.payment.service.WebhookSigner;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
@Tag(name = "Payments")
public class PaymentController {
    private final PaymentService payments;
    private final AppProperties props;
    private final ObjectMapper json;

    public PaymentController(PaymentService payments, AppProperties props, ObjectMapper json) {
        this.payments = payments;
        this.props = props;
        this.json = json.copy().configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
    }

    @PostMapping("/intent")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> intent(@Valid @RequestBody IntentRequest r) {
        Map<String, Object> p = new LinkedHashMap<>(payments.createIntent(CurrentUser.require().id(), r.bookingId(), r.idempotencyKey(), r.methodOrDefault()));
        if ("qr".equals(p.get("method"))) p.put("notice", "Pay by scanning the property's QR code (see GET /api/bookings/{id}/pay-qr), then call POST /api/payments/{id}/claim.");
        return p;
    }

    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable UUID id) { return payments.get(CurrentUser.require().id(), id); }

    /** Guest reports a QR payment as done; the property then confirms or rejects it. */
    @PostMapping("/{id}/claim")
    public Map<String, Object> claim(@PathVariable UUID id, @RequestBody(required = false) @Valid ClaimRequest r) {
        return payments.claim(CurrentUser.require().id(), id, r == null ? null : r.note());
    }

    @PostMapping("/{id}/simulate")
    public Map<String, Object> simulate(@PathVariable UUID id, @Valid @RequestBody SimulateRequest r) {
        return payments.simulate(CurrentUser.require().id(), id, r.outcome());
    }

    /** Provider webhook: authenticated by HMAC signature over the raw body, never by user session. */
    @PostMapping("/webhook")
    @SecurityRequirements
    public Map<String, Object> webhook(@RequestBody byte[] raw, @RequestHeader(value = "X-Wayfarer-Signature", required = false) String signature) throws IOException {
        if (!WebhookSigner.verify(props.payment().webhookSecret(), raw, signature)) {
            throw ApiException.unauthorized("INVALID_SIGNATURE", "Webhook signature verification failed");
        }
        WebhookEvent ev = json.readValue(raw, WebhookEvent.class);
        if (ev.id() == null || ev.payment_ref() == null || ev.type() == null) throw ApiException.unprocessable("VALIDATION_ERROR", "id, type and payment_ref are required");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("received", true);
        out.putAll(payments.applyWebhookEvent(ev));
        return out;
    }
}

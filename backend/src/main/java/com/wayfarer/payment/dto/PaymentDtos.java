package com.wayfarer.payment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

public final class PaymentDtos {
    private PaymentDtos() {}

    public record IntentRequest(@NotNull UUID bookingId, @NotBlank @Size(min = 8, max = 100) String idempotencyKey,
                                @Pattern(regexp = "card|qr", message = "must be card or qr") String method) {
        public String methodOrDefault() { return method == null ? "card" : method; }
    }

    /** Guest says they have paid by scanning the partner's QR code. */
    public record ClaimRequest(@Size(max = 200) String note) {}

    public record SimulateRequest(@NotBlank @Pattern(regexp = "success|fail|cancel", message = "must be success, fail or cancel") String outcome) {}

    /** Event delivered by the payment provider (field names follow the provider's snake_case contract). */
    public record WebhookEvent(String id, String type, String payment_ref, BigDecimal amount_usd, String reason) {}
}

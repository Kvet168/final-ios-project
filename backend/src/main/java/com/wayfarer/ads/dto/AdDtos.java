package com.wayfarer.ads.dto;

import com.wayfarer.auth.dto.AuthDtos;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class AdDtos {
    private AdDtos() {}

    public static final String CATEGORIES = "hotel|resort|restaurant|cafe|camping|tour_operator|activity|shop|other";

    /** Self-registration of an advertiser: creates the login (role business) and a pending business profile. */
    public record BusinessRegisterRequest(
        @NotBlank @Email @Size(max = 160) String email,
        @NotBlank @Pattern(regexp = AuthDtos.PASSWORD_RULE, message = AuthDtos.PASSWORD_MSG) String password,
        @NotBlank @Size(min = 2, max = 80) String ownerName,
        @NotBlank @Size(min = 2, max = 100) String businessName,
        @NotBlank @Pattern(regexp = CATEGORIES) String category,
        @Size(max = 30) String phone) {}

    public record BusinessProfileRequest(
        @NotBlank @Size(min = 2, max = 100) String name,
        @Size(max = 100) String nameKm,
        @NotBlank @Pattern(regexp = CATEGORIES) String category,
        @Size(max = 1000) String description,
        @Size(max = 1000) String descriptionKm,
        @Size(max = 30) String phone,
        @Size(max = 200) String website,
        @Size(max = 200) String address,
        UUID destinationId,
        @Size(max = 500) String logoUrl) {}

    public record CampaignRequest(
        @NotNull UUID packageId,
        @NotBlank @Size(max = 90) String titleEn,
        @Size(max = 90) String titleKm,
        @Size(max = 300) String bodyEn,
        @Size(max = 300) String bodyKm,
        @Size(max = 120) String offerEn,
        @Size(max = 120) String offerKm,
        @Size(max = 6000) String articleEn,
        @Size(max = 6000) String articleKm,
        @Size(max = 500) String imageUrl,
        @Size(max = 500) String ctaUrl,
        UUID accommodationId,
        @Size(max = 12) List<UUID> targetDestinationIds,
        @Size(max = 10) List<@Size(max = 40) String> keywords,
        @Size(max = 80) String festivalNameEn,
        @Size(max = 80) String festivalNameKm,
        @NotNull LocalDate startDate,
        @Min(1) @Max(52) int units,
        Boolean submit) {}

    public record QuoteRequest(@NotNull UUID packageId, @Min(1) @Max(52) int units, @NotNull LocalDate startDate, @Pattern(regexp = "USD|KHR") String currency) {}

    public record RenewRequest(@Min(1) @Max(52) Integer units, LocalDate startDate) {}

    public record PaymentRequest(@NotBlank @Pattern(regexp = "khqr|bank_transfer") String method, @NotBlank @Pattern(regexp = "USD|KHR") String currency) {}

    public record ClaimRequest(@NotBlank @Size(min = 4, max = 64) @Pattern(regexp = "^[A-Za-z0-9 ._/#-]+$", message = "Use only letters, digits and - . _ / #") String bankTxnRef,
                               @Size(max = 500) String proofUrl) {}

    public record TrackEvent(@NotNull UUID campaignId, @NotBlank @Pattern(regexp = "impression|click") String type) {}

    public record TrackRequest(@NotNull @Size(min = 1, max = 50) List<@jakarta.validation.Valid TrackEvent> events) {}

    public record DecisionRequest(@Size(max = 500) String note) {}

    public record ReasonRequest(@NotBlank @Size(min = 3, max = 500) String reason) {}

    public record RescheduleRequest(@NotNull LocalDate startDate) {}

    public record VerifyPaymentRequest(@NotNull @Min(0) BigDecimal receivedAmount, @Size(max = 300) String note) {}

    public record PackageRequest(
        @NotBlank @Size(max = 80) String nameEn,
        @NotBlank @Size(max = 80) String nameKm,
        @Size(max = 400) String descriptionEn,
        @Size(max = 400) String descriptionKm,
        @NotNull @Min(0) @Max(100000) BigDecimal unitPriceUsd,
        @Min(1) @Max(366) int daysPerUnit,
        @Min(1) @Max(52) int minUnits,
        @Min(1) @Max(52) int maxUnits,
        @Min(1) @Max(200) int slotCapacity,
        boolean active,
        @Min(0) @Max(1000) int sortOrder) {}

    public record NewPackageRequest(
        @NotBlank @Pattern(regexp = "^[a-z0-9_]{3,40}$") String code,
        @NotBlank @Pattern(regexp = "featured_destination|top_search|homepage_banner|sponsored_article|festival") String placement,
        @NotBlank @Pattern(regexp = "week|post|month") String unit,
        @jakarta.validation.Valid PackageRequest details) {}

    public record SettingsRequest(
        @Size(max = 500) String khqrImageUrl,
        @Size(max = 100) String accountName,
        @Size(max = 100) String bankName,
        @Size(max = 60) String accountNumber,
        @Size(max = 500) String transferInstructions,
        @Pattern(regexp = "^(1|10|50|100|500|1000)$") String khrRounding) {}
}

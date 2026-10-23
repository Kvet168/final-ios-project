package com.wayfarer.admin.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class AdminDtos {
    private AdminDtos() {}

    public record DestinationRequest(@NotBlank @Size(min = 2, max = 80) String name, @NotBlank @Size(min = 2, max = 60) String country, @Size(max = 80) String region,
                                     @NotBlank @Size(min = 10, max = 300) String shortDescription, @NotBlank @Size(min = 20, max = 4000) String longDescription,
                                     @NotNull @DecimalMin("-90") @DecimalMax("90") Double lat, @NotNull @DecimalMin("-180") @DecimalMax("180") Double lng,
                                     @NotNull @DecimalMin("0") @DecimalMax("5000") BigDecimal dailyBudgetUsd, @Size(min = 3, max = 3) String currency,
                                     String coverImage, @Size(max = 12) List<@Size(max = 30) String> tags, Boolean isInternational, Boolean isFeatured) {}

    /** Partial update: every field optional. Presence is derived from the raw body in the controller. */
    public record DestinationPatch(@Size(min = 2, max = 80) String name, @Size(min = 2, max = 60) String country, @Size(max = 80) String region,
                                   @Size(min = 10, max = 300) String shortDescription, @Size(min = 20, max = 4000) String longDescription,
                                   @DecimalMin("-90") @DecimalMax("90") Double lat, @DecimalMin("-180") @DecimalMax("180") Double lng,
                                   @DecimalMin("0") @DecimalMax("5000") BigDecimal dailyBudgetUsd, @Size(min = 3, max = 3) String currency, String coverImage,
                                   @Size(max = 12) List<@Size(max = 30) String> tags, Boolean isInternational, Boolean isFeatured) {}

    public record RoomRequest(@NotBlank @Size(min = 2, max = 80) String name, @NotBlank @Size(min = 5, max = 500) String description, @Size(max = 40) String bedType,
                              @NotNull @Min(1) @Max(8) Integer maxAdults, @Min(0) @Max(6) Integer maxChildren, @NotNull @Positive @DecimalMax("10000") BigDecimal basePriceUsd,
                              @NotNull @Min(1) @Max(500) Integer totalUnits, @Size(max = 500) String coverImage) {}

    public record AccommodationRequest(@NotNull UUID destinationId, @NotBlank @Size(min = 2, max = 100) String name,
                                       @NotBlank @Pattern(regexp = "hotel|guesthouse|resort|hostel|boutique|villa|apartment|bungalow") String type,
                                       @NotNull @Min(1) @Max(5) Integer stars, @NotBlank @Size(min = 20, max = 3000) String description,
                                       @NotBlank @Size(min = 5, max = 200) String address, @NotNull @DecimalMin("-90") @DecimalMax("90") Double lat,
                                       @NotNull @DecimalMin("-180") @DecimalMax("180") Double lng, @Min(0) @Max(720) Integer freeCancelHours, Boolean breakfastIncluded,
                                       Boolean familyFriendly, String coverImage, @NotEmpty @Size(max = 10) List<@Valid RoomRequest> rooms) {}

    /** Partial update of a property. Omitted (null) fields are left unchanged. */
    public record AccommodationPatch(@Size(min = 2, max = 100) String name, @Pattern(regexp = "hotel|guesthouse|resort|hostel|boutique|villa|apartment|bungalow") String type,
                                     @Min(1) @Max(5) Integer stars, @Size(min = 20, max = 3000) String description, @Size(min = 5, max = 200) String address,
                                     @DecimalMin("-90") @DecimalMax("90") Double lat, @DecimalMin("-180") @DecimalMax("180") Double lng,
                                     @Min(0) @Max(720) Integer freeCancelHours, Boolean breakfastIncluded, Boolean familyFriendly, String coverImage) {}

    /** Partial update of a room type. Omitted (null) fields are left unchanged. */
    public record RoomPatch(@Size(min = 2, max = 80) String name, @Size(min = 5, max = 500) String description, @Size(max = 40) String bedType,
                            @Min(1) @Max(8) Integer maxAdults, @Min(0) @Max(6) Integer maxChildren, @Positive @DecimalMax("10000") BigDecimal basePriceUsd,
                            @Min(1) @Max(500) Integer totalUnits, @Size(max = 500) String coverImage) {}

    public record InventoryRequest(@NotNull LocalDate from, @NotNull LocalDate to, @NotNull @Min(0) @Max(500) Integer units, @Positive @DecimalMax("10000") BigDecimal priceUsd) {}
}

package com.wayfarer.itinerary.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public final class ItineraryDtos {
    private ItineraryDtos() {}

    public record CreateRequest(@NotBlank @Size(min = 2) String destination, @NotNull @Min(1) @Max(14) Integer days, @Min(1) @Max(12) Integer adults,
                                @Min(0) @Max(12) Integer children, @Positive Double budgetUsd, @Size(max = 10) List<@Size(max = 30) String> interests,
                                @Pattern(regexp = "relaxed|balanced|packed") String pace, LocalDate startDate, @Size(min = 2, max = 120) String title) {}

    public record StopRef(@NotNull UUID attractionId) {}

    public record DayEdit(@NotNull @Min(1) @Max(14) Integer day, @NotNull @Size(max = 10) List<@Valid StopRef> items) {}

    /** Partial update. A field present in the JSON body (even null for startDate/budgetUsd) is applied; absent fields are left alone. */
    public record PatchRequest(@Size(min = 2, max = 120) String title, LocalDate startDate, @Min(1) @Max(12) Integer adults, @Min(0) @Max(12) Integer children,
                               Double budgetUsd, @Size(max = 14) List<@Valid DayEdit> days) {}

    public record GenerateRequest(@Min(1) @Max(14) Integer day) {}
}

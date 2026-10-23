package com.wayfarer.catalog.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record RouteEstimateRequest(@NotNull @Size(min = 2, max = 25) List<@Valid Point> points) {
    public record Point(@NotNull @DecimalMin("-90") @DecimalMax("90") Double lat, @NotNull @DecimalMin("-180") @DecimalMax("180") Double lng,
                        @Size(max = 80) String name) {}
}

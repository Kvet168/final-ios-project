package com.wayfarer.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public final class ReviewDtos {
    private ReviewDtos() {}

    public record CreateReviewRequest(@NotNull @Min(1) @Max(5) Integer rating, @NotBlank @Size(min = 3, max = 100) String title,
                                      @NotBlank @Size(min = 10, max = 2000) String body) {}

    public record ModerateRequest(@NotBlank @Pattern(regexp = "published|hidden") String status) {}
}

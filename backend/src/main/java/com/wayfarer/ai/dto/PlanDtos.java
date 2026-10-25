package com.wayfarer.ai.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Request and response shapes of the trip planner. Response field names are camelCase and part of the public API. */
public final class PlanDtos {
    private PlanDtos() {}

    /** What the traveller wants. Nulls are allowed while information is still missing; defaults are applied by {@link #normalized()}. */
    public record PlanRequest(String destination, @Min(1) @Max(14) Integer days, @Min(1) @Max(12) Integer adults, @Min(0) @Max(12) Integer children,
                              @Positive Double budgetUsd, Boolean budgetIsPerDay, @Size(max = 10) List<@Size(max = 30) String> interests,
                              @Pattern(regexp = "relaxed|balanced|packed") String pace) {
        public PlanRequest normalized() {
            return new PlanRequest(destination, days, adults == null ? 1 : adults, children == null ? 0 : children, budgetUsd,
                budgetIsPerDay != null && budgetIsPerDay, interests == null ? List.of() : interests, pace == null ? "balanced" : pace);
        }

        public PlanRequest withDestination(String d) { return new PlanRequest(d, days, adults, children, budgetUsd, budgetIsPerDay, interests, pace); }

        /** Values from `over` win where they are present. */
        public PlanRequest mergedWith(PlanRequest over) {
            return new PlanRequest(over.destination != null ? over.destination : destination, over.days != null ? over.days : days,
                over.adults != null ? over.adults : adults, over.children != null ? over.children : children,
                over.budgetUsd != null ? over.budgetUsd : budgetUsd, over.budgetIsPerDay != null ? over.budgetIsPerDay : budgetIsPerDay,
                over.interests != null ? over.interests : interests, over.pace != null ? over.pace : pace);
        }
    }

    public record TravelPlanRequest(@Size(min = 5, max = 800) String prompt, @Valid PlanRequest structured, Boolean save, LocalDate startDate) {
        public boolean shouldSave() { return Boolean.TRUE.equals(save); }
    }

    public record PlannedItem(UUID attractionId, String name, String kind, String category, double lat, double lng, String image, int startMin, int durationMin,
                              int travelMinFromPrev, double costUsd, String reason, boolean isDemo, boolean hoursVerified) {}

    public record PlannedDay(int day, List<PlannedItem> items, double costUsd) {}

    public record Lodging(UUID id, String name, double nightlyUsd, int nights, double totalUsd, boolean breakfastIncluded, boolean isDemo) {}

    public record PlanDestination(UUID id, String slug, String name, double lat, double lng) {}

    public record PlanBudget(double lodgingUsd, double activitiesUsd, double foodUsd, double transportUsd, double totalUsd, Double budgetUsd,
                             Boolean withinBudget, List<Double> perDayUsd) {}

    public record Plan(String title, String summary, PlanDestination destination, List<PlannedDay> days, Lodging lodging, PlanBudget budget,
                       List<String> assumptions, List<String> warnings, String mode, String modeNote) {
        public Plan withSummary(String newSummary, String newMode, String newNote) {
            return new Plan(title, newSummary, destination, days, lodging, budget, assumptions, warnings, newMode, newNote);
        }
    }

    /** One earlier chat message ({@code role} is "user" or "assistant"), sent so follow-up questions keep their context. */
    public record ChatTurn(@Size(max = 12) String role, @Size(max = 1500) String text) {}

    public record AssistantRequest(@jakarta.validation.constraints.NotBlank @Size(min = 3, max = 500) String question, @Size(max = 60) String destination,
                                   @Size(max = 10) List<@Valid ChatTurn> history) {}

    public record RecommendationRequest(@jakarta.validation.constraints.NotBlank @Size(min = 2) String destination, @Size(max = 8) List<@Size(max = 30) String> interests,
                                        @Positive Double budgetPerNightUsd, @Min(0) @Max(10) Integer children) {}
}

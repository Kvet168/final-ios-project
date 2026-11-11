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

    /**
     * What the traveller wants. Nulls are allowed while information is still missing; defaults are applied by {@link #normalized()}.
     * A trip through several cities lists the first in {@code destination} and the rest, in visiting order, in {@code alsoVisit};
     * {@code daysPerDestination} (optional, same order, summing to {@code days}) fixes how many days each city gets.
     */
    public record PlanRequest(String destination, @Min(1) @Max(14) Integer days, @Min(1) @Max(12) Integer adults, @Min(0) @Max(12) Integer children,
                              @Positive Double budgetUsd, Boolean budgetIsPerDay, @Size(max = 10) List<@Size(max = 30) String> interests,
                              @Pattern(regexp = "relaxed|balanced|packed") String pace, @Size(max = 3) List<@Size(max = 60) String> alsoVisit,
                              @Size(max = 4) List<@Min(1) @Max(14) Integer> daysPerDestination) {
        public static final int MAX_DESTINATIONS = 4;

        /** The single-city shape (no extra cities). */
        public PlanRequest(String destination, Integer days, Integer adults, Integer children, Double budgetUsd, Boolean budgetIsPerDay, List<String> interests, String pace) {
            this(destination, days, adults, children, budgetUsd, budgetIsPerDay, interests, pace, List.of(), null);
        }

        public PlanRequest normalized() {
            return new PlanRequest(destination, days, adults == null ? 1 : adults, children == null ? 0 : children, budgetUsd,
                budgetIsPerDay != null && budgetIsPerDay, interests == null ? List.of() : interests, pace == null ? "balanced" : pace,
                alsoVisit == null ? List.of() : alsoVisit, daysPerDestination);
        }

        public PlanRequest withDestination(String d) { return new PlanRequest(d, days, adults, children, budgetUsd, budgetIsPerDay, interests, pace, alsoVisit, daysPerDestination); }

        /** Every city in visiting order, without blanks or repeats. */
        public List<String> allDestinations() {
            java.util.LinkedHashSet<String> all = new java.util.LinkedHashSet<>();
            if (destination != null && !destination.isBlank()) all.add(destination);
            if (alsoVisit != null) alsoVisit.stream().filter(x -> x != null && !x.isBlank()).forEach(all::add);
            return List.copyOf(all);
        }

        /** The same request for the given cities (first becomes {@code destination}) and optional per-city days. */
        public PlanRequest withDestinations(List<String> cities, List<Integer> perCityDays) {
            return new PlanRequest(cities.isEmpty() ? null : cities.get(0), days, adults, children, budgetUsd, budgetIsPerDay, interests, pace,
                cities.size() > 1 ? List.copyOf(cities.subList(1, cities.size())) : List.of(), perCityDays);
        }

        /** Values from `over` win where they are present. */
        public PlanRequest mergedWith(PlanRequest over) {
            boolean overCities = over.destination != null;
            return new PlanRequest(overCities ? over.destination : destination, over.days != null ? over.days : days,
                over.adults != null ? over.adults : adults, over.children != null ? over.children : children,
                over.budgetUsd != null ? over.budgetUsd : budgetUsd, over.budgetIsPerDay != null ? over.budgetIsPerDay : budgetIsPerDay,
                over.interests != null ? over.interests : interests, over.pace != null ? over.pace : pace,
                overCities ? over.alsoVisit : alsoVisit, overCities ? over.daysPerDestination : daysPerDestination);
        }
    }

    public record TravelPlanRequest(@Size(min = 5, max = 800) String prompt, @Valid PlanRequest structured, Boolean save, LocalDate startDate) {
        public boolean shouldSave() { return Boolean.TRUE.equals(save); }
    }

    public record PlannedItem(UUID attractionId, String name, String kind, String category, double lat, double lng, String image, int startMin, int durationMin,
                              int travelMinFromPrev, double costUsd, String reason, boolean isDemo, boolean hoursVerified) {}

    public record PlanDestination(UUID id, String slug, String name, double lat, double lng) {}

    /** Getting from the previous city to this day's city (an estimate: straight-line distance, a road detour factor and an intercity speed). */
    public record Transfer(String fromName, double km, int minutes, double costUsd) {}

    /** One day. {@code destination} and {@code transfer} are set on trips through several cities ({@code transfer} on the first day in a new city). */
    public record PlannedDay(int day, List<PlannedItem> items, double costUsd, PlanDestination destination, Transfer transfer) {
        public PlannedDay(int day, List<PlannedItem> items, double costUsd) { this(day, items, costUsd, null, null); }

        public PlannedDay in(PlanDestination d, Transfer t) { return new PlannedDay(day, items, costUsd, d, t); }
    }

    /** The stay chosen for one city ({@code destination} is the city's slug). */
    public record Lodging(UUID id, String name, double nightlyUsd, int nights, double totalUsd, boolean breakfastIncluded, boolean isDemo, String destination) {}

    public record PlanBudget(double lodgingUsd, double activitiesUsd, double foodUsd, double transportUsd, double totalUsd, Double budgetUsd,
                             Boolean withinBudget, List<Double> perDayUsd) {}

    /** {@code destination} and {@code lodging} are the first city's; {@code destinations} and {@code lodgings} list every city in order. */
    public record Plan(String title, String summary, PlanDestination destination, List<PlannedDay> days, Lodging lodging, PlanBudget budget,
                       List<String> assumptions, List<String> warnings, String mode, String modeNote, List<PlanDestination> destinations, List<Lodging> lodgings) {
        public Plan withSummary(String newSummary, String newMode, String newNote) {
            return new Plan(title, newSummary, destination, days, lodging, budget, assumptions, warnings, newMode, newNote, destinations, lodgings);
        }
    }

    /** One earlier chat message ({@code role} is "user" or "assistant"), sent so follow-up questions keep their context. */
    public record ChatTurn(@Size(max = 12) String role, @Size(max = 1500) String text) {}

    public record AssistantRequest(@jakarta.validation.constraints.NotBlank @Size(min = 1, max = 500) String question, @Size(max = 60) String destination,
                                   @Size(max = 10) List<@Valid ChatTurn> history) {}

    public record RecommendationRequest(@jakarta.validation.constraints.NotBlank @Size(min = 2) String destination, @Size(max = 8) List<@Size(max = 30) String> interests,
                                        @Positive Double budgetPerNightUsd, @Min(0) @Max(10) Integer children) {}
}

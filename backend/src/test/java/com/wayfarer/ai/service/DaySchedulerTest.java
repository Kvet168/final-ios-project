package com.wayfarer.ai.service;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** The scheduler is pure logic, so its guarantees are checked on an in-memory pool (no database). */
class DaySchedulerTest {
    private static Place place(String name, String kind, String category, double lat, double lng, Double price, Integer opens, Integer closes, boolean family, int minutes) {
        return new Place(UUID.randomUUID(), name.toLowerCase().replace(' ', '-'), name, kind, category, lat, lng, null, price, minutes, opens, closes, true, List.of(), family, false);
    }

    private static List<Place> pool() {
        List<Place> p = new ArrayList<>();
        for (int i = 0; i < 8; i++) p.add(place("Temple " + i, "attraction", "temple", 11.55 + i * 0.002, 104.92, i % 2 == 0 ? 0.0 : 10.0, 7 * 60, 17 * 60, true, 90));
        p.add(place("Night Market", "attraction", "market", 11.56, 104.93, 0.0, 17 * 60, 23 * 60, true, 90));
        p.add(place("Museum", "attraction", "museum", 11.57, 104.93, 10.0, 8 * 60, 17 * 60, false, 120));
        for (int i = 0; i < 6; i++) p.add(place("Cafe " + i, "restaurant", "food", 11.55 + i * 0.002, 104.93, 8.0, 7 * 60, 22 * 60, true, 60));
        return p;
    }

    private static PlanRequest req(String pace, int children, List<String> interests) {
        return new PlanRequest("x", 3, 2, children, null, false, interests, pace).normalized();
    }

    @Test
    void days_never_repeat_a_place_and_stops_are_ordered_and_do_not_overlap() {
        Set<UUID> used = new HashSet<>();
        PlanRequest r = req("balanced", 0, List.of("temples"));
        for (int d = 1; d <= 3; d++) {
            PlannedDay day = DayScheduler.buildDay(d, pool(), used, r, null, DayScheduler.slot("balanced"));
            int end = 0;
            for (PlannedItem i : day.items()) {
                assertTrue(i.startMin() >= end, "stop starts before the previous one ends");
                end = i.startMin() + i.durationMin();
            }
        }
        long total = used.size();
        assertEquals(total, new HashSet<>(used).size());
    }

    @Test
    void opening_hours_are_respected() {
        Set<UUID> u2 = new HashSet<>();
        List<Place> pool = pool();
        for (int d = 1; d <= 3; d++) {
            for (PlannedItem i : DayScheduler.buildDay(d, pool, u2, req("packed", 0, List.of()), null, DayScheduler.slot("packed")).items()) {
                Place p = pool.stream().filter(x -> x.id().equals(i.attractionId())).findFirst().orElseThrow();
                assertTrue(DayScheduler.fitsHours(p, i.startMin()), p.name() + " scheduled outside opening hours at " + DayScheduler.fmtTime(i.startMin()));
            }
        }
    }

    @Test
    void pace_controls_how_many_stops_a_day_has() {
        List<Place> pool = pool();
        int relaxed = DayScheduler.buildDay(1, pool, new HashSet<>(), req("relaxed", 0, List.of()), null, DayScheduler.slot("relaxed")).items().size();
        int packed = DayScheduler.buildDay(1, pool, new HashSet<>(), req("packed", 0, List.of()), null, DayScheduler.slot("packed")).items().size();
        assertTrue(packed > relaxed, "packed=" + packed + " relaxed=" + relaxed);
    }

    @Test
    void a_balanced_day_has_sights_and_a_lunch_restaurant() {
        PlannedDay day = DayScheduler.buildDay(1, pool(), new HashSet<>(), req("balanced", 0, List.of()), null, DayScheduler.slot("balanced"));
        assertTrue(day.items().stream().anyMatch(i -> "restaurant".equals(i.kind())));
        assertTrue(day.items().stream().anyMatch(i -> !"restaurant".equals(i.kind())));
    }

    @Test
    void interests_pull_matching_places_to_the_top() {
        PlannedDay day = DayScheduler.buildDay(1, pool(), new HashSet<>(), req("relaxed", 0, List.of("markets", "museum")), null, DayScheduler.slot("relaxed"));
        assertTrue(day.items().stream().anyMatch(i -> "Museum".equals(i.name()) || "Night Market".equals(i.name())));
    }

    @Test
    void day_cost_is_the_sum_of_its_stops_and_children_pay_half_for_activities() {
        Place paid = place("Paid", "attraction", "museum", 11.5, 104.9, 10.0, null, null, true, 60);
        assertEquals(20.0, DayScheduler.costFor(paid, 2, 0));
        assertEquals(25.0, DayScheduler.costFor(paid, 2, 1));
        Place meal = place("Meal", "restaurant", "food", 11.5, 104.9, 10.0, null, null, true, 60);
        assertEquals(26.0, DayScheduler.costFor(meal, 2, 1));     // children at 60% for meals
        PlannedDay day = DayScheduler.buildDay(1, pool(), new HashSet<>(), req("balanced", 0, List.of()), null, DayScheduler.slot("balanced"));
        assertEquals(Math.round(day.items().stream().mapToDouble(PlannedItem::costUsd).sum() * 100) / 100.0, day.costUsd(), 0.011);
    }

    @Test
    void nearby_stops_are_preferred_so_travel_time_stays_short() {
        List<Place> pool = new ArrayList<>(pool());
        pool.add(place("Far Temple", "attraction", "temple", 12.5, 105.9, 0.0, null, null, true, 90));
        PlannedDay day = DayScheduler.buildDay(1, pool, new HashSet<>(), req("balanced", 0, List.of("temples")), new DayScheduler.Anchor(11.55, 104.92), DayScheduler.slot("balanced"));
        assertTrue(day.items().stream().noneMatch(i -> "Far Temple".equals(i.name())));
    }
}

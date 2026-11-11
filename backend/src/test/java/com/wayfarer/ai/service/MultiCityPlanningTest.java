package com.wayfarer.ai.service;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.wayfarer.ai.dto.PlanDtos.Transfer;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class MultiCityPlanningTest {
    @Test
    void days_are_split_evenly_with_the_extra_days_going_to_the_first_cities() {
        assertArrayEquals(new int[] {3, 2}, PlannerService.allocateDays(5, 2, null));
        assertArrayEquals(new int[] {2, 2, 1}, PlannerService.allocateDays(5, 3, null));
        assertArrayEquals(new int[] {7}, PlannerService.allocateDays(7, 1, null));
        assertArrayEquals(new int[] {1, 1, 1, 1}, PlannerService.allocateDays(4, 4, null));
    }

    @Test
    void a_requested_split_is_used_only_when_it_adds_up() {
        assertArrayEquals(new int[] {1, 4}, PlannerService.allocateDays(5, 2, List.of(1, 4)));
        assertArrayEquals(new int[] {3, 2}, PlannerService.allocateDays(5, 2, List.of(1, 3)), "wrong total: even split instead");
        assertArrayEquals(new int[] {3, 2}, PlannerService.allocateDays(5, 2, List.of(5)), "wrong length: even split instead");
    }

    @Test
    void transfer_estimate_uses_road_distance_speed_and_a_fare_per_traveller() {
        // Kampot to Siem Reap, roughly 300 km apart in a straight line.
        Map<String, Object> kampot = Map.of("name", "Kampot", "lat", 10.6104, "lng", 104.1815);
        Map<String, Object> siemReap = Map.of("name", "Siem Reap", "lat", 13.3633, "lng", 103.8564);
        Transfer one = PlannerService.transfer(kampot, siemReap, 1, 0);
        assertEquals("Kampot", one.fromName());
        assertTrue(one.km() > 380 && one.km() < 450, "road km " + one.km());
        assertTrue(one.minutes() > 7 * 60 && one.minutes() < 10 * 60, "minutes " + one.minutes());
        assertEquals(PlannerService.transferCost(one.km(), 1, 0), one.costUsd(), 0.001);
        // Two adults and a child pay 2.5 fares.
        assertEquals(one.costUsd() * 2.5, PlannerService.transfer(kampot, siemReap, 2, 1).costUsd(), 0.02);
    }

    @Test
    void short_hops_still_cost_at_least_the_minimum_fare() {
        assertEquals(2.0, PlannerService.transferCost(10, 1, 0), 0.001);
    }
}

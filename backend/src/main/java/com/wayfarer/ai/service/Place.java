package com.wayfarer.ai.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/** An attraction, restaurant or activity as the planner sees it. */
public record Place(UUID id, String slug, String name, String kind, String category, double lat, double lng, String image, Double priceUsd, int durationMin,
                    Integer opensMin, Integer closesMin, boolean hoursVerified, List<String> tags, boolean familyFriendly, boolean isDemo) {

    @SuppressWarnings("unchecked")
    public static Place from(Map<String, Object> r) {
        return new Place((UUID) r.get("id"), (String) r.get("slug"), (String) r.get("name"), (String) r.get("kind"), (String) r.get("category"),
            ((Number) r.get("lat")).doubleValue(), ((Number) r.get("lng")).doubleValue(), (String) r.get("image"),
            r.get("price_usd") == null ? null : ((Number) r.get("price_usd")).doubleValue(), ((Number) r.get("duration_min")).intValue(),
            r.get("opens_min") == null ? null : ((Number) r.get("opens_min")).intValue(), r.get("closes_min") == null ? null : ((Number) r.get("closes_min")).intValue(),
            Boolean.TRUE.equals(r.get("hours_verified")), r.get("tags") == null ? List.of() : (List<String>) r.get("tags"),
            Boolean.TRUE.equals(r.get("family_friendly")), Boolean.TRUE.equals(r.get("is_demo")));
    }

    public boolean isRestaurant() { return "restaurant".equals(kind); }
}

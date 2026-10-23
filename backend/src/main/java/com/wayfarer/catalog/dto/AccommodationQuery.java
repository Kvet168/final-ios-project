package com.wayfarer.catalog.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;

/** Query parameters for accommodation search; bound from the query string. Defaults and bounds are applied in the constructor. */
public record AccommodationQuery(String destination, String q,
                                 @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
                                 @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
                                 Integer adults, Integer children, Integer rooms, BigDecimal minPrice, BigDecimal maxPrice,
                                 String stars, Double minRating, String amenities, String type,
                                 Boolean freeCancellation, Boolean breakfast, Boolean familyFriendly,
                                 Double lat, Double lng, Double maxDistanceKm, String sort, Integer page, Integer pageSize) {
    public AccommodationQuery {
        adults = clamp(adults, 2, 1, 20);
        children = clamp(children, 0, 0, 10);
        rooms = clamp(rooms, 1, 1, 8);
        page = clamp(page, 1, 1, 100_000);
        pageSize = clamp(pageSize, 12, 1, 50);
        sort = sort == null ? "relevance" : sort;
    }

    /** Same query scoped to one destination (used by /destinations/{id}/accommodations). */
    public AccommodationQuery withDestination(String destinationId) {
        return new AccommodationQuery(destinationId, q, checkIn, checkOut, adults, children, rooms, minPrice, maxPrice, stars, minRating, amenities, type,
            freeCancellation, breakfast, familyFriendly, lat, lng, maxDistanceKm, sort, page, pageSize);
    }

    public boolean hasDates() { return checkIn != null && checkOut != null; }

    private static int clamp(Integer v, int def, int min, int max) { return v == null ? def : Math.max(min, Math.min(max, v)); }
}

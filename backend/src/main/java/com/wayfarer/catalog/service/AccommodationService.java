package com.wayfarer.catalog.service;

import com.wayfarer.booking.service.StayQuote;
import com.wayfarer.booking.service.StayQuoteService;
import com.wayfarer.catalog.dto.AccommodationQuery;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.wishlist.service.WishlistService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class AccommodationService {
    private final AccommodationRepository accommodations;
    private final StayQuoteService quotes;
    private final WishlistService history;

    public AccommodationService(AccommodationRepository accommodations, StayQuoteService quotes, WishlistService history) {
        this.accommodations = accommodations;
        this.quotes = quotes;
        this.history = history;
    }

    /** Public search; for a signed-in user the search term is also remembered. */
    public Map<String, Object> search(AccommodationQuery q, UUID userIdOrNull) {
        if (userIdOrNull != null) history.recordSearch(userIdOrNull, q.q() != null ? q.q() : q.destination());
        return search(q);
    }

    public Map<String, Object> search(AccommodationQuery q) {
        int nights = 0;
        if (q.hasDates()) nights = StayQuoteService.validateDates(q.checkIn(), q.checkOut());
        else if (q.checkIn() != null || q.checkOut() != null) throw ApiException.unprocessable("INVALID_DATES", "Provide both checkIn and checkOut");

        final int n = nights;
        List<Map<String, Object>> shaped = accommodations.search(q, nights).stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>(r);
            Object dk = r.get("distance_km");
            m.put("distance_km", dk == null ? null : Math.round(((Number) dk).doubleValue() * 10) / 10.0);
            m.put("total_for_stay_usd", q.hasDates() ? Rows.round2(Rows.dec(r, "price_from").multiply(BigDecimal.valueOf((long) n * q.rooms()))) : null);
            return m;
        }).toList();
        Map<String, Object> out = Pages.of(shaped, q.page(), q.pageSize());
        out.put("nights", q.hasDates() ? nights : null);
        return out;
    }

    public Map<String, Object> detail(String idOrSlug, LocalDate checkIn, LocalDate checkOut, int rooms) {
        Map<String, Object> a = accommodations.findByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Accommodation"));
        UUID id = Rows.uuid(a, "id");
        List<Map<String, Object>> roomsWithQuotes = new ArrayList<>();
        for (Map<String, Object> r : accommodations.roomTypes(id)) {
            Map<String, Object> m = new LinkedHashMap<>(r);
            m.put("quote", checkIn != null && checkOut != null ? quotes.quote(Rows.uuid(r, "id"), checkIn, checkOut, rooms, false).toMap() : null);
            roomsWithQuotes.add(m);
        }
        Map<String, Object> out = new LinkedHashMap<>(a);
        out.put("images", accommodations.images(id));
        out.put("amenities", accommodations.amenities(id));
        out.put("room_types", roomsWithQuotes);
        out.put("related", accommodations.related(Rows.uuid(a, "destination_id"), id, a.get("from_price_usd")));
        out.put("rating_breakdown", accommodations.ratingBreakdown(id));
        if (Boolean.TRUE.equals(a.get("is_demo"))) out.put("data_notice", "Educational demo listing: details, prices and reviews are sample data.");
        return out;
    }

    public Map<String, Object> availability(String idOrSlug, LocalDate checkIn, LocalDate checkOut, int rooms) {
        Map<String, Object> a = accommodations.findLightByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Accommodation"));
        List<Map<String, Object>> results = new ArrayList<>();
        for (Map<String, Object> r : accommodations.roomTypeNames(Rows.uuid(a, "id"))) {
            StayQuote q = quotes.quote(Rows.uuid(r, "id"), checkIn, checkOut, rooms, false);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("roomTypeId", r.get("id"));
            m.put("name", r.get("name"));
            m.putAll(q.toMap());
            m.put("average_nightly_usd", q.nightly().isEmpty() ? null
                : q.subtotal().divide(BigDecimal.valueOf((long) rooms * q.nightly().size()), 2, RoundingMode.HALF_UP));
            results.add(m);
        }
        return Map.of("checkIn", checkIn, "checkOut", checkOut, "rooms", rooms, "results", results, "nights", ChronoUnit.DAYS.between(checkIn, checkOut));
    }

    public Map<String, Object> roomType(UUID id, LocalDate checkIn, LocalDate checkOut, int rooms) {
        Map<String, Object> r = quotes.findRoomWithAccommodation(id).orElseThrow(() -> ApiException.notFound("Room type"));
        Map<String, Object> out = new LinkedHashMap<>(r);
        out.put("quote", checkIn != null && checkOut != null ? quotes.quote(id, checkIn, checkOut, rooms, false).toMap() : null);
        return out;
    }
}

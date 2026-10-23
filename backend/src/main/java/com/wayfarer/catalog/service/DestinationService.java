package com.wayfarer.catalog.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.wayfarer.catalog.dto.AccommodationQuery;
import com.wayfarer.catalog.dto.PlaceQuery;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Geo;
import com.wayfarer.common.JsonCache;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class DestinationService {
    public static final String CACHE_PREFIX = "cat:dest:";
    private static final TypeReference<Map<String, Object>> MAP = new TypeReference<>() {};

    private final DestinationRepository destinations;
    private final AttractionRepository attractions;
    private final AccommodationRepository accommodations;
    private final AccommodationService accommodationService;
    private final JsonCache cache;

    public DestinationService(DestinationRepository destinations, AttractionRepository attractions, AccommodationRepository accommodations,
                              AccommodationService accommodationService, JsonCache cache) {
        this.destinations = destinations;
        this.attractions = attractions;
        this.accommodations = accommodations;
        this.accommodationService = accommodationService;
        this.cache = cache;
    }

    public Map<String, Object> list(String q, String country, String tag, Boolean international, Boolean featured, String sort, int page, int pageSize) {
        int p = Pages.clampPage(page), size = Pages.clampSize(pageSize, 50);
        String order = switch (sort == null ? "popularity" : sort) {
            case "name" -> "name";
            case "budget_asc" -> "daily_budget_usd";
            case "budget_desc" -> "daily_budget_usd DESC";
            case "popularity" -> "popularity DESC";
            default -> throw ApiException.unprocessable("VALIDATION_ERROR", "Unknown sort: " + sort);
        };
        String key = CACHE_PREFIX + "list:" + Objects.hash(q, country, tag, international, featured, order, p, size);
        return cache.get(key, MAP, () -> Pages.of(destinations.search(q, country, tag, international, featured, order, size, Pages.offset(p, size)), p, size));
    }

    public Map<String, Object> detail(String idOrSlug) {
        return cache.get(CACHE_PREFIX + "detail:" + idOrSlug, MAP, () -> {
            Map<String, Object> d = destinations.findByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Destination"));
            UUID id = Rows.uuid(d, "id");
            double lat = ((Number) d.get("lat")).doubleValue(), lng = ((Number) d.get("lng")).doubleValue();
            List<Map<String, Object>> related = destinations.related(id).stream().map(r -> Rows.with(r, "distance_km",
                Math.round(Geo.haversineKm(lat, lng, ((Number) r.get("lat")).doubleValue(), ((Number) r.get("lng")).doubleValue())))).toList();
            Map<String, Object> out = new LinkedHashMap<>(d);
            out.put("images", destinations.images(id));
            out.put("related", related);
            out.put("top_attractions", attractions.topForDestination(id, 6));
            out.put("top_accommodations", accommodations.topForDestination(id, 4));
            out.put("guides", destinations.guides(id));
            out.put("estimated_daily_budget_note", "Indicative mid-range daily budget in USD, excluding international travel.");
            return out;
        });
    }

    public Map<String, Object> attractions(String idOrSlug, PlaceQuery q) {
        Map<String, Object> d = destinations.findByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Destination"));
        return Pages.of(attractions.search(q, Rows.uuid(d, "id")), q.page(), q.pageSize());
    }

    public Map<String, Object> accommodations(String idOrSlug, AccommodationQuery q) {
        Map<String, Object> d = destinations.findByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Destination"));
        return accommodationService.search(q.withDestination(Rows.str(d, "id")));
    }

    public void evictCache() { cache.evictPrefix(CACHE_PREFIX); }
}

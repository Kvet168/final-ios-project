package com.wayfarer.catalog.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.wayfarer.catalog.dto.RouteEstimateRequest;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.catalog.repository.ReferenceDataRepository;
import com.wayfarer.common.Geo;
import com.wayfarer.common.JsonCache;
import com.wayfarer.common.Text;
import com.wayfarer.itinerary.repository.ItineraryRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

/** Read models for the home feed, lookup data, the internal gazetteer and the straight-line route estimate. */
@Service
public class DiscoveryService {
    private static final TypeReference<Map<String, Object>> MAP = new TypeReference<>() {};

    private final DestinationRepository destinations;
    private final AccommodationRepository accommodations;
    private final AttractionRepository attractions;
    private final ReferenceDataRepository reference;
    private final ItineraryRepository itineraries;
    private final JsonCache cache;

    public DiscoveryService(DestinationRepository destinations, AccommodationRepository accommodations, AttractionRepository attractions,
                            ReferenceDataRepository reference, ItineraryRepository itineraries, JsonCache cache) {
        this.destinations = destinations;
        this.accommodations = accommodations;
        this.attractions = attractions;
        this.reference = reference;
        this.itineraries = itineraries;
        this.cache = cache;
    }

    public Map<String, Object> meta() {
        return cache.get(DestinationService.CACHE_PREFIX + "meta", MAP, () -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("currencies", reference.currencies());
            m.put("amenities", reference.amenities());
            m.put("destinations", destinations.listAllSlugs());
            m.put("notice", "Exchange rates are documented sample rates, not live market rates.");
            return m;
        });
    }

    public Map<String, Object> home() {
        return cache.get(DestinationService.CACHE_PREFIX + "home", MAP, () -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("featured", destinations.featured(6));
            m.put("trending", destinations.trending(8));
            m.put("hotels", accommodations.topRated(6));
            m.put("itineraries", itineraries.templates(6));
            m.put("categories", attractions.categoryCounts());
            m.put("counts", destinations.counts());
            return m;
        });
    }

    public Map<String, Object> documents() { return Map.of("items", reference.documents()); }

    public Map<String, Object> searchLocations(String q) {
        return Map.of("source", "WAYFARER internal gazetteer (not a global geocoder)", "results", attractions.gazetteer(Text.like(q)));
    }

    public Map<String, Object> estimateRoute(RouteEstimateRequest req) {
        List<RouteEstimateRequest.Point> pts = req.points();
        List<Map<String, Object>> legs = new ArrayList<>();
        double km = 0;
        int min = 0;
        for (int i = 1; i < pts.size(); i++) {
            RouteEstimateRequest.Point a = pts.get(i - 1), b = pts.get(i);
            double straight = Geo.haversineKm(a.lat(), a.lng(), b.lat(), b.lng()), road = straight * Geo.DETOUR_FACTOR;
            int m = Geo.roadMinutes(straight);
            km += road;
            min += m;
            Map<String, Object> leg = new LinkedHashMap<>();
            leg.put("from", a.name() != null ? a.name() : "Point " + i);
            leg.put("to", b.name() != null ? b.name() : "Point " + (i + 1));
            leg.put("straightLineKm", round2(straight));
            leg.put("estimatedRoadKm", round2(road));
            leg.put("estimatedMinutes", m);
            legs.add(leg);
        }
        String path = String.join("/", pts.stream().map(p -> p.lat() + "," + p.lng()).toList());
        RouteEstimateRequest.Point first = pts.get(0), last = pts.get(pts.size() - 1);
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("method", "straight_line_estimate");
        out.put("liveTraffic", false);
        out.put("disclaimer", "Distances use great-circle distance x1.35 and an assumed 22 km/h urban speed. This is not turn-by-turn routing and ignores live traffic.");
        out.put("totalKm", round2(km));
        out.put("totalMinutes", min);
        out.put("legs", legs);
        out.put("externalNavigation", Map.of("googleMaps", "https://www.google.com/maps/dir/" + path,
            "openStreetMap", "https://www.openstreetmap.org/directions?route=" + first.lat() + "%2C" + first.lng() + "%3B" + last.lat() + "%2C" + last.lng()));
        return out;
    }

    private static double round2(double v) { return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP).doubleValue(); }
}

package com.wayfarer.ads.service;

import com.wayfarer.ads.dto.AdDtos.TrackEvent;
import com.wayfarer.ads.repository.AdRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** What travellers see. Every item is marked sponsored, so the app can label it without guessing. */
@Service
public class AdPublicService {
    private static final Set<String> PLACEMENTS = Set.of("featured_destination", "top_search", "homepage_banner", "sponsored_article", "festival");
    private static final Map<String, Integer> DEFAULT_LIMIT = Map.of("featured_destination", 6, "top_search", 2, "homepage_banner", 5, "sponsored_article", 6, "festival", 6);

    private final AdRepository ads;

    public AdPublicService(AdRepository ads) { this.ads = ads; }

    public Map<String, Object> serve(String placement, String destinationSlug, String q, Integer limit) {
        if (!PLACEMENTS.contains(placement)) throw ApiException.unprocessable("VALIDATION_ERROR", "Unknown placement");
        UUID dest = null;
        if (destinationSlug != null && !destinationSlug.isBlank()) {
            var d = ads.destinationBySlug(destinationSlug.trim());
            if (d.isEmpty()) return Map.of("items", List.of());
            dest = Rows.uuid(d.get(), "id");
        }
        // Top Search is only shown when the search has something to match; a blank search shows no paid result.
        boolean search = "top_search".equals(placement);
        if (search && (q == null || q.isBlank()) && dest == null) return Map.of("items", List.of());
        int n = Math.max(1, Math.min(10, limit == null ? DEFAULT_LIMIT.get(placement) : limit));
        List<Map<String, Object>> rows = ads.serve(placement, dest, search && dest != null && (q == null || q.isBlank()) ? null : q, n).stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>(r);
            m.put("sponsored", true);
            return m;
        }).toList();
        return Map.of("items", rows);
    }

    public Map<String, Object> article(UUID id) {
        Map<String, Object> a = ads.servedArticle(id).orElseThrow(() -> ApiException.notFound("Article"));
        Map<String, Object> m = new LinkedHashMap<>(a);
        m.put("sponsored", true);
        return m;
    }

    /** Batches of impressions and clicks from the app; counted per campaign per day. */
    @Transactional
    public void track(List<TrackEvent> events) {
        Map<UUID, int[]> sums = new HashMap<>();
        for (TrackEvent e : events) {
            int[] s = sums.computeIfAbsent(e.campaignId(), k -> new int[2]);
            s["click".equals(e.type()) ? 1 : 0]++;
        }
        sums.forEach((id, s) -> ads.track(id, s[0], s[1]));
    }
}

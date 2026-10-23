package com.wayfarer.catalog.service;

import com.wayfarer.catalog.dto.PlaceQuery;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class AttractionService {
    private final AttractionRepository attractions;

    public AttractionService(AttractionRepository attractions) { this.attractions = attractions; }

    public Map<String, Object> list(PlaceQuery q) { return Pages.of(attractions.search(q, null), q.page(), q.pageSize()); }

    public Map<String, Object> detail(String idOrSlug) {
        return attractions.findByIdOrSlug(idOrSlug).orElseThrow(() -> ApiException.notFound("Attraction"));
    }
}

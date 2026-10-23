package com.wayfarer.catalog.web;

import com.wayfarer.catalog.dto.AccommodationQuery;
import com.wayfarer.catalog.dto.PlaceQuery;
import com.wayfarer.catalog.service.DestinationService;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/destinations")
@Tag(name = "Destinations")
@SecurityRequirements
public class DestinationController {
    private final DestinationService service;

    public DestinationController(DestinationService service) { this.service = service; }

    @GetMapping
    public Map<String, Object> list(@RequestParam(required = false) String q, @RequestParam(required = false) String country,
                                    @RequestParam(required = false) String tag, @RequestParam(required = false) Boolean international,
                                    @RequestParam(required = false) Boolean featured, @RequestParam(defaultValue = "popularity") String sort,
                                    @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "12") int pageSize) {
        return service.list(q, country, tag, international, featured, sort, page, pageSize);
    }

    @GetMapping("/{idOrSlug}")
    public Map<String, Object> detail(@PathVariable String idOrSlug) { return service.detail(idOrSlug); }

    @GetMapping("/{idOrSlug}/attractions")
    public Map<String, Object> attractions(@PathVariable String idOrSlug, PlaceQuery q) { return service.attractions(idOrSlug, q); }

    @GetMapping("/{idOrSlug}/accommodations")
    public Map<String, Object> accommodations(@PathVariable String idOrSlug, AccommodationQuery q) { return service.accommodations(idOrSlug, q); }
}

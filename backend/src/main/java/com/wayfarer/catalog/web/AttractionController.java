package com.wayfarer.catalog.web;

import com.wayfarer.catalog.dto.PlaceQuery;
import com.wayfarer.catalog.service.AttractionService;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/attractions")
@Tag(name = "Attractions")
@SecurityRequirements
public class AttractionController {
    private final AttractionService service;

    public AttractionController(AttractionService service) { this.service = service; }

    @GetMapping
    public Map<String, Object> list(PlaceQuery q) { return service.list(q); }

    @GetMapping("/{idOrSlug}")
    public Map<String, Object> detail(@PathVariable String idOrSlug) { return service.detail(idOrSlug); }
}

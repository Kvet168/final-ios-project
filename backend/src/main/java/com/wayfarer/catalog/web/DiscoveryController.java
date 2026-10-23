package com.wayfarer.catalog.web;

import com.wayfarer.catalog.dto.RouteEstimateRequest;
import com.wayfarer.catalog.service.DiscoveryService;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@Validated
@Tag(name = "Discovery")
@SecurityRequirements
public class DiscoveryController {
    private final DiscoveryService service;

    public DiscoveryController(DiscoveryService service) { this.service = service; }

    @GetMapping("/meta")
    public Map<String, Object> meta() { return service.meta(); }

    @GetMapping("/home")
    public Map<String, Object> home() { return service.home(); }

    @GetMapping("/documents")
    public Map<String, Object> documents() { return service.documents(); }

    @GetMapping("/locations/search")
    public Map<String, Object> locations(@RequestParam @NotBlank @Size(min = 2, max = 60) String q) { return service.searchLocations(q); }

    @PostMapping("/routes/estimate")
    public Map<String, Object> route(@Valid @RequestBody RouteEstimateRequest req) { return service.estimateRoute(req); }
}

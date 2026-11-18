package com.wayfarer.ads.web;

import com.wayfarer.ads.dto.AdDtos.TrackRequest;
import com.wayfarer.ads.service.AdPublicService;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Public, read-only sponsored content for the traveller app plus anonymous impression/click counters. */
@RestController
@RequestMapping("/api/ads")
@Tag(name = "Advertising (public)")
@SecurityRequirements
public class AdPublicController {
    private final AdPublicService service;

    public AdPublicController(AdPublicService service) { this.service = service; }

    @GetMapping
    public Map<String, Object> serve(@RequestParam String placement, @RequestParam(required = false) String destination, @RequestParam(required = false) String q,
                                     @RequestParam(required = false) Integer limit) {
        return service.serve(placement, destination, q, limit);
    }

    @GetMapping("/{id}/article")
    public Map<String, Object> article(@PathVariable UUID id) { return service.article(id); }

    @PostMapping("/events")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void track(@Valid @RequestBody TrackRequest r) { service.track(r.events()); }
}

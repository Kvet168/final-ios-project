package com.wayfarer.catalog.web;

import com.wayfarer.catalog.dto.AccommodationQuery;
import com.wayfarer.catalog.service.AccommodationService;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
@Tag(name = "Accommodations")
@SecurityRequirements
public class AccommodationController {
    private final AccommodationService service;

    public AccommodationController(AccommodationService service) { this.service = service; }

    @GetMapping("/accommodations")
    public Map<String, Object> search(AccommodationQuery q) {
        var user = com.wayfarer.security.CurrentUser.optional();
        return service.search(q, user == null ? null : user.id());
    }

    @GetMapping("/accommodations/{idOrSlug}")
    public Map<String, Object> detail(@PathVariable String idOrSlug,
                                      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
                                      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
                                      @RequestParam(defaultValue = "1") int rooms) {
        return service.detail(idOrSlug, checkIn, checkOut, rooms);
    }

    @GetMapping("/accommodations/{idOrSlug}/availability")
    public Map<String, Object> availability(@PathVariable String idOrSlug,
                                            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
                                            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
                                            @RequestParam(defaultValue = "1") int rooms) {
        return service.availability(idOrSlug, checkIn, checkOut, rooms);
    }

    @GetMapping("/room-types/{id}")
    public Map<String, Object> roomType(@PathVariable UUID id,
                                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkIn,
                                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkOut,
                                        @RequestParam(defaultValue = "1") int rooms) {
        return service.roomType(id, checkIn, checkOut, rooms);
    }
}

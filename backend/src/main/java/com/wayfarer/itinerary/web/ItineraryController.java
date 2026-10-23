package com.wayfarer.itinerary.web;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.common.ApiException;
import com.wayfarer.itinerary.dto.ItineraryDtos.CreateRequest;
import com.wayfarer.itinerary.dto.ItineraryDtos.GenerateRequest;
import com.wayfarer.itinerary.dto.ItineraryDtos.PatchRequest;
import com.wayfarer.itinerary.service.ItineraryService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/itineraries")
@Tag(name = "Itineraries")
public class ItineraryController {
    private final ItineraryService service;
    private final ObjectMapper json;
    private final Validator validator;

    public ItineraryController(ItineraryService service, ObjectMapper json, Validator validator) {
        this.service = service;
        this.json = json;
        this.validator = validator;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CreateRequest r) { return service.create(CurrentUser.require().id(), r); }

    @GetMapping
    public Map<String, Object> list() { return service.list(CurrentUser.require().id()); }

    /** Public for curated templates; otherwise owner only. */
    @GetMapping("/{id}")
    public Map<String, Object> get(@PathVariable UUID id) { return service.get(id, CurrentUser.optional()); }

    /** The raw body is read so that an explicit null (clear the start date or budget) can be told apart from an omitted field. */
    @PatchMapping("/{id}")
    public Map<String, Object> patch(@PathVariable UUID id, @RequestBody JsonNode body) throws Exception {
        PatchRequest r = json.treeToValue(body, PatchRequest.class);
        Set<ConstraintViolation<PatchRequest>> violations = validator.validate(r);
        if (!violations.isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "VALIDATION_ERROR", "Request validation failed",
                violations.stream().map(v -> Map.of("path", v.getPropertyPath().toString(), "message", v.getMessage())).toList());
        }
        return service.patch(id, CurrentUser.require(), r, ItineraryService.has(body, "startDate"), ItineraryService.has(body, "budgetUsd"));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable UUID id) { service.delete(id, CurrentUser.require()); }

    @PostMapping("/{id}/generate")
    public Map<String, Object> generate(@PathVariable UUID id, @RequestBody(required = false) @Valid GenerateRequest r) {
        return service.generate(id, CurrentUser.require(), r == null ? null : r.day());
    }

    @PostMapping("/{id}/recalculate")
    public Map<String, Object> recalculate(@PathVariable UUID id) { return service.recalculate(id, CurrentUser.require()); }

    @PostMapping("/{id}/copy")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> copy(@PathVariable UUID id) { return service.copy(id, CurrentUser.require()); }
}

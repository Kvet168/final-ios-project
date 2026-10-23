package com.wayfarer.admin.web;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.admin.dto.AdminDtos.DestinationPatch;
import com.wayfarer.admin.dto.AdminDtos.DestinationRequest;
import com.wayfarer.admin.service.ContentService;
import com.wayfarer.common.ApiException;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Valid;
import jakarta.validation.Validator;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Destination content management (staff and admin; deleting a destination is admin only). Hotels, rooms, prices and stock belong to partners. */
@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin content")
public class ContentController {
    private final ContentService content;
    private final ObjectMapper json;
    private final Validator validator;

    public ContentController(ContentService content, ObjectMapper json, Validator validator) {
        this.content = content;
        this.json = json;
        this.validator = validator;
    }

    @PostMapping("/destinations")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> createDestination(@Valid @RequestBody DestinationRequest r) { return content.createDestination(CurrentUser.require().id(), r); }

    @PatchMapping("/destinations/{id}")
    public Map<String, Object> updateDestination(@PathVariable UUID id, @RequestBody JsonNode body) throws Exception {
        DestinationPatch patch = json.treeToValue(body, DestinationPatch.class);
        Set<ConstraintViolation<DestinationPatch>> violations = validator.validate(patch);
        if (!violations.isEmpty()) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "VALIDATION_ERROR", "Request validation failed",
                violations.stream().map(v -> Map.of("path", v.getPropertyPath().toString(), "message", v.getMessage())).toList());
        }
        return content.updateDestination(CurrentUser.require().id(), id, patch, body);
    }

    @DeleteMapping("/destinations/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteDestination(@PathVariable UUID id) { content.deleteDestination(CurrentUser.require().id(), id); }
}

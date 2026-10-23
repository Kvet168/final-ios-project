package com.wayfarer.admin.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.wayfarer.admin.dto.AdminDtos.DestinationPatch;
import com.wayfarer.admin.dto.AdminDtos.DestinationRequest;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.catalog.repository.ReferenceDataRepository;
import com.wayfarer.catalog.service.DestinationService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Text;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Destination content management. Every change is audited and drops the Redis catalogue cache. */
@Service
public class ContentService {
    private final DestinationRepository destinations;
    private final ReferenceDataRepository reference;
    private final DestinationService destinationService;
    private final AuditService audit;

    public ContentService(DestinationRepository destinations, ReferenceDataRepository reference, DestinationService destinationService, AuditService audit) {
        this.destinations = destinations;
        this.reference = reference;
        this.destinationService = destinationService;
        this.audit = audit;
    }

    @Transactional
    public Map<String, Object> createDestination(UUID actor, DestinationRequest b) {
        String slug = Text.slugify(b.name());
        if (destinations.slugExists(slug)) throw ApiException.conflict("DUPLICATE", "A destination with this name already exists");
        String currency = b.currency() == null ? "USD" : b.currency().toUpperCase();
        if (!reference.currencyExists(currency)) throw ApiException.unprocessable("VALIDATION_ERROR", "Unsupported currency code");
        Map<String, Object> d = destinations.insert(new MapSqlParameterSource().addValue("slug", slug).addValue("name", b.name().trim()).addValue("country", b.country().trim())
            .addValue("region", b.region()).addValue("intl", Boolean.TRUE.equals(b.isInternational())).addValue("shortDesc", b.shortDescription().trim())
            .addValue("longDesc", b.longDescription().trim()).addValue("lat", b.lat()).addValue("lng", b.lng()).addValue("cover", b.coverImage())
            .addValue("budget", b.dailyBudgetUsd()).addValue("currency", currency).addValue("tags", Text.pgArray(b.tags() == null ? List.of() : b.tags()))
            .addValue("featured", Boolean.TRUE.equals(b.isFeatured())));
        audit.record(actor, "destination.create", "destination", d.get("id"), Map.of("name", d.get("name")));
        destinationService.evictCache();
        return d;
    }

    /** @param body the raw JSON, used to learn which fields were sent. */
    @Transactional
    public Map<String, Object> updateDestination(UUID actor, UUID id, DestinationPatch b, JsonNode body) {
        Map<String, String> columns = new LinkedHashMap<>();
        columns.put("name", "name");
        columns.put("country", "country");
        columns.put("region", "region");
        columns.put("shortDescription", "short_description");
        columns.put("longDescription", "long_description");
        columns.put("lat", "lat");
        columns.put("lng", "lng");
        columns.put("dailyBudgetUsd", "daily_budget_usd");
        columns.put("currency", "currency");
        columns.put("coverImage", "cover_image");
        columns.put("tags", "tags");
        columns.put("isInternational", "is_international");
        columns.put("isFeatured", "is_featured");
        MapSqlParameterSource ps = new MapSqlParameterSource();
        List<String> sets = new ArrayList<>();
        List<String> touched = new ArrayList<>();
        for (Map.Entry<String, String> c : columns.entrySet()) {
            if (!body.has(c.getKey())) continue;
            touched.add(c.getKey());
            Object v = switch (c.getKey()) {
                case "name" -> b.name();
                case "country" -> b.country();
                case "region" -> b.region();
                case "shortDescription" -> b.shortDescription();
                case "longDescription" -> b.longDescription();
                case "lat" -> b.lat();
                case "lng" -> b.lng();
                case "dailyBudgetUsd" -> b.dailyBudgetUsd();
                case "currency" -> b.currency() == null ? null : b.currency().toUpperCase();
                case "coverImage" -> b.coverImage();
                case "tags" -> Text.pgArray(b.tags() == null ? List.of() : b.tags());
                case "isInternational" -> b.isInternational();
                default -> b.isFeatured();
            };
            ps.addValue(c.getValue(), v);
            sets.add(c.getValue() + (c.getKey().equals("tags") ? " = CAST(:tags AS text[])" : " = :" + c.getValue()));
        }
        if (sets.isEmpty()) throw ApiException.unprocessable("VALIDATION_ERROR", "No fields to update");
        Map<String, Object> d = destinations.update(id, sets, ps).orElseThrow(() -> ApiException.notFound("Destination"));
        audit.record(actor, "destination.update", "destination", id, Map.of("fields", touched));
        destinationService.evictCache();
        return d;
    }

    @Transactional
    public void deleteDestination(UUID actor, UUID id) {
        if (!destinations.softDelete(id)) throw ApiException.notFound("Destination");
        audit.record(actor, "destination.delete", "destination", id, Map.of());
        destinationService.evictCache();
    }
}

package com.wayfarer.audit.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.audit.repository.AuditRepository;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Text;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/** Append-only audit trail (table audit_logs). Runs inside the caller's transaction so the record commits or rolls back with the change. */
@Service
public class AuditService {
    private final AuditRepository repository;
    private final ObjectMapper json;

    public AuditService(AuditRepository repository, ObjectMapper json) {
        this.repository = repository;
        this.json = json;
    }

    public void record(UUID actorId, String action, String entity, Object entityId, Map<String, ?> meta) {
        String metaJson;
        try {
            metaJson = json.writeValueAsString(meta == null ? Map.of() : meta);
        } catch (JsonProcessingException e) {
            metaJson = "{}";
        }
        repository.insert(actorId, action, entity, entityId == null ? null : entityId.toString(), metaJson);
    }

    public Map<String, Object> search(String action, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(repository.search(action == null || action.isBlank() ? null : Text.like(action), size, Pages.offset(p, size)), p, size);
    }
}

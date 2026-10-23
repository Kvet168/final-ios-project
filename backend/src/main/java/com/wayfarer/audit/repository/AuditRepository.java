package com.wayfarer.audit.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class AuditRepository {
    private final Db db;

    public AuditRepository(Db db) { this.db = db; }

    public void insert(UUID actorId, String action, String entity, String entityId, String metaJson) {
        db.update("INSERT INTO audit_logs(actor_id, action, entity, entity_id, meta) VALUES (:actor, :action, :entity, :eid, CAST(:meta AS jsonb))",
            Db.params().addValue("actor", actorId).addValue("action", action).addValue("entity", entity).addValue("eid", entityId).addValue("meta", metaJson));
    }

    public List<Map<String, Object>> search(String actionLike, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("limit", limit).addValue("offset", offset);
        String where = "true";
        if (actionLike != null) { ps.addValue("a", actionLike); where = "l.action ILIKE :a"; }
        return db.list("SELECT l.id, l.action, l.entity, l.entity_id, l.meta, l.created_at, u.email AS actor_email, COUNT(*) OVER () AS total_count "
            + "FROM audit_logs l LEFT JOIN users u ON u.id = l.actor_id WHERE " + where + " ORDER BY l.id DESC LIMIT :limit OFFSET :offset", ps);
    }
}

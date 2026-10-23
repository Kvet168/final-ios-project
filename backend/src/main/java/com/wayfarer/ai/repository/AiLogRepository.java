package com.wayfarer.ai.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Repository;

@Repository
public class AiLogRepository {
    private final Db db;

    public AiLogRepository(Db db) { this.db = db; }

    public void usage(UUID userIdOrNull, String kind, String mode, String provider, long latencyMs, boolean ok) {
        db.update("INSERT INTO ai_usage_events(user_id, kind, mode, provider, latency_ms, ok) VALUES (:u, :k, :m, :p, :l, :ok)",
            Db.params().addValue("u", userIdOrNull).addValue("k", kind).addValue("m", mode).addValue("p", provider).addValue("l", (int) latencyMs).addValue("ok", ok));
    }

    /** Stores one question/answer exchange as a new conversation. */
    public void conversation(UUID userId, String question, String answer, String sourcesJson, String mode) {
        db.update("WITH c AS (INSERT INTO ai_conversations(user_id) VALUES (:u) RETURNING id), "
            + "m AS (INSERT INTO ai_messages(conversation_id, role, content) SELECT id, 'user', :q FROM c) "
            + "INSERT INTO ai_messages(conversation_id, role, content, sources, mode) SELECT id, 'assistant', :a, CAST(:s AS jsonb), :mode FROM c",
            Db.params().addValue("u", userId).addValue("q", question).addValue("a", answer).addValue("s", sourcesJson).addValue("mode", mode));
    }

    public List<Map<String, Object>> recentUsage(int limit) {
        return db.list("SELECT id, kind, mode, provider, latency_ms, ok, created_at FROM ai_usage_events ORDER BY id DESC LIMIT " + limit);
    }

    public List<Map<String, Object>> usageByKind() {
        return db.list("SELECT kind, mode, COUNT(*)::int AS calls, ROUND(AVG(latency_ms))::int AS avg_ms FROM ai_usage_events GROUP BY kind, mode ORDER BY calls DESC");
    }
}

package com.wayfarer.ai.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

/** Approved travel guides, searched with PostgreSQL full-text search (lexical, not semantic). */
@Repository
public class DocumentRepository {
    private final Db db;

    public DocumentRepository(Db db) { this.db = db; }

    public List<Map<String, Object>> search(String tsQuery, int limit, String destinationSlug) {
        MapSqlParameterSource ps = Db.params().addValue("q", tsQuery).addValue("l", limit);
        String dest = "";
        if (destinationSlug != null) { ps.addValue("slug", destinationSlug); dest = "AND (d.slug = :slug OR t.destination_id IS NULL)"; }
        return db.list("SELECT t.id AS document_id, t.slug, t.title, t.source_label, t.category, t.is_demo, c.content, ts_rank(c.tsv, to_tsquery('english', :q)) AS score "
            + "FROM document_chunks c JOIN travel_documents t ON t.id = c.document_id LEFT JOIN destinations d ON d.id = t.destination_id "
            + "WHERE c.tsv @@ to_tsquery('english', :q) " + dest + " ORDER BY score DESC LIMIT :l", ps);
    }

    public List<Map<String, Object>> sources() {
        return db.list("SELECT t.slug, t.title, t.category, t.source_label, t.is_demo, (SELECT COUNT(*)::int FROM document_chunks c WHERE c.document_id = t.id) AS chunks "
            + "FROM travel_documents t ORDER BY t.category, t.title");
    }
}

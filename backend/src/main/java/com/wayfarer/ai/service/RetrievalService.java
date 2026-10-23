package com.wayfarer.ai.service;

import com.wayfarer.ai.dto.AssistantDtos.Source;
import com.wayfarer.ai.repository.DocumentRepository;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * Retrieval over approved travel_documents: PostgreSQL full-text search (tsvector + ts_rank) over document chunks with OR-combined terms.
 * This is lexical retrieval, not embedding search.
 */
@Service
public class RetrievalService {
    private final DocumentRepository documents;

    public RetrievalService(DocumentRepository documents) { this.documents = documents; }

    public List<Source> retrieve(String question, int limit, String destinationSlug) {
        String tsq = QueryAnalysis.toOrQuery(question);
        if (tsq.isEmpty()) return List.of();
        return documents.search(tsq, limit, destinationSlug).stream().map(r -> new Source((UUID) r.get("document_id"), (String) r.get("slug"), (String) r.get("title"),
            (String) r.get("source_label"), (String) r.get("category"), (String) r.get("content"), ((Number) r.get("score")).doubleValue(), Boolean.TRUE.equals(r.get("is_demo")))).toList();
    }

    public Map<String, Object> sources() {
        return Map.of("retrieval", "PostgreSQL full-text search (lexical). Embedding search is not enabled.", "items", documents.sources());
    }
}

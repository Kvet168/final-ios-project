package com.wayfarer.ai.service;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class QueryAnalysisTest {
    @Test
    void stop_words_are_dropped_and_synonyms_expanded() {
        String q = QueryAnalysis.toOrQuery("What should I wear at temples?");
        assertTrue(q.contains("wear") && q.contains("dress") && q.contains("clothing") && q.contains("temples"));
        assertFalse(q.contains("what") || q.contains(" i "));
    }

    @Test
    void cancellation_questions_expand_to_policy_terms() {
        String q = QueryAnalysis.toOrQuery("How does free cancel work?");
        assertTrue(q.contains("cancellation") && q.contains("refund"));
    }

    @Test
    void only_stop_words_gives_an_empty_query() { assertEquals("", QueryAnalysis.toOrQuery("what is the")); }

    @Test
    void concept_groups_exclude_the_destination_name() {
        List<List<String>> g = QueryAnalysis.queryGroups("best time to visit Siem Reap", List.of("siem", "reap"));
        assertTrue(g.stream().noneMatch(grp -> grp.contains("siem") || grp.contains("reap")));
        assertFalse(g.isEmpty());
    }
}

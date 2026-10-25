package com.wayfarer.ai.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.wayfarer.ai.service.LlmClient.Turn;
import java.util.List;
import org.junit.jupiter.api.Test;

class LlmClientTest {
    @Test
    void dropsBlankAndLeadingAssistantTurns() {
        List<Turn> out = LlmClient.normalize(List.of(new Turn("assistant", "Hello!"), new Turn("user", "  "), new Turn("user", "Best time for Siem Reap?")));
        assertEquals(1, out.size());
        assertEquals("user", out.get(0).role());
    }

    @Test
    void mergesNeighboursWithTheSameRoleSoRolesAlternate() {
        List<Turn> out = LlmClient.normalize(List.of(new Turn("user", "Hi"), new Turn("user", "3 days in Cambodia"), new Turn("assistant", "Sure"), new Turn("user", "only Phnom Penh")));
        assertEquals(3, out.size());
        assertEquals("user", out.get(0).role());
        assertTrue(out.get(0).text().contains("3 days in Cambodia"));
        assertEquals("assistant", out.get(1).role());
        assertEquals("user", out.get(2).role());
    }

    @Test
    void unknownRolesCountAsUser() {
        List<Turn> out = LlmClient.normalize(List.of(new Turn(null, "hello")));
        assertEquals("user", out.get(0).role());
    }
}

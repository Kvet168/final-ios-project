package com.wayfarer.ai;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.service.LlmClient;
import com.wayfarer.ai.service.RequestParser;
import com.wayfarer.ai.service.RequestParser.Slug;
import com.wayfarer.config.AppProperties;
import java.util.List;
import org.junit.jupiter.api.Test;

class RequestParserTest {
    private static final List<Slug> DESTS = List.of(new Slug("phnom-penh", "Phnom Penh"), new Slug("siem-reap", "Siem Reap"), new Slug("bali", "Bali (Ubud)"),
        new Slug("kampot", "Kampot"));

    private static RequestParser parser() {
        AppProperties props = new AppProperties(false, 30, new AppProperties.Jwt("x".repeat(40), 900, 3600, "wayfarer"), new AppProperties.Payment("mock", "s"),
            new AppProperties.RateLimit(30, 900), "*", 300, new AppProperties.Ai("", "m", 20));
        return new RequestParser(new LlmClient(props), new ObjectMapper());
    }

    @Test
    void brief_example_three_days_in_phnom_penh_and_150_dollars() {
        PlanRequest r = parser().parseWithRules("I have three days in Phnom Penh and $150.", DESTS);
        assertEquals("phnom-penh", r.destination());
        assertEquals(3, r.days());
        assertEquals(150.0, r.budgetUsd());
        assertFalse(r.budgetIsPerDay());
    }

    @Test
    void scenario_prompt_with_party_and_interests() {
        PlanRequest r = parser().parseWithRules("Three days in Phnom Penh, two adults, $150, food, culture, photography, relaxed pace", DESTS);
        assertEquals("phnom-penh", r.destination());
        assertEquals(3, r.days());
        assertEquals(2, r.adults());
        assertEquals("relaxed", r.pace());
        assertTrue(r.interests().containsAll(List.of("food", "culture", "photography", "relaxed")));
    }

    @Test
    void per_day_budget_children_and_nights() {
        PlanRequest r = parser().parseWithRules("2 nights in Kampot with 2 kids, $80 per day", DESTS);
        assertEquals("kampot", r.destination());
        assertEquals(3, r.days());            // 2 nights = 3 days
        assertEquals(2, r.children());
        assertEquals(80.0, r.budgetUsd());
        assertTrue(r.budgetIsPerDay());
        assertTrue(r.interests().contains("family"));
    }

    @Test
    void landmarks_and_aliases_resolve_to_destinations() {
        assertEquals("siem-reap", parser().parseWithRules("a week at Angkor", DESTS).destination());
        assertEquals(7, parser().parseWithRules("a week at Angkor", DESTS).days());
        assertEquals("bali", parser().parseWithRules("honeymoon in Ubud for 5 days", DESTS).destination());
        assertEquals(2, parser().parseWithRules("honeymoon in Ubud for 5 days", DESTS).adults());
    }

    @Test
    void missing_essentials_stay_null_rather_than_guessed() {
        PlanRequest r = parser().parseWithRules("somewhere nice", DESTS);
        assertNull(r.destination());
        assertNull(r.days());
        assertNull(r.budgetUsd());
    }
}

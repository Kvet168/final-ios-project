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
            new AppProperties.RateLimit(30, 900), "*", 300, new AppProperties.Ai("", "m", 20, "auto"));
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

    @Test
    void country_without_city_uses_its_most_popular_destination() {
        // Ordered most popular first, as the planner loads them.
        List<Slug> dests = List.of(new Slug("hanoi", "Hanoi", "Vietnam"), new Slug("phnom-penh", "Phnom Penh", "Cambodia"),
            new Slug("hoi-an", "Hoi An", "Vietnam"), new Slug("da-nang", "Da Nang", "Vietnam"));
        RequestParser.Parsed p = parser().understand("I want to got vietnam 3 days", dests);
        assertEquals("hanoi", p.request().destination());
        assertEquals(3, p.request().days());
        assertTrue(p.note().contains("Hoi An") && p.note().contains("Da Nang"), p.note());

        // A named city still wins over its country.
        assertEquals("hoi-an", parser().understand("3 days in Hoi An, Vietnam", dests).request().destination());
        // No country, no city: still asks.
        assertNull(parser().understand("3 days somewhere warm", dests).request().destination());
    }

    private static final List<Slug> CAMBODIA = List.of(new Slug("siem-reap", "Siem Reap", "Cambodia"), new Slug("phnom-penh", "Phnom Penh", "Cambodia"),
        new Slug("kampot", "Kampot", "Cambodia"), new Slug("koh-rong", "Koh Rong", "Cambodia"), new Slug("koh-kong", "Koh Kong", "Cambodia"),
        new Slug("kep", "Kep", "Cambodia"), new Slug("battambang", "Battambang", "Cambodia"), new Slug("kampong-cham", "Kampong Cham", "Cambodia"));

    private static List<String> cities(String text) { return parser().parseWithRules(text, CAMBODIA).allDestinations(); }

    @Test
    void two_cities_in_the_order_they_are_named_even_when_spacing_is_off() {
        // The request that used to plan only Kampot.
        PlanRequest r = parser().parseWithRules("kampot and siemreap. for 5 days", CAMBODIA);
        assertEquals(List.of("kampot", "siem-reap"), r.allDestinations());
        assertEquals("kampot", r.destination());
        assertEquals(List.of("siem-reap"), r.alsoVisit());
        assertEquals(5, r.days());
        assertNull(r.daysPerDestination());
    }

    @Test
    void order_follows_the_text_not_the_destination_list() {
        assertEquals(List.of("siem-reap", "kampot", "phnom-penh"), cities("Siem Reap, then Kampot and finish in Phnom Penh, 7 days"));
        assertEquals(List.of("phnom-penh", "siem-reap"), cities("phnompenh to siem reap 4 days"));
    }

    @Test
    void angkor_means_siem_reap_and_a_city_is_only_listed_once() {
        assertEquals(List.of("siem-reap", "kampot"), cities("Angkor and Siem Reap then Kampot"));
    }

    @Test
    void one_letter_typos_are_forgiven_but_exact_names_always_win() {
        assertEquals(List.of("battambang", "kampot"), cities("battambong and kampott for 4 days"));
        // "koh rong" is one letter away from "koh kong": the exact name must win, and a vague one must not guess.
        assertEquals(List.of("koh-rong"), cities("3 days on koh rong"));
        assertEquals(List.of("koh-kong"), cities("3 days on kohkong"));
    }

    @Test
    void words_that_merely_contain_a_city_name_are_not_cities() {
        assertEquals(List.of(), cities("We kept all the plans and keep going, 3 days"));
        assertEquals(List.of("kep"), cities("3 days in kep"));
    }

    @Test
    void days_per_city_are_read_in_both_phrasings() {
        PlanRequest a = parser().parseWithRules("3 days in Kampot and 2 days in Siem Reap", CAMBODIA);
        assertEquals(List.of("kampot", "siem-reap"), a.allDestinations());
        assertEquals(List.of(3, 2), a.daysPerDestination());
        assertEquals(5, a.days());

        PlanRequest b = parser().parseWithRules("kampot for 2 days then siem reap 3 days", CAMBODIA);
        assertEquals(List.of(2, 3), b.daysPerDestination());
        assertEquals(5, b.days());

        PlanRequest c = parser().parseWithRules("two days in Phnom Penh, one day in Kep and three days in Siem Reap", CAMBODIA);
        assertEquals(List.of("phnom-penh", "kep", "siem-reap"), c.allDestinations());
        assertEquals(List.of(2, 1, 3), c.daysPerDestination());
        assertEquals(6, c.days());
    }

    @Test
    void a_total_followed_by_cities_is_not_mistaken_for_per_city_days() {
        PlanRequest r = parser().parseWithRules("5 days kampot and siem reap", CAMBODIA);
        assertEquals(List.of("kampot", "siem-reap"), r.allDestinations());
        assertNull(r.daysPerDestination());
        assertEquals(5, r.days());
    }

    @Test
    void more_than_four_cities_keeps_the_first_four() {
        PlanRequest r = parser().parseWithRules("phnom penh, siem reap, kampot, kep, battambang in 10 days", CAMBODIA);
        assertEquals(4, r.allDestinations().size());
        assertEquals(List.of("phnom-penh", "siem-reap", "kampot", "kep"), r.allDestinations());
    }
}

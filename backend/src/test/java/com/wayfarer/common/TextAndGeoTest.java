package com.wayfarer.common;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;
import org.junit.jupiter.api.Test;

class TextAndGeoTest {
    @Test
    void slugify_removes_accents_and_punctuation() {
        assertEquals("phnom-penh", Text.slugify("Phnom Penh"));
        assertEquals("cafe-d-ete-2", Text.slugify("  Café d'Été #2 "));
    }

    @Test
    void like_escapes_wildcards() { assertEquals("%50\\%\\_off%", Text.like("50%_off")); }

    @Test
    void pg_array_quotes_and_escapes() { assertEquals("{\"a\",\"b\\\"c\"}", Text.pgArray(List.of("a", "b\"c"))); }

    @Test
    void haversine_phnom_penh_to_siem_reap_is_about_250_km() {
        double km = Geo.haversineKm(11.5564, 104.9282, 13.3671, 103.8448);
        assertTrue(km > 220 && km < 280, "km=" + km);
    }

    @Test
    void road_minutes_use_the_documented_detour_and_speed() { assertEquals(Math.round(10 * 1.35 / 22 * 60), Geo.roadMinutes(10)); }

    @Test
    void uuid_detection() {
        assertTrue(Db.isUuid("83778e5d-08c7-418c-9c79-dcf8aa291792"));
        assertFalse(Db.isUuid("phnom-penh"));
    }
}

package com.wayfarer.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import org.junit.jupiter.api.Test;

class ConnectionUrlTest {

    @Test
    void convertsProviderUrlWithCredentials() {
        Map<String, Object> p = ConnectionUrlEnvironmentPostProcessor.datasource("postgres://wayfarer:s3cr%40t@db.example.com:5432/wayfarer_db?sslmode=require");
        assertEquals("jdbc:postgresql://db.example.com:5432/wayfarer_db?sslmode=require", p.get("spring.datasource.url"));
        assertEquals("wayfarer", p.get("spring.datasource.username"));
        assertEquals("s3cr@t", p.get("spring.datasource.password"));
    }

    @Test
    void convertsInternalUrlWithoutPort() {
        Map<String, Object> p = ConnectionUrlEnvironmentPostProcessor.datasource("postgresql://u:p@dpg-abc123-a/wayfarer");
        assertEquals("jdbc:postgresql://dpg-abc123-a/wayfarer", p.get("spring.datasource.url"));
        assertEquals("p", p.get("spring.datasource.password"));
    }

    @Test
    void leavesJdbcUrlsAlone() {
        assertTrue(ConnectionUrlEnvironmentPostProcessor.datasource("jdbc:postgresql://localhost:5432/wayfarer").isEmpty());
    }
}

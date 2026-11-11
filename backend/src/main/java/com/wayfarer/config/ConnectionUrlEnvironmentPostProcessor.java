package com.wayfarer.config;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.Ordered;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

/**
 * Accepts the connection strings hosting providers hand out, so they can be pasted as-is.
 *
 * <p>Render, Neon, Supabase and Heroku give {@code postgres://user:pass@host:5432/db}; Spring needs
 * {@code jdbc:postgresql://host:5432/db} with the user and password as separate properties. When {@code DATABASE_URL}
 * uses the provider form it is converted here; a {@code jdbc:} URL is left untouched. {@code REDIS_URL}
 * ({@code redis://} or {@code rediss://}) is mapped to {@code spring.data.redis.url} the same way.
 */
public class ConnectionUrlEnvironmentPostProcessor implements EnvironmentPostProcessor, Ordered {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment env, SpringApplication app) {
        Map<String, Object> props = new HashMap<>();
        String db = env.getProperty("DATABASE_URL");
        if (db != null) props.putAll(datasource(db.trim()));
        String redis = env.getProperty("REDIS_URL");
        if (redis != null && (redis.startsWith("redis://") || redis.startsWith("rediss://"))) props.put("spring.data.redis.url", redis.trim());
        if (!props.isEmpty()) env.getPropertySources().addFirst(new MapPropertySource("providerConnectionUrls", props));
    }

    /** Spring datasource properties for a provider-style URL, or none when the URL is already JDBC (or unrecognised). */
    static Map<String, Object> datasource(String url) {
        if (!(url.startsWith("postgres://") || url.startsWith("postgresql://"))) return Map.of();
        URI u = URI.create(url);
        StringBuilder jdbc = new StringBuilder("jdbc:postgresql://").append(u.getHost());
        if (u.getPort() > 0) jdbc.append(':').append(u.getPort());
        jdbc.append(u.getRawPath() == null || u.getRawPath().isEmpty() ? "/" : u.getRawPath());
        if (u.getRawQuery() != null) jdbc.append('?').append(u.getRawQuery());
        Map<String, Object> props = new HashMap<>();
        props.put("spring.datasource.url", jdbc.toString());
        String info = u.getRawUserInfo();
        if (info != null && !info.isEmpty()) {
            int colon = info.indexOf(':');
            props.put("spring.datasource.username", decode(colon < 0 ? info : info.substring(0, colon)));
            if (colon >= 0) props.put("spring.datasource.password", decode(info.substring(colon + 1)));
        }
        return props;
    }

    private static String decode(String s) { return URLDecoder.decode(s, StandardCharsets.UTF_8); }

    @Override
    public int getOrder() { return Ordered.LOWEST_PRECEDENCE; }
}

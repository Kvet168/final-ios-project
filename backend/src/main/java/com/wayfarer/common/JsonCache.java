package com.wayfarer.common;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.config.AppProperties;
import java.time.Duration;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

/** Read-through JSON cache in Redis for catalogue data. Any Redis failure falls back to the database. */
@Component
public class JsonCache {
    private static final Logger log = LoggerFactory.getLogger(JsonCache.class);

    private final StringRedisTemplate redis;
    private final ObjectMapper json;
    private final Duration ttl;

    public JsonCache(StringRedisTemplate redis, ObjectMapper json, AppProperties props) {
        this.redis = redis;
        this.json = json;
        this.ttl = Duration.ofSeconds(props.cacheTtlSec());
    }

    /** Drops every entry whose key starts with the prefix (after admin edits). Cache failures are ignored. */
    public void evictPrefix(String prefix) {
        try {
            var keys = redis.keys(prefix + "*");
            if (keys != null && !keys.isEmpty()) redis.delete(keys);
        } catch (Exception e) {
            log.debug("cache evict skipped for {}: {}", prefix, e.getMessage());
        }
    }

    public <T> T get(String key, TypeReference<T> type, Supplier<T> loader) {
        try {
            String hit = redis.opsForValue().get(key);
            if (hit != null) return json.readValue(hit, type);
        } catch (Exception e) {
            log.debug("cache read skipped for {}: {}", key, e.getMessage());
        }
        T value = loader.get();
        try {
            redis.opsForValue().set(key, json.writeValueAsString(value), ttl);
        } catch (Exception e) {
            log.debug("cache write skipped for {}: {}", key, e.getMessage());
        }
        return value;
    }
}

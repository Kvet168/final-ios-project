package com.wayfarer.security;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

/** Fixed-window counter in Redis. Fails open: if Redis is unavailable requests are allowed (and a warning is logged). */
@Component
public class RateLimiter {
    private static final Logger log = LoggerFactory.getLogger(RateLimiter.class);
    private final StringRedisTemplate redis;

    public RateLimiter(StringRedisTemplate redis) { this.redis = redis; }

    public boolean allow(String key, int max, int windowSec) {
        try {
            Long count = redis.opsForValue().increment(key);
            if (count != null && count == 1) redis.expire(key, Duration.ofSeconds(windowSec));
            return count == null || count <= max;
        } catch (Exception e) {
            log.warn("Rate limiter skipped, Redis unavailable: {}", e.getMessage());
            return true;
        }
    }
}

package com.wayfarer.security;

import java.time.Duration;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

/** Access tokens revoked by logout, kept in Redis until they would have expired anyway. */
@Component
public class TokenDenylist {
    private static final Logger log = LoggerFactory.getLogger(TokenDenylist.class);
    private final StringRedisTemplate redis;

    public TokenDenylist(StringRedisTemplate redis) { this.redis = redis; }

    public void deny(String jti, Instant expiresAt) {
        Duration ttl = Duration.between(Instant.now(), expiresAt);
        if (ttl.isNegative() || ttl.isZero()) return;
        try {
            redis.opsForValue().set("deny:jti:" + jti, "1", ttl);
        } catch (Exception e) {
            log.warn("Redis unavailable; access token could not be denylisted ({})", e.getMessage());
        }
    }

    /** Fails open if Redis is down: the token still expires within minutes and refresh tokens are revoked in PostgreSQL. */
    public boolean isDenied(String jti) {
        try {
            return Boolean.TRUE.equals(redis.hasKey("deny:jti:" + jti));
        } catch (Exception e) {
            return false;
        }
    }
}

package com.wayfarer;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.config.AppProperties;
import com.wayfarer.security.JwtService;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class JwtServiceTest {
    private static JwtService service(String secret, long ttl) {
        return new JwtService(new AppProperties(false, 30, new AppProperties.Jwt(secret, ttl, 3600, "wayfarer"),
            new AppProperties.Payment("mock", "s"), new AppProperties.RateLimit(30, 900), "*", 300, new AppProperties.Ai("", "m", 20)));
    }

    private static final String SECRET = "unit-test-secret-unit-test-secret-0123456789";

    @Test
    void roundTrip() {
        UUID id = UUID.randomUUID();
        Claims c = service(SECRET, 60).parse(service(SECRET, 60).issueAccessToken(id, "a@b.co", "customer"));
        assertEquals(id.toString(), c.getSubject());
        assertEquals("customer", c.get("role"));
        assertNotNull(c.getId());
    }

    @Test
    void tamperedTokenIsRejected() {
        String t = service(SECRET, 60).issueAccessToken(UUID.randomUUID(), "a@b.co", "customer");
        assertThrows(JwtException.class, () -> service(SECRET, 60).parse(t.substring(0, t.length() - 2) + "xx"));
    }

    @Test
    void tokenSignedWithAnotherKeyIsRejected() {
        String t = service("another-secret-another-secret-0123456789ab", 60).issueAccessToken(UUID.randomUUID(), "a@b.co", "admin");
        assertThrows(JwtException.class, () -> service(SECRET, 60).parse(t));
    }

    @Test
    void expiredTokenIsRejected() {
        String t = service(SECRET, -5).issueAccessToken(UUID.randomUUID(), "a@b.co", "customer");
        assertThrows(ExpiredJwtException.class, () -> service(SECRET, 60).parse(t));
    }
}

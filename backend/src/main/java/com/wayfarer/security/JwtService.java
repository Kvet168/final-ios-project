package com.wayfarer.security;

import com.wayfarer.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

/** Issues and verifies short-lived HS256 access tokens. Refresh tokens are opaque and stored hashed (see AuthService). */
@Service
public class JwtService {
    private final SecretKey key;
    private final AppProperties.Jwt cfg;

    public JwtService(AppProperties props) {
        this.cfg = props.jwt();
        this.key = Keys.hmacShaKeyFor(cfg.accessSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String issueAccessToken(UUID userId, String email, String role) {
        Instant now = Instant.now();
        return Jwts.builder()
            .issuer(cfg.issuer())
            .subject(userId.toString())
            .id(UUID.randomUUID().toString())
            .claim("email", email)
            .claim("role", role)
            .issuedAt(Date.from(now))
            .expiration(Date.from(now.plusSeconds(cfg.accessTtlSec())))
            .signWith(key)
            .compact();
    }

    /** @throws io.jsonwebtoken.JwtException when the token is malformed, tampered with, or expired */
    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).requireIssuer(cfg.issuer()).build().parseSignedClaims(token).getPayload();
    }

    public long accessTtlSec() { return cfg.accessTtlSec(); }
}

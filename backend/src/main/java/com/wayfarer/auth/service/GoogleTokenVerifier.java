package com.wayfarer.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.wayfarer.common.ApiException;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.LocatorAdapter;
import java.math.BigInteger;
import java.security.Key;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Verifies Google ID tokens locally: RS256 signature against Google's published keys, expiry, issuer, audience (one of our OAuth
 * client IDs) and a verified email. Keys are cached for an hour and refreshed once when an unknown key id appears.
 */
@Component
public class GoogleTokenVerifier {
    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifier.class);
    private static final String CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs";
    private static final Duration CACHE = Duration.ofHours(1);

    public record GoogleIdentity(String subject, String email, String name) {}

    private final Set<String> audiences;
    private final RestClient http = RestClient.create();
    private volatile Map<String, PublicKey> keys = Map.of();
    private volatile Instant loadedAt = Instant.EPOCH;

    public GoogleTokenVerifier(@Value("${wayfarer.google.client-ids:}") String clientIds) {
        Set<String> ids = new LinkedHashSet<>();
        for (String s : Arrays.asList(clientIds.split(","))) if (!s.isBlank()) ids.add(s.trim());
        this.audiences = ids;
    }

    public boolean configured() { return !audiences.isEmpty(); }

    public String primaryClientId() { return audiences.iterator().next(); }

    public GoogleIdentity verify(String idToken) {
        if (!configured()) throw ApiException.unavailable("GOOGLE_NOT_CONFIGURED", "Google sign-in is not set up on this server yet");
        try {
            Claims c = Jwts.parser().keyLocator(new LocatorAdapter<Key>() {
                @Override protected Key locate(JwsHeader header) { return keyFor(header.getKeyId()); }
            }).build().parseSignedClaims(idToken).getPayload();
            String iss = c.getIssuer();
            if (!"https://accounts.google.com".equals(iss) && !"accounts.google.com".equals(iss)) throw new JwtException("bad issuer");
            Set<String> aud = c.getAudience();
            if (aud == null || aud.stream().noneMatch(audiences::contains)) throw new JwtException("bad audience");
            Object verified = c.get("email_verified");
            String email = c.get("email", String.class);
            if (email == null || email.isBlank() || !(Boolean.TRUE.equals(verified) || "true".equals(String.valueOf(verified)))) throw new JwtException("email not verified");
            String name = c.get("name", String.class);
            if (name == null || name.trim().length() < 2) name = email.substring(0, email.indexOf('@'));
            return new GoogleIdentity(c.getSubject(), email.trim(), name.trim().length() > 80 ? name.trim().substring(0, 80) : name.trim());
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Rejected Google ID token: {}", e.getMessage());
            throw ApiException.unauthorized("INVALID_GOOGLE_TOKEN", "Google sign-in could not be verified. Please try again.");
        }
    }

    private Key keyFor(String kid) {
        if (kid == null) throw new JwtException("missing key id");
        PublicKey k = keys.get(kid);
        if (k == null || Instant.now().isAfter(loadedAt.plus(CACHE))) {
            refresh();
            k = keys.get(kid);
        }
        if (k == null) throw new JwtException("unknown signing key");
        return k;
    }

    private synchronized void refresh() {
        if (Instant.now().isBefore(loadedAt.plusSeconds(30))) return; // do not hammer Google when tokens carry unknown key ids
        try {
            JsonNode body = http.get().uri(CERTS_URL).retrieve().body(JsonNode.class);
            Map<String, PublicKey> next = new HashMap<>();
            KeyFactory rsa = KeyFactory.getInstance("RSA");
            for (JsonNode jwk : body.path("keys")) {
                if (!"RSA".equals(jwk.path("kty").asText())) continue;
                BigInteger n = new BigInteger(1, Base64.getUrlDecoder().decode(jwk.path("n").asText()));
                BigInteger e = new BigInteger(1, Base64.getUrlDecoder().decode(jwk.path("e").asText()));
                next.put(jwk.path("kid").asText(), rsa.generatePublic(new RSAPublicKeySpec(n, e)));
            }
            if (!next.isEmpty()) {
                keys = next;
                loadedAt = Instant.now();
            }
        } catch (Exception ex) {
            log.warn("Could not load Google signing keys: {}", ex.getMessage());
        }
    }
}

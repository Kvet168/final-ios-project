package com.wayfarer.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.wayfarer.common.ApiException;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.LocatorAdapter;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.security.PublicKey;
import java.security.cert.CertificateFactory;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/**
 * Verifies Firebase Authentication ID tokens locally: RS256 signature against Google's published securetoken certificates, expiry,
 * issuer {@code https://securetoken.google.com/<project>}, audience (the Firebase project id) and a non-empty subject (the Firebase uid).
 * Certificates are cached for an hour and refreshed once when an unknown key id appears.
 */
@Component
public class FirebaseTokenVerifier {
    private static final Logger log = LoggerFactory.getLogger(FirebaseTokenVerifier.class);
    private static final String CERTS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";
    private static final Duration CACHE = Duration.ofHours(1);

    /** {@code signInProvider} is Firebase's "password", "google.com", "apple.com" and so on. */
    public record FirebaseIdentity(String uid, String email, boolean emailVerified, String name, String signInProvider) {
        /** Google and Apple vouch for the address themselves; for passwords the user must have clicked the verification link. */
        public boolean trustedEmail() { return emailVerified || "google.com".equals(signInProvider) || "apple.com".equals(signInProvider); }
    }

    private final String projectId;
    private final RestClient http = RestClient.create();
    private volatile Map<String, PublicKey> keys = Map.of();
    private volatile Instant loadedAt = Instant.EPOCH;

    public FirebaseTokenVerifier(@Value("${wayfarer.firebase.project-id:}") String projectId) {
        this.projectId = projectId == null ? "" : projectId.trim();
    }

    public boolean configured() { return !projectId.isEmpty(); }

    public String projectId() { return projectId; }

    /** Test hook: use these keys instead of fetching Google's. */
    void useKeys(Map<String, PublicKey> testKeys) {
        this.keys = testKeys;
        this.loadedAt = Instant.now();
    }

    public FirebaseIdentity verify(String idToken) {
        if (!configured()) throw ApiException.unavailable("FIREBASE_NOT_CONFIGURED", "Firebase sign-in is not set up on this server yet");
        try {
            Claims c = Jwts.parser().keyLocator(new LocatorAdapter<Key>() {
                @Override protected Key locate(JwsHeader header) { return keyFor(header.getKeyId()); }
            }).build().parseSignedClaims(idToken).getPayload();
            if (!("https://securetoken.google.com/" + projectId).equals(c.getIssuer())) throw new JwtException("bad issuer");
            if (c.getAudience() == null || !c.getAudience().contains(projectId)) throw new JwtException("bad audience");
            String uid = c.getSubject();
            if (uid == null || uid.isBlank() || uid.length() > 128) throw new JwtException("bad subject");
            String email = c.get("email", String.class);
            if (email == null || email.isBlank()) throw new JwtException("no email on the account");
            boolean verified = Boolean.TRUE.equals(c.get("email_verified")) || "true".equals(String.valueOf(c.get("email_verified")));
            String provider = null;
            if (c.get("firebase") instanceof Map<?, ?> fb && fb.get("sign_in_provider") != null) provider = String.valueOf(fb.get("sign_in_provider"));
            String name = c.get("name", String.class);
            if (name == null || name.trim().length() < 2) name = email.substring(0, email.indexOf('@') > 0 ? email.indexOf('@') : email.length());
            name = name.trim();
            return new FirebaseIdentity(uid, email.trim(), verified, name.length() > 80 ? name.substring(0, 80) : name, provider);
        } catch (JwtException | IllegalArgumentException e) {
            log.warn("Rejected Firebase ID token: {}", e.getMessage());
            throw ApiException.unauthorized("INVALID_FIREBASE_TOKEN", "Sign-in could not be verified. Please try again.");
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
            CertificateFactory x509 = CertificateFactory.getInstance("X.509");
            Map<String, PublicKey> next = new HashMap<>();
            body.fields().forEachRemaining(e -> {
                try {
                    next.put(e.getKey(), x509.generateCertificate(new ByteArrayInputStream(e.getValue().asText().getBytes(StandardCharsets.UTF_8))).getPublicKey());
                } catch (Exception ex) {
                    log.warn("Skipping unreadable Firebase certificate {}: {}", e.getKey(), ex.getMessage());
                }
            });
            if (!next.isEmpty()) {
                keys = next;
                loadedAt = Instant.now();
            }
        } catch (Exception ex) {
            log.warn("Could not load Firebase signing certificates: {}", ex.getMessage());
        }
    }
}

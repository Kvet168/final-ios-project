package com.wayfarer.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.wayfarer.auth.service.FirebaseTokenVerifier.FirebaseIdentity;
import com.wayfarer.common.ApiException;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Date;
import java.util.Map;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class FirebaseTokenVerifierTest {
    private static final String PROJECT = "wayfarer-test";
    private static KeyPair pair;

    @BeforeAll
    static void keys() throws Exception {
        KeyPairGenerator g = KeyPairGenerator.getInstance("RSA");
        g.initialize(2048);
        pair = g.generateKeyPair();
    }

    private FirebaseTokenVerifier verifier() {
        FirebaseTokenVerifier v = new FirebaseTokenVerifier(PROJECT);
        v.useKeys(Map.of("kid-1", pair.getPublic()));
        return v;
    }

    private JwtBuilder token(String iss, String aud, String sub) {
        return Jwts.builder().header().keyId("kid-1").and().issuer(iss).audience().add(aud).and().subject(sub)
            .expiration(new Date(System.currentTimeMillis() + 60_000));
    }

    private String sign(JwtBuilder b) { return b.signWith(pair.getPrivate()).compact(); }

    @Test
    void disabledWithoutProjectId() {
        FirebaseTokenVerifier v = new FirebaseTokenVerifier("");
        assertFalse(v.configured());
        assertEquals("FIREBASE_NOT_CONFIGURED", assertThrows(ApiException.class, () -> v.verify("x")).code());
    }

    @Test
    void acceptsAValidPasswordUserWithVerifiedEmail() {
        String t = sign(token("https://securetoken.google.com/" + PROJECT, PROJECT, "uid-1").claim("email", "maya@example.com").claim("email_verified", true)
            .claim("name", "Maya Lee").claim("firebase", Map.of("sign_in_provider", "password")));
        FirebaseIdentity id = verifier().verify(t);
        assertEquals("uid-1", id.uid());
        assertEquals("maya@example.com", id.email());
        assertEquals("Maya Lee", id.name());
        assertTrue(id.trustedEmail());
    }

    @Test
    void unverifiedPasswordEmailIsNotTrusted() {
        String t = sign(token("https://securetoken.google.com/" + PROJECT, PROJECT, "uid-2").claim("email", "x@example.com").claim("email_verified", false)
            .claim("firebase", Map.of("sign_in_provider", "password")));
        FirebaseIdentity id = verifier().verify(t);
        assertFalse(id.trustedEmail());
        assertEquals("x", id.name());
    }

    @Test
    void googleSignInIsTrustedEvenWithoutTheVerifiedFlag() {
        String t = sign(token("https://securetoken.google.com/" + PROJECT, PROJECT, "uid-3").claim("email", "g@example.com")
            .claim("firebase", Map.of("sign_in_provider", "google.com")));
        assertTrue(verifier().verify(t).trustedEmail());
    }

    @Test
    void rejectsWrongAudienceIssuerAndMissingEmail() {
        FirebaseTokenVerifier v = verifier();
        String wrongAud = sign(token("https://securetoken.google.com/" + PROJECT, "other-project", "u").claim("email", "a@b.co"));
        String wrongIss = sign(token("https://securetoken.google.com/other-project", PROJECT, "u").claim("email", "a@b.co"));
        String noEmail = sign(token("https://securetoken.google.com/" + PROJECT, PROJECT, "u"));
        for (String t : new String[] {wrongAud, wrongIss, noEmail}) {
            assertEquals("INVALID_FIREBASE_TOKEN", assertThrows(ApiException.class, () -> v.verify(t)).code());
        }
    }

    @Test
    void rejectsExpiredUnknownKeyAndGarbage() throws Exception {
        FirebaseTokenVerifier v = verifier();
        String expired = Jwts.builder().header().keyId("kid-1").and().issuer("https://securetoken.google.com/" + PROJECT).audience().add(PROJECT).and()
            .subject("u").claim("email", "a@b.co").expiration(new Date(System.currentTimeMillis() - 60_000)).signWith(pair.getPrivate()).compact();
        KeyPairGenerator g = KeyPairGenerator.getInstance("RSA");
        g.initialize(2048);
        String forged = Jwts.builder().header().keyId("kid-1").and().issuer("https://securetoken.google.com/" + PROJECT).audience().add(PROJECT).and()
            .subject("u").claim("email", "a@b.co").expiration(new Date(System.currentTimeMillis() + 60_000)).signWith(g.generateKeyPair().getPrivate()).compact();
        for (String t : new String[] {expired, forged, "not-a-token"}) {
            assertEquals("INVALID_FIREBASE_TOKEN", assertThrows(ApiException.class, () -> v.verify(t)).code());
        }
    }
}

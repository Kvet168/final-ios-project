package com.wayfarer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.wayfarer.auth.service.GoogleTokenVerifier;
import com.wayfarer.common.ApiException;
import io.jsonwebtoken.Jwts;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Date;
import org.junit.jupiter.api.Test;

class GoogleTokenVerifierTest {
    @Test
    void disabledWithoutClientIds() {
        GoogleTokenVerifier v = new GoogleTokenVerifier("");
        assertFalse(v.configured());
        ApiException e = assertThrows(ApiException.class, () -> v.verify("anything"));
        assertEquals("GOOGLE_NOT_CONFIGURED", e.code());
    }

    @Test
    void parsesSeveralClientIds() {
        GoogleTokenVerifier v = new GoogleTokenVerifier(" web-id , ios-id ,");
        assertTrue(v.configured());
        assertEquals("web-id", v.primaryClientId());
    }

    @Test
    void rejectsGarbageAndUnsignedTokens() {
        GoogleTokenVerifier v = new GoogleTokenVerifier("web-id");
        assertEquals("INVALID_GOOGLE_TOKEN", assertThrows(ApiException.class, () -> v.verify("not-a-token")).code());
    }

    @Test
    void rejectsTokenSignedWithAnUnknownKey() throws Exception {
        KeyPairGenerator g = KeyPairGenerator.getInstance("RSA");
        g.initialize(2048);
        KeyPair pair = g.generateKeyPair();
        String forged = Jwts.builder().header().keyId("forged-kid").and().issuer("https://accounts.google.com").audience().add("web-id").and()
            .subject("123").claim("email", "a@b.co").claim("email_verified", true).expiration(new Date(System.currentTimeMillis() + 60_000))
            .signWith(pair.getPrivate()).compact();
        GoogleTokenVerifier v = new GoogleTokenVerifier("web-id");
        assertEquals("INVALID_GOOGLE_TOKEN", assertThrows(ApiException.class, () -> v.verify(forged)).code());
    }
}

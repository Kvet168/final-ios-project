package com.wayfarer;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.payment.service.WebhookSigner;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;

class WebhookSignerTest {
    private static final byte[] BODY = "{\"id\":\"evt_1\"}".getBytes(StandardCharsets.UTF_8);

    @Test
    void validSignatureVerifies() {
        assertTrue(WebhookSigner.verify("secret", BODY, WebhookSigner.sign("secret", BODY)));
    }

    @Test
    void wrongSecretOrBodyOrMissingSignatureFails() {
        assertFalse(WebhookSigner.verify("other", BODY, WebhookSigner.sign("secret", BODY)));
        assertFalse(WebhookSigner.verify("secret", "{\"id\":\"evt_2\"}".getBytes(StandardCharsets.UTF_8), WebhookSigner.sign("secret", BODY)));
        assertFalse(WebhookSigner.verify("secret", BODY, null));
    }
}

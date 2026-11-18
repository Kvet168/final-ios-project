package com.wayfarer.ads;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.wayfarer.ads.dto.AdDtos.TrackEvent;
import com.wayfarer.ads.dto.AdDtos.TrackRequest;
import com.wayfarer.common.ApiException;
import jakarta.validation.Validation;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class AdRulesTest {
    @Test
    void onlyHttpsAndPhoneLinksAreAccepted() throws Exception {
        var m = Class.forName("com.wayfarer.ads.service.BusinessAdService").getDeclaredMethod("safeLink", String.class);
        m.setAccessible(true);
        assertEquals("https://example.com/a", m.invoke(null, " https://example.com/a "));
        assertEquals("tel:+855123456789", m.invoke(null, "tel:+855123456789"));
        assertNull(m.invoke(null, "  "));
        for (String bad : List.of("javascript:alert(1)", "http://example.com", "data:text/html,x", "//evil.example")) {
            var e = assertThrows(java.lang.reflect.InvocationTargetException.class, () -> m.invoke(null, bad));
            assertEquals(ApiException.class, e.getCause().getClass(), bad);
        }
    }

    @Test
    void trackingBatchesAreBounded() {
        try (var f = Validation.buildDefaultValidatorFactory()) {
            var v = f.getValidator();
            UUID id = UUID.randomUUID();
            var ok = new TrackRequest(List.of(new TrackEvent(id, "impression"), new TrackEvent(id, "click")));
            assertEquals(0, v.validate(ok).size());
            assertEquals(1, v.validate(new TrackRequest(List.of(new TrackEvent(id, "purchase")))).stream().filter(x -> x.getPropertyPath().toString().contains("type")).count());
            var many = new TrackRequest(java.util.Collections.nCopies(51, new TrackEvent(id, "click")));
            assertEquals(1, v.validate(many).size());
        }
    }
}

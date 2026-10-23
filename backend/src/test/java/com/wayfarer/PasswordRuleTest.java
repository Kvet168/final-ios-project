package com.wayfarer;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.auth.dto.AuthDtos;
import org.junit.jupiter.api.Test;

class PasswordRuleTest {
    private static boolean ok(String p) { return p.matches(AuthDtos.PASSWORD_RULE); }

    @Test
    void acceptsLongPasswordWithLettersAndDigit() { assertTrue(ok("correct-horse-9")); }

    @Test
    void rejectsShortOrMissingClasses() {
        assertFalse(ok("short1"));
        assertFalse(ok("onlyletterspassword"));
        assertFalse(ok("12345678901234"));
    }
}

package com.wayfarer.security;

import java.time.Instant;
import java.util.UUID;

/** The authenticated caller. `role` is re-read from the database on every request so role changes apply immediately. */
public record AuthUser(UUID id, String email, String role, String jti, Instant tokenExpiresAt) {
    public boolean isStaff() { return "admin".equals(role) || "staff".equals(role); }
}

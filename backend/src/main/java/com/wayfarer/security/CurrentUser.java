package com.wayfarer.security;

import com.wayfarer.common.ApiException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class CurrentUser {
    private CurrentUser() {}

    /** The signed-in user, or null for anonymous callers on endpoints that work both ways. */
    public static AuthUser optional() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        return a != null && a.getPrincipal() instanceof AuthUser u ? u : null;
    }

    public static AuthUser require() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a != null && a.getPrincipal() instanceof AuthUser u) return u;
        throw ApiException.unauthorized("UNAUTHENTICATED", "Authentication required");
    }
}

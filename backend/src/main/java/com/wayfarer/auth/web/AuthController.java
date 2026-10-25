package com.wayfarer.auth.web;

import com.wayfarer.auth.dto.AuthDtos.AuthResponse;
import com.wayfarer.auth.dto.AuthDtos.ChangePasswordRequest;
import com.wayfarer.auth.dto.AuthDtos.ForgotPasswordRequest;
import com.wayfarer.auth.dto.AuthDtos.LoginRequest;
import com.wayfarer.auth.dto.AuthDtos.RefreshRequest;
import com.wayfarer.auth.dto.AuthDtos.RegisterRequest;
import com.wayfarer.auth.dto.AuthDtos.ResetPasswordRequest;
import com.wayfarer.auth.dto.AuthDtos.TokenResponse;
import com.wayfarer.auth.service.AuthService;
import com.wayfarer.security.AuthUser;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Auth")
@SecurityRequirements
public class AuthController {
    private final AuthService auth;

    public AuthController(AuthService auth) { this.auth = auth; }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest r) { return auth.register(r); }

    /** Exchanges a Google ID token (from the app's Google sign-in) for WAYFARER tokens, creating the customer account on first use. */
    @PostMapping("/google")
    public AuthResponse google(@Valid @RequestBody com.wayfarer.auth.dto.AuthDtos.GoogleLoginRequest r) { return auth.loginWithGoogle(r.idToken()); }

    /** Tells the app which social sign-in options are configured on this server. */
    @org.springframework.web.bind.annotation.GetMapping("/providers")
    public Map<String, Object> providers() { return auth.providers(); }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest r) { return auth.login(r); }

    @PostMapping("/refresh")
    public TokenResponse refresh(@Valid @RequestBody RefreshRequest r) { return auth.refresh(r.refreshToken()); }

    /** Revokes the refresh token and, if an access token is supplied, denylists it in Redis. */
    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest r) {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        auth.logout(r.refreshToken(), a != null && a.getPrincipal() instanceof AuthUser u ? u : null);
    }

    /** Signed-in users change their own password (required on first sign-in for accounts created by an administrator). */
    @PostMapping("/change-password")
    @io.swagger.v3.oas.annotations.security.SecurityRequirement(name = "bearer")
    public AuthResponse changePassword(@Valid @RequestBody ChangePasswordRequest r) {
        return auth.changePassword(com.wayfarer.security.CurrentUser.require().id(), r.currentPassword(), r.newPassword());
    }

    @PostMapping("/forgot-password")
    public Map<String, Object> forgot(@Valid @RequestBody ForgotPasswordRequest r) { return auth.forgotPassword(r.email()); }

    @PostMapping("/reset-password")
    public Map<String, String> reset(@Valid @RequestBody ResetPasswordRequest r) {
        auth.resetPassword(r);
        return Map.of("message", "Password updated. Please sign in.");
    }
}

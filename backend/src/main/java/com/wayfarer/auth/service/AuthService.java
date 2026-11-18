package com.wayfarer.auth.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.auth.dto.AuthDtos.AuthResponse;
import com.wayfarer.auth.dto.AuthDtos.LoginRequest;
import com.wayfarer.auth.dto.AuthDtos.RegisterRequest;
import com.wayfarer.auth.dto.AuthDtos.ResetPasswordRequest;
import com.wayfarer.auth.dto.AuthDtos.TokenResponse;
import com.wayfarer.auth.repository.PasswordResetRepository;
import com.wayfarer.auth.repository.RefreshTokenRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.config.AppProperties;
import com.wayfarer.notification.service.NotificationService;
import com.wayfarer.security.AuthUser;
import com.wayfarer.security.JwtService;
import com.wayfarer.security.TokenDenylist;
import com.wayfarer.user.repository.UserRepository;
import com.wayfarer.user.service.UserService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private static final SecureRandom RANDOM = new SecureRandom();

    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final PasswordResetRepository resets;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final AppProperties props;
    private final TokenDenylist denylist;
    private final NotificationService notifications;
    private final AuditService audit;
    private final GoogleTokenVerifier google;
    private final FirebaseTokenVerifier firebase;
    /** A real bcrypt hash compared against for unknown emails, so login timing does not reveal which emails exist. */
    private final String dummyHash;

    public AuthService(UserRepository users, RefreshTokenRepository refreshTokens, PasswordResetRepository resets, PasswordEncoder encoder, JwtService jwt,
                       AppProperties props, TokenDenylist denylist, NotificationService notifications, AuditService audit, GoogleTokenVerifier google, FirebaseTokenVerifier firebase) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.resets = resets;
        this.encoder = encoder;
        this.jwt = jwt;
        this.props = props;
        this.denylist = denylist;
        this.notifications = notifications;
        this.audit = audit;
        this.google = google;
        this.firebase = firebase;
        this.dummyHash = encoder.encode("not-a-real-password");
    }

    public static String sha256(String s) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    static String randomToken(int bytes) {
        byte[] b = new byte[bytes];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    @Transactional
    public AuthResponse register(RegisterRequest r) {
        if (users.emailTaken(r.email())) throw ApiException.conflict("EMAIL_TAKEN", "An account with this email already exists");
        // The role is never taken from the client: self-registration always yields a customer.
        Map<String, Object> u = users.insertCustomer(r.email().trim(), encoder.encode(r.password()), r.name().trim(), r.phone());
        UUID id = Rows.uuid(u, "id");
        notifications.notify(id, "account", "Welcome to WAYFARER", "Your account is ready. Start by searching a destination or asking the AI planner for an itinerary.", Map.of());
        audit.record(id, "auth.register", "user", id, Map.of());
        return respond(u);
    }

    @Transactional
    public AuthResponse login(LoginRequest r) {
        Optional<Map<String, Object>> found = users.findActiveByEmail(r.email());
        boolean ok = encoder.matches(r.password(), found.map(u -> Rows.str(u, "password_hash")).orElse(dummyHash)) && found.isPresent();
        if (!ok) throw ApiException.unauthorized("INVALID_CREDENTIALS", "Email or password is incorrect");
        return respond(found.get());
    }

    /**
     * Google sign-in. The ID token is verified against Google's published keys (signature, expiry, issuer, audience, verified email).
     * A known Google identity or an existing account with the same verified email signs in; otherwise a customer account is created.
     * Accounts created this way get a random password nobody knows, so they can only be entered through Google until the user resets it.
     */
    @Transactional
    public AuthResponse loginWithGoogle(String idToken) {
        GoogleTokenVerifier.GoogleIdentity g = google.verify(idToken);
        Map<String, Object> u = users.findByIdentity("google", g.subject()).orElse(null);
        if (u == null) {
            u = users.findActiveByEmail(g.email()).orElse(null);
            if (u == null) {
                u = users.insertCustomer(g.email(), encoder.encode(randomToken(32)), g.name(), null);
                UUID id = Rows.uuid(u, "id");
                notifications.notify(id, "account", "Welcome to WAYFARER", "Your account is ready. Start by searching a destination or asking the AI planner for an itinerary.", Map.of());
                audit.record(id, "auth.register", "user", id, Map.of("provider", "google"));
            }
            users.linkIdentity(Rows.uuid(u, "id"), "google", g.subject(), g.email());
        }
        audit.record(Rows.uuid(u, "id"), "auth.login", "user", Rows.uuid(u, "id"), Map.of("provider", "google"));
        return respond(u);
    }

    /**
     * Firebase sign-in. The Firebase ID token is verified locally (signature, expiry, issuer, audience). A known Firebase uid signs in; otherwise
     * an existing account with the same address is linked, or a customer account is created. Linking and creating need a trusted address
     * (verified by Firebase's email link, or vouched for by Google/Apple), so nobody can take over an account by registering its email unverified.
     */
    @Transactional
    public AuthResponse loginWithFirebase(String idToken) {
        FirebaseTokenVerifier.FirebaseIdentity f = firebase.verify(idToken);
        Map<String, Object> u = users.findByIdentity("firebase", f.uid()).orElse(null);
        if (u == null) {
            if (!f.trustedEmail()) {
                throw ApiException.forbidden("EMAIL_NOT_VERIFIED", "Please verify your email address first. We sent you a link; open it, then sign in again.");
            }
            u = users.findActiveByEmail(f.email()).orElse(null);
            if (u == null) {
                u = users.insertCustomer(f.email(), encoder.encode(randomToken(32)), f.name(), null);
                UUID id = Rows.uuid(u, "id");
                notifications.notify(id, "account", "Welcome to WAYFARER", "Your account is ready. Start by searching a destination or asking the AI planner for an itinerary.", Map.of());
                audit.record(id, "auth.register", "user", id, Map.of("provider", "firebase"));
            }
            users.linkIdentity(Rows.uuid(u, "id"), "firebase", f.uid(), f.email());
        }
        audit.record(Rows.uuid(u, "id"), "auth.login", "user", Rows.uuid(u, "id"), Map.of("provider", "firebase"));
        return respond(u);
    }

    public Map<String, Object> providers() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("firebase", firebase.configured() ? Map.of("enabled", true, "projectId", firebase.projectId()) : Map.of("enabled", false));
        out.put("google", google.configured() ? Map.of("enabled", true, "clientId", google.primaryClientId()) : Map.of("enabled", false));
        return out;
    }

    /** Signs in a user that another service has just created (advertiser self-registration). */
    public AuthResponse issueSession(Map<String, Object> u) { return respond(u); }

    private AuthResponse respond(Map<String, Object> u) {
        TokenResponse t = issueTokens(Rows.uuid(u, "id"), Rows.str(u, "email"), Rows.str(u, "role"), UUID.randomUUID());
        return new AuthResponse(UserService.toDto(u), t.accessToken(), t.refreshToken(), t.expiresIn(), t.tokenType());
    }

    private TokenResponse issueTokens(UUID userId, String email, String role, UUID familyId) {
        String refresh = randomToken(48);
        refreshTokens.insert(userId, familyId, sha256(refresh), Instant.now().plusSeconds(props.jwt().refreshTtlSec()));
        return new TokenResponse(jwt.issueAccessToken(userId, email, role), refresh, jwt.accessTtlSec(), "Bearer");
    }

    /** Rotates a refresh token. Re-use of an already-rotated token revokes the whole family (theft detection). */
    @Transactional(noRollbackFor = ApiException.class)
    public TokenResponse refresh(String token) {
        Map<String, Object> t = refreshTokens.findForUpdate(sha256(token)).orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH", "Invalid refresh token"));
        if (t.get("revoked_at") != null) {
            refreshTokens.revokeFamily(t.get("family_id"));
            throw ApiException.unauthorized("REFRESH_REUSED", "Refresh token was already used; please sign in again");
        }
        if (Boolean.TRUE.equals(t.get("expired")) || t.get("deleted_at") != null) throw ApiException.unauthorized("INVALID_REFRESH", "Refresh token expired");
        refreshTokens.revoke(t.get("id"));
        return issueTokens(Rows.uuid(t, "user_id"), Rows.str(t, "email"), Rows.str(t, "role"), Rows.uuid(t, "family_id"));
    }

    /** Verifies the current password, sets the new one, ends every other session and returns fresh tokens. */
    @Transactional
    public AuthResponse changePassword(UUID userId, String currentPassword, String newPassword) {
        Map<String, Object> u = users.findActiveById(userId).orElseThrow(() -> ApiException.unauthorized("UNAUTHENTICATED", "Account no longer exists"));
        if (!encoder.matches(currentPassword, Rows.str(u, "password_hash"))) throw ApiException.forbidden("INVALID_CREDENTIALS", "Your current password is incorrect");
        if (currentPassword.equals(newPassword)) throw ApiException.unprocessable("VALIDATION_ERROR", "Choose a password you have not used just now");
        users.setPassword(userId, encoder.encode(newPassword), false);
        refreshTokens.revokeAllForUser(userId);
        audit.record(userId, "auth.password_change", "user", userId, Map.of());
        return respond(users.findActiveById(userId).orElseThrow());
    }

    @Transactional
    public void logout(String refreshToken, AuthUser caller) {
        refreshTokens.revokeByHash(sha256(refreshToken));
        if (caller != null) denylist.deny(caller.jti(), caller.tokenExpiresAt());
    }

    /**
     * Password reset. No email provider is configured, so the single-use token is returned only outside production.
     * The response is identical whether or not the account exists.
     */
    @Transactional
    public Map<String, Object> forgotPassword(String email) {
        Optional<Map<String, Object>> u = users.findActiveByEmail(email);
        String devToken = null;
        if (u.isPresent()) {
            String token = randomToken(24);
            resets.insert(Rows.uuid(u.get(), "id"), sha256(token), 30);
            if (!props.prod()) devToken = token;
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("message", "If an account exists for that email, a reset link has been prepared.");
        if (devToken != null) out.put("demoResetToken", devToken);
        return out;
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest r) {
        Map<String, Object> row = resets.findUsableForUpdate(sha256(r.token()))
            .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "INVALID_RESET_TOKEN", "This reset link is invalid or has expired"));
        UUID userId = Rows.uuid(row, "user_id");
        users.setPassword(userId, encoder.encode(r.password()));
        resets.markUsed(row.get("id"));
        refreshTokens.revokeAllForUser(userId);
        audit.record(userId, "auth.password_reset", "user", userId, Map.of());
    }
}

package com.wayfarer.user.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.auth.repository.RefreshTokenRepository;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.media.service.MediaService;
import org.springframework.web.multipart.MultipartFile;
import com.wayfarer.user.dto.UserDtos.CreateUserRequest;
import com.wayfarer.user.dto.UserDtos.DeleteAccountRequest;
import com.wayfarer.user.dto.UserDtos.UpdateProfileRequest;
import com.wayfarer.user.dto.UserDtos.UserDto;
import com.wayfarer.user.repository.UserRepository;
import java.security.SecureRandom;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz", DIGITS = "23456789";

    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final BookingRepository bookings;
    private final PasswordEncoder encoder;
    private final AuditService audit;
    private final MediaService media;

    public UserService(UserRepository users, RefreshTokenRepository refreshTokens, BookingRepository bookings, PasswordEncoder encoder, AuditService audit, MediaService media) {
        this.media = media;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.bookings = bookings;
        this.encoder = encoder;
        this.audit = audit;
    }

    /** 12 characters, no look-alike characters, always at least one letter and one digit. */
    static String temporaryPassword() {
        char[] c = new char[12];
        for (int i = 0; i < c.length; i++) c[i] = (i % 4 == 3 ? DIGITS : LETTERS).charAt(RANDOM.nextInt((i % 4 == 3 ? DIGITS : LETTERS).length()));
        for (int i = c.length - 1; i > 0; i--) { int j = RANDOM.nextInt(i + 1); char t = c[i]; c[i] = c[j]; c[j] = t; }
        return new String(c);
    }

    public static UserDto toDto(Map<String, Object> u) {
        return new UserDto(Rows.uuid(u, "id"), Rows.str(u, "email"), Rows.str(u, "name"), Rows.str(u, "phone"), Rows.str(u, "role"),
            Rows.str(u, "preferred_currency"), Boolean.TRUE.equals(u.get("is_demo")), Rows.instant(u, "created_at"), Boolean.TRUE.equals(u.get("must_change_password")), !Boolean.TRUE.equals(u.get("social_only")), Rows.str(u, "avatar_url"));
    }

    private UserDto withAuthMethod(Map<String, Object> u) {
        Map<String, Object> m = new LinkedHashMap<>(u);
        m.put("social_only", users.hasIdentity(Rows.uuid(u, "id")));
        return toDto(m);
    }

    public UserDto me(UUID id) {
        return users.findActiveById(id).map(this::withAuthMethod).orElseThrow(() -> ApiException.unauthorized("UNAUTHENTICATED", "Account no longer exists"));
    }

    @Transactional
    public UserDto update(UUID id, UpdateProfileRequest r) {
        String currency = r.preferredCurrency() == null ? null : r.preferredCurrency().toUpperCase();
        if (currency != null && !users.currencyExists(currency)) throw ApiException.unprocessable("VALIDATION_ERROR", "Unsupported currency");
        return withAuthMethod(users.updateProfile(id, r.name(), r.phone(), currency));
    }

    /** Stores the uploaded image and makes it the profile photo; the previous photo is removed. */
    @Transactional
    public UserDto setAvatar(UUID id, MultipartFile file) {
        Map<String, Object> stored = media.store(id, file);
        String old = Rows.str(users.findById(id).orElseThrow(), "avatar_url");
        Map<String, Object> u = users.setAvatar(id, (String) stored.get("url"));
        media.deleteByUrl(id, old);
        return withAuthMethod(u);
    }

    @Transactional
    public UserDto removeAvatar(UUID id) {
        String old = Rows.str(users.findById(id).orElseThrow(), "avatar_url");
        Map<String, Object> u = users.setAvatar(id, null);
        media.deleteByUrl(id, old);
        return withAuthMethod(u);
    }

    @Transactional
    public void delete(UUID id, DeleteAccountRequest r) {
        Map<String, Object> u = users.findById(id).orElseThrow();
        boolean socialOnly = users.hasIdentity(id);
        if (!socialOnly && (r.password() == null || !encoder.matches(r.password(), Rows.str(u, "password_hash")))) throw ApiException.forbidden("INVALID_CREDENTIALS", "Password is incorrect");
        if (bookings.userHasActive(id)) throw ApiException.conflict("ACTIVE_BOOKINGS", "Cancel or complete your active bookings before deleting your account.");
        String avatar = Rows.str(u, "avatar_url");
        users.anonymise(id);
        media.deleteByUrl(id, avatar);
        refreshTokens.revokeAllForUser(id);
        audit.record(id, "account.delete", "user", id, Map.of());
    }

    // ---- staff operations
    public Map<String, Object> search(String q, String role, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(users.search(q, role, size, Pages.offset(p, size)), p, size);
    }

    @Transactional
    public void changeRole(UUID actorId, UUID targetId, String role) {
        if (actorId.equals(targetId)) throw ApiException.conflict("SELF_ROLE_CHANGE", "You cannot change your own role.");
        users.setRole(targetId, role).orElseThrow(() -> ApiException.notFound("User"));
        refreshTokens.revokeAllForUser(targetId);       // force a fresh sign-in under the new role
        audit.record(actorId, "user.role_change", "user", targetId, Map.of("role", role));
    }

    @Transactional
    public Map<String, Object> createByAdmin(UUID actorId, CreateUserRequest r) {
        String email = r.email().trim();
        if (users.emailTaken(email)) throw ApiException.conflict("EMAIL_TAKEN", "An account with this email already exists");
        boolean customPw = r.password() != null && !r.password().isBlank();
        String chosenPw = customPw ? r.password() : temporaryPassword();
        String phone = (r.phone() == null || r.phone().isBlank()) ? null : r.phone().trim();
        Map<String, Object> u = users.insertManagedUser(email, encoder.encode(chosenPw), r.name().trim(), phone, r.role(), !customPw);
        UUID userId = Rows.uuid(u, "id");
        audit.record(actorId, "user.create", "user", userId, Map.of("email", email, "role", r.role()));
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("id", userId);
        out.put("name", Rows.str(u, "name"));
        out.put("email", Rows.str(u, "email"));
        out.put("phone", Rows.str(u, "phone"));
        out.put("role", Rows.str(u, "role"));
        out.put("temporaryPassword", chosenPw);
        out.put("customPassword", customPw);
        out.put("notice", customPw
            ? "Account created with the password you set. Give these sign-in credentials to the user."
            : "Give these credentials to the user. The temporary password is shown only once and must be changed at first sign-in.");
        return out;
    }

    @Transactional
    public Map<String, Object> resetPasswordByAdmin(UUID actorId, UUID targetId) {
        if (actorId.equals(targetId)) throw ApiException.conflict("SELF_PASSWORD_RESET", "Use the Account page to change your own password.");
        Map<String, Object> u = users.findActiveById(targetId).orElseThrow(() -> ApiException.notFound("User"));
        String temp = temporaryPassword();
        users.setPassword(targetId, encoder.encode(temp), true);
        refreshTokens.revokeAllForUser(targetId);
        audit.record(actorId, "user.password_reset", "user", targetId, Map.of("email", Rows.str(u, "email"), "role", Rows.str(u, "role")));
        return Map.of(
            "id", targetId,
            "name", Rows.str(u, "name"),
            "email", Rows.str(u, "email"),
            "role", Rows.str(u, "role"),
            "temporaryPassword", temp,
            "notice", "Shown only once. The user is signed out everywhere and must set a new password at next sign-in."
        );
    }
}

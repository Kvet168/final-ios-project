package com.wayfarer.user.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.auth.repository.RefreshTokenRepository;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.user.dto.UserDtos.DeleteAccountRequest;
import com.wayfarer.user.dto.UserDtos.UpdateProfileRequest;
import com.wayfarer.user.dto.UserDtos.UserDto;
import com.wayfarer.user.repository.UserRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {
    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final BookingRepository bookings;
    private final PasswordEncoder encoder;
    private final AuditService audit;

    public UserService(UserRepository users, RefreshTokenRepository refreshTokens, BookingRepository bookings, PasswordEncoder encoder, AuditService audit) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.bookings = bookings;
        this.encoder = encoder;
        this.audit = audit;
    }

    public static UserDto toDto(Map<String, Object> u) {
        return new UserDto(Rows.uuid(u, "id"), Rows.str(u, "email"), Rows.str(u, "name"), Rows.str(u, "phone"), Rows.str(u, "role"),
            Rows.str(u, "preferred_currency"), Boolean.TRUE.equals(u.get("is_demo")), Rows.instant(u, "created_at"), Boolean.TRUE.equals(u.get("must_change_password")));
    }

    public UserDto me(UUID id) {
        return users.findActiveById(id).map(UserService::toDto).orElseThrow(() -> ApiException.unauthorized("UNAUTHENTICATED", "Account no longer exists"));
    }

    @Transactional
    public UserDto update(UUID id, UpdateProfileRequest r) {
        String currency = r.preferredCurrency() == null ? null : r.preferredCurrency().toUpperCase();
        if (currency != null && !users.currencyExists(currency)) throw ApiException.unprocessable("VALIDATION_ERROR", "Unsupported currency");
        return toDto(users.updateProfile(id, r.name(), r.phone(), currency));
    }

    @Transactional
    public void delete(UUID id, DeleteAccountRequest r) {
        Map<String, Object> u = users.findById(id).orElseThrow();
        if (!encoder.matches(r.password(), Rows.str(u, "password_hash"))) throw ApiException.forbidden("INVALID_CREDENTIALS", "Password is incorrect");
        if (bookings.userHasActive(id)) throw ApiException.conflict("ACTIVE_BOOKINGS", "Cancel or complete your active bookings before deleting your account.");
        users.anonymise(id);
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
}

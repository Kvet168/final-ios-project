package com.wayfarer.partner.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.auth.repository.RefreshTokenRepository;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Pages;
import com.wayfarer.common.Rows;
import com.wayfarer.common.Text;
import com.wayfarer.partner.dto.PartnerDtos.CreatePartnerRequest;
import com.wayfarer.partner.repository.PartnerRepository;
import com.wayfarer.user.repository.UserRepository;
import java.security.SecureRandom;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Administrator-side partner management: create the owner login and organisation, hand over a one-time temporary password,
 * and read (never edit) their properties. Pricing, rooms and stock belong to the partner.
 */
@Service
public class PartnerAccountService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz", DIGITS = "23456789";

    private final PartnerRepository partners;
    private final UserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final AccommodationRepository accommodations;
    private final PasswordEncoder encoder;
    private final AuditService audit;

    public PartnerAccountService(PartnerRepository partners, UserRepository users, RefreshTokenRepository refreshTokens, AccommodationRepository accommodations,
                                 PasswordEncoder encoder, AuditService audit) {
        this.partners = partners;
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.accommodations = accommodations;
        this.encoder = encoder;
        this.audit = audit;
    }

    /** 12 characters, no look-alike characters, always at least one letter and one digit (meets the password rule). */
    static String temporaryPassword() {
        char[] c = new char[12];
        for (int i = 0; i < c.length; i++) c[i] = (i % 4 == 3 ? DIGITS : LETTERS).charAt(RANDOM.nextInt((i % 4 == 3 ? DIGITS : LETTERS).length()));
        for (int i = c.length - 1; i > 0; i--) { int j = RANDOM.nextInt(i + 1); char t = c[i]; c[i] = c[j]; c[j] = t; }
        return new String(c);
    }

    @Transactional
    public Map<String, Object> create(UUID actor, CreatePartnerRequest r) {
        if (users.emailTaken(r.email())) throw ApiException.conflict("EMAIL_TAKEN", "An account with this email already exists");
        String temp = temporaryPassword();
        Map<String, Object> u = users.insertPartnerUser(r.email().trim(), encoder.encode(temp), r.ownerName().trim(), r.phone());
        UUID partnerId = partners.insert(Rows.uuid(u, "id"), r.businessName().trim(), r.phone());
        audit.record(actor, "partner.create", "partner", partnerId, Map.of("owner", r.email(), "business", r.businessName()));
        Map<String, Object> out = new LinkedHashMap<>(partners.findDetail(partnerId).orElseThrow());
        out.put("temporaryPassword", temp);
        out.put("notice", "Give these credentials to the partner. The password is shown only once and must be changed at first sign-in.");
        return out;
    }

    @Transactional
    public Map<String, Object> resetPassword(UUID actor, UUID partnerId) {
        Map<String, Object> p = partners.findDetail(partnerId).orElseThrow(() -> ApiException.notFound("Partner"));
        String temp = temporaryPassword();
        users.setPassword(Rows.uuid(p, "user_id"), encoder.encode(temp), true);
        refreshTokens.revokeAllForUser(p.get("user_id"));
        audit.record(actor, "partner.password_reset", "partner", partnerId, Map.of());
        return Map.of("temporaryPassword", temp, "ownerEmail", p.get("owner_email"), "notice", "Shown only once. The partner must change it at next sign-in.");
    }

    public Map<String, Object> list(String q, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(partners.list(q == null || q.isBlank() ? null : Text.like(q), size, Pages.offset(p, size)), p, size);
    }

    public Map<String, Object> detail(UUID partnerId) {
        Map<String, Object> out = new LinkedHashMap<>(partners.findDetail(partnerId).orElseThrow(() -> ApiException.notFound("Partner")));
        out.remove("payment_qr_media_id");
        out.put("hotels", partners.hotelsOf(partnerId));
        return out;
    }

    /** Read-only catalogue of every property (hotels, hostels, bungalows, resorts ...). */
    public Map<String, Object> hotels(String q, String type, UUID partnerId, int page, int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(accommodations.adminList(q == null || q.isBlank() ? null : Text.like(q), type, partnerId, size, Pages.offset(p, size)), p, size);
    }
}

package com.wayfarer.partner.web;

import com.wayfarer.partner.dto.PartnerDtos.CreatePartnerRequest;
import com.wayfarer.partner.service.PartnerAccountService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Administrator's view of partners and properties. Creating partner accounts is admin-only; everything else here is read-only. */
@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin partners")
public class PartnerAdminController {
    private final PartnerAccountService accounts;

    public PartnerAdminController(PartnerAccountService accounts) { this.accounts = accounts; }

    @GetMapping("/partners")
    public Map<String, Object> list(@RequestParam(required = false) String q, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return accounts.list(q, page, pageSize);
    }

    @GetMapping("/partners/{id}")
    public Map<String, Object> detail(@PathVariable UUID id) { return accounts.detail(id); }

    @PostMapping("/partners")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CreatePartnerRequest r) { return accounts.create(CurrentUser.require().id(), r); }

    @PostMapping("/partners/{id}/reset-password")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> resetPassword(@PathVariable UUID id) { return accounts.resetPassword(CurrentUser.require().id(), id); }

    @GetMapping("/hotels")
    public Map<String, Object> hotels(@RequestParam(required = false) String q, @RequestParam(required = false) String type, @RequestParam(required = false) UUID partnerId,
                                      @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return accounts.hotels(q, type, partnerId, page, pageSize);
    }
}

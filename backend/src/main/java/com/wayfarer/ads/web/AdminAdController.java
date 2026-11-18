package com.wayfarer.ads.web;

import com.wayfarer.ads.dto.AdDtos.DecisionRequest;
import com.wayfarer.ads.dto.AdDtos.NewPackageRequest;
import com.wayfarer.ads.dto.AdDtos.PackageRequest;
import com.wayfarer.ads.dto.AdDtos.ReasonRequest;
import com.wayfarer.ads.dto.AdDtos.RescheduleRequest;
import com.wayfarer.ads.dto.AdDtos.SettingsRequest;
import com.wayfarer.ads.dto.AdDtos.VerifyPaymentRequest;
import com.wayfarer.ads.service.AdminAdService;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Advertising administration. URL rule: STAFF and ADMIN (SecurityConfig). Pricing, packages, payment settings and payment verification
 * need the ADMIN role: staff review businesses and content but cannot change what is charged or confirm that money arrived.
 */
@RestController
@RequestMapping("/api/admin/ads")
@Tag(name = "Advertising (admin)")
public class AdminAdController {
    private final AdminAdService service;

    public AdminAdController(AdminAdService service) { this.service = service; }

    @GetMapping("/analytics")
    public Map<String, Object> analytics() { return service.analytics(); }

    /* businesses */
    @GetMapping("/businesses")
    public Map<String, Object> businesses(@RequestParam(required = false) String status, @RequestParam(required = false) String q,
                                          @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return service.businesses(status, q, page, pageSize);
    }

    @GetMapping("/businesses/{id}")
    public Map<String, Object> business(@PathVariable UUID id) { return service.businessDetail(id); }

    @PostMapping("/businesses/{id}/verify")
    public Map<String, Object> verify(@PathVariable UUID id, @RequestBody(required = false) @Valid DecisionRequest r) {
        return service.verifyBusiness(CurrentUser.require().id(), id, "verified", r == null ? null : r.note());
    }

    @PostMapping("/businesses/{id}/reject")
    public Map<String, Object> rejectBusiness(@PathVariable UUID id, @Valid @RequestBody ReasonRequest r) { return service.verifyBusiness(CurrentUser.require().id(), id, "rejected", r.reason()); }

    @PostMapping("/businesses/{id}/suspend")
    public Map<String, Object> suspend(@PathVariable UUID id, @Valid @RequestBody ReasonRequest r) { return service.verifyBusiness(CurrentUser.require().id(), id, "suspended", r.reason()); }

    /* campaigns */
    @GetMapping("/campaigns")
    public Map<String, Object> campaigns(@RequestParam(required = false) String status, @RequestParam(required = false) String placement, @RequestParam(required = false) String q,
                                         @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return service.campaigns(status, placement, q, page, pageSize);
    }

    @GetMapping("/campaigns/{id}")
    public Map<String, Object> campaign(@PathVariable UUID id) { return service.campaignDetail(id); }

    @PostMapping("/campaigns/{id}/approve")
    public Map<String, Object> approve(@PathVariable UUID id, @RequestBody(required = false) @Valid DecisionRequest r) { return service.approve(CurrentUser.require().id(), id, r == null ? null : r.note()); }

    @PostMapping("/campaigns/{id}/reject")
    public Map<String, Object> reject(@PathVariable UUID id, @Valid @RequestBody ReasonRequest r) { return service.reject(CurrentUser.require().id(), id, r.reason()); }

    @PostMapping("/campaigns/{id}/pause")
    public Map<String, Object> pause(@PathVariable UUID id, @RequestBody(required = false) @Valid DecisionRequest r) { return service.pause(CurrentUser.require().id(), id, r == null ? null : r.note()); }

    @PostMapping("/campaigns/{id}/resume")
    public Map<String, Object> resume(@PathVariable UUID id) { return service.resume(CurrentUser.require().id(), id); }

    @PostMapping("/campaigns/{id}/cancel")
    public Map<String, Object> cancel(@PathVariable UUID id, @RequestBody(required = false) @Valid DecisionRequest r) { return service.cancel(CurrentUser.require().id(), id, r == null ? null : r.note()); }

    @PostMapping("/campaigns/{id}/reschedule")
    public Map<String, Object> reschedule(@PathVariable UUID id, @Valid @RequestBody RescheduleRequest r) { return service.reschedule(CurrentUser.require().id(), id, r.startDate()); }

    @GetMapping("/placements")
    public Map<String, Object> placements(@RequestParam(defaultValue = "28") int days) { return service.placements(days); }

    /* payments */
    @GetMapping("/payments")
    public Map<String, Object> payments(@RequestParam(required = false) String status, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return service.payments(status, page, pageSize);
    }

    @PostMapping("/payments/{id}/verify")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> verifyPayment(@PathVariable UUID id, @Valid @RequestBody VerifyPaymentRequest r) { return service.verifyPayment(CurrentUser.require().id(), id, r); }

    @PostMapping("/payments/{id}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> rejectPayment(@PathVariable UUID id, @Valid @RequestBody ReasonRequest r) { return service.rejectPayment(CurrentUser.require().id(), id, r.reason()); }

    /* packages and payment settings */
    @GetMapping("/packages")
    public Map<String, Object> packages() { return service.packages(); }

    @PutMapping("/packages/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> updatePackage(@PathVariable UUID id, @Valid @RequestBody PackageRequest r) { return service.updatePackage(CurrentUser.require().id(), id, r); }

    @PostMapping("/packages")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> createPackage(@Valid @RequestBody NewPackageRequest r) { return service.createPackage(CurrentUser.require().id(), r); }

    @GetMapping("/settings")
    public Map<String, Object> settings() { return service.settings(); }

    @PutMapping("/settings")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> updateSettings(@Valid @RequestBody SettingsRequest r) { return service.updateSettings(CurrentUser.require().id(), r); }
}

package com.wayfarer.ads.web;

import com.wayfarer.ads.dto.AdDtos.BusinessProfileRequest;
import com.wayfarer.ads.dto.AdDtos.BusinessRegisterRequest;
import com.wayfarer.ads.dto.AdDtos.CampaignRequest;
import com.wayfarer.ads.dto.AdDtos.ClaimRequest;
import com.wayfarer.ads.dto.AdDtos.PaymentRequest;
import com.wayfarer.ads.dto.AdDtos.QuoteRequest;
import com.wayfarer.ads.dto.AdDtos.RenewRequest;
import com.wayfarer.ads.service.BusinessAdService;
import com.wayfarer.auth.dto.AuthDtos.AuthResponse;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Business owner API. URL rule: roles BUSINESS and PARTNER only (SecurityConfig); every record is additionally checked to belong to the caller's business. */
@RestController
@RequestMapping("/api/business")
@Tag(name = "Business advertising")
public class BusinessAdController {
    private final BusinessAdService service;

    public BusinessAdController(BusinessAdService service) { this.service = service; }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    @SecurityRequirements
    public AuthResponse register(@Valid @RequestBody BusinessRegisterRequest r) { return service.register(r); }

    @GetMapping("/profile")
    public Map<String, Object> profile() { return service.business(CurrentUser.require()); }

    @PutMapping("/profile")
    public Map<String, Object> updateProfile(@Valid @RequestBody BusinessProfileRequest r) { return service.updateProfile(CurrentUser.require(), r); }

    @GetMapping("/packages")
    public Map<String, Object> packages() { return service.packages(); }

    @PostMapping("/quote")
    public Map<String, Object> quote(@Valid @RequestBody QuoteRequest r) { return service.quote(CurrentUser.require(), r); }

    @GetMapping("/campaigns")
    public Map<String, Object> campaigns() { return service.campaigns(CurrentUser.require()); }

    @PostMapping("/campaigns")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> create(@Valid @RequestBody CampaignRequest r) { return service.create(CurrentUser.require(), r); }

    @GetMapping("/campaigns/{id}")
    public Map<String, Object> campaign(@PathVariable UUID id) { return service.campaign(CurrentUser.require(), id); }

    @PutMapping("/campaigns/{id}")
    public Map<String, Object> update(@PathVariable UUID id, @Valid @RequestBody CampaignRequest r) { return service.update(CurrentUser.require(), id, r); }

    @PostMapping("/campaigns/{id}/submit")
    public Map<String, Object> submit(@PathVariable UUID id) { return service.submit(CurrentUser.require(), id); }

    @PostMapping("/campaigns/{id}/cancel")
    public Map<String, Object> cancel(@PathVariable UUID id) { return service.cancel(CurrentUser.require(), id); }

    @PostMapping("/campaigns/{id}/renew")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> renew(@PathVariable UUID id, @Valid @RequestBody(required = false) RenewRequest r) { return service.renew(CurrentUser.require(), id, r); }

    @GetMapping("/payment-info")
    public Map<String, Object> paymentInfo() { return service.paymentInfo(); }

    @PostMapping("/campaigns/{id}/payment")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> startPayment(@PathVariable UUID id, @Valid @RequestBody PaymentRequest r) { return service.startPayment(CurrentUser.require(), id, r); }

    @PostMapping("/payments/{id}/claim")
    public Map<String, Object> claim(@PathVariable UUID id, @Valid @RequestBody ClaimRequest r) { return service.claimPayment(CurrentUser.require(), id, r); }

    @GetMapping("/payments")
    public Map<String, Object> payments() { return service.payments(CurrentUser.require()); }

    @GetMapping("/analytics")
    public Map<String, Object> analytics() { return service.analytics(CurrentUser.require()); }
}

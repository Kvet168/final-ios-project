package com.wayfarer.admin.web;

import com.wayfarer.admin.service.DashboardService;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.dto.BookingDtos.TransitionRequest;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.booking.service.BookingService;
import com.wayfarer.common.Pages;
import com.wayfarer.payment.repository.PaymentRepository;
import com.wayfarer.review.dto.ReviewDtos.ModerateRequest;
import com.wayfarer.review.service.ReviewService;
import com.wayfarer.security.CurrentUser;
import com.wayfarer.user.dto.UserDtos.CreateUserRequest;
import com.wayfarer.user.dto.UserDtos.RoleRequest;
import com.wayfarer.user.service.UserService;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Staff and admin console. URL rule: STAFF or ADMIN (SecurityConfig). Role changes need ADMIN (method-level rule). */
@RestController
@RequestMapping("/api/admin")
@Tag(name = "Admin")
public class AdminController {
    private final DashboardService dashboard;
    private final UserService users;
    private final BookingService bookings;
    private final BookingRepository bookingRepository;
    private final PaymentRepository payments;
    private final ReviewService reviews;
    private final AuditService audit;

    public AdminController(DashboardService dashboard, UserService users, BookingService bookings, BookingRepository bookingRepository, PaymentRepository payments,
                           ReviewService reviews, AuditService audit) {
        this.dashboard = dashboard;
        this.users = users;
        this.bookings = bookings;
        this.bookingRepository = bookingRepository;
        this.payments = payments;
        this.reviews = reviews;
        this.audit = audit;
    }

    @GetMapping("/overview")
    public Map<String, Object> overview() { return dashboard.overview(); }

    @GetMapping("/users")
    public Map<String, Object> users(@RequestParam(required = false) String q, @RequestParam(required = false) String role,
                                     @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return users.search(q, role, page, pageSize);
    }

    @PatchMapping("/users/{id}/role")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void setRole(@PathVariable UUID id, @Valid @RequestBody RoleRequest r) { users.changeRole(CurrentUser.require().id(), id, r.role()); }

    @DeleteMapping("/users/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable UUID id) { users.deleteByAdmin(CurrentUser.require().id(), id); }

    @PostMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> createUser(@Valid @RequestBody CreateUserRequest r) {
        return users.createByAdmin(CurrentUser.require().id(), r);
    }

    @PostMapping("/users/{id}/reset-password")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, Object> resetUserPassword(@PathVariable UUID id) {
        return users.resetPasswordByAdmin(CurrentUser.require().id(), id);
    }

    @GetMapping("/bookings")
    public Map<String, Object> bookingsList(@RequestParam(required = false) String status, @RequestParam(required = false) String q,
                                            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(bookingRepository.search(status, q, null, false, size, Pages.offset(p, size)), p, size);
    }

    @GetMapping("/bookings/{id}")
    public Map<String, Object> bookingDetail(@PathVariable UUID id) { return bookings.detail(id, CurrentUser.require()); }

    @PostMapping("/bookings/{id}/cancel")
    public Map<String, Object> cancel(@PathVariable UUID id) { return bookings.cancel(id, CurrentUser.require().id(), true); }

    @PostMapping("/bookings/{id}/transition")
    public Map<String, Object> transition(@PathVariable UUID id, @Valid @RequestBody TransitionRequest r) {
        return bookings.staffTransition(id, r.to(), CurrentUser.require().id(), r.note(), null, "staff");
    }

    @GetMapping("/payments")
    public Map<String, Object> payments(@RequestParam(required = false) String status, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        int size = Pages.clampSize(pageSize, 100), p = Pages.clampPage(page);
        return Pages.of(payments.search(status, size, Pages.offset(p, size)), p, size);
    }

    @GetMapping("/audit-logs")
    public Map<String, Object> auditLogs(@RequestParam(required = false) String action, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "50") int pageSize) {
        return audit.search(action, page, pageSize);
    }

    @GetMapping("/reviews")
    public Map<String, Object> reviews(@RequestParam(required = false) String status, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return reviews.moderationList(status, page, pageSize);
    }

    @PatchMapping("/reviews/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void moderate(@PathVariable UUID id, @Valid @RequestBody ModerateRequest r) { reviews.moderate(CurrentUser.require().id(), id, r.status()); }

    @GetMapping("/ai-usage")
    public Map<String, Object> aiUsage() { return dashboard.aiUsage(); }
}

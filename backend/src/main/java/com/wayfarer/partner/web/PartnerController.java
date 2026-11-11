package com.wayfarer.partner.web;

import com.wayfarer.admin.dto.AdminDtos.AccommodationPatch;
import com.wayfarer.admin.dto.AdminDtos.AccommodationRequest;
import com.wayfarer.admin.dto.AdminDtos.InventoryRequest;
import com.wayfarer.admin.dto.AdminDtos.RoomPatch;
import com.wayfarer.admin.dto.AdminDtos.RoomRequest;
import com.wayfarer.booking.dto.BookingDtos.TransitionRequest;
import com.wayfarer.partner.dto.PartnerDtos.DecisionRequest;
import com.wayfarer.partner.dto.PartnerDtos.ImageRequest;
import com.wayfarer.partner.dto.PartnerDtos.ProfileRequest;
import com.wayfarer.partner.service.PartnerService;
import com.wayfarer.partner.service.PropertyService;
import com.wayfarer.security.CurrentUser;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Hotel/partner dashboard API. URL rule: PARTNER only (SecurityConfig); every record is additionally checked to belong to the caller. */
@RestController
@RequestMapping("/api/partner")
@Tag(name = "Partner")
public class PartnerController {
    private final PartnerService partner;
    private final PropertyService properties;

    public PartnerController(PartnerService partner, PropertyService properties) {
        this.partner = partner;
        this.properties = properties;
    }

    /* organisation and QR payment settings */
    @GetMapping("/profile")
    public Map<String, Object> profile() { return partner.profile(CurrentUser.require()); }

    @PutMapping("/profile")
    public Map<String, Object> updateProfile(@Valid @RequestBody ProfileRequest r) { return partner.updateProfile(CurrentUser.require(), r); }

    /* properties */
    @GetMapping("/accommodations")
    public Map<String, Object> accommodations() { return partner.accommodations(CurrentUser.require()); }

    @PostMapping("/accommodations")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> createAccommodation(@Valid @RequestBody AccommodationRequest r) { return Map.of("id", properties.create(CurrentUser.require().id(), r)); }

    @PatchMapping("/accommodations/{id}")
    public Map<String, Object> updateAccommodation(@PathVariable UUID id, @Valid @RequestBody AccommodationPatch r) { return properties.update(CurrentUser.require().id(), id, r); }

    @DeleteMapping("/accommodations/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAccommodation(@PathVariable UUID id) { properties.delete(CurrentUser.require().id(), id); }

    @PostMapping("/accommodations/{id}/rooms")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addRoom(@PathVariable UUID id, @Valid @RequestBody RoomRequest r) { return properties.addRoom(CurrentUser.require().id(), id, r); }

    @PostMapping("/accommodations/{id}/images")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> addImage(@PathVariable UUID id, @Valid @RequestBody ImageRequest r) { return properties.addImage(CurrentUser.require().id(), id, r); }

    @DeleteMapping("/accommodations/{id}/images/{imageId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeImage(@PathVariable UUID id, @PathVariable UUID imageId) { properties.removeImage(CurrentUser.require().id(), id, imageId); }

    /* rooms, stock and prices */
    @PatchMapping("/room-types/{id}")
    public Map<String, Object> updateRoom(@PathVariable UUID id, @Valid @RequestBody RoomPatch r) { return properties.updateRoom(CurrentUser.require().id(), id, r); }

    @DeleteMapping("/room-types/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteRoom(@PathVariable UUID id) { properties.deleteRoom(CurrentUser.require().id(), id); }

    @PutMapping("/room-types/{id}/inventory")
    public Map<String, Object> inventory(@PathVariable UUID id, @Valid @RequestBody InventoryRequest r) { return partner.inventory(CurrentUser.require(), id, r); }

    /* bookings */
    @GetMapping("/bookings")
    public Map<String, Object> bookings(@RequestParam(required = false) String status, @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return partner.bookings(CurrentUser.require(), status, page, pageSize);
    }

    @PostMapping("/bookings/{id}/transition")
    public Map<String, Object> transition(@PathVariable UUID id, @Valid @RequestBody TransitionRequest r) { return partner.transition(CurrentUser.require(), id, r.to(), r.note()); }

    @PostMapping("/bookings/{id}/cancel")
    public Map<String, Object> cancelBooking(@PathVariable UUID id) { return partner.cancelBooking(CurrentUser.require(), id); }

    /* QR payments */
    @GetMapping("/payments")
    public Map<String, Object> payments(@RequestParam(required = false) String status, @RequestParam(required = false) String method,
                                        @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) {
        return partner.payments(CurrentUser.require(), status, method, page, pageSize);
    }

    @PostMapping("/payments/{id}/confirm")
    public Map<String, Object> confirm(@PathVariable UUID id) { return partner.confirmPayment(CurrentUser.require(), id); }

    @PostMapping("/payments/{id}/reject")
    public Map<String, Object> reject(@PathVariable UUID id, @RequestBody(required = false) @Valid DecisionRequest r) {
        return partner.rejectPayment(CurrentUser.require(), id, r == null ? null : r.reason());
    }

    /* insight */
    @GetMapping("/analytics")
    public Map<String, Object> analytics() { return partner.analytics(CurrentUser.require()); }

    @GetMapping("/reviews")
    public Map<String, Object> reviews(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "20") int pageSize) { return partner.reviews(CurrentUser.require(), page, pageSize); }
}

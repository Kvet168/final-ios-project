package com.wayfarer.booking.dto;

import com.wayfarer.booking.domain.BookingStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.UUID;

public final class BookingDtos {
    private BookingDtos() {}

    public record QuoteRequest(@NotNull UUID roomTypeId, @NotNull LocalDate checkIn, @NotNull LocalDate checkOut,
                               @Min(1) @Max(8) Integer rooms) {
        public int roomsOrDefault() { return rooms == null ? 1 : rooms; }
    }

    public record CreateBookingRequest(@NotNull UUID roomTypeId, @NotNull LocalDate checkIn, @NotNull LocalDate checkOut,
                                       @Min(1) @Max(8) Integer rooms, @NotNull @Min(1) @Max(20) Integer adults,
                                       @Min(0) @Max(10) Integer children,
                                       @NotBlank @Size(min = 2, max = 100) String guestName,
                                       @NotBlank @Email @Size(max = 160) String guestEmail,
                                       @Size(max = 30) String guestPhone, @Size(max = 500) String specialRequests) {
        public int roomsOrDefault() { return rooms == null ? 1 : rooms; }
        public int childrenOrDefault() { return children == null ? 0 : children; }
    }

    /** Body of PATCH /api/orders/{id}/status. */
    public record StatusRequest(@NotNull BookingStatus status, @Size(max = 200) String note) {}

    /** Body of the admin and partner transition endpoints: staff may only move a stay forward on site. */
    public record TransitionRequest(@NotNull BookingStatus to, @Size(max = 200) String note) {}
}

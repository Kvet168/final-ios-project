package com.wayfarer.booking.domain;

import java.util.EnumSet;
import java.util.Set;

/** Booking lifecycle. Legal transitions are enforced server-side; clients never set a status directly. */
public enum BookingStatus {
    DRAFT, PENDING_CONFIRMATION, CONFIRMED, CHECKED_IN, COMPLETED, CANCELLED, EXPIRED, REFUND_PENDING, REFUNDED;

    public Set<BookingStatus> next() {
        return switch (this) {
            case DRAFT -> EnumSet.of(PENDING_CONFIRMATION, CANCELLED);
            case PENDING_CONFIRMATION -> EnumSet.of(CONFIRMED, CANCELLED, EXPIRED);
            case CONFIRMED -> EnumSet.of(CHECKED_IN, CANCELLED);
            case CHECKED_IN -> EnumSet.of(COMPLETED);
            case CANCELLED -> EnumSet.of(REFUND_PENDING);
            case REFUND_PENDING -> EnumSet.of(REFUNDED);
            case COMPLETED, EXPIRED, REFUNDED -> EnumSet.noneOf(BookingStatus.class);
        };
    }

    public boolean canMoveTo(BookingStatus to) { return next().contains(to); }

    public boolean isCancellable() { return this == PENDING_CONFIRMATION || this == CONFIRMED; }
}

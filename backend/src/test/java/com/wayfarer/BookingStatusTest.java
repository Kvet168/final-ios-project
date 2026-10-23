package com.wayfarer;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.booking.domain.BookingStatus;
import org.junit.jupiter.api.Test;

class BookingStatusTest {
    @Test
    void happyPathIsLegal() {
        assertTrue(BookingStatus.PENDING_CONFIRMATION.canMoveTo(BookingStatus.CONFIRMED));
        assertTrue(BookingStatus.CONFIRMED.canMoveTo(BookingStatus.CHECKED_IN));
        assertTrue(BookingStatus.CHECKED_IN.canMoveTo(BookingStatus.COMPLETED));
    }

    @Test
    void illegalJumpsAreRejected() {
        assertFalse(BookingStatus.PENDING_CONFIRMATION.canMoveTo(BookingStatus.COMPLETED));
        assertFalse(BookingStatus.CONFIRMED.canMoveTo(BookingStatus.PENDING_CONFIRMATION));
        assertFalse(BookingStatus.COMPLETED.canMoveTo(BookingStatus.CANCELLED));
    }

    @Test
    void terminalStatesHaveNoExits() {
        for (BookingStatus s : new BookingStatus[] {BookingStatus.COMPLETED, BookingStatus.EXPIRED, BookingStatus.REFUNDED}) {
            assertTrue(s.next().isEmpty(), s + " should be terminal");
        }
    }

    @Test
    void onlyPendingAndConfirmedAreCancellable() {
        for (BookingStatus s : BookingStatus.values()) {
            assertEquals(s == BookingStatus.PENDING_CONFIRMATION || s == BookingStatus.CONFIRMED, s.isCancellable(), s.name());
        }
    }
}

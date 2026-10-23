package com.wayfarer;

import static org.junit.jupiter.api.Assertions.*;

import com.wayfarer.booking.service.StayQuoteService;
import com.wayfarer.common.ApiException;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class StayQuoteServiceTest {
    @Test
    void countsNights() {
        LocalDate in = LocalDate.now().plusDays(10);
        assertEquals(3, StayQuoteService.validateDates(in, in.plusDays(3)));
    }

    @Test
    void rejectsBadRanges() {
        LocalDate in = LocalDate.now().plusDays(10);
        assertEquals("INVALID_DATES", assertThrows(ApiException.class, () -> StayQuoteService.validateDates(in, in)).code());
        assertEquals("INVALID_DATES", assertThrows(ApiException.class, () -> StayQuoteService.validateDates(in, in.plusDays(31))).code());
        assertEquals("INVALID_DATES", assertThrows(ApiException.class, () -> StayQuoteService.validateDates(LocalDate.now().minusDays(1), LocalDate.now().plusDays(1))).code());
    }
}

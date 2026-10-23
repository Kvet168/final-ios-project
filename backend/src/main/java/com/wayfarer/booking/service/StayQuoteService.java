package com.wayfarer.booking.service;

import com.wayfarer.booking.repository.InventoryRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class StayQuoteService {
    private final InventoryRepository inventory;

    public StayQuoteService(InventoryRepository inventory) { this.inventory = inventory; }

    public static int validateDates(LocalDate checkIn, LocalDate checkOut) {
        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);
        if (nights <= 0) throw ApiException.unprocessable("INVALID_DATES", "Check-out must be after check-in");
        if (nights > 30) throw ApiException.unprocessable("INVALID_DATES", "Stays are limited to 30 nights");
        if (checkIn.isBefore(LocalDate.now())) throw ApiException.unprocessable("INVALID_DATES", "Check-in cannot be in the past");
        return (int) nights;
    }

    public Optional<Map<String, Object>> findRoomWithAccommodation(UUID roomTypeId) { return inventory.findRoomWithAccommodation(roomTypeId); }

    /** @param lock when true the inventory rows are locked FOR UPDATE; call inside a transaction. */
    public StayQuote quote(UUID roomTypeId, LocalDate checkIn, LocalDate checkOut, int rooms, boolean lock) {
        int nights = validateDates(checkIn, checkOut);
        Map<String, Object> room = inventory.findRoomWithAccommodation(roomTypeId).orElseThrow(() -> ApiException.notFound("Room type"));
        List<StayQuote.Night> nightly = inventory.nights(roomTypeId, checkIn, checkOut, lock).stream()
            .map(r -> new StayQuote.Night(Rows.date(r, "night"), Rows.dec(r, "price_usd"), Rows.integer(r, "units_available"))).toList();

        boolean available = true;
        String reason = null;
        if (nightly.size() != nights) {
            available = false;
            reason = "These dates are not open for booking.";
        } else {
            for (StayQuote.Night n : nightly) {
                if (n.unitsAvailable() < rooms) {
                    available = false;
                    reason = "Not enough rooms left on " + n.night() + ". Try different dates or fewer rooms.";
                    break;
                }
            }
        }
        BigDecimal subtotal = Rows.round2(nightly.stream().map(StayQuote.Night::rate).reduce(BigDecimal.ZERO, BigDecimal::add).multiply(BigDecimal.valueOf(rooms)));
        BigDecimal taxRate = Rows.dec(room, "tax_rate"), feeRate = Rows.dec(room, "service_fee_rate");
        BigDecimal taxes = Rows.round2(subtotal.multiply(taxRate)), fees = Rows.round2(subtotal.multiply(feeRate));
        return new StayQuote(available, reason, nights, rooms, nightly, subtotal, taxes, fees, subtotal.add(taxes).add(fees), taxRate, feeRate, room);
    }
}

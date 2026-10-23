package com.wayfarer.booking.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Price and availability for a stay. `room` carries the joined room type + accommodation row. */
public record StayQuote(boolean available, String reason, int nights, int rooms, List<Night> nightly,
                        BigDecimal subtotal, BigDecimal taxes, BigDecimal fees, BigDecimal total,
                        BigDecimal taxRate, BigDecimal serviceFeeRate, Map<String, Object> room) {

    public record Night(LocalDate night, BigDecimal rate, int unitsAvailable) {}

    /** Wire format (snake_case money fields, matching the rest of the API rows). */
    public Map<String, Object> toMap() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("available", available);
        if (reason != null) m.put("reason", reason);
        m.put("nights", nights);
        m.put("rooms", rooms);
        m.put("nightly", nightly.stream().map(n -> Map.of("night", n.night(), "rate_usd", n.rate(), "units_available", n.unitsAvailable())).toList());
        m.put("subtotal_usd", subtotal);
        m.put("taxes_usd", taxes);
        m.put("fees_usd", fees);
        m.put("total_usd", total);
        m.put("tax_rate", taxRate);
        m.put("service_fee_rate", serviceFeeRate);
        return m;
    }
}

package com.wayfarer.common;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Small helpers for reading values out of JdbcTemplate row maps. */
public final class Rows {
    private Rows() {}

    public static UUID uuid(Map<String, Object> r, String k) { return (UUID) r.get(k); }
    public static String str(Map<String, Object> r, String k) { Object v = r.get(k); return v == null ? null : v.toString(); }
    public static int integer(Map<String, Object> r, String k) { return ((Number) r.get(k)).intValue(); }
    public static BigDecimal dec(Map<String, Object> r, String k) { Object v = r.get(k); return v == null ? null : new BigDecimal(v.toString()); }
    public static LocalDate date(Map<String, Object> r, String k) { return (LocalDate) r.get(k); }
    public static Instant instant(Map<String, Object> r, String k) { return (Instant) r.get(k); }
    public static BigDecimal round2(BigDecimal v) { return v.setScale(2, RoundingMode.HALF_UP); }

    public static Map<String, Object> without(Map<String, Object> row, String... keys) {
        Map<String, Object> copy = new LinkedHashMap<>(row);
        for (String k : keys) copy.remove(k);
        return copy;
    }

    public static Map<String, Object> with(Map<String, Object> row, String k, Object v) {
        Map<String, Object> copy = new LinkedHashMap<>(row);
        copy.put(k, v);
        return copy;
    }
}

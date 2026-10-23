package com.wayfarer.booking.repository;

import com.wayfarer.common.Db;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Room types and the per-night inventory table (one row per room type per night; a missing row means not sellable). */
@Repository
public class InventoryRepository {
    private final Db db;

    public InventoryRepository(Db db) { this.db = db; }

    public Optional<Map<String, Object>> findRoomWithAccommodation(UUID roomTypeId) {
        return db.one("SELECT r.*, a.id AS accommodation_id, a.name AS accommodation_name, a.tax_rate, a.service_fee_rate, a.free_cancel_hours, a.cancellation_policy, "
            + "a.partner_id, a.slug AS accommodation_slug, a.check_in_from, a.check_out_until "
            + "FROM room_types r JOIN accommodations a ON a.id = r.accommodation_id WHERE r.id = :id AND r.deleted_at IS NULL AND a.deleted_at IS NULL", Map.of("id", roomTypeId));
    }

    public List<Map<String, Object>> nights(UUID roomTypeId, LocalDate from, LocalDate to, boolean lock) {
        return db.list("SELECT night, units_available, price_usd FROM room_inventory WHERE room_type_id = :id AND night >= :ci AND night < :co ORDER BY night"
            + (lock ? " FOR UPDATE" : ""), Map.of("id", roomTypeId, "ci", from, "co", to));
    }

    /** Takes `rooms` units from every night in [from, to). Returns how many nights were updated. */
    public int take(UUID roomTypeId, LocalDate from, LocalDate to, int rooms) {
        return db.update("UPDATE room_inventory SET units_available = units_available - :rooms "
            + "WHERE room_type_id = :r AND night >= :ci AND night < :co AND units_available >= :rooms", Map.of("rooms", rooms, "r", roomTypeId, "ci", from, "co", to));
    }

    /** Returns the units a booking took (once: booking_items.released guards against double release). */
    public void release(UUID bookingId, UUID roomTypeId) {
        db.update("UPDATE room_inventory ri SET units_available = ri.units_available + bi.rooms FROM booking_items bi "
            + "WHERE bi.booking_id = :b AND bi.released = false AND ri.room_type_id = :r AND ri.night = bi.night", Map.of("b", bookingId, "r", roomTypeId));
        db.update("UPDATE booking_items SET released = true WHERE booking_id = :b", Map.of("b", bookingId));
    }

    /** Adds the rolling window of sellable nights for every active room type. */
    public int topUp(int days) {
        return db.update("INSERT INTO room_inventory(room_type_id, night, units_available, price_usd) "
            + "SELECT r.id, d::date, r.total_units, r.base_price_usd FROM room_types r "
            + "CROSS JOIN generate_series(current_date, current_date + :days, interval '1 day') AS d WHERE r.deleted_at IS NULL "
            + "ON CONFLICT (room_type_id, night) DO NOTHING", Map.of("days", days));
    }

    /** Staff/partner editing: sets units (and optionally the price) for a date range. */
    public void upsertRange(UUID roomTypeId, LocalDate from, LocalDate to, int units, java.math.BigDecimal priceOrNull, java.math.BigDecimal basePrice) {
        db.update("INSERT INTO room_inventory(room_type_id, night, units_available, price_usd) "
            + "SELECT CAST(:r AS uuid), d::date, CAST(:units AS int), COALESCE(CAST(:price AS numeric), CAST(:base AS numeric)) FROM generate_series(CAST(:from AS date), CAST(:to AS date), interval '1 day') d "
            + "ON CONFLICT (room_type_id, night) DO UPDATE SET units_available = EXCLUDED.units_available, price_usd = COALESCE(CAST(:price AS numeric), room_inventory.price_usd)",
            Db.params().addValue("r", roomTypeId).addValue("units", units).addValue("price", priceOrNull).addValue("base", basePrice).addValue("from", from).addValue("to", to));
    }
}

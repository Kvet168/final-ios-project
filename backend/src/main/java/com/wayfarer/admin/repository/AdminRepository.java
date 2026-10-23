package com.wayfarer.admin.repository;

import com.wayfarer.common.Db;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Repository;

/** Read-only aggregates for the admin dashboard. */
@Repository
public class AdminRepository {
    private final Db db;

    public AdminRepository(Db db) { this.db = db; }

    public Map<String, Object> counts() {
        return db.one("SELECT (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL)::int AS users, (SELECT COUNT(*) FROM destinations WHERE deleted_at IS NULL)::int AS destinations, "
            + "(SELECT COUNT(*) FROM accommodations WHERE deleted_at IS NULL)::int AS accommodations, (SELECT COUNT(*) FROM room_types WHERE deleted_at IS NULL)::int AS room_types, "
            + "(SELECT COUNT(*) FROM room_inventory)::int AS inventory_rows, (SELECT COUNT(*) FROM attractions WHERE deleted_at IS NULL)::int AS attractions, "
            + "(SELECT COUNT(*) FROM reviews)::int AS reviews, (SELECT COUNT(*) FROM bookings)::int AS bookings, (SELECT COUNT(*) FROM payments)::int AS payments, "
            + "(SELECT COUNT(*) FROM payment_events)::int AS payment_events, (SELECT COUNT(*) FROM notifications)::int AS notifications, (SELECT COUNT(*) FROM itineraries)::int AS itineraries, "
            + "(SELECT COUNT(*) FROM travel_documents)::int AS documents, (SELECT COUNT(*) FROM document_chunks)::int AS chunks, (SELECT COUNT(*) FROM audit_logs)::int AS audit_logs", Map.of()).orElseThrow();
    }

    public List<Map<String, Object>> bookingsByStatus() { return db.list("SELECT status, COUNT(*)::int AS count FROM bookings GROUP BY status ORDER BY count DESC"); }

    public Map<String, Object> revenue() {
        return db.one("SELECT COALESCE(SUM(amount_usd - refunded_usd), 0) AS usd, COUNT(*)::int AS payments FROM payments WHERE status IN ('SUCCESS','REFUNDED')", Map.of()).orElseThrow();
    }

    public List<Map<String, Object>> bookingsPerDay(int days) {
        return db.list("SELECT to_char(created_at::date, 'YYYY-MM-DD') AS day, COUNT(*)::int AS bookings FROM bookings WHERE created_at > now() - make_interval(days => :d) GROUP BY 1 ORDER BY 1", Map.of("d", days));
    }
}

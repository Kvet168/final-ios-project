package com.wayfarer.booking.service;

import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.repository.InventoryRepository;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Rows;
import com.wayfarer.security.AuthUser;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Keeps a rolling window of sellable nights and lets staff and partners edit stock and prices. */
@Service
public class InventoryService {
    private static final Logger log = LoggerFactory.getLogger(InventoryService.class);
    static final int WINDOW_DAYS = 180;

    private final InventoryRepository inventory;
    private final AuditService audit;

    public InventoryService(InventoryRepository inventory, AuditService audit) {
        this.inventory = inventory;
        this.audit = audit;
    }

    @EventListener(ApplicationReadyEvent.class)
    @Scheduled(cron = "0 15 2 * * *")
    public int topUp() {
        int n = inventory.topUp(WINDOW_DAYS);
        if (n > 0) log.info("Inventory top-up added {} room-nights", n);
        return n;
    }

    /** Opens or updates nightly stock for a room type. The caller (admin or partner service) has already checked who may edit it. */
    @Transactional
    public Map<String, Object> updateRange(AuthUser actor, UUID roomTypeId, LocalDate from, LocalDate to, int units, BigDecimal price) {
        if (to.isBefore(from)) throw ApiException.unprocessable("INVALID_DATES", "'to' must be on or after 'from'");
        if (from.isBefore(LocalDate.now())) throw ApiException.unprocessable("INVALID_DATES", "Cannot change inventory in the past");
        long days = ChronoUnit.DAYS.between(from, to) + 1;
        if (days > 366) throw ApiException.unprocessable("INVALID_DATES", "Range is limited to 366 days");
        Map<String, Object> room = inventory.findRoomWithAccommodation(roomTypeId).orElseThrow(() -> ApiException.notFound("Room type"));
        if (units > Rows.integer(room, "total_units")) throw ApiException.unprocessable("VALIDATION_ERROR", "Units cannot exceed the room count (" + room.get("total_units") + ").");
        inventory.upsertRange(roomTypeId, from, to, units, price, Rows.dec(room, "base_price_usd"));
        audit.record(actor.id(), "inventory.update", "room_type", roomTypeId, Map.of("from", from.toString(), "to", to.toString(), "units", units));
        return Map.of("updatedNights", days);
    }
}

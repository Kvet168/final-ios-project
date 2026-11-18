package com.wayfarer.partner.service;

import com.wayfarer.admin.dto.AdminDtos.AccommodationPatch;
import com.wayfarer.admin.dto.AdminDtos.AccommodationRequest;
import com.wayfarer.admin.dto.AdminDtos.RoomPatch;
import com.wayfarer.admin.dto.AdminDtos.RoomRequest;
import com.wayfarer.audit.service.AuditService;
import com.wayfarer.booking.repository.BookingRepository;
import com.wayfarer.booking.service.InventoryService;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.catalog.service.DestinationService;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Text;
import com.wayfarer.media.service.MediaService;
import com.wayfarer.partner.dto.PartnerDtos.ImageRequest;
import com.wayfarer.partner.repository.PartnerRepository;
import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A partner's own properties: hotels, resorts, bungalows, hostels and their rooms, photos, prices and stock.
 * Every method checks that the caller owns what it touches; other partners' records answer 404 as if they did not exist.
 */
@Service
public class PropertyService {
    private final PartnerRepository partners;
    private final AccommodationRepository accommodations;
    private final DestinationRepository destinations;
    private final BookingRepository bookings;
    private final InventoryService inventory;
    private final MediaService media;
    private final DestinationService cache;
    private final AuditService audit;

    public PropertyService(PartnerRepository partners, AccommodationRepository accommodations, DestinationRepository destinations, BookingRepository bookings,
                           InventoryService inventory, MediaService media, DestinationService cache, AuditService audit) {
        this.partners = partners;
        this.accommodations = accommodations;
        this.destinations = destinations;
        this.bookings = bookings;
        this.inventory = inventory;
        this.media = media;
        this.cache = cache;
        this.audit = audit;
    }

    private void ownProperty(UUID actor, UUID accommodationId) {
        if (!partners.ownsAccommodation(accommodationId, actor)) throw ApiException.notFound("Accommodation");
    }

    private static String trim(String s) { return s == null ? null : s.trim(); }

    /** A room always has a photo: its own, or (when the owner added none) the property's cover photo. */
    private void addRoomRow(UUID actor, UUID accommodationId, RoomRequest r, boolean breakfast, String propertyCover) {
        String own = media.requireSafeImageUrl(actor, r.coverImage());
        accommodations.insertRoomType(new MapSqlParameterSource().addValue("acc", accommodationId).addValue("name", r.name().trim()).addValue("description", r.description().trim())
            .addValue("bed", r.bedType() == null ? "double" : r.bedType()).addValue("maxAdults", r.maxAdults()).addValue("maxChildren", r.maxChildren() == null ? 0 : r.maxChildren())
            .addValue("price", r.basePriceUsd()).addValue("units", r.totalUnits()).addValue("breakfast", breakfast).addValue("cover", own != null ? own : propertyCover));
    }

    @Transactional
    public UUID create(UUID actor, AccommodationRequest b) {
        UUID partnerId = partners.partnerIdForUser(actor).orElseThrow(() -> ApiException.forbidden("NO_PARTNER_ACCOUNT", "This account is not linked to a partner organisation."));
        destinations.findById(b.destinationId()).orElseThrow(() -> ApiException.notFound("Destination"));
        int free = b.freeCancelHours() == null ? 48 : b.freeCancelHours();
        boolean breakfast = Boolean.TRUE.equals(b.breakfastIncluded());
        BigDecimal cheapest = b.rooms().stream().map(RoomRequest::basePriceUsd).min(BigDecimal::compareTo).orElseThrow();
        String slug = Text.slugify(b.name()) + "-" + Integer.toString(ThreadLocalRandom.current().nextInt(36 * 36 * 36 * 36), 36);
        UUID id = accommodations.insert(new MapSqlParameterSource().addValue("slug", slug).addValue("dest", b.destinationId()).addValue("name", b.name().trim())
            .addValue("type", b.type()).addValue("stars", b.stars()).addValue("description", b.description().trim()).addValue("address", b.address().trim())
            .addValue("lat", b.lat()).addValue("lng", b.lng()).addValue("cover", media.requireSafeImageUrl(actor, b.coverImage())).addValue("freeHours", free)
            .addValue("policy", policy(free)).addValue("breakfast", breakfast).addValue("family", Boolean.TRUE.equals(b.familyFriendly())).addValue("fromPrice", cheapest)
            .addValue("partner", partnerId));
        String propertyCover = media.requireSafeImageUrl(actor, b.coverImage());
        for (RoomRequest r : b.rooms()) addRoomRow(actor, id, r, breakfast, propertyCover);
        inventory.topUp();      // open the rolling stock window so the new rooms are bookable straight away
        audit.record(actor, "accommodation.create", "accommodation", id, Map.of("name", b.name(), "type", b.type()));
        cache.evictCache();
        return id;
    }

    private static String policy(int hours) {
        return hours > 0 ? "Free cancellation up to " + hours + " hours before check-in. After that the booking is non-refundable." : "Non-refundable rate.";
    }

    @Transactional
    public Map<String, Object> update(UUID actor, UUID id, AccommodationPatch b) {
        ownProperty(actor, id);
        accommodations.update(id, new MapSqlParameterSource().addValue("name", trim(b.name())).addValue("type", b.type()).addValue("stars", b.stars())
            .addValue("description", trim(b.description())).addValue("address", trim(b.address())).addValue("lat", b.lat()).addValue("lng", b.lng())
            .addValue("freeHours", b.freeCancelHours()).addValue("policy", b.freeCancelHours() == null ? null : policy(b.freeCancelHours()))
            .addValue("breakfast", b.breakfastIncluded()).addValue("family", b.familyFriendly()).addValue("cover", media.requireSafeImageUrl(actor, b.coverImage())));
        audit.record(actor, "accommodation.update", "accommodation", id, Map.of());
        cache.evictCache();
        return accommodations.findRaw(id).orElseThrow();
    }

    @Transactional
    public void delete(UUID actor, UUID id) {
        ownProperty(actor, id);
        if (bookings.hasActiveForAccommodation(id)) {
            throw ApiException.conflict("HAS_ACTIVE_BOOKINGS", "This property has bookings that are still pending, confirmed or in house. Complete or cancel them first.");
        }
        accommodations.softDelete(id);
        audit.record(actor, "accommodation.delete", "accommodation", id, Map.of());
        cache.evictCache();
    }

    @Transactional
    public Map<String, Object> addRoom(UUID actor, UUID accommodationId, RoomRequest r) {
        ownProperty(actor, accommodationId);
        boolean breakfast = Boolean.TRUE.equals(accommodations.findRaw(accommodationId).orElseThrow().get("breakfast_included"));
        addRoomRow(actor, accommodationId, r, breakfast, (String) accommodations.findRaw(accommodationId).orElseThrow().get("cover_image"));
        accommodations.refreshFromPrice(accommodationId);
        inventory.topUp();
        audit.record(actor, "room.create", "accommodation", accommodationId, Map.of("name", r.name()));
        cache.evictCache();
        return Map.of("rooms", accommodations.roomCount(accommodationId));
    }

    @Transactional
    public Map<String, Object> updateRoom(UUID actor, UUID roomId, RoomPatch b) {
        if (!partners.ownsRoomType(roomId, actor)) throw ApiException.notFound("Room type");
        Map<String, Object> room = accommodations.findRoom(roomId).orElseThrow(() -> ApiException.notFound("Room type"));
        accommodations.updateRoom(roomId, new MapSqlParameterSource().addValue("name", trim(b.name())).addValue("description", trim(b.description())).addValue("bed", b.bedType())
            .addValue("maxAdults", b.maxAdults()).addValue("maxChildren", b.maxChildren()).addValue("price", b.basePriceUsd()).addValue("units", b.totalUnits())
            .addValue("cover", media.requireSafeImageUrl(actor, b.coverImage())));
        if (b.totalUnits() != null) accommodations.adjustFutureInventory(roomId, b.totalUnits() - ((Number) room.get("total_units")).intValue());
        accommodations.refreshFromPrice((UUID) room.get("accommodation_id"));
        audit.record(actor, "room.update", "room_type", roomId, Map.of());
        cache.evictCache();
        return accommodations.findRoom(roomId).orElseThrow();
    }

    @Transactional
    public void deleteRoom(UUID actor, UUID roomId) {
        if (!partners.ownsRoomType(roomId, actor)) throw ApiException.notFound("Room type");
        Map<String, Object> room = accommodations.findRoom(roomId).orElseThrow(() -> ApiException.notFound("Room type"));
        UUID accId = (UUID) room.get("accommodation_id");
        if (accommodations.roomCount(accId) <= 1) throw ApiException.conflict("LAST_ROOM", "A property needs at least one room type. Add another first or delete the property.");
        if (bookings.hasActiveForRoom(roomId)) throw ApiException.conflict("HAS_ACTIVE_BOOKINGS", "This room has bookings that are still pending, confirmed or in house.");
        accommodations.softDeleteRoom(roomId);
        accommodations.refreshFromPrice(accId);
        audit.record(actor, "room.delete", "room_type", roomId, Map.of());
        cache.evictCache();
    }

    @Transactional
    public Map<String, Object> addImage(UUID actor, UUID accommodationId, ImageRequest r) {
        ownProperty(actor, accommodationId);
        String url = media.requireSafeImageUrl(actor, r.url());
        UUID id = accommodations.insertImage(accommodationId, url, trim(r.caption()));
        cache.evictCache();
        return Map.of("id", id, "url", url);
    }

    @Transactional
    public void removeImage(UUID actor, UUID accommodationId, UUID imageId) {
        ownProperty(actor, accommodationId);
        if (!accommodations.deleteImage(accommodationId, imageId)) throw ApiException.notFound("Image");
        cache.evictCache();
    }

}

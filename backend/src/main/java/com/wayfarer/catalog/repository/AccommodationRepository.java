package com.wayfarer.catalog.repository;

import com.wayfarer.catalog.dto.AccommodationQuery;
import com.wayfarer.common.ApiException;
import com.wayfarer.common.Db;
import com.wayfarer.common.Text;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.stereotype.Repository;

@Repository
public class AccommodationRepository {
    private final Db db;

    public AccommodationRepository(Db db) { this.db = db; }

    private static List<String> csv(String s) {
        return s == null || s.isBlank() ? List.of() : Arrays.stream(s.split(",")).map(String::trim).filter(x -> !x.isEmpty()).toList();
    }

    public Optional<Map<String, Object>> findByIdOrSlug(String key) {
        boolean byId = Db.isUuid(key);
        return db.one("SELECT a.*, d.name AS destination_name, d.slug AS destination_slug, d.country FROM accommodations a JOIN destinations d ON d.id = a.destination_id "
            + "WHERE " + (byId ? "a.id = :k" : "a.slug = :k") + " AND a.deleted_at IS NULL", Map.of("k", byId ? UUID.fromString(key) : key));
    }

    public Optional<Map<String, Object>> findLightByIdOrSlug(String key) {
        boolean byId = Db.isUuid(key);
        return db.one("SELECT id FROM accommodations WHERE " + (byId ? "id = :k" : "slug = :k") + " AND deleted_at IS NULL", Map.of("k", byId ? UUID.fromString(key) : key));
    }

    public List<Map<String, Object>> images(UUID id) {
        return db.list("SELECT id, url, caption FROM accommodation_images WHERE accommodation_id = :id ORDER BY position, id", Map.of("id", id));
    }

    public List<Map<String, Object>> amenities(UUID id) {
        return db.list("SELECT m.code, m.label FROM accommodation_amenities x JOIN amenities m ON m.id = x.amenity_id WHERE x.accommodation_id = :id ORDER BY m.label", Map.of("id", id));
    }

    public List<Map<String, Object>> roomTypes(UUID id) {
        return db.list("SELECT * FROM room_types WHERE accommodation_id = :id AND deleted_at IS NULL ORDER BY base_price_usd", Map.of("id", id));
    }

    public List<Map<String, Object>> roomTypeNames(UUID id) {
        return db.list("SELECT id, name FROM room_types WHERE accommodation_id = :id AND deleted_at IS NULL ORDER BY base_price_usd", Map.of("id", id));
    }

    public List<Map<String, Object>> related(UUID destinationId, UUID excludeId, Object fromPrice) {
        return db.list("SELECT id, slug, name, stars, cover_image, rating_avg, from_price_usd FROM accommodations WHERE destination_id = :d AND id <> :id AND deleted_at IS NULL "
            + "ORDER BY ABS(from_price_usd - :price) LIMIT 4", Map.of("d", destinationId, "id", excludeId, "price", fromPrice));
    }

    public List<Map<String, Object>> ratingBreakdown(UUID id) {
        return db.list("SELECT rating, COUNT(*)::int AS count FROM reviews WHERE accommodation_id = :id AND status = 'published' GROUP BY rating ORDER BY rating DESC", Map.of("id", id));
    }

    public List<Map<String, Object>> topForDestination(UUID destinationId, int limit) {
        return db.list("SELECT id, slug, name, stars, type, cover_image, rating_avg, review_count, from_price_usd FROM accommodations "
            + "WHERE destination_id = :id AND deleted_at IS NULL ORDER BY rating_avg DESC LIMIT :l", Map.of("id", destinationId, "l", limit));
    }

    public List<Map<String, Object>> topRated(int limit) {
        return db.list("SELECT a.id, a.slug, a.name, a.type, a.stars, a.cover_image, a.rating_avg, a.review_count, a.from_price_usd, a.is_demo, d.name AS destination_name "
            + "FROM accommodations a JOIN destinations d ON d.id = a.destination_id WHERE a.deleted_at IS NULL AND a.review_count >= 2 "
            + "ORDER BY a.rating_avg DESC, a.review_count DESC LIMIT :l", Map.of("l", limit));
    }

    /** Hotels in a destination within an optional nightly budget (AI recommendations). */
    public List<Map<String, Object>> recommend(UUID destinationId, Object maxNightly) {
        MapSqlParameterSource ps = Db.params().addValue("d", destinationId);
        String budget = "";
        if (maxNightly != null) { ps.addValue("max", maxNightly); budget = " AND from_price_usd <= :max"; }
        return db.list("SELECT id, name, stars, from_price_usd, rating_avg, family_friendly FROM accommodations WHERE destination_id = :d AND deleted_at IS NULL"
            + budget + " ORDER BY rating_avg DESC LIMIT 4", ps);
    }

    /** Planner: priced stays, cheapest first. */
    public List<Map<String, Object>> pricedForDestination(UUID destinationId) {
        return db.list("SELECT id, name, from_price_usd, rating_avg, breakfast_included, family_friendly, is_demo, lat, lng, tax_rate, service_fee_rate "
            + "FROM accommodations WHERE destination_id = :d AND deleted_at IS NULL AND from_price_usd > 0 ORDER BY from_price_usd", Map.of("d", destinationId));
    }

    public List<Map<String, Object>> cardsForDestination(UUID destinationId, int limit) {
        return db.list("SELECT slug, name, stars, from_price_usd, cover_image FROM accommodations WHERE destination_id = :d AND deleted_at IS NULL "
            + "ORDER BY rating_avg DESC, stars DESC LIMIT :l", Map.of("d", destinationId, "l", limit));
    }

    public Optional<Map<String, Object>> findLocation(UUID id) {
        return db.one("SELECT lat, lng FROM accommodations WHERE id = :id", Map.of("id", id));
    }

    public Optional<Map<String, Object>> findPricing(UUID id) {
        return db.one("SELECT from_price_usd, tax_rate, service_fee_rate, breakfast_included FROM accommodations WHERE id = :id", Map.of("id", id));
    }

    public Object minPriceForDestination(UUID destinationId) {
        return db.one("SELECT MIN(from_price_usd) AS p FROM accommodations WHERE destination_id = :d AND deleted_at IS NULL", Map.of("d", destinationId)).map(r -> r.get("p")).orElse(null);
    }

    public void refreshRating(UUID accommodationId) {
        db.update("UPDATE accommodations SET rating_avg = COALESCE((SELECT ROUND(AVG(rating)::numeric, 2) FROM reviews WHERE accommodation_id = :id AND status = 'published'), 0), "
            + "review_count = (SELECT COUNT(*) FROM reviews WHERE accommodation_id = :id AND status = 'published') WHERE id = :id", Map.of("id", accommodationId));
    }

    public UUID insert(MapSqlParameterSource p) {
        return (UUID) db.one("INSERT INTO accommodations(slug, destination_id, name, type, stars, description, address, lat, lng, cover_image, free_cancel_hours, cancellation_policy, "
            + "breakfast_included, family_friendly, from_price_usd, is_demo, partner_id) VALUES (:slug, :dest, :name, :type, :stars, :description, :address, :lat, :lng, :cover, :freeHours, :policy, "
            + ":breakfast, :family, :fromPrice, false, :partner) RETURNING id", p).orElseThrow().get("id");
    }

    /** Read-only catalogue listing for administrators: every property with its owner, price and room count. */
    public List<Map<String, Object>> adminList(String likeTerm, String type, UUID partnerId, int limit, int offset) {
        MapSqlParameterSource ps = Db.params().addValue("l", limit).addValue("o", offset);
        List<String> where = new ArrayList<>(List.of("a.deleted_at IS NULL"));
        if (likeTerm != null) { ps.addValue("q", likeTerm); where.add("(a.name ILIKE :q OR d.name ILIKE :q OR p.name ILIKE :q)"); }
        if (type != null) { ps.addValue("t", type); where.add("a.type = :t"); }
        if (partnerId != null) { ps.addValue("p", partnerId); where.add("a.partner_id = :p"); }
        return db.list("SELECT a.id, a.slug, a.name, a.type, a.stars, a.cover_image, a.from_price_usd, a.rating_avg, a.review_count, a.is_demo, a.created_at, "
            + "d.name AS destination_name, p.id AS partner_id, p.name AS partner_name, "
            + "(SELECT COUNT(*)::int FROM room_types r WHERE r.accommodation_id = a.id AND r.deleted_at IS NULL) AS rooms, COUNT(*) OVER () AS total_count "
            + "FROM accommodations a JOIN destinations d ON d.id = a.destination_id LEFT JOIN partners p ON p.id = a.partner_id WHERE " + String.join(" AND ", where)
            + " ORDER BY a.name LIMIT :l OFFSET :o", ps);
    }

    public Optional<Map<String, Object>> findRaw(UUID id) { return db.one("SELECT * FROM accommodations WHERE id = :id AND deleted_at IS NULL", Map.of("id", id)); }

    public boolean update(UUID id, MapSqlParameterSource p) {
        p.addValue("id", id);
        return db.update("UPDATE accommodations SET name = COALESCE(:name, name), type = COALESCE(:type, type), stars = COALESCE(:stars, stars), "
            + "description = COALESCE(:description, description), address = COALESCE(:address, address), lat = COALESCE(:lat, lat), lng = COALESCE(:lng, lng), "
            + "free_cancel_hours = COALESCE(:freeHours, free_cancel_hours), cancellation_policy = COALESCE(:policy, cancellation_policy), "
            + "breakfast_included = COALESCE(:breakfast, breakfast_included), family_friendly = COALESCE(:family, family_friendly), cover_image = COALESCE(:cover, cover_image) "
            + "WHERE id = :id AND deleted_at IS NULL", p) > 0;
    }

    public boolean softDelete(UUID id) {
        db.update("UPDATE room_types SET deleted_at = now() WHERE accommodation_id = :id AND deleted_at IS NULL", Map.of("id", id));
        return db.update("UPDATE accommodations SET deleted_at = now() WHERE id = :id AND deleted_at IS NULL", Map.of("id", id)) > 0;
    }

    public Optional<Map<String, Object>> findRoom(UUID roomId) {
        return db.one("SELECT r.*, a.partner_id FROM room_types r JOIN accommodations a ON a.id = r.accommodation_id WHERE r.id = :id AND r.deleted_at IS NULL AND a.deleted_at IS NULL", Map.of("id", roomId));
    }

    public boolean updateRoom(UUID roomId, MapSqlParameterSource p) {
        p.addValue("id", roomId);
        return db.update("UPDATE room_types SET name = COALESCE(:name, name), description = COALESCE(:description, description), bed_type = COALESCE(:bed, bed_type), "
            + "max_adults = COALESCE(:maxAdults, max_adults), max_children = COALESCE(:maxChildren, max_children), base_price_usd = COALESCE(:price, base_price_usd), "
            + "total_units = COALESCE(:units, total_units), cover_image = COALESCE(:cover, cover_image) WHERE id = :id AND deleted_at IS NULL", p) > 0;
    }

    /** Keeps the "from" price shown in search equal to the cheapest active room. */
    public void refreshFromPrice(UUID accommodationId) {
        db.update("UPDATE accommodations SET from_price_usd = COALESCE((SELECT MIN(base_price_usd) FROM room_types WHERE accommodation_id = :id AND deleted_at IS NULL), from_price_usd) WHERE id = :id",
            Map.of("id", accommodationId));
    }

    /** When a room's total changes, tonight-onwards stock moves by the same amount (never below zero). */
    public void adjustFutureInventory(UUID roomId, int delta) {
        db.update("UPDATE room_inventory SET units_available = GREATEST(0, units_available + :d) WHERE room_type_id = :r AND night >= current_date", Map.of("d", delta, "r", roomId));
    }

    public boolean softDeleteRoom(UUID roomId) { return db.update("UPDATE room_types SET deleted_at = now() WHERE id = :id AND deleted_at IS NULL", Map.of("id", roomId)) > 0; }

    public int roomCount(UUID accommodationId) {
        return ((Number) db.one("SELECT COUNT(*) AS n FROM room_types WHERE accommodation_id = :id AND deleted_at IS NULL", Map.of("id", accommodationId)).orElseThrow().get("n")).intValue();
    }

    public UUID insertImage(UUID accommodationId, String url, String caption) {
        return (UUID) db.one("INSERT INTO accommodation_images(accommodation_id, url, caption, position) VALUES (:a, :u, :c, "
            + "COALESCE((SELECT MAX(position) + 1 FROM accommodation_images WHERE accommodation_id = :a), 0)) RETURNING id",
            Db.params().addValue("a", accommodationId).addValue("u", url).addValue("c", caption)).orElseThrow().get("id");
    }

    public boolean deleteImage(UUID accommodationId, UUID imageId) { return db.update("DELETE FROM accommodation_images WHERE id = :i AND accommodation_id = :a", Map.of("i", imageId, "a", accommodationId)) > 0; }

    public void insertRoomType(MapSqlParameterSource p) {
        db.update("INSERT INTO room_types(accommodation_id, name, description, bed_type, max_adults, max_children, base_price_usd, total_units, breakfast_included, cover_image) "
            + "VALUES (:acc, :name, :description, :bed, :maxAdults, :maxChildren, :price, :units, :breakfast, :cover)", p);
    }

    /** Dynamic availability search. Filters are applied in SQL; room capacity and (optionally) nightly inventory decide which rooms qualify. */
    public List<Map<String, Object>> search(AccommodationQuery q, int nights) {
        MapSqlParameterSource ps = Db.params().addValue("rooms", q.rooms()).addValue("adults", q.adults()).addValue("children", q.children());
        String price = "r.base_price_usd", avail = "true";
        if (q.hasDates()) {
            ps.addValue("ci", q.checkIn()).addValue("co", q.checkOut()).addValue("n", nights);
            price = "(SELECT AVG(i.price_usd) FROM room_inventory i WHERE i.room_type_id = r.id AND i.night >= :ci AND i.night < :co)";
            avail = "(SELECT COUNT(*) FROM room_inventory i WHERE i.room_type_id = r.id AND i.night >= :ci AND i.night < :co AND i.units_available >= :rooms) = :n";
        }
        List<String> where = new ArrayList<>(List.of("a.deleted_at IS NULL", "d.deleted_at IS NULL"));
        if (q.destination() != null) {
            if (Db.isUuid(q.destination())) { ps.addValue("dest", UUID.fromString(q.destination())); where.add("a.destination_id = :dest"); }
            else { ps.addValue("dest", q.destination()); where.add("d.slug = :dest"); }
        }
        if (q.q() != null && !q.q().isBlank()) {
            ps.addValue("like", Text.like(q.q()));
            where.add("(a.name ILIKE :like OR d.name ILIKE :like OR d.country ILIKE :like OR a.address ILIKE :like)");
        }
        List<Integer> stars = csv(q.stars()).stream().map(s -> { try { return Integer.parseInt(s); } catch (NumberFormatException e) { return 0; } })
            .filter(n -> n >= 1 && n <= 5).toList();
        if (!stars.isEmpty()) { ps.addValue("stars", stars); where.add("a.stars IN (:stars)"); }
        List<String> types = csv(q.type());
        if (!types.isEmpty()) { ps.addValue("types", types); where.add("a.type IN (:types)"); }
        if (q.minRating() != null) { ps.addValue("minRating", q.minRating()); where.add("a.rating_avg >= :minRating"); }
        if (Boolean.TRUE.equals(q.freeCancellation())) where.add("a.free_cancel_hours > 0");
        if (Boolean.TRUE.equals(q.breakfast())) where.add("(a.breakfast_included OR EXISTS (SELECT 1 FROM room_types rb WHERE rb.accommodation_id = a.id AND rb.breakfast_included))");
        if (Boolean.TRUE.equals(q.familyFriendly())) where.add("a.family_friendly = true");
        List<String> amenities = csv(q.amenities());
        if (!amenities.isEmpty()) {
            ps.addValue("amenities", amenities).addValue("amenityCount", amenities.size());
            where.add("a.id IN (SELECT aa.accommodation_id FROM accommodation_amenities aa JOIN amenities am ON am.id = aa.amenity_id "
                + "WHERE am.code IN (:amenities) GROUP BY aa.accommodation_id HAVING COUNT(*) = :amenityCount)");
        }
        String dist = "NULL::float8";
        if (q.lat() != null && q.lng() != null) {
            ps.addValue("la", q.lat()).addValue("lo", q.lng());
            dist = "(6371 * acos(LEAST(1, cos(radians(CAST(:la AS float8))) * cos(radians(a.lat)) * cos(radians(a.lng) - radians(CAST(:lo AS float8))) "
                + "+ sin(radians(CAST(:la AS float8))) * sin(radians(a.lat)))))";
            if (q.maxDistanceKm() != null) { ps.addValue("maxKm", q.maxDistanceKm()); where.add(dist + " <= :maxKm"); }
        } else if ("distance".equals(q.sort()) || q.maxDistanceKm() != null) {
            throw ApiException.unprocessable("MISSING_LOCATION", "Provide lat and lng to filter or sort by distance");
        }
        List<String> having = new ArrayList<>();
        if (q.minPrice() != null) { ps.addValue("minPrice", q.minPrice()); having.add("MIN(rt.price) >= :minPrice"); }
        if (q.maxPrice() != null) { ps.addValue("maxPrice", q.maxPrice()); having.add("MIN(rt.price) <= :maxPrice"); }
        String order = switch (q.sort()) {
            case "relevance" -> "a.rating_avg * ln(a.review_count + 2) DESC, a.name";
            case "price_asc" -> "price_from ASC, a.name";
            case "price_desc" -> "price_from DESC, a.name";
            case "rating" -> "a.rating_avg DESC, a.review_count DESC";
            case "distance" -> "distance_km ASC NULLS LAST";
            default -> throw ApiException.unprocessable("VALIDATION_ERROR", "Unknown sort: " + q.sort());
        };
        ps.addValue("limit", q.pageSize()).addValue("offset", (q.page() - 1) * q.pageSize());
        return db.list("WITH rt AS (SELECT r.id, r.accommodation_id, " + price + " AS price, " + avail + " AS ok FROM room_types r "
            + "WHERE r.deleted_at IS NULL AND :adults <= r.max_adults * :rooms AND :children <= r.max_children * :rooms) "
            + "SELECT a.id, a.slug, a.name, a.type, a.stars, a.cover_image, a.image_credit, a.address, a.lat, a.lng, a.rating_avg, a.review_count, "
            + "a.free_cancel_hours, a.breakfast_included, a.family_friendly, a.is_demo, a.cancellation_policy, "
            + "d.id AS destination_id, d.slug AS destination_slug, d.name AS destination_name, d.country, "
            + "ROUND(MIN(rt.price)::numeric, 2) AS price_from, COUNT(rt.id) AS matching_rooms, " + dist + " AS distance_km, COUNT(*) OVER () AS total_count "
            + "FROM accommodations a JOIN destinations d ON d.id = a.destination_id JOIN rt ON rt.accommodation_id = a.id AND rt.ok "
            + "WHERE " + String.join(" AND ", where) + " GROUP BY a.id, d.id "
            + (having.isEmpty() ? "" : "HAVING " + String.join(" AND ", having) + " ")
            + "ORDER BY " + order + " LIMIT :limit OFFSET :offset", ps);
    }
}

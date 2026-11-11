package com.wayfarer.ai.service;

import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import com.wayfarer.ai.dto.PlanDtos.PlannedDay;
import com.wayfarer.ai.dto.PlanDtos.PlannedItem;
import com.wayfarer.common.Geo;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Deterministic, explainable day scheduling: scores places against the traveller's interests, prefers nearby stops, respects opening hours
 * and a rhythm of sights, lunch and an evening meal. No machine learning is involved; every choice carries a human-readable reason.
 */
final class DayScheduler {
    static final int DAY_START = 9 * 60;

    record Slot(int want, boolean withLunch, boolean withEvening) {}

    record Anchor(double lat, double lng) {}

    private record Score(double value, List<String> why) {}

    private record Pick(Place place, double value, List<String> why) {}

    private static final Map<String, List<String>> CATEGORY_FOR_INTEREST = Map.of(
        "culture", List.of("museum", "culture", "temple", "landmark"), "temples", List.of("temple"), "food", List.of("food", "cafe", "market"),
        "markets", List.of("market"), "nature", List.of("nature"), "beach", List.of("beach"), "outdoor", List.of("outdoor", "nature"),
        "family", List.of(), "photography", List.of("landmark", "temple", "nature", "market"), "relaxed", List.of("landmark", "nature", "cafe"));

    private DayScheduler() {}

    static Slot slot(String pace) {
        return switch (pace) {
            case "relaxed" -> new Slot(2, true, false);
            case "packed" -> new Slot(4, true, true);
            default -> new Slot(3, true, true);
        };
    }

    static int travelMin(Anchor a, Anchor b) { return Geo.roadMinutes(Geo.haversineKm(a.lat, a.lng, b.lat, b.lng)) + 8; }

    static int travelMin(Place a, Place b) { return Geo.roadMinutes(Geo.haversineKm(a.lat(), a.lng(), b.lat(), b.lng())) + 8; }

    private static Score score(Place p, PlanRequest req) {
        double s = 1;
        List<String> why = new ArrayList<>();
        Set<String> hay = new HashSet<>();
        hay.add(p.category().toLowerCase());
        p.tags().forEach(t -> hay.add(t.toLowerCase()));
        for (String i : req.interests()) {
            if (hay.contains(i) || CATEGORY_FOR_INTEREST.getOrDefault(i, List.of()).contains(p.category())) {
                s += 3;
                why.add(i);
            }
        }
        if (req.interests().contains("family") && p.familyFriendly()) {
            s += 2;
            why.add("family-friendly");
        }
        if (req.children() > 0 && !p.familyFriendly()) s -= 2;
        if (req.interests().contains("relaxed") && p.durationMin() > 150) s -= 1;
        if (p.priceUsd() != null && p.priceUsd() == 0) s += 0.5;
        return new Score(s, why);
    }

    static String fmtTime(int m) { return String.format("%02d:%02d", (m / 60) % 24, m % 60); }

    static boolean fitsHours(Place p, int start) {
        if (p.opensMin() == null || p.closesMin() == null) return true;
        int close = p.closesMin() <= p.opensMin() ? 1440 + p.closesMin() : p.closesMin();    // spans midnight
        return start >= p.opensMin() && start + p.durationMin() <= close;
    }

    static double costFor(Place p, int adults, int children) {
        double price = p.priceUsd() == null ? 0 : p.priceUsd();
        return p.isRestaurant() ? Money.round2(price * (adults + children * 0.6)) : Money.round2(price * adults + price * 0.5 * children);
    }

    private static String reasonFor(Place p, List<String> why, PlanRequest req, String hoursNote) {
        List<String> parts = new ArrayList<>();
        if (!why.isEmpty()) parts.add("Matches your interest in " + String.join(", ", new LinkedHashSet<>(why).stream().limit(3).toList()));
        else parts.add("A well-regarded local stop chosen to round out the day");
        if (p.familyFriendly() && req.children() > 0) parts.add("suitable for children");
        if (p.priceUsd() != null && p.priceUsd() == 0) parts.add("free to visit");
        if (!hoursNote.isEmpty()) parts.add(hoursNote);
        return String.join("; ", parts) + ".";
    }

    /** Builds one day from the pool; `used` is updated with every place chosen so days never repeat a stop. */
    static PlannedDay buildDay(int day, List<Place> pool, Set<UUID> used, PlanRequest req, Anchor hotel, Slot slot) {
        return buildDay(day, pool, used, req, hotel, slot, 0);
    }

    /** [startOffsetMin] pushes the first stop later, for a day that begins with a transfer from another city. */
    static PlannedDay buildDay(int day, List<Place> pool, Set<UUID> used, PlanRequest req, Anchor hotel, Slot slot, int startOffsetMin) {
        return new Builder(pool, used, req, hotel, DAY_START + Math.max(0, startOffsetMin)).build(day, slot);
    }

    private static final class Builder {
        private final Set<UUID> used;
        private final PlanRequest req;
        private final Anchor hotel;
        private final List<Place> sights = new ArrayList<>(), eats = new ArrayList<>();
        private final List<PlannedItem> items = new ArrayList<>();
        private int cursor;
        private Anchor prev;

        Builder(List<Place> pool, Set<UUID> used, PlanRequest req, Anchor hotel, int dayStart) {
            this.cursor = dayStart;
            this.used = used;
            this.req = req;
            this.hotel = hotel;
            this.prev = hotel;
            for (Place p : pool) if (!used.contains(p.id())) (p.isRestaurant() ? eats : sights).add(p);
        }

        private Pick pick(List<Place> candidates, int atMin) {
            Pick best = null;
            for (Place c : candidates) {
                if (used.contains(c.id()) || !fitsHours(c, atMin)) continue;
                Score sc = score(c, req);
                double d = prev == null ? 0 : Geo.haversineKm(prev.lat, prev.lng, c.lat(), c.lng());
                double v = sc.value - Math.min(d, 40) * 0.25;
                if (best == null || v > best.value) best = new Pick(c, v, sc.why);
            }
            return best;
        }

        private boolean push(Pick b, int startAt) {
            Place p = b.place;
            int travel = prev == null ? 0 : travelMin(prev, new Anchor(p.lat(), p.lng()));
            int start = Math.max(startAt, cursor + travel);
            if (!fitsHours(p, start)) return false;
            boolean allDay = p.opensMin() != null && p.opensMin() == 0 && p.closesMin() != null && p.closesMin() >= 1439;
            String hoursNote = p.opensMin() != null && p.closesMin() != null
                ? (allDay ? "open access, no fixed hours" : (p.hoursVerified() ? "open " : "typically open ") + fmtTime(p.opensMin()) + "-" + fmtTime(p.closesMin() % 1440)) : "";
            items.add(new PlannedItem(p.id(), p.name(), p.kind(), p.category(), p.lat(), p.lng(), p.image(), start, p.durationMin(),
                items.isEmpty() && hotel == null ? 0 : travel, costFor(p, req.adults(), req.children()), reasonFor(p, b.why, req, hoursNote), p.isDemo(), p.hoursVerified()));
            used.add(p.id());
            cursor = start + p.durationMin();
            prev = new Anchor(p.lat(), p.lng());
            return true;
        }

        PlannedDay build(int day, Slot slot) {
            int morning = (int) Math.ceil(slot.want / 2.0);
            for (int i = 0; i < morning; i++) {
                Pick b = pick(sights, cursor + (prev != null ? 15 : 0));
                if (b == null || !push(b, cursor)) break;
                if (cursor > 11 * 60 + 45) break;
            }
            if (slot.withLunch) {
                int lunchAt = Math.max(cursor + 10, 12 * 60);
                Pick b = pick(eats, lunchAt);
                if (b != null) push(b, lunchAt);
            }
            for (int i = 0; i < slot.want - morning; i++) {
                int at = Math.max(cursor + 10, 13 * 60 + 30);
                Pick b = pick(sights, at);
                if (b == null || !push(b, at)) break;
                if (cursor > 17 * 60 + 30) break;
            }
            if (slot.withEvening) {
                int at = Math.max(cursor + 10, 18 * 60 + 30);
                Pick b = pick(eats, at);
                if (b != null) push(b, at);
            }
            items.sort((a, b) -> Integer.compare(a.startMin(), b.startMin()));
            return new PlannedDay(day, List.copyOf(items), Money.round2(items.stream().mapToDouble(PlannedItem::costUsd).sum()));
        }
    }
}

package com.wayfarer.common;

/** Great-circle distance and the documented travel-time estimate used by the planner and the route endpoint. */
public final class Geo {
    private Geo() {}

    /** Road distance is estimated as straight-line distance times this factor (not a routed distance). */
    public static final double DETOUR_FACTOR = 1.35;
    /** Assumed average urban speed in km/h. */
    public static final double URBAN_KMH = 22;

    public static double haversineKm(double aLat, double aLng, double bLat, double bLng) {
        double rad = Math.PI / 180, dLat = (bLat - aLat) * rad, dLng = (bLng - aLng) * rad;
        double x = Math.pow(Math.sin(dLat / 2), 2) + Math.cos(aLat * rad) * Math.cos(bLat * rad) * Math.pow(Math.sin(dLng / 2), 2);
        return 2 * 6371 * Math.asin(Math.min(1, Math.sqrt(x)));
    }

    public static int roadMinutes(double straightKm) { return (int) Math.round((straightKm * DETOUR_FACTOR / URBAN_KMH) * 60); }
}

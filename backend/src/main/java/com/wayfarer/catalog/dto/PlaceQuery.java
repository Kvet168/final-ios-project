package com.wayfarer.catalog.dto;

/** Filters for listing attractions, restaurants and activities. */
public record PlaceQuery(String destination, String kind, String category, String q, Boolean familyFriendly, String sort, Integer page, Integer pageSize) {
    public PlaceQuery {
        page = page == null ? 1 : Math.max(1, page);
        pageSize = pageSize == null ? 12 : Math.max(1, Math.min(50, pageSize));
        sort = sort == null ? "name" : sort;
    }

    public PlaceQuery inDestination(String d) { return new PlaceQuery(d, kind, category, q, familyFriendly, sort, page, pageSize); }
}

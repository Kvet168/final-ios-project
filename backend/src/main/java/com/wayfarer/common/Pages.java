package com.wayfarer.common;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Builds the standard paged response {items, page, pageSize, total, totalPages} from rows that carry a window `total_count` column. */
public final class Pages {
    private Pages() {}

    public static int clampSize(int pageSize, int max) { return Math.max(1, Math.min(max, pageSize)); }

    public static int clampPage(int page) { return Math.max(1, page); }

    public static int offset(int page, int size) { return (clampPage(page) - 1) * size; }

    public static Map<String, Object> of(List<Map<String, Object>> rows, int page, int pageSize) {
        long total = rows.isEmpty() ? 0 : ((Number) rows.get(0).get("total_count")).longValue();
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("items", rows.stream().map(r -> Rows.without(r, "total_count")).toList());
        out.put("page", page);
        out.put("pageSize", pageSize);
        out.put("total", total);
        out.put("totalPages", (long) Math.ceil(total / (double) pageSize));
        return out;
    }
}

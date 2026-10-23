package com.wayfarer.common;

import java.text.Normalizer;
import java.util.Locale;
import java.util.UUID;

public final class Text {
    private Text() {}

    /** Escapes LIKE wildcards and wraps the term for a contains-match. */
    public static String like(String s) { return "%" + s.trim().replaceAll("([%_\\\\])", "\\\\$1") + "%"; }

    public static String slugify(String s) {
        String n = Normalizer.normalize(s.toLowerCase(Locale.ROOT), Normalizer.Form.NFKD).replaceAll("\\p{M}", "");
        return n.replaceAll("[^a-z0-9]+", "-").replaceAll("^-+|-+$", "");
    }

    /** Renders values as a PostgreSQL array literal for CAST(:p AS text[]). */
    public static String pgArray(java.util.Collection<String> values) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (String v : values) {
            if (!first) sb.append(',');
            sb.append('"').append(v.replace("\\", "\\\\").replace("\"", "\\\"")).append('"');
            first = false;
        }
        return sb.append('}').toString();
    }

    public static UUID uuidOrNull(String s) { return Db.isUuid(s) ? UUID.fromString(s) : null; }
}

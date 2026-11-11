package com.wayfarer.ai.service;

import com.wayfarer.ai.service.RequestParser.Slug;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Finds the cities a traveller names, in the order they name them, and how many days each should get.
 *
 * <p>Matching works on words, not substrings ("kept" is not Kep), copes with spacing ("siemreap", "siem reap") and
 * forgives a one-letter typo ("battambong"), but never prefers a typo over an exact name ("koh rong" is not "koh kong").
 */
final class CityMatcher {
    private CityMatcher() {}

    /** A city mentioned at token positions [from, to). */
    record Mention(Slug slug, int from, int to) {}

    private static final Map<String, String> ALIASES = Map.of("angkor", "siem-reap", "angkorwat", "siem-reap", "kompongcham", "kampong-cham",
        "sihanouk", "sihanoukville", "kohrongsamloem", "koh-rong",
        "ubud", "bali", "saigon", "ho-chi-minh-city");
    private static final Set<String> FILLER = Set.of("in", "at", "to", "for", "around", "spend", "spending", "stay", "staying", "the", "about", "visit", "visiting", "trip", "of");
    private static final Map<String, Integer> NUMBER_WORDS = Map.ofEntries(Map.entry("a", 1), Map.entry("one", 1), Map.entry("two", 2), Map.entry("three", 3), Map.entry("four", 4),
        Map.entry("five", 5), Map.entry("six", 6), Map.entry("seven", 7), Map.entry("eight", 8), Map.entry("nine", 9), Map.entry("ten", 10));

    static List<String> tokens(String text) {
        String t = text.toLowerCase().replaceAll("[^\\p{L}\\p{N}]+", " ").trim();
        return t.isEmpty() ? List.of() : Arrays.asList(t.split(" "));
    }

    /** "Bali (Ubud)" becomes "bali"; "Kampong Cham" becomes "kampongcham". */
    static String compact(String name) { return name.toLowerCase().replaceAll("\\(.*?\\)", "").replaceAll("[^\\p{L}\\p{N}]", ""); }

    /** Every city named in the text, first mention of each, in the order they appear. */
    static List<Mention> find(List<String> tokens, List<Slug> dests) {
        List<Mention> hits = new ArrayList<>();
        boolean[] covered = new boolean[tokens.size()];

        // Exact pass: longest span first, so "kampong cham" wins over any shorter reading.
        for (int i = 0; i < tokens.size(); i++) {
            for (int len = Math.min(3, tokens.size() - i); len >= 1; len--) {
                String joined = String.join("", tokens.subList(i, i + len));
                Slug hit = exact(joined, dests);
                if (hit == null) continue;
                hits.add(new Mention(hit, i, i + len));
                for (int k = i; k < i + len; k++) covered[k] = true;
                i += len - 1;
                break;
            }
        }

        // Fuzzy pass over words that are still unexplained: a single wrong, missing or extra letter in a longer name.
        for (int i = 0; i < tokens.size(); i++) {
            if (covered[i]) continue;
            for (int len = Math.min(2, tokens.size() - i); len >= 1; len--) {
                boolean free = true;
                for (int k = i; k < i + len; k++) if (covered[k]) free = false;
                String joined = String.join("", tokens.subList(i, i + len));
                if (!free || joined.length() < 5) continue;
                Slug hit = fuzzy(joined, dests);
                if (hit == null) continue;
                hits.add(new Mention(hit, i, i + len));
                for (int k = i; k < i + len; k++) covered[k] = true;
                break;
            }
        }

        hits.sort((a, b) -> Integer.compare(a.from, b.from));
        List<Mention> unique = new ArrayList<>();
        for (Mention m : hits) if (unique.stream().noneMatch(u -> u.slug.slug().equals(m.slug.slug()))) unique.add(m);
        return unique;
    }

    private static Slug exact(String joined, List<Slug> dests) {
        String alias = ALIASES.get(joined);
        for (Slug d : dests) {
            if (compact(d.name()).equals(joined) || compact(d.slug()).equals(joined) || d.slug().equals(alias)) return d;
        }
        return null;
    }

    private static Slug fuzzy(String joined, List<Slug> dests) {
        Slug best = null;
        int bestDistance = 2;
        boolean tie = false;
        for (Slug d : dests) {
            String name = compact(d.name());
            if (name.length() < 6) continue;
            int dist = distance(joined, name);
            if (dist > 1) continue;
            if (dist < bestDistance) { best = d; bestDistance = dist; tie = false; }
            else if (dist == bestDistance) tie = true;
        }
        return tie ? null : best;
    }

    static int distance(String a, String b) {
        int[] prev = new int[b.length() + 1], cur = new int[b.length() + 1];
        for (int j = 0; j <= b.length(); j++) prev[j] = j;
        for (int i = 1; i <= a.length(); i++) {
            cur[0] = i;
            for (int j = 1; j <= b.length(); j++) cur[j] = Math.min(Math.min(cur[j - 1], prev[j]) + 1, prev[j - 1] + (a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1));
            int[] t = prev; prev = cur; cur = t;
        }
        return prev[b.length()];
    }

    /**
     * Days per city when the text gives one for every city ("3 days in Kampot and 2 in Siem Reap", "Kampot 2 days, Siem Reap 3 days"),
     * in the same order as [mentions]; null when it does not.
     */
    static List<Integer> daysPerCity(List<String> tokens, List<Mention> mentions) {
        if (mentions.size() < 2) return null;
        List<Integer> before = assign(tokens, mentions, true), after = assign(tokens, mentions, false);
        return before != null ? before : after;
    }

    /** One number-of-days per city, read just before ("3 days in Kampot") or just after ("Kampot for 3 days") its name; null unless every city has its own. */
    private static List<Integer> assign(List<String> tokens, List<Mention> mentions, boolean beforeName) {
        List<Integer> out = new ArrayList<>();
        Set<Integer> claimed = new java.util.HashSet<>();
        int total = 0;
        for (Mention m : mentions) {
            int numIdx = -1;
            if (beforeName) {
                int j = m.from - 1;
                while (j >= 0 && FILLER.contains(tokens.get(j))) j--;
                if (j >= 1 && isDay(tokens.get(j)) && number(tokens.get(j - 1)) != null) numIdx = j - 1;
            } else {
                int j = m.to;
                while (j < tokens.size() && FILLER.contains(tokens.get(j))) j++;
                if (j + 1 < tokens.size() && number(tokens.get(j)) != null && isDay(tokens.get(j + 1))) numIdx = j;
            }
            if (numIdx < 0 || !claimed.add(numIdx)) return null;
            int days = number(tokens.get(numIdx));
            if (days < 1 || days > 14) return null;
            total += days;
            out.add(days);
        }
        return total >= 1 && total <= 14 ? out : null;
    }

    private static boolean isDay(String t) { return t.equals("day") || t.equals("days") || t.equals("night") || t.equals("nights"); }

    private static Integer number(String t) {
        if (t.matches("\\d{1,2}")) return Integer.valueOf(t);
        return NUMBER_WORDS.get(t);
    }
}

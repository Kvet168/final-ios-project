package com.wayfarer.ai.service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Query expansion for lexical search over the guides. A small, explicit synonym map and stop-word list: this is not semantic understanding.
 */
final class QueryAnalysis {
    private static final Set<String> STOP = Set.of(("a an the and or but if of to in on at for from by with about is are was were be been am do does did "
        + "i you we they he she it my your our their me us what which who whom how when where why can could should would will shall may might "
        + "there here this that these those any some into over under than then so very just also not no yes please tell need want know").split(" "));

    private static final Map<String, List<String>> SYNONYMS = Map.ofEntries(
        Map.entry("wear", List.of("dress", "clothes", "clothing")), Map.entry("clothes", List.of("dress", "clothing")), Map.entry("cost", List.of("price", "budget")),
        Map.entry("cheap", List.of("budget")), Map.entry("money", List.of("dollars", "riel", "payments")), Map.entry("cancel", List.of("cancellation", "refund")),
        Map.entry("refund", List.of("cancellation")), Map.entry("bus", List.of("minibuses", "transport")), Map.entry("taxi", List.of("tuk-tuk", "transport")),
        Map.entry("getting", List.of("transport")), Map.entry("safe", List.of("safety")), Map.entry("dangerous", List.of("safety")),
        Map.entry("pay", List.of("payment", "payments")), Map.entry("kids", List.of("children", "family")), Map.entry("visa", List.of("entry")),
        Map.entry("hours", List.of("open", "opening")));

    private QueryAnalysis() {}

    private static List<String> tokens(String q) {
        return Arrays.stream(q.toLowerCase().replaceAll("[^a-z0-9\\s]", " ").split("\\s+")).filter(t -> t.length() > 2 && !STOP.contains(t)).toList();
    }

    /** to_tsquery text: OR-combined terms and their synonyms. */
    static String toOrQuery(String q) {
        Set<String> out = new LinkedHashSet<>();
        for (String t : tokens(q)) {
            out.add(t.replaceAll("[^a-z0-9]", ""));
            SYNONYMS.getOrDefault(t, List.of()).forEach(s -> out.add(s.replaceAll("[^a-z0-9]", "")));
        }
        out.remove("");
        return String.join(" | ", out.stream().limit(16).toList());
    }

    /** Question concepts, each with its synonyms: a sentence matches a concept once however many synonyms it contains. */
    static List<List<String>> queryGroups(String q, List<String> exclude) {
        Set<String> ex = new LinkedHashSet<>(exclude.stream().map(String::toLowerCase).toList());
        List<List<String>> groups = new ArrayList<>();
        for (String t : new LinkedHashSet<>(tokens(q))) {
            if (ex.contains(t)) continue;
            List<String> g = new ArrayList<>();
            g.add(t);
            g.addAll(SYNONYMS.getOrDefault(t, List.of()));
            groups.add(g.stream().map(x -> x.replaceAll("s$", "")).filter(x -> x.length() > 2).toList());
        }
        return groups;
    }
}

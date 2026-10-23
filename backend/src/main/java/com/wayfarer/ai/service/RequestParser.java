package com.wayfarer.ai.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.wayfarer.ai.dto.PlanDtos.PlanRequest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/** Turns free text into a structured {@link PlanRequest}. Uses the language model when configured, validates its output, and falls back to explicit rules. */
@Component
public class RequestParser {
    private static final Logger log = LoggerFactory.getLogger(RequestParser.class);

    public record Slug(String slug, String name) {}

    public record Parsed(PlanRequest request, String mode, String note) {}

    private static final Map<String, Integer> WORD_NUM = Map.ofEntries(Map.entry("one", 1), Map.entry("a", 1), Map.entry("two", 2), Map.entry("three", 3),
        Map.entry("four", 4), Map.entry("five", 5), Map.entry("six", 6), Map.entry("seven", 7), Map.entry("eight", 8), Map.entry("nine", 9), Map.entry("ten", 10),
        Map.entry("couple", 2));
    private static final String NUM = "(\\d+|one|two|three|four|five|six|seven|eight|nine|ten|a)";
    private static final Pattern DAYS = Pattern.compile(NUM + "[\\s-]*(?:days?|day trip)");
    private static final Pattern NIGHTS = Pattern.compile(NUM + "[\\s-]*nights?");
    private static final Pattern ADULTS = Pattern.compile(NUM + "\\s+adults?");
    private static final Pattern CHILDREN = Pattern.compile(NUM + "\\s+(?:children|kids|child|kid)");
    private static final Pattern BUDGET_SYMBOL = Pattern.compile("(?:\\$|usd\\s?)\\s?(\\d[\\d,]*(?:\\.\\d+)?)");
    private static final Pattern BUDGET_WORD = Pattern.compile("(\\d[\\d,]*(?:\\.\\d+)?)\\s?(?:usd|dollars?|bucks)");
    private static final Pattern PER_DAY = Pattern.compile("per day|a day|/day|daily|each day");

    private static final Map<String, List<String>> INTERESTS = new LinkedHashMap<>();
    static {
        INTERESTS.put("culture", List.of("culture", "cultural", "heritage", "museum", "history", "historical", "art"));
        INTERESTS.put("food", List.of("food", "cuisine", "eat", "eating", "street food", "khmer food", "dining", "restaurant", "foodie"));
        INTERESTS.put("photography", List.of("photo", "photography", "photographs", "instagram", "scenic"));
        INTERESTS.put("temples", List.of("temple", "temples", "pagoda", "wat", "angkor"));
        INTERESTS.put("nature", List.of("nature", "hiking", "trek", "waterfall", "wildlife", "jungle", "national park"));
        INTERESTS.put("beach", List.of("beach", "beaches", "island", "snorkel", "swim"));
        INTERESTS.put("relaxed", List.of("relaxed", "relaxing", "slow", "calm", "walks", "walk", "stroll", "easy"));
        INTERESTS.put("family", List.of("family", "kids", "children", "child"));
        INTERESTS.put("markets", List.of("market", "markets", "shopping", "souvenir"));
        INTERESTS.put("outdoor", List.of("adventure", "outdoor", "kayak", "cycling", "bike"));
    }

    private final LlmClient llm;
    private final ObjectMapper json;

    public RequestParser(LlmClient llm, ObjectMapper json) {
        this.llm = llm;
        this.json = json;
    }

    private static Integer num(String s) { return s.matches("\\d+") ? Integer.valueOf(s) : WORD_NUM.get(s.toLowerCase()); }

    private static Optional<Slug> findSlug(List<Slug> all, String slug) { return all.stream().filter(d -> d.slug().equals(slug)).findFirst(); }

    public PlanRequest parseWithRules(String text, List<Slug> destinations) {
        String t = text.toLowerCase();
        Optional<Slug> dest = destinations.stream().filter(d -> t.contains(d.name().toLowerCase()) || t.contains(d.slug().replace('-', ' '))).findFirst();
        if (dest.isEmpty() && t.contains("angkor")) dest = findSlug(destinations, "siem-reap");
        if (dest.isEmpty() && Pattern.compile("\\bbali\\b|\\bubud\\b").matcher(t).find()) dest = findSlug(destinations, "bali");
        if (dest.isEmpty() && Pattern.compile("\\bsaigon\\b").matcher(t).find()) dest = findSlug(destinations, "ho-chi-minh-city");

        Integer days = null;
        Matcher dm = DAYS.matcher(t);
        boolean dayHit = dm.find();
        Matcher nm = NIGHTS.matcher(t);
        boolean nightHit = !dayHit && nm.find();
        Matcher hit = dayHit ? dm : nightHit ? nm : null;
        if (hit != null) days = num(hit.group(1));
        if (days == null && Pattern.compile("\\bweekend\\b").matcher(t).find()) days = 2;
        if (days == null && Pattern.compile("\\bweek\\b").matcher(t).find()) days = 7;
        if (days != null && nightHit) days = days + 1;

        int adults = 1;
        Matcher am = ADULTS.matcher(t);
        if (am.find()) { Integer n = num(am.group(1)); adults = n == null ? 1 : n; }
        else if (Pattern.compile("\\bcouple\\b|\\bhoneymoon\\b").matcher(t).find()) adults = 2;
        int children = 0;
        Matcher cm = CHILDREN.matcher(t);
        if (cm.find()) { Integer n = num(cm.group(1)); children = n == null ? 0 : n; }

        Double budget = null;
        boolean perDay = false;
        Matcher bm = BUDGET_SYMBOL.matcher(t);
        boolean b1 = bm.find();
        if (!b1) { bm = BUDGET_WORD.matcher(t); b1 = bm.find(); }
        if (b1) {
            budget = Double.valueOf(bm.group(1).replace(",", ""));
            int from = Math.max(0, bm.start() - 15), to = Math.min(t.length(), bm.end() + 20);
            perDay = PER_DAY.matcher(t.substring(from, to)).find();
        }

        List<String> interests = new ArrayList<>();
        INTERESTS.forEach((k, kws) -> { if (kws.stream().anyMatch(w -> Pattern.compile("\\b" + Pattern.quote(w)).matcher(t).find())) interests.add(k); });
        String pace = Pattern.compile("relax|slow|easy|calm").matcher(t).find() ? "relaxed"
            : Pattern.compile("packed|busy|see everything|as much as").matcher(t).find() ? "packed" : "balanced";
        if (children > 0 && !interests.contains("family")) interests.add("family");
        return new PlanRequest(dest.map(Slug::slug).orElse(null), days, adults, children, budget, perDay, interests, pace);
    }

    /** Tries the model for extraction when a key exists; the result is validated and the rules parser is used on any doubt. */
    public Parsed understand(String text, List<Slug> destinations) {
        if (llm.configured()) {
            try {
                String raw = llm.complete("Extract trip parameters. Reply with ONLY a JSON object with keys: destination (one of the provided slugs or null), days (int|null), adults (int), "
                    + "children (int), budgetUsd (number|null), budgetIsPerDay (boolean), interests (array of lowercase keywords), pace ('relaxed'|'balanced'|'packed'). "
                    + "Do not invent values that the user did not state.",
                    "Destination slugs: " + String.join(", ", destinations.stream().map(Slug::slug).toList()) + "\nUser request: " + text, 300, Duration.ofSeconds(8));
                PlanRequest r = json.readValue(LlmClient.extractJson(raw), PlanRequest.class).normalized();
                boolean slugOk = r.destination() == null || findSlug(destinations, r.destination()).isPresent();
                boolean rangeOk = (r.days() == null || (r.days() >= 1 && r.days() <= 14)) && r.adults() >= 1 && r.adults() <= 12 && r.children() >= 0 && r.children() <= 12;
                if (slugOk && rangeOk) return new Parsed(r, "llm", null);
            } catch (Exception e) {
                log.debug("LLM request parsing failed, using rules: {}", e.getMessage());
            }
        }
        return new Parsed(parseWithRules(text, destinations), "rules",
            llm.configured() ? "The language model was unavailable or returned invalid output; the rules-based parser was used." : null);
    }
}

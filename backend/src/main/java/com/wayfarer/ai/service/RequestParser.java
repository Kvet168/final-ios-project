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

    /** A plannable destination. Lists passed to the parser are ordered most popular first. */
    public record Slug(String slug, String name, String country) {
        public Slug(String slug, String name) { this(slug, name, null); }
    }

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
        List<String> words = CityMatcher.tokens(text);
        List<CityMatcher.Mention> mentions = CityMatcher.find(words, destinations);
        List<String> cities = mentions.stream().map(m -> m.slug().slug()).limit(PlanRequest.MAX_DESTINATIONS).toList();
        List<Integer> perCity = cities.size() == mentions.size() ? CityMatcher.daysPerCity(words, mentions) : null;

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
        if (perCity != null) days = perCity.stream().mapToInt(Integer::intValue).sum();   // "3 days in Kampot and 2 in Siem Reap" is a 5-day trip

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
        return new PlanRequest(null, days, adults, children, budget, perDay, interests, pace).withDestinations(cities, perCity);
    }

    /**
     * A country named without a city ("Vietnam, 3 days"): that country's most popular destination, so the user gets a
     * plan instead of a question. [destinations] must be ordered most popular first.
     */
    static Optional<Slug> byCountry(String text, List<Slug> destinations) {
        String t = text.toLowerCase().replace("viet nam", "vietnam");
        return destinations.stream()
            .filter(d -> d.country() != null && Pattern.compile("\\b" + Pattern.quote(d.country().toLowerCase()) + "\\b").matcher(t).find())
            .findFirst();
    }

    /** Fills in the destination from a named country and explains the choice; returns [p] unchanged otherwise. */
    private static Parsed withCountryFallback(Parsed p, String text, List<Slug> destinations) {
        PlanRequest r = p.request();
        if (r.destination() != null) return p;
        Optional<Slug> pick = byCountry(text, destinations);
        if (pick.isEmpty()) return p;
        Slug d = pick.get();
        List<String> others = destinations.stream().filter(o -> d.country().equals(o.country()) && !o.slug().equals(d.slug())).map(Slug::name).limit(4).toList();
        String note = "You named " + d.country() + " without a city, so this plan is for " + d.name() + ", its most visited destination."
            + (others.isEmpty() ? "" : " Name a city to plan another: " + String.join(", ", others) + ".");
        PlanRequest filled = new PlanRequest(d.slug(), r.days(), r.adults(), r.children(), r.budgetUsd(), r.budgetIsPerDay(), r.interests(), r.pace());
        return new Parsed(filled, p.mode(), p.note() == null ? note : p.note() + " " + note);
    }

    /** Tries the model for extraction when a key exists; the result is validated and the rules parser is used on any doubt. */
    public Parsed understand(String text, List<Slug> destinations) {
        return withCountryFallback(understandRaw(text, destinations), text, destinations);
    }

    /**
     * The model's cities, cross-checked against the rules parser: if the text clearly names more cities than the model returned
     * (it dropped one), the rules parser's list wins. Per-city days are kept only when they match the cities and the total.
     */
    private PlanRequest reconcileCities(PlanRequest r, String text, List<Slug> destinations) {
        PlanRequest rules = parseWithRules(text, destinations);
        if (rules.allDestinations().size() > r.allDestinations().size()) {
            r = r.withDestinations(rules.allDestinations(), rules.daysPerDestination());
            if (rules.daysPerDestination() != null) r = new PlanRequest(r.destination(), rules.days(), r.adults(), r.children(), r.budgetUsd(), r.budgetIsPerDay(), r.interests(), r.pace(), r.alsoVisit(), r.daysPerDestination());
        }
        List<Integer> per = r.daysPerDestination();
        boolean perOk = per != null && per.size() == r.allDestinations().size() && r.days() != null && per.stream().mapToInt(Integer::intValue).sum() == r.days();
        return perOk || per == null ? r : r.withDestinations(r.allDestinations(), null);
    }

    private Parsed understandRaw(String text, List<Slug> destinations) {
        if (llm.configured()) {
            try {
                String raw = llm.complete("Extract trip parameters. Reply with ONLY a JSON object with keys: destination (the FIRST city, one of the provided slugs or null), "
                    + "alsoVisit (array of further city slugs in the order they will be visited, empty when only one city), days (total trip days, int|null), "
                    + "daysPerDestination (array of ints for [destination, ...alsoVisit] when the user states days per city, else null), adults (int), "
                    + "children (int), budgetUsd (number|null), budgetIsPerDay (boolean), interests (array of lowercase keywords), pace ('relaxed'|'balanced'|'packed'). "
                    + "Do not invent values that the user did not state. People often mis-spell or join place names (siemreap = siem-reap); map them to the provided slugs.",
                    "Destination slugs: " + String.join(", ", destinations.stream().map(Slug::slug).toList()) + "\nUser request: " + text, 300, Duration.ofSeconds(8));
                PlanRequest r = json.readValue(LlmClient.extractJson(raw), PlanRequest.class).normalized();
                boolean slugOk = r.allDestinations().stream().allMatch(c -> findSlug(destinations, c).isPresent()) && r.allDestinations().size() <= PlanRequest.MAX_DESTINATIONS;
                boolean rangeOk = (r.days() == null || (r.days() >= 1 && r.days() <= 14)) && r.adults() >= 1 && r.adults() <= 12 && r.children() >= 0 && r.children() <= 12;
                if (slugOk && rangeOk) {
                    r = reconcileCities(r, text, destinations);
                    return new Parsed(r, "llm", null);
                }
            } catch (Exception e) {
                log.warn("LLM request parsing failed, using rules: {}", e.getMessage());
            }
        }
        return new Parsed(parseWithRules(text, destinations), "rules",
            llm.configured() ? "The language model was unavailable or returned invalid output; the rules-based parser was used." : null);
    }
}

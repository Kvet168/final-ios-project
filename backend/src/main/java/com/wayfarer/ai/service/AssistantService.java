package com.wayfarer.ai.service;

import com.wayfarer.ai.dto.AssistantDtos.Answer;
import com.wayfarer.ai.dto.AssistantDtos.Card;
import com.wayfarer.ai.dto.AssistantDtos.DestinationRef;
import com.wayfarer.ai.dto.AssistantDtos.Source;
import com.wayfarer.catalog.repository.AccommodationRepository;
import com.wayfarer.catalog.repository.AttractionRepository;
import com.wayfarer.catalog.repository.DestinationRepository;
import com.wayfarer.common.Rows;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Travel assistant. Detects the question's intent and destination with explicit rules, answers from the structured destination record and the
 * approved guides (never from memory), and returns tappable cards plus follow-up questions. When a language-model key is configured it only
 * rewrites the same grounded context into friendlier prose.
 */
@Service
public class AssistantService {
    private static final Logger log = LoggerFactory.getLogger(AssistantService.class);
    private static final String DISCLAIMER = "Answers are drawn from WAYFARER's educational demo guides. Verify prices, opening hours, visas and safety advice with official sources before travelling.";
    private static final Pattern SENTENCE = Pattern.compile("[^.!?]+[.!?]+(\\s|$)|[^.!?]+$");
    private static final Map<String, String> ALIASES = Map.of("angkor", "siem-reap", "ubud", "bali", "saigon", "ho-chi-minh-city", "hcmc", "ho-chi-minh-city",
        "george town", "penang", "banlung", "ratanakiri", "kl", "kuala-lumpur");

    private enum Intent { SMALLTALK, BEST_TIME, TRANSPORT, BUDGET, THINGS_TO_DO, FOOD, STAY, PRACTICAL, PLAN, OVERVIEW, GENERAL;
        String id() { return name().toLowerCase(); } }

    private static final Map<Intent, Pattern> INTENTS = new LinkedHashMap<>();
    static {
        int i = Pattern.CASE_INSENSITIVE;
        INTENTS.put(Intent.SMALLTALK, Pattern.compile("^\\s*(hi|hello|hey|hola|good (morning|afternoon|evening)|thanks?|thank you|ok(ay)?|help|who are you|what can you do)\\b[\\s!.?]*$", i));
        INTENTS.put(Intent.BEST_TIME, Pattern.compile("\\b(best time|when (to|should)|season|weather|climate|rainy|dry season|monsoon|month)\\b", i));
        INTENTS.put(Intent.TRANSPORT, Pattern.compile("\\b(get(ting)? (around|to|there)|transport|tuk|taxi|grab|bus|train|metro|ferry|boat|flight|airport|bike|scooter)\\b", i));
        INTENTS.put(Intent.BUDGET, Pattern.compile("\\b(budget|cost|how much|price|cheap|afford|expensive|spend|per day)\\b", i));
        INTENTS.put(Intent.FOOD, Pattern.compile("\\b(eat|food|dish|restaurant|cafe|coffee|dinner|lunch|breakfast|street food|cuisine|vegetarian)\\b", i));
        INTENTS.put(Intent.STAY, Pattern.compile("\\b(hotel|stay|sleep|accommodation|hostel|resort|guesthouse|room)\\b", i));
        INTENTS.put(Intent.PLAN, Pattern.compile("\\b(itinerary|plan|route|days? in|\\d+[- ]?day)\\b", i));
        INTENTS.put(Intent.THINGS_TO_DO, Pattern.compile("\\b(things? to do|what to (do|see)|see|visit|attractions?|sights?|activities|explore|highlights)\\b", i));
        INTENTS.put(Intent.PRACTICAL, Pattern.compile("\\b(wear|dress|clothes|money|currency|dollar|riel|safe|safety|visa|tip|tipping|sim|wifi|etiquette|rules|scam|water)\\b", i));
    }

    private record Facts(UUID id, String slug, String name, String country, String shortDescription, String bestPeriod, String transportInfo, String practicalInfo,
                         Double dailyBudgetUsd, String coverImage) {}

    private record CachedDestinations(long at, List<Facts> rows) {}

    private final DestinationRepository destinations;
    private final AccommodationRepository accommodations;
    private final AttractionRepository attractions;
    private final RetrievalService retrieval;
    private final LlmClient llm;
    private final AtomicReference<CachedDestinations> cache = new AtomicReference<>();

    public AssistantService(DestinationRepository destinations, AccommodationRepository accommodations, AttractionRepository attractions, RetrievalService retrieval, LlmClient llm) {
        this.destinations = destinations;
        this.accommodations = accommodations;
        this.attractions = attractions;
        this.retrieval = retrieval;
        this.llm = llm;
    }

    private List<Facts> loadDestinations() {
        CachedDestinations c = cache.get();
        if (c != null && System.currentTimeMillis() - c.at < 5 * 60_000) return c.rows;
        List<Facts> rows = destinations.assistantFacts().stream().map(r -> new Facts(
            (UUID) r.get("id"), Rows.str(r, "slug"), Rows.str(r, "name"), Rows.str(r, "country"), Rows.str(r, "short_description"), Rows.str(r, "best_period"),
            Rows.str(r, "transport_info"), Rows.str(r, "practical_info"), r.get("daily_budget_usd") == null ? null : ((Number) r.get("daily_budget_usd")).doubleValue(),
            Rows.str(r, "cover_image"))).toList();
        cache.set(new CachedDestinations(System.currentTimeMillis(), rows));
        return rows;
    }

    private static Facts findDestination(String q, List<Facts> dests, String hint) {
        String t = " " + q.toLowerCase().replaceAll("[^a-z\\s]", " ").replaceAll("\\s+", " ") + " ";
        Facts best = null;
        int bestLen = 0;
        for (Facts d : dests) {
            for (String n : List.of(d.name.replaceAll("\\s*\\(.*\\)", "").toLowerCase(), d.slug.replace('-', ' '))) {
                if (t.contains(" " + n + " ") && n.length() > bestLen) { best = d; bestLen = n.length(); }
            }
        }
        for (Map.Entry<String, String> a : ALIASES.entrySet()) {
            if (t.contains(" " + a.getKey() + " ") && a.getKey().length() > bestLen) {
                Facts d = dests.stream().filter(x -> x.slug.equals(a.getValue())).findFirst().orElse(null);
                if (d != null) { best = d; bestLen = a.getKey().length(); }
            }
        }
        // A destination named in the question wins; the hint (e.g. the previous topic) only fills the gap.
        if (best != null) return best;
        return hint == null ? null : dests.stream().filter(d -> d.slug.equals(hint)).findFirst().orElse(null);
    }

    private static Intent detectIntent(String q, boolean hasDest) {
        for (Map.Entry<Intent, Pattern> e : INTENTS.entrySet()) if (e.getValue().matcher(q).find()) return e.getKey();
        return hasDest ? Intent.OVERVIEW : Intent.GENERAL;
    }

    private static String usd(double n) { return "$" + Math.round(n); }

    private record Picked(String text, double score, int doc, int pos) {}

    private record BestSentences(String text, List<Source> used) {}

    /** Picks the sentences that best match the question concepts (extractive summary), counting each concept once. */
    private static BestSentences bestSentences(List<Source> chunks, List<List<String>> groups, int maxSentences, int offset, int minScore) {
        List<Source> docs = new ArrayList<>();
        for (Source c : chunks) if (docs.stream().noneMatch(d -> d.slug().equals(c.slug()))) docs.add(c);   // one entry per document
        List<Picked> picked = new ArrayList<>();
        for (Source c : chunks) {
            int doc = indexOf(docs, c.slug());
            String body = c.snippet().startsWith(c.title()) ? c.snippet().substring(c.title().length()).replaceFirst("^[.\\s]+", "") : c.snippet();
            Matcher m = SENTENCE.matcher(body);
            List<String> sents = new ArrayList<>();
            while (m.find()) sents.add(m.group());
            if (sents.isEmpty()) sents.add(body);
            for (int pos = 0; pos < sents.size(); pos++) {
                String s = sents.get(pos).trim();
                if (s.length() < 25) continue;
                String low = (c.title() + " " + s).toLowerCase();
                int hits = 0;
                for (List<String> g : groups) if (g.stream().anyMatch(low::contains)) hits++;
                if (hits >= minScore) picked.add(new Picked(s, hits + (pos == 0 ? 0.2 : 0), doc, pos));
            }
        }
        picked.sort(Comparator.comparingDouble(Picked::score).reversed());
        Set<String> seen = new HashSet<>();
        List<Picked> out = new ArrayList<>();
        for (Picked p : picked) {
            String key = p.text.toLowerCase().substring(0, Math.min(60, p.text.length()));
            if (seen.contains(key) || out.stream().filter(o -> o.doc == p.doc).count() >= 2) continue;
            seen.add(key);
            out.add(p);
            if (out.size() >= maxSentences) break;
        }
        out.sort(Comparator.comparingInt(Picked::doc).thenComparingInt(Picked::pos));
        List<Integer> usedIdx = new ArrayList<>(new LinkedHashSet<>(out.stream().map(Picked::doc).toList()));
        String text = String.join(" ", out.stream().map(o -> o.text + " [" + (usedIdx.indexOf(o.doc) + 1 + offset) + "]").toList());
        return new BestSentences(text, usedIdx.stream().map(docs::get).toList());
    }

    private static int indexOf(List<Source> docs, String slug) {
        for (int i = 0; i < docs.size(); i++) if (docs.get(i).slug().equals(slug)) return i;
        return -1;
    }

    /** Lexical retrieval ranks by term frequency only; nudge it with what we know about the question. */
    private static List<Source> rerank(List<Source> sources, String q, Intent intent, List<String> countries) {
        String t = q.toLowerCase();
        String country = countries.stream().filter(c -> t.contains(c.toLowerCase())).findFirst().orElse(null);
        Map<Intent, List<String>> catBonus = Map.of(Intent.PRACTICAL, List.of("etiquette", "faq", "safety"), Intent.TRANSPORT, List.of("transport"),
            Intent.THINGS_TO_DO, List.of("guide"), Intent.PLAN, List.of("guide"), Intent.FOOD, List.of("guide", "faq"));
        boolean wantPolicy = Pattern.compile("cancel|refund|payment|pay |booking|check-?in|check-?out").matcher(t).find();
        return sources.stream().map(s -> {
            double b = s.score();
            String snip = s.snippet().toLowerCase(), title = s.title().toLowerCase();
            if (country != null && (snip.contains(country.toLowerCase()) || title.contains(country.toLowerCase()))) b += 0.04;
            if (country != null && !snip.contains(country.toLowerCase()) && !"policy".equals(s.category())) b -= 0.02;
            if (catBonus.getOrDefault(intent, List.of()).contains(s.category())) b += 0.03;
            if (wantPolicy && "policy".equals(s.category())) b += 0.05;
            for (String w : t.split("\\W+")) if (w.length() > 3 && title.contains(w)) b += 0.015;
            return s.withScore(b);
        }).sorted(Comparator.comparingDouble(Source::score).reversed()).toList();
    }

    private static List<String> followUps(Intent intent, Facts d) {
        if (d == null) return List.of("What is the best time to visit Siem Reap?", "How do I get around Phnom Penh?", "What should I wear at temples?", "How does free cancellation work?");
        Map<Intent, String> base = new LinkedHashMap<>();
        base.put(Intent.BEST_TIME, "What is the best time to visit " + d.name + "?");
        base.put(Intent.TRANSPORT, "How do I get around " + d.name + "?");
        base.put(Intent.BUDGET, "How much does a day in " + d.name + " cost?");
        base.put(Intent.THINGS_TO_DO, "What are the top things to do in " + d.name + "?");
        base.put(Intent.FOOD, "What should I eat in " + d.name + "?");
        base.put(Intent.STAY, "Where should I stay in " + d.name + "?");
        base.put(Intent.PRACTICAL, "Any practical tips for " + d.name + "?");
        return base.entrySet().stream().filter(e -> e.getKey() != intent).map(Map.Entry::getValue).limit(4).toList();
    }

    private List<Card> destinationCards(Facts d, Intent intent) {
        List<Card> cards = new ArrayList<>();
        if (intent == Intent.STAY) {
            for (Map<String, Object> r : accommodations.cardsForDestination(d.id, 3)) {
                cards.add(new Card("stay", Rows.str(r, "name"), "★".repeat(Rows.integer(r, "stars")) + "  from " + usd(((Number) r.get("from_price_usd")).doubleValue()) + "/night",
                    Rows.str(r, "cover_image"), "/stays/" + r.get("slug")));
            }
        } else {
            for (Map<String, Object> r : attractions.cardsForDestination(d.id, intent == Intent.FOOD, 3)) {
                Object price = r.get("price_usd");
                String p = price == null ? "" : ((Number) price).doubleValue() == 0 ? "  ·  Free" : "  ·  " + usd(((Number) price).doubleValue());
                cards.add(new Card("place", Rows.str(r, "name"), r.get("category") + p, Rows.str(r, "image"), "/destinations/" + d.slug));
            }
        }
        cards.add(0, new Card("destination", d.name, d.country, d.coverImage, "/destinations/" + d.slug));
        return cards;
    }

    public Answer answer(String question, String destinationHint) {
        String q = question.trim();
        List<Facts> dests = loadDestinations();
        Facts dest = findDestination(q, dests, destinationHint);
        Intent intent = detectIntent(q, dest != null);
        DestinationRef destRef = dest == null ? null : new DestinationRef(dest.slug, dest.name);

        if (intent == Intent.SMALLTALK) {
            return new Answer("Hi! I'm your WAYFARER travel guide. Ask me about the best time to go, getting around, budgets, food, where to stay or local etiquette across Cambodia and "
                + "Southeast Asia, and I'll answer from our guides and listings.", "retrieval-only", List.of(), true, DISCLAIMER, intent.id(), null, List.of(), followUps(Intent.GENERAL, null));
        }

        boolean wantsCards = dest != null && List.of(Intent.STAY, Intent.FOOD, Intent.THINGS_TO_DO, Intent.OVERVIEW).contains(intent);
        List<Source> found = retrieval.retrieve(q, 8, dest == null ? null : dest.slug);
        List<Card> cards = wantsCards ? destinationCards(dest, intent) : List.of();

        List<Source> ranked = rerank(found, q, intent, dests.stream().map(d -> d.country).distinct().toList());
        String baseName = dest == null ? "" : dest.name.replaceAll("\\s*\\(.*\\)", "").toLowerCase();
        double top = ranked.isEmpty() ? 0 : ranked.get(0).score();
        // For a destination question, guides that never mention that destination (or its country) cannot answer it; policy guides always can.
        List<Source> sources = ranked.stream().filter(s -> s.score() >= top * 0.6).filter(s -> dest == null || "policy".equals(s.category())
            || (s.title() + " " + s.snippet()).toLowerCase().contains(baseName) || s.snippet().toLowerCase().contains(dest.country.toLowerCase())).toList();
        List<String> exclude = new ArrayList<>();
        if (dest != null) {
            exclude.addAll(List.of(dest.name.toLowerCase().split("\\W+")));
            exclude.addAll(List.of(dest.slug.split("-")));
        }
        List<List<String>> groups = QueryAnalysis.queryGroups(q, exclude);

        // Structured facts straight from the destination record: exact, instant and always grounded.
        List<String> facts = new ArrayList<>();
        if (dest != null) {
            switch (intent) {
                case BEST_TIME -> { if (dest.bestPeriod != null) facts.add("Best time to visit " + dest.name + ": " + dest.bestPeriod.replaceAll("\\.$", "") + "."); }
                case TRANSPORT -> { if (dest.transportInfo != null) facts.add(dest.transportInfo); }
                case PRACTICAL -> { if (dest.practicalInfo != null) facts.add(dest.practicalInfo); }
                case BUDGET -> {
                    Object cheap = accommodations.minPriceForDestination(dest.id);
                    if (dest.dailyBudgetUsd != null) {
                        facts.add("A comfortable day in " + dest.name + " costs around " + usd(dest.dailyBudgetUsd) + " per person on our indicative budget"
                            + (cheap != null ? ", with rooms from about " + usd(((Number) cheap).doubleValue()) + " a night" : "")
                            + ". Entrance fees for major sites are usually the biggest single cost.");
                    }
                }
                case OVERVIEW -> {
                    facts.add(dest.shortDescription);
                    if (dest.bestPeriod != null) facts.add("Best time: " + dest.bestPeriod);
                }
                case THINGS_TO_DO -> { List<String> n = cards.stream().filter(c -> "place".equals(c.type())).map(Card::title).toList(); if (!n.isEmpty()) facts.add("Top picks in " + dest.name + ": " + String.join(", ", n) + "."); }
                case FOOD -> { List<String> n = cards.stream().filter(c -> "place".equals(c.type())).map(Card::title).toList(); if (!n.isEmpty()) facts.add("Places to eat in " + dest.name + ": " + String.join(", ", n) + "."); }
                case STAY -> { List<String> n = cards.stream().filter(c -> "stay".equals(c.type())).map(Card::title).toList(); if (!n.isEmpty()) facts.add("Top-rated stays in " + dest.name + ": " + String.join(", ", n) + "."); }
                default -> { }
            }
        }

        // With a structured fact in hand (cited as [1]), only strongly matching guide sentences are added on top of it.
        int minScore = !facts.isEmpty() || groups.size() >= 3 ? 2 : 1;
        BestSentences sentences = bestSentences(sources, groups, facts.isEmpty() ? 3 : 2, facts.isEmpty() ? 0 : 1, minScore);
        List<Source> factSource = dest != null && !facts.isEmpty()
            ? List.of(new Source(dest.id, dest.slug, dest.name + " destination guide", "WAYFARER destination data", "destination", String.join(" ", facts), 1, false)) : List.of();
        List<Source> allSources = new ArrayList<>(factSource);
        allSources.addAll(sentences.used);
        String factText = facts.isEmpty() ? "" : String.join(" ", facts) + " [1]";

        if (factText.isEmpty() && sentences.text.isEmpty()) {
            String hint = dest != null ? "I don't have specifics on that for " + dest.name + " yet." : "I couldn't find that in the approved travel guides, so I won't guess.";
            return new Answer(hint + " Try asking about the best time to go, transport, budget, food or places to stay" + (dest != null ? " in " + dest.name : "") + ".",
                "retrieval-only", List.of(), false, DISCLAIMER, intent.id(), destRef, cards, followUps(intent, dest));
        }

        if (llm.configured()) {
            try {
                StringBuilder ctx = new StringBuilder();
                for (int i = 0; i < allSources.size(); i++) ctx.append(i > 0 ? "\n\n" : "").append('[').append(i + 1).append("] ").append(allSources.get(i).title()).append(": ").append(allSources.get(i).snippet());
                String text = llm.complete("You are a friendly travel guide for Southeast Asia. Answer ONLY using the numbered context. Cite sources like [1]. If the context does not contain "
                    + "the answer, say you do not have that information. Never invent prices, opening hours or policies. Keep it under 120 words, in short paragraphs.",
                    "Context:\n" + ctx + "\n\nQuestion: " + q, 350, Duration.ofSeconds(9));
                if (!text.isBlank()) return new Answer(text, "llm", allSources, true, DISCLAIMER, intent.id(), destRef, cards, followUps(intent, dest));
            } catch (Exception e) {
                log.warn("LLM answer failed, using extractive answer: {}", e.getMessage());
            }
        }
        List<String> parts = new ArrayList<>();
        if (!factText.isEmpty()) parts.add(factText);
        if (!sentences.text.isEmpty()) parts.add(sentences.text);
        return new Answer(String.join("\n\n", parts), "retrieval-only", allSources, true, DISCLAIMER, intent.id(), destRef, cards, followUps(intent, dest));
    }
}

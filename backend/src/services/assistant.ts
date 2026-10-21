import type { Db } from "../db/index.js";
import { isLlmConfigured, llmComplete } from "./llm.js";
import { queryGroups, retrieve, type Source } from "./rag.js";

/**
 * Travel assistant. Understands the question's intent and destination with explicit rules, answers from the structured
 * destination record and the approved guides (never from memory), and returns tappable cards plus follow-up questions.
 * When a language-model key is configured it only rewrites the same grounded context into friendlier prose.
 */

export interface Card { type: "destination" | "place" | "stay"; title: string; subtitle: string; image: string | null; route: string }
export interface Answer {
  answer: string; mode: "retrieval-only" | "llm"; sources: Source[]; grounded: boolean; disclaimer: string;
  intent: string; destination: { slug: string; name: string } | null; cards: Card[]; followUps: string[];
}

const DISCLAIMER = "Answers are drawn from WAYFARER's educational demo guides. Verify prices, opening hours, visas and safety advice with official sources before travelling.";

interface DestFacts {
  id: string; slug: string; name: string; country: string; short_description: string; best_period: string | null; transport_info: string | null;
  practical_info: string | null; daily_budget_usd: number | null; cover_image: string | null;
}

let destCache: { at: number; rows: DestFacts[] } | null = null;
async function loadDestinations(db: Db): Promise<DestFacts[]> {
  if (destCache && Date.now() - destCache.at < 5 * 60_000) return destCache.rows;
  const { rows } = await db.query<DestFacts>(
    `SELECT id, slug, name, country, short_description, best_period, transport_info, practical_info, daily_budget_usd, cover_image
       FROM destinations WHERE deleted_at IS NULL`);
  destCache = { at: Date.now(), rows };
  return rows;
}

const ALIASES: Record<string, string> = {
  angkor: "siem-reap", ubud: "bali", saigon: "ho-chi-minh-city", hcmc: "ho-chi-minh-city", "george town": "penang", banlung: "ratanakiri", kl: "kuala-lumpur",
};

function findDestination(q: string, dests: DestFacts[], hint?: string): DestFacts | null {
  const t = ` ${q.toLowerCase().replace(/[^a-z\s]/g, " ").replace(/\s+/g, " ")} `;
  let best: DestFacts | null = null; let bestLen = 0;
  for (const d of dests) {
    for (const n of [d.name.replace(/\s*\(.*\)/, "").toLowerCase(), d.slug.replace(/-/g, " ")]) {
      if (t.includes(` ${n} `) && n.length > bestLen) { best = d; bestLen = n.length; }
    }
  }
  for (const [a, slug] of Object.entries(ALIASES)) {
    if (t.includes(` ${a} `) && a.length > bestLen) {
      const d = dests.find((x) => x.slug === slug);
      if (d) { best = d; bestLen = a.length; }
    }
  }
  // A destination named in the question wins; the hint (e.g. the previous topic) only fills the gap.
  return best ?? (hint ? dests.find((d) => d.slug === hint) ?? null : null);
}

type Intent = "smalltalk" | "best_time" | "transport" | "budget" | "things_to_do" | "food" | "stay" | "practical" | "plan" | "overview" | "general";
const INTENT_PATTERNS: [Intent, RegExp][] = [
  ["smalltalk", /^\s*(hi|hello|hey|hola|good (morning|afternoon|evening)|thanks?|thank you|ok(ay)?|help|who are you|what can you do)\b[\s!.?]*$/i],
  ["best_time", /\b(best time|when (to|should)|season|weather|climate|rainy|dry season|monsoon|month)\b/i],
  ["transport", /\b(get(ting)? (around|to|there)|transport|tuk|taxi|grab|bus|train|metro|ferry|boat|flight|airport|bike|scooter)\b/i],
  ["budget", /\b(budget|cost|how much|price|cheap|afford|expensive|spend|per day)\b/i],
  ["food", /\b(eat|food|dish|restaurant|cafe|coffee|dinner|lunch|breakfast|street food|cuisine|vegetarian)\b/i],
  ["stay", /\b(hotel|stay|sleep|accommodation|hostel|resort|guesthouse|room)\b/i],
  ["plan", /\b(itinerary|plan|route|days? in|\d+[- ]?day)\b/i],
  ["things_to_do", /\b(things? to do|what to (do|see)|see|visit|attractions?|sights?|activities|explore|highlights)\b/i],
  ["practical", /\b(wear|dress|clothes|money|currency|dollar|riel|safe|safety|visa|tip|tipping|sim|wifi|etiquette|rules|scam|water)\b/i],
];

function detectIntent(q: string, hasDest: boolean): Intent {
  for (const [i, re] of INTENT_PATTERNS) if (re.test(q)) return i;
  return hasDest ? "overview" : "general";
}

const usd = (n: number) => `$${Math.round(n)}`;

/** Picks the sentences that best match the question concepts (extractive summary), counting each concept once. */
export function bestSentences(chunks: Source[], groups: string[][], maxSentences = 3, offset = 0, minScore = 1): { text: string; used: Source[] } {
  // One entry per document so the same guide is never cited twice.
  const docs: Source[] = [];
  chunks.forEach((c) => { if (!docs.some((d) => d.slug === c.slug)) docs.push(c); });
  const picked: { s: string; score: number; doc: number; pos: number }[] = [];
  chunks.forEach((c) => {
    const doc = docs.findIndex((d) => d.slug === c.slug);
    const body = c.snippet.startsWith(c.title) ? c.snippet.slice(c.title.length).replace(/^[.\s]+/, "") : c.snippet;
    const sents = body.match(/[^.!?]+[.!?]+(\s|$)|[^.!?]+$/g) ?? [body];
    sents.forEach((raw, pos) => {
      const s = raw.trim();
      if (s.length < 25) return;
      const low = `${c.title} ${s}`.toLowerCase();   // the title is context for every sentence in the guide
      const hits = groups.reduce((n, g) => n + (g.some((t) => low.includes(t)) ? 1 : 0), 0);
      if (hits >= minScore) picked.push({ s, score: hits + (pos === 0 ? 0.2 : 0), doc, pos });
    });
  });
  picked.sort((a, b) => b.score - a.score);
  const seen = new Set<string>(); const out: typeof picked = [];
  for (const p of picked) {
    const key = p.s.toLowerCase().slice(0, 60);
    if (seen.has(key) || out.filter((o) => o.doc === p.doc).length >= 2) continue;
    seen.add(key); out.push(p);
    if (out.length >= maxSentences) break;
  }
  out.sort((a, b) => a.doc - b.doc || a.pos - b.pos);
  const usedIdx = [...new Set(out.map((o) => o.doc))];
  return { text: out.map((o) => `${o.s} [${usedIdx.indexOf(o.doc) + 1 + offset}]`).join(" "), used: usedIdx.map((i) => docs[i]) };
}

/** Lexical retrieval returns by term frequency only; nudge it with what we know about the question. */
function rerank(sources: Source[], q: string, intent: Intent, countries: string[]): Source[] {
  const t = q.toLowerCase();
  const country = countries.find((c) => t.includes(c.toLowerCase()));
  const catBonus: Partial<Record<Intent, string[]>> = { practical: ["etiquette", "faq", "safety"], transport: ["transport"], things_to_do: ["guide"], plan: ["guide"], food: ["guide", "faq"] };
  const wantPolicy = /cancel|refund|payment|pay |booking|check-?in|check-?out/.test(t);
  return [...sources].map((s) => {
    let b = s.score;
    if (country && (s.snippet.toLowerCase().includes(country.toLowerCase()) || s.title.toLowerCase().includes(country.toLowerCase()))) b += 0.04;
    if (country && !s.snippet.toLowerCase().includes(country.toLowerCase()) && s.category !== "policy") b -= 0.02;
    if ((catBonus[intent] ?? []).includes(s.category)) b += 0.03;
    if (wantPolicy && s.category === "policy") b += 0.05;
    for (const w of t.split(/\W+/).filter((x) => x.length > 3)) if (s.title.toLowerCase().includes(w)) b += 0.015;
    return { s, b };
  }).sort((x, y) => y.b - x.b).map((x) => ({ ...x.s, score: x.b }));
}

function followUps(intent: Intent, d: DestFacts | null): string[] {
  if (!d) return ["What is the best time to visit Siem Reap?", "How do I get around Phnom Penh?", "What should I wear at temples?", "How does free cancellation work?"];
  const base: Record<string, string> = {
    best_time: `What is the best time to visit ${d.name}?`, transport: `How do I get around ${d.name}?`, budget: `How much does a day in ${d.name} cost?`,
    things_to_do: `What are the top things to do in ${d.name}?`, food: `What should I eat in ${d.name}?`, stay: `Where should I stay in ${d.name}?`,
    practical: `Any practical tips for ${d.name}?`,
  };
  return Object.entries(base).filter(([k]) => k !== intent).map(([, v]) => v).slice(0, 4);
}

async function destinationCards(db: Db, d: DestFacts, intent: Intent): Promise<Card[]> {
  const cards: Card[] = [];
  if (intent === "stay") {
    const { rows } = await db.query<any>(
      `SELECT slug, name, stars, from_price_usd, cover_image FROM accommodations
        WHERE destination_id=$1 AND deleted_at IS NULL ORDER BY rating_avg DESC, stars DESC LIMIT 3`, [d.id]);
    for (const r of rows) cards.push({ type: "stay", title: r.name, subtitle: `${"★".repeat(r.stars)}  from ${usd(r.from_price_usd)}/night`, image: r.cover_image, route: `/stays/${r.slug}` });
  } else {
    const food = intent === "food";
    const { rows } = await db.query<any>(
      `SELECT name, category, image, price_usd FROM attractions
        WHERE destination_id=$1 AND deleted_at IS NULL AND ((kind = 'restaurant') = $2::boolean)
        ORDER BY (image IS NOT NULL) DESC, (price_usd = 0) DESC, name LIMIT 3`, [d.id, food]);
    for (const r of rows) {
      const price = r.price_usd === 0 ? "  ·  Free" : r.price_usd ? `  ·  ${usd(r.price_usd)}` : "";
      cards.push({ type: "place", title: r.name, subtitle: `${r.category}${price}`, image: r.image, route: `/destinations/${d.slug}` });
    }
  }
  cards.unshift({ type: "destination", title: d.name, subtitle: d.country, image: d.cover_image, route: `/destinations/${d.slug}` });
  return cards;
}

export async function answerQuestion(db: Db, question: string, destinationSlug?: string): Promise<Answer> {
  const q = question.trim();
  const dests = await loadDestinations(db);
  const dest = findDestination(q, dests, destinationSlug);
  const intent = detectIntent(q, !!dest);
  const destRef = dest ? { slug: dest.slug, name: dest.name } : null;

  if (intent === "smalltalk") {
    return {
      answer: "Hi! I'm your WAYFARER travel guide. Ask me about the best time to go, getting around, budgets, food, where to stay or local etiquette across Cambodia and Southeast Asia, and I'll answer from our guides and listings.",
      mode: "retrieval-only", sources: [], grounded: true, disclaimer: DISCLAIMER, intent, destination: null, cards: [], followUps: followUps("general", null),
    };
  }

  const wantsCards = !!dest && ["stay", "food", "things_to_do", "overview"].includes(intent);
  const [found, cards] = await Promise.all([
    retrieve(db, q, 8, dest?.slug),
    wantsCards ? destinationCards(db, dest!, intent) : Promise.resolve([] as Card[]),
  ]);

  const ranked = rerank(found, q, intent, [...new Set(dests.map((d) => d.country))]);
  // Keep only guides that rank close to the best one, so a stray keyword match cannot pad the answer.
  const baseName = dest ? dest.name.replace(/\s*\(.*\)/, "").toLowerCase() : "";
  // For a destination question, guides that never mention that destination (or its country) cannot answer it; policy guides always can.
  const about = (s: Source) => !dest || s.category === "policy" || `${s.title} ${s.snippet}`.toLowerCase().includes(baseName) || s.snippet.toLowerCase().includes(dest.country.toLowerCase());
  const sources = ranked.filter((s) => s.score >= (ranked[0]?.score ?? 0) * 0.6).filter(about);
  const groups = queryGroups(q, dest ? [...dest.name.toLowerCase().split(/\W+/), ...dest.slug.split("-")] : []);

  // Structured facts straight from the destination record: exact, instant and always grounded.
  const facts: string[] = [];
  if (dest) {
    switch (intent) {
      case "best_time": if (dest.best_period) facts.push(`Best time to visit ${dest.name}: ${dest.best_period.replace(/\.$/, "")}.`); break;
      case "transport": if (dest.transport_info) facts.push(dest.transport_info); break;
      case "practical": if (dest.practical_info) facts.push(dest.practical_info); break;
      case "budget": {
        const cheap = (await db.query<any>("SELECT MIN(from_price_usd) AS p FROM accommodations WHERE destination_id=$1 AND deleted_at IS NULL", [dest.id])).rows[0]?.p;
        if (dest.daily_budget_usd) {
          facts.push(`A comfortable day in ${dest.name} costs around ${usd(dest.daily_budget_usd)} per person on our indicative budget${cheap ? `, with rooms from about ${usd(cheap)} a night` : ""}. Entrance fees for major sites are usually the biggest single cost.`);
        }
        break;
      }
      case "overview": facts.push(dest.short_description); if (dest.best_period) facts.push(`Best time: ${dest.best_period}`); break;
      case "things_to_do": { const n = cards.filter((c) => c.type === "place").map((c) => c.title); if (n.length) facts.push(`Top picks in ${dest.name}: ${n.join(", ")}.`); break; }
      case "food": { const n = cards.filter((c) => c.type === "place").map((c) => c.title); if (n.length) facts.push(`Places to eat in ${dest.name}: ${n.join(", ")}.`); break; }
      case "stay": { const n = cards.filter((c) => c.type === "stay").map((c) => c.title); if (n.length) facts.push(`Top-rated stays in ${dest.name}: ${n.join(", ")}.`); break; }
      default: break;
    }
  }

  // With a structured fact in hand (cited as [1]), only strongly matching guide sentences are added on top of it.
  const minScore = facts.length || groups.length >= 3 ? 2 : 1;
  const sentences = bestSentences(sources, groups, facts.length ? 2 : 3, facts.length ? 1 : 0, minScore);
  const factSource: Source[] = dest && facts.length
    ? [{ documentId: dest.id, slug: dest.slug, title: `${dest.name} destination guide`, source: "WAYFARER destination data", category: "destination", snippet: facts.join(" "), score: 1, isDemo: false }]
    : [];
  const allSources = [...factSource, ...sentences.used];
  const factText = facts.length ? `${facts.join(" ")} [1]` : "";

  if (!factText && !sentences.text) {
    const hint = dest ? `I don't have specifics on that for ${dest.name} yet.` : "I couldn't find that in the approved travel guides, so I won't guess.";
    return {
      answer: `${hint} Try asking about the best time to go, transport, budget, food or places to stay${dest ? ` in ${dest.name}` : ""}.`,
      mode: "retrieval-only", sources: [], grounded: false, disclaimer: DISCLAIMER, intent, destination: destRef, cards, followUps: followUps(intent, dest),
    };
  }

  if (isLlmConfigured()) {
    try {
      const ctx = allSources.map((s, i) => `[${i + 1}] ${s.title}: ${s.snippet}`).join("\n\n");
      const text = await llmComplete(
        "You are a friendly travel guide for Southeast Asia. Answer ONLY using the numbered context. Cite sources like [1]. If the context does not contain the answer, say you do not have that information. Never invent prices, opening hours or policies. Keep it under 120 words, in short paragraphs.",
        `Context:\n${ctx}\n\nQuestion: ${q}`, { maxTokens: 350, timeoutMs: 9_000 });
      if (text) return { answer: text, mode: "llm", sources: allSources, grounded: true, disclaimer: DISCLAIMER, intent, destination: destRef, cards, followUps: followUps(intent, dest) };
    } catch { /* fall back to the extractive answer below */ }
  }

  return {
    answer: [factText, sentences.text].filter(Boolean).join("\n\n"),
    mode: "retrieval-only", sources: allSources, grounded: true, disclaimer: DISCLAIMER, intent, destination: destRef, cards, followUps: followUps(intent, dest),
  };
}

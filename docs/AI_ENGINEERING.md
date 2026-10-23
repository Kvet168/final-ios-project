# AI engineering

## Planner (`ai/service/PlannerService`, `DayScheduler`, `RequestParser`)
1. **Understand** (`RequestParser`): LLM extraction when configured (validated: destination must be a known slug, ranges checked); otherwise a rules parser (days, nights, party, budget, per-day vs total, interest keywords, pace).
2. **Ask**: missing destination/duration returns `status: needs_more_info` with questions.
3. **Retrieve**: all candidates come from `attractions`/`accommodations` rows.
4. **Plan** (`DayScheduler`): score by interests and family fit, prefer nearby stops, respect opening hours, never repeat a place, morning sights, lunch, afternoon sights and an evening meal by pace.
5. **Price**: entry fees x party (children 50%), meals (60%), transport allowance, lodging with tax and fees; lodging is chosen within half of the budget when one is given. Every assumption is returned and shown.
6. **Disclose**: `mode: rules|llm` and `modeNote` say who produced the output. A rules plan is never labelled as AI.

Travel-time estimates are straight-line x1.35 at 22 km/h plus 8 minutes per hop, not routed or traffic-aware. `POST /api/routes/estimate` returns the same estimate with Google Maps and OpenStreetMap links for real navigation.

## Assistant (`ai/service/AssistantService`, `RetrievalService`)
documents -> sentence chunks (~480 chars, title prepended) -> `document_chunks` with generated `tsvector` -> OR-query with an explicit synonym map -> `ts_rank` -> rerank by country/intent -> extractive answer (or LLM answer constrained to the numbered context) with citations, sources and a disclaimer. Structured destination facts (best period, transport, budget) are cited as source [1]. No hit means an explicit "not in the approved guides" answer with `grounded=false`.

**Not implemented:** embeddings/pgvector, conversation memory beyond logging, weather-aware planning.

## LLM provider (`LlmClient`)
Anthropic Messages API over a timeout-bound HTTP client; model from `AI_MODEL` (default `claude-sonnet-5-5`). **This path has not been exercised in this project (no key was available);** any failure falls back silently to the rules/extractive path.

## Safeguards
Redis rate limit (default 20 requests/minute/IP on `/api/ai/**`), usage events in `ai_usage_events` (admin-visible), validation of all model output, the model never writes structured plan data (only summary text).

# AI evaluation

Automated checks (unit tests in `backend/src/test/java/com/wayfarer/ai`, end-to-end checks in `backend/scripts/smoke.sh`):
- The brief's example "three days in Phnom Penh and $150" is parsed to `{destination: phnom-penh, days: 3, budgetUsd: 150}`, and a fuller prompt (two adults, food/culture/photography, relaxed) to the right party, pace and interests.
- Plans have the requested number of days; no place repeats; stops are time-ordered and do not overlap; stops respect opening hours; pace changes the number of stops; interests and proximity influence the choice; day cost equals the sum of its stops.
- Missing essentials produce questions rather than guesses (`needs_more_info`).
- The assistant answers "best time to visit Siem Reap" with `grounded=true`, and declines nonsense with `grounded=false`.
- Behavioural parity with the retired implementation: for the same prompts and questions both produced identical plans and answers.

Example result for the brief: 3 days, lodging at a hostel, 14 stops over 3 days (sights plus restaurants), estimated total 120.36 USD within the 150 USD budget.

Not yet done: human relevance rating, retrieval recall/precision benchmark, LLM-mode evaluation, weather-aware optimisation.

Known weaknesses: lexical retrieval misses paraphrases without a synonym entry; the planner has no multi-day transport routing and small pools per destination can repeat categories.

---
name: verify-against-architecture-doc
description: Before treating a component or mechanic as undecided, check 12-architecture.md's component table and JSON schema section, not just the current phase's plan.md reading list
metadata:
  type: feedback
---

Phase 05 shipped a first version claiming `Health` was "undecided" — no enemy hit-point value
anywhere in `docs/planning/`. A coordinator review corrected this: `12-architecture.md`'s component
table names `Health` explicitly ("health points, enemies and boss") and its JSON schema example
gives a concrete illustrative value (`"health": {"points": 40}` for a tank). It was decided, just
never built — it fell through a gap between phase 04 (which read that document but modelled
fragility as `Collider.fragile` instead) and phase 05 (whose `plan.md` did not list
`12-architecture.md` among its required reading at all).

**Why this happened:** each phase's `plan.md` has its own short, curated "Before you start" reading
list, and it is easy to trust that list as complete. It is not guaranteed to be — this exact gap is
proof. `12-architecture.md` is the one document that names every MVP component and shows the JSON
shape each one is read from; nothing else in `docs/planning/` is as authoritative for "does this
component already have a decided shape."

**How to apply:** before writing agent memory or a status report that says a component, a JSON
field, or a mechanic's shape is "undecided" or "not in any planning doc," grep
`12-architecture.md`'s component table (`grep -n "| \`" docs/planning/12-architecture.md` finds it
fast) and its JSON schema example section, not just the current phase's `plan.md` reading list or
what an earlier agent-memory note said. A component's *values* can genuinely be undecided
(`10-mvp-initial-values.md` is the source of truth for those, and does not fix per-enemy hit points
even now) while its *shape and existence* were decided from the start. Conflating the two — as the
first version of phase 05 did — produces a report that is confidently wrong instead of admitting an
implementation gap.

See [[core-deferred-surface]] for the corrected `Health` entry this lesson came from, and
[[game-systems-design]] for what got built once the gap was caught.

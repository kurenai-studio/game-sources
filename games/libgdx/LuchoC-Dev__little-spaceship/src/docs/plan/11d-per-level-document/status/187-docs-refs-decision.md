# #187 — `docs-refs` (#56) is decided: it stays open

**Branch:** `docs/docs-refs-decision` · **Closes:** [#187](https://github.com/LuchoC-Dev/little-spaceship/issues/187) · **Written:** 31/08/2026

Task 5 of phase 11d. The plan asked for #56 to be resolved or for a written reason why it is separate.

## Completed

[`../docs-refs-decision.md`](../docs-refs-decision.md) holds the decision and the measurement behind
it. **#56 stays open and is a phase of its own**, not because the check is hard — the measurement says
it is cheaper than #56 assumed — but because **running it green today needs an audit pass over roughly
fifteen real findings**, which is 10a's kind of work rather than 11d's.

A comment carrying the measurement was posted on [#56](https://github.com/LuchoC-Dev/little-spaceship/issues/56)
so the next person finds it there rather than only here.

## The measurement, in one paragraph

A prototype extractor over the 104 markdown files in scope found 8,988 backticked spans. **A naive
extractor leaves 271 unresolved; a narrowed one leaves 122** — and the difference is entirely in the
extractor, which is exactly the trade #56 asked to be checked (*"if it needs more than a short
allow-list to run green today, the extraction is too greedy"*). The single largest rule is that **this
repository names paths relative to the Java package**, so resolution must be by suffix: that one change
took unresolved paths from 155 to 50.

Of the 122 that remain, 72 are types and almost all are libGDX or JDK names — about fifty, a closed
set, and that **is** the short allow-list #56 set as its bar. The 50 paths split into extraction work,
build output, branch names, **the deliberate references to deleted things**, and about fifteen that are
genuinely stale. That last group is the phase's real content.

## Decided, which the plan did not specify

- **The exemption key is per-file or inline, never per-name.** `audit.md` and `mechanism.md` quote
  false references on purpose, because their subject is false references, and `docs/STATUS.md` does the
  same for `spikes/web-viability/` by a decision recorded in 10a's `decisions.md`, D1. An allow-list
  keyed on the name would excuse `Composition.java` in `12-architecture.md`, where it would be a real
  finding, in order to excuse it in `audit.md`, where it is not. Deciding this **before** writing the
  extractor is the note left for whoever builds it.

## The interaction task 1 flagged, answered

The contract warned that the generated level documents are dense with backticked content ids that look
like references. **All 25 ids in `assets/data/` were tested against both shapes and none matches** —
they are lowercase and hyphenated, so neither `CamelCase` nor path-shaped. `docs/levels/level-01.md`
contributed exactly one unresolved span to the whole run: `drops.json`, which it names in order to say
there is no `drops.json`, so it is the same hard case as the paragraph above rather than a new one.

## Open

- **#56 itself**, with a much shorter runway than it had this morning.
- **#56's acceptance test was not run** — it needs an extractor pointed at the repository as it stood on
  26/08/2026, and no extractor exists. Stated as "not checked" rather than estimated.
- The prototype was not committed. A check that reports without failing is a convenience a tired agent
  skips, which is the failure mode 10a's `mechanism.md` exists to refuse; the rules it found are worth
  more than the code, and they are written down.

---
name: formation-slot-delay-quantisation
description: Issue #334 — quantise-on-parse for a formation slot's delaySeconds, and the pre-existing per-slot validation gap it also closed
metadata:
  type: project
---

`core`'s #330 half gave `FormationSlot` a third field, `delaySeconds`, and left the loader
(`game/adapter/content/JsonContentSource.java`) two ways to avoid a decimal-seconds value drifting by
a tick once `core` accumulates `1f/60f` onto it (see `docs/plan/11k-level-one-rebuilt/status/330-formation-slot-delay.md`).
Chose **quantise on parse**: `Math.round(rawDelaySeconds * 60f) * TICK_SECONDS` before constructing
`FormationSlot`, keeping the JSON authoring surface in seconds like every other timestamp
(`SpawnEvent.at`) rather than introducing a `"delayTicks"` unit. `TICK_SECONDS` is a fourth duplicate
of `core.application.GameLoop.STEP` in this file, joining `PLAYFIELD_WIDTH`/`PLAYFIELD_HEIGHT` as
constants `game` cannot import from `core.application`/`core.domain` and re-declares with a javadoc
pointing at the original.

**Re-deriving the `core` fragment's drift table by hand is easy to get backwards.** Its script reports,
for the raw literal `0.3`, `active_pass=18` against `ideal_active_pass=19` — the slot turns active
*one tick earlier* than a whole-tick reading predicts. It is tempting to describe this as "needs one
more addition to cross zero" and get the direction inverted; I did this once while drafting the status
fragment and caught it only by re-running the reproduction script myself before writing the final
wording. If a future task needs to explain this drift again, re-run the script rather than
paraphrasing the earlier fragment's prose from memory.

**A per-slot key check did not exist before this issue.** `loadFormations` read `offsetX`/`offsetY`
directly with no `requireOnlyKeys` call on the slot object at all — a typo'd key on a slot loaded
clean and was silently ignored, the exact failure mode `requireOnlyKeys` exists to close elsewhere in
this file. Added it as part of this change (`offsetX`, `offsetY`, `delaySeconds`) since a new optional
key is precisely the moment a missing schema check turns into a live gap, per the issue's own
"watch out for" note. The formation *entry* itself (`id`, `slots`) still has no such check — left
alone as out of this issue's scope, worth knowing if a later task touches formations again.

See also [[core-boundary-check]] for the mechanical grep that would have caught an accidental
`core.domain`/`core.application` import if `TICK_SECONDS` had been fetched from `GameLoop` directly
instead of duplicated.

# Sprint 3 — Location Pull (Completed)

Goal: split the one field `NeedsEvaluator` and `apply_stat_tick` currently share (`Location.modifiers`) into two — a physical per-hour rate (stays as `modifiers`, unchanged) and a new hand-authored, normalized decision-scoring signal (`Location.pull`). See `docs/sprints/02-game-time.md`'s "Findings during development" for how this need surfaced: once location modifiers were rescoped to real per-hour values, the same field could no longer honestly serve both "how fast does this physically work" and "how desireable of a choice is this, compared to other locations" — those are different questions that only coincidentally shared a scale before.

This is the "smart object advertising" pattern (see `docs/RAT_SIMULATION_BACKLOG.md` References) done properly: locations advertise their appeal per need on a shared, comparable scale, decoupled from the physical simulation detail of how fast that appeal is actually delivered.

## Design decisions locked this sprint

- **`pull` is hand-authored, not computed from `modifiers`.** A location can be physically effective at satisfying a need while being unappealing, or vice versa (a nutritious broccoli basket vs. a bucket of crisps) — appeal and physical efficacy are independent facts about a location, so `pull` can't be a normalization formula over `modifiers`.
- **Scale: `-3..+3`, a 7-point Likert scale, not the originally floated `-5..+5`.** `pull` is a single hand-picked value per location per need — a repeated discrete human judgment call, not a continuous formula-driven quantity like `Mood`/`Personality`. That distinction matters: Miller's ~7±2 limit on reliably distinguishable categories applies to hand-classification, not to continuous accumulators or distribution parameters (which `Mood`'s and `Personality`'s `-100..100` ranges are — see the scale-audit discussion this sprint). `-3..+3` gets a named anchor at every step (extremely repulsive → unbothered → extremely appealing), so every value is a real judgment, not an arbitrary pick between ambiguous integers. Repulsion (negative `pull`) is a real, intended case — some locations should actively feel bad to use for a given need, not just be neutral toward it.
- **Shape: a new `Resource` subclass, `LocationPull extends BaseStatGroup`**, mirroring `Mood`'s shape conceptually. This sprint only implements the `nutrition` field — the other four (`energy`, `social`, `stimulation`, `vice_satisfaction`) are added when their own needs get wired into scoring next sprint, not pre-scaffolded empty now.
- **`Location.modifiers` is untouched** — stays exactly as rescoped in the Game Time sprint, feeding only `apply_stat_tick`. `NeedsEvaluator` switches to reading `Location.pull` instead.
- **Scope stays nutrition-only**, matching every prior sprint's scope-limiting — only `pull.nutrition` needs real hand-authored values this sprint.
- **`BaseStatGroup` extracted out of `entities/rat/stats/shared/`** into a top-level `shared/base_stat_group.gd`. It was never actually rat-specific (nothing in its implementation touches rat data — just `_min`/`_max`/`_clamp_value`/`stat_changed`), and `Location.pull` reaching into `entities/rat/` for a shared utility would have been a real layering violation. All existing consumers (`Mood`, `Personality`, `Status`, `Vice`, `JobSkills`, `Other`, `Camaraderie`) resolve it by global `class_name`, not file path, so the move required no import changes.

## Tasks

### `LocationPull` resource
- [x] Create `LocationPull extends BaseStatGroup` with a `nutrition` field, clamped `-3..+3`
- [x] Add `pull: LocationPull = LocationPull.new()` as a new `@export` field on `Location`, alongside the existing `modifiers`
- [x] `nutrition`'s setter emits `stat_changed`, matching every other `BaseStatGroup` subclass's convention (confirmed universal — even `Camaraderie`, which isn't wired into the debug panel, still emits on every set)

### Rederive location values
- [x] Hand-author `pull.nutrition` for all six locations: Pantry `+3`, three cook stations `+1` each, Dishwasher `-1`, Bartender `0` (unbothered)
- [x] Rederive `JobConstants.EMPLOYMENT_PRESSURE` against the new `-3..+3`-scale formula — solved exactly for the -40 crossover: `urgency(-40) × pull.pantry = urgency(-40) × pull.job + EMPLOYMENT_PRESSURE` → `0.188 × 3 = 0.188 × 1 + EMPLOYMENT_PRESSURE` → `EMPLOYMENT_PRESSURE = 0.376`
- [x] Nutrition urgency curve's crossover point re-checked against the new scale — confirmed still exact at `nutrition = -40` once `EMPLOYMENT_PRESSURE` was corrected to `0.376` (an initial rough estimate of `0.3` was tried first and found to break the exact tie)

### `NeedsEvaluator`
- [x] Change `evaluate()` to read `location.pull.nutrition` instead of `location.modifiers.nutrition`

## Test scenarios — all confirmed

1. **Modifiers untouched:** `apply_stat_tick`'s nutrition-per-tick math unaffected — same behavior as end of Game Time sprint. ✅
2. **Scoring uses the new field:** changing `pull.nutrition` moves `NeedsEvaluator`'s scores; changing `modifiers.nutrition` no longer affects scoring at all. ✅
3. **Crossover sanity check:** with `EMPLOYMENT_PRESSURE = 0.376`, the debug-panel `nutrition = -40` override reproduces the intended job-vs-Pantry crossover. ✅
4. **Broccoli/crisps case:** inverted `modifiers`/`pull` relationships across two locations — `NeedsEvaluator` picks based on `pull`, not `modifiers`. ✅

## Findings during development

**The Likert-scale question surfaced a real distinction between two kinds of "stat":** continuous, formula-driven accumulators (`Mood`, decayed and read through a curve) and distribution parameters (`Personality`'s hand-authored `mean`/`deviation`) don't have the same resolution problem that a single, repeated, hand-picked judgment call does. `-100..100` is fine for the former; `pull` needed the latter's treatment (`BaseStatGroup` already differentiates scale *shape* by semantics elsewhere — unsigned `0..100` for `stress`/`health` vs. signed `-100..100` for `owner_relationship` — this just extends that instinct to resolution, not just sign).

**`EMPLOYMENT_PRESSURE`'s first value (`0.3`) was a rough conversational estimate, not a solved one.** A code review caught that it didn't reproduce the exact tie at `nutrition = -40` that the original Sprint 2 tuning methodology established as the crossover point — recalculating from the actual curve data (`urgency(-40) = 0.188`, an exact point on the curve, not interpolated) gave `0.376`.

**`BaseStatGroup`'s extraction had its own hiccup:** a first attempt at moving the directory landed it at a doubled `shared/shared/base_stat_group.gd` — the whole `shared`-named source directory got relocated as a unit into a new top-level `shared/`, rather than flattened. Caught in the same review pass and corrected to `shared/base_stat_group.gd`.

**Considered and deferred: extracting `Location` into its own `.tscn`.** Right now it's a bare `Marker2D` with a script and exported `Resource` fields, no child nodes — instancing a scene buys nothing over placing nodes directly in `main.tscn` until `Location` needs shared visual/child-node structure (a sprite, a label, an `Area2D`). Revisit once art integration starts.

## Next sprint (not this one)

Wire the remaining four needs (`energy`, `stimulation`, `social`, `vice_satisfaction`) into both `pull` and `modifiers` across all locations, and extend `NeedsEvaluator`'s formula to a genuine `sum(need_urgency[n] × pull[n])` across all five needs — worth re-deriving the combination logic then (weighted sum vs. multiplicative, per Dave Mark's discussion of combining considerations) rather than guessing ahead now. See `docs/CURRENT_SPRINT.md`.

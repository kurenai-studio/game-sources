# Sprint 2 — Game Time (Completed)

Goal: replace Sprint 1's ad hoc per-rat `Timer` with real simulation-time infrastructure — a centralized game clock, staggered per-rat decision scheduling, and a new mechanism that actually applies a location's effect to a rat's needs over time (`NeedsEvaluator` only ever picked a destination; it never touched `rat.mood`). See `docs/sprints/01-minimal-watchable-loop.md` for how this sprint's scope was arrived at.

Explicitly out of scope this sprint: the location "quality"/desiredness tag-value scale and the new `Location.pull` resource. This sprint kept reading `Location.modifiers.nutrition` as-is for decision-scoring — only *when* and *how often* it got applied to the rat changed, not the underlying values (until testing forced a rederivation — see Findings below).

## Design decisions locked this sprint

- **Game-time convention:** 1 game-hour = 60 real seconds at 1x `Engine.time_scale`. A 16-hour shift plays out in 16 real minutes. `SECONDS_PER_GAME_TICK = 1.0` (one `Timer`-driven tick = one real second = one game-minute), `GAME_TICKS_PER_IN_GAME_HOUR = 60` — a fixed in-game-calendar fact (60 minutes/hour), independent of the real-time rate.
- **Two systems, fully decoupled:**
  - **Decision-making** (`Rat.reevaluate_needs`) — the existing scoring/comparison that picks *where* a rat should go. Runs on a staggered per-rat schedule: 15 slots, each rat weighted-randomly assigned one at generation (biased toward less-occupied slots, via a shared `pick_weighted_random` util — not `rat.id % 15`, to avoid id-ordered clumping), giving 4 decisions/hour/rat (60 ticks/hour ÷ 15 slots). Replaced `Rat`'s own `DecisionPeriod` Timer, whose only real job was avoiding N rats all re-evaluating in the same frame.
  - **Need application** (`apply_stat_tick`) — actually changes a rat's stat over time (`mood.nutrition` ticking upward while stood at the Pantry). Runs every tick, for every rat, unconditionally — except while mid-travel (`state == PROCEEDING_TO_LOCATION`), when nothing is applied at all.
- **`RatManager` is the sole listener of `GameClock`'s tick signal**, and the only thing that calls into individual rats. Rats do not each subscribe to the clock independently. Matches the existing manager-owns-iteration pattern used by `JobManager`/`LocationManager`.
- **`Rat` owns both `current_location` and `destination`.** `current_location` persists after arrival instead of being cleared, and updates whenever a new destination is chosen.
- **`GameClock` is a `Node` under `Main`, not an autoload** — it's stateful/runtime behavior (an active `Timer`, an incrementing counter), unlike the project's existing autoloads (`Colony`, `JobConstants`, `RatConstants`), which are shared static data.
- **Location nutrition modifiers rescoped to per-hour values**, since `apply_stat_tick` divides by `GAME_TICKS_PER_IN_GAME_HOUR`: `Pantry = 200` (a full `-100 → 100` swing over 1 hour of continuous eating), `Cook stations (Head/Line/Prep) = 20` (a small trickle — meant to slow future decay, not replace real eating), `Dishwasher = -10`, `Bartender = 0` (physical-labor drain, dishwasher harsher). `JobConstants.EMPLOYMENT_PRESSURE` rederived to `33.84` to match, chosen so the job-vs-Pantry crossover lands exactly at `nutrition = -40` (the curve's steep-drop control point).
- **Deferred, explicitly not this sprint:** the `-5..+5` Location Pull scale and resource (see `docs/sprints/03-location-pull.md`), and moving `Location._job` into `JobManager`.

## Tasks

All tasks from the original scope (`GameClock`, `RatManager` as central driver, `Rat` location tracking, need application) completed — see `docs/RAT_SIMULATION_BACKLOG.md` section 2 for the full checklist, now fully checked.

## Test scenarios — all confirmed

1. **Slot distribution** ✅ — multiple rats (given distinct `modulate` colors for visual tracking) confirmed reevaluating at staggered times, not in lockstep.
2. **Continuous nutrition tick** ✅ — confirmed with multiple rats running concurrently.
3. **No nutrition while traveling** ✅
4. **Timer removal sanity check** ✅ — no `DecisionPeriod`/`DECISION_PERIOD` references left in `rat.gd` or `rat_constants.gd`; `.tscn` node removed.
5. **Time-scale interaction** ✅ — 10x `Engine.time_scale` confirmed to tick `GameClock` proportionally faster without changing the underlying game-time rate.

## Findings during development

**Naming clarity forced a split of "ticks_per_hour" into two constants.** The single ambiguous name was actually conflating three concepts: how often the `Timer` fires in real seconds, the real-time↔game-time bridge, and how many ticks make up a game-hour. The middle concept turned out to be redundant (derivable from the other two once "1 tick = 1 game-minute" is fixed), leaving two clean constants: `SECONDS_PER_GAME_TICK` (real-seconds knob) and `GAME_TICKS_PER_IN_GAME_HOUR` (a fixed in-game-calendar fact, unrelated to real time).

**Slot assignment ended up weighted-random, not `rat.id % NUM_SLOTS`.** Deterministic modulo assignment left some slots structurally empty for small rat counts and made slot membership fully predictable from generation order — feeling "too orderly." Landed on a full-weighted-random pick across all 15 slots (weight `1/(count+1)`, favoring less-occupied slots) via a new shared `pick_weighted_random` util, rather than a "power of two choices"-style sampled approach — that technique's whole value is avoiding an O(N) scan across huge N, which doesn't apply at 15 slots.

**`NUM_SLOTS` and tick interval were derived together, from "decisions per hour," not picked independently.** Landed on 15 slots / 4 decisions-per-hour-per-rat, with `SECONDS_PER_GAME_TICK = 1.0`.

**Renaming `Location`'s exported fields silently erased scene data.** `_job`/`_personality_modifiers`/`_title` → `job`/`modifiers`/`title` caused Godot to drop all six locations' values from `main.tscn` on next save — `@export` renames aren't migrated automatically, they're just treated as new properties with no prior value. Values had to be re-authored from scratch (which turned out to be necessary anyway, once per-hour rescoping was underway).

**Several GDScript/Godot footguns hit and fixed:**
- `Array[TickSlotRegistry]` assigned by index into an empty array (`registry[i] = x`) rather than grown with `append()` — indexing doesn't auto-grow.
- `Array.map()` always returns a plain untyped `Array`, even with a typed lambda return — can't assign straight into an `Array[int]`-typed variable.
- `in` is a membership test, not an index lookup — doesn't help when you have an `id` and need to find the matching object in an array of objects.
- A cascading parse failure: a syntax error in `rat.gd` caused `Could not parse global class "Rat"` errors to surface at unrelated call sites referencing the `Rat` type, and separately caused a `TickSlotRegistry` script (which typed a field as `Array[Rat]`) to fail to register its own properties, producing a confusing "Invalid assignment... on a base object of type Node" error.

**A real design tension surfaced, deliberately not resolved this sprint.** Rescoping location modifiers to real per-hour values exposed that `NeedsEvaluator` (decision-scoring) and `apply_stat_tick` (need-application) read the *same* field for two structurally different purposes: a physical per-hour rate and a comparative decision-scoring signal don't naturally share a scale. Concretely, two needs' locations chosen for good in-fiction physical reasons (a fast-recovering food source vs. a slow-recovering social fix) would score wildly unequally in a summed multi-need formula, for reasons unrelated to actual urgency — the same normalization problem Sprint 1 hit, reappearing structurally rather than as a tuning mistake. This sprint patched around it for the single-need case by rederiving `employment_pressure` to match the new scale; the actual fix — splitting a hand-authored `Location.pull` field (normalized, `-5..+5`, drives `NeedsEvaluator`) from `Location.modifiers` (physical rate, drives `apply_stat_tick`) — is Sprint 3's scope. Confirmed hand-authored rather than computed-from-modifiers: a location can be physically effective at satisfying a need (high `modifiers`) while being unappealing (low `pull`), or vice versa — e.g. a nutritious broccoli basket vs. a bucket of crisps — so `pull` can't be a pure normalization of `modifiers`, it's an independent authorial judgment.

**Added beyond original scope:** a simulation pause button (debug tooling), and random `modulate` coloring per rat (`Color.from_hsv`) so multiple rats are visually distinguishable during testing.

# #161 — Per-entity movement state

**Owner:** `core-domain` · **Branch:** `feat/movement-state` · **Status:** done, ready for review

## What was built

- `core/domain/component/Trajectory.java` — a plain-data component holding one field: `elapsed`
  (mutable, seconds since spawn, accumulated from the fixed step). No logic lives on the component
  itself.
- `World.java` — a nineteenth `ComponentStore<Trajectory>` field, an accessor `trajectories()`, and
  removal in `destroyEntity` alongside every other store.
- `MotionSystem.java` — a new private step, `advanceTrajectories`, called from `update()` right after
  `applyPlayerInput` and before `integrate`: it walks `world.trajectories()` and adds `step` to every
  entity's `elapsed`. Ordering matters for the future consumer, not for this task: a shape evaluator
  reading `elapsed` to decide this tick's velocity needs this tick's step already counted. Nothing
  evaluates a shape yet — that is #163/#164 — so today this only accumulates the number.
- Corrected `Motion.java`'s javadoc, which claimed trajectories "are not here yet" — false the moment
  `Trajectory` exists. `TrajectoryDefinition.java` was left untouched: nothing in this task changes
  what a *content* trajectory is (still a constant vector), so its javadoc is not falsified by this
  PR. That correction belongs to whichever of #163/#86 actually adds a non-constant shape to content.
- Tests: `MotionSystemTest` gained two cases — elapsed accumulates one step at a time across two
  ticks, and an entity with no `Trajectory` is unaffected. `WorldTest.populateEveryComponent` was
  extended for the new store, which its own reflection-based guard (`destroyStripsEveryComponent`)
  requires.

## An origin field was added, then removed once #162 answered the question

The plan's task 1 description ("a plain-data component holding that state ... and a system advancing
it") did not say whether the per-entity state should carry anything beyond elapsed time, and the
shape catalogue that would answer it — task 2, #162 — was still open, running in parallel on a
different branch. I flagged this explicitly in my first report rather than guessing silently, and
made a judgment call under invariant 6: I added `originX`/`originY`, the entity's spawn `Transform`,
reasoning that a position-relative shape (a U-turn, a loop back towards where it started) could not
be resolved from elapsed time alone once the entity's own `Transform` had already moved away from
its spawn point.

**#162 landed and settled it the other way.** `docs/plan/11c-movement-shapes/shape-catalogue.md`
decides that a shape is "a function from the entity's own elapsed time to its velocity. Nothing else
goes in," and that exactly two kinds exist — `constant` and `arc`, `velocity(t) = (vx, vy)` and
`velocity(t) = (vx, vy + ay·t)` — neither of which reads a position. Waypoints and splines, the kinds
of shape an origin would have served, were refused by name. That made the two fields an abstraction
with no case: invariant 6 says a case is "a written design or a shipped need, not an expectation,"
and the catalogue is now the written design that answers this one — origin is not a need. The
coordinator asked for the fields to come out once the catalogue landed, and they did, on the same
branch and the same PR: `Trajectory` is now `elapsed` alone.

This is the record worth keeping over the original reasoning: the plan left a question open, it was
flagged rather than guessed past silently, and the answer that came back removed what the guess had
added. That is the process working, not a mistake to have made — but the origin fields themselves
were wrong to keep once the design existed, and removing them promptly is what invariant 6 asks for.

## Acceptance criteria

- [x] A plain-data component holds the entity's elapsed time — `elapsed` alone, per the shape
  catalogue's own rule that a shape reads elapsed time and nothing else.
- [x] The advance happens inside `SystemOrder.MOTION` — `MotionSystem.advanceTrajectories`.
- [x] Elapsed time accumulates from the fixed step; no clock, no `Math.random()`, no libGDX import.
- [x] The determinism replays pass unchanged — `./gradlew :core:test` is green, including every
  `*ReplayTest` and `DeterminismRulesTest`.
- [x] Every javadoc this falsifies is corrected — `Motion.java`, and `Trajectory.java`'s own javadoc
  rewritten to match the field it now actually has.
- [x] `SystemOrder` is unchanged — no new stage, no reordering.

## Not done, on purpose (later tasks in this phase)

- No evaluation of `elapsed` into a velocity — that is #163 (contract and loader for `constant` and
  `arc`) and #164 (`SpawnEvent` carrying a shape id).
- No content contract, no loader, no `assets/data/` file.
- Nothing attaches a `Trajectory` to a spawned entity yet — `ComponentFactoryRegistry` is untouched,
  so no enemy in the game carries one today. That is exactly why this PR cannot itself demonstrate
  "the same archetype with two shapes" — that is the phase's acceptance criterion, not this task's.

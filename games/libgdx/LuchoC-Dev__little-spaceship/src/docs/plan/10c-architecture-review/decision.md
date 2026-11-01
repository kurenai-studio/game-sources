# Phase 10c — the decision

Written on 27/08/2026. This is the record tasks 4 and 5 of [`plan.md`](plan.md) ask for. The evidence
behind it is in [`assessment.md`](assessment.md); the backlog behind it is in
[`issue-triage.md`](issue-triage.md).

---

## The decision

> **The architecture holds, with four named extensions. Nothing in its shape changes.**

The four are additive and each one is a single issue:

| | What | Issue | Size |
|---|---|---|---|
| 1 | An entity that leaves the playfield leaves the simulation | [#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84) | small |
| 2 | An entity records which wave spawned it | [#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85) | small |
| 3 | Movement becomes a function of an entity's own state, not a vector fixed at spawn | [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86) | medium |
| 4 | `JsonContentSource` loads a level by id instead of hardcoding `level-01` | [#87](https://github.com/LuchoC-Dev/little-spaceship/issues/87) | small |

Plus one that is **not** the 11 group's and is opened only so it does not arrive as a surprise:
[#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88), `BossSystem` is level 1's boss and
not a boss engine — phase 12's problem.

**Order.** [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) first — rule-asserting
tests, because every one of the four is a behaviour change under a suite that mostly proves a run
reproduces itself. Then 1 and 2 together, since they are jointly what makes "this wave is cleared"
answerable. Then 3. Then 4, which is independent of the other three and can go at any point.

**Why "holds with extensions" and not one of the other two verdicts** is the whole content of the
next two sections.

---

## Why not "holds as is"

Because area E of the assessment is a **missing mechanism**, not a strained one, and calling it a
strain would be a false statement of the kind the 10 group exists to stop producing.

`Motion` is two floats (`core/domain/component/Motion.java:12`). `TrajectoryDefinition` is a constant
vector and says so in its own javadoc (`core/port/TrajectoryDefinition.java:7-8`).
`ComponentFactoryRegistry.attachMotion` (lines 95-99) resolves it once at spawn and discards the id.
No system writes an enemy's `Motion` after creation — six write sites, every enemy one at creation
(`grep -rn "motions()\.set\|motions()\.get" core/src/main --include=*.java`).

The roadmap asks for "a U-shaped attack run, a straight 30° diagonal, or a curve", varying by where in
a level an enemy appears. There is no partial version of that in the code to extend. Saying "holds as
is" would mean the 11 group discovers the gap while building, which is the expensive place to find it.

---

## Why not "needs a change"

Because **nothing in the architecture's shape is wrong**, and the assessment kept demonstrating that
from the other direction: every finding turned out to be cheap *because* of the boundary, not in
spite of it.

- Five levels coexisting is **three lines in `game` and zero in `core`**
  (`grep -rn "LEVEL_ID" --include=*.java .`), because `core` was already keyed by a level id it never
  interprets.
- A new content kind is a new interface plus a new `ContentSource` method, additive, because
  `ContentSource` has one production implementation and `EnemyDefinition` is a list of untyped
  component specs the core does not understand (`core/port/ComponentSpec.java:26`).
- The per-level document's whole risk — two copies of one truth — is answered by the fact that
  **`core` reads a `ContentSource`, never a file**. `grep -rn "json" -i core/src/main --include=*.java`
  returns six lines and every one is inside a javadoc comment.
- A world-state trigger does not threaten determinism, and this is not an argument from the
  invariants: `World.View.outcome()` already reads world state to decide `COMPLETED`
  (`core/domain/World.java:490,510-517`). The precedent shipped.
- The fixed system order survives untouched. `SPAWN` stays fifth; a cleared-based trigger resolves one
  tick late, deterministically. `SystemOrder.MOTION`'s javadoc already reads "Applies velocities and
  trajectories" (`SystemOrder.java:20`), so even the movement work needs no new stage.

A design that absorbs four levels, a wave system and a movement system with four additive issues and
no reordering is not a design that needs changing.

---

## What was considered and rejected

The plan asks for this explicitly, and it is the part a future reader will want most.

### Rejected: move `SPAWN` later in `SystemOrder` so a cleared trigger fires the same tick

`SPAWN` is the 5th stage; `COLLISION`, `DAMAGE` and `CLEANUP` are the 10th, 11th and 14th. So a wave
asking "is the previous one cleared?" sees a world where this tick's kills have not been detected, let
alone cleaned up — `CleanupSystem` is the sole caller of `World.destroyEntity` precisely so no store
changes under a system mid-tick (`CleanupSystem.java:19-22`). The trigger therefore resolves on the
*next* tick.

Moving `SPAWN` after `CLEANUP` would make it immediate. **Rejected**, for three reasons:

1. It would put wave spawning after the tick's collision pass, which is a different and worse game
   rule — a wave would spawn into a world that has already resolved its impacts.
2. The order is invariant 5, and every stage's placement in `SystemOrder` carries a javadoc saying
   what breaks if it moves. Moving one to buy a 16-millisecond improvement in a pacing trigger is not
   a trade this project makes.
3. One tick at 1/60 s is not observable, and stale-by-one is perfectly deterministic — it reproduces
   identically on replay, which is the only property that actually matters here.

**Instead:** the one-tick rule gets written into `SystemOrder.SPAWN`'s javadoc, which is where every
other ordering rule in this project already lives. Named on
[#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85).

### Rejected: build the generalisations now that four levels "obviously" need

Specifically: a `PatternDefinition`/`ContentSource.pattern()` content contract, a `Lifetime` timer
component, the remaining six `GameEvent` types, and generalising `BossSystem` into a boss engine.

**Rejected on invariant 6**, and the assessment's Part 3 is the working: three of eight deferrals flip
into a real case, five do not. The five that hold are the more informative half — the invariant is
doing its job rather than being a slogan.

Concretely: enemy fire is one shape today, and `EnemyWeaponSystem.java:85-93` switches on one value.
Four levels *probably* want more. "Probably" is exactly what invariant 6 refuses, and the cost of
being wrong is a content contract shaped around a guess — which is how
`docs/planning/12-architecture.md` ended up describing a `patterns.json` that was never created
(finding F23 of the 10a audit). Revisit when a level design names a second shot shape.

`BossSystem` is the same call with a longer fuse: `08-decisions-and-open-items.md` still lists "Detail
of bosses and sub-bosses" and "Frequency and rules for multi-boss levels" as open campaign items.
Generalising before those are decided is guessing at the shape.

### Rejected: changing the module boundary, the hexagonal shape, or any of invariants 1–5

Nothing the 11 group asks for pushes on them, and the assessment says why in each case: `core` stays
pure Java (the only `com.badlogic.gdx` string under `core/src` is the forbidden-name rule inside
`DeterminismRulesTest.java:22`); determinism is untouched, since elapsed time accumulated from the
fixed step is not reading the clock and `World.rng()` already exists for anything wanting randomness;
single-threading is not in question — nothing here is parallelisable and TeaVM offers no parallelism
anyway; the contracts hold and the extensions go through them; and the order does not move.

**Recorded because the plan asks for it, not because it was close.** Treating the invariants as
negotiable was one of the two available mistakes, and the honest report is that four of the six were
never under pressure.

### Rejected: deciding what a wave is

The single largest thing this phase did **not** do, deliberately. The roadmap leaves four questions
open — what ends a wave, how a wave is placed, whether a wave takes parameters, where waves live
relative to formations — and each of them changes what a wave is. They belong to the phase that
builds waves.

Where this review was tempted to specify, it turned the temptation into an issue instead. Three
examples, so the line is visible:

- *whether a wave's "cleared" means every entity destroyed or every entity gone* → the mechanism gap
  is [#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84); the rule is not decided here;
- *whether a carrier's spawned children count towards their parent's wave* → named as a game rule on
  [#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85), not answered;
- *which movement shapes exist and where the binding is chosen — archetype, spawn event, or wave* →
  named as out of scope on [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86).

### Rejected: deciding the per-level document's form

For the same reason, and with a stronger one behind it: **the architecture does not constrain the
choice**, so choosing here would be a design decision wearing an architectural costume.

What the review does contribute is the boundary of the problem. Because `core` reads a
`ContentSource` and never a file, three arrangements are all equally available — the document is
authored and the JSON generated from it; the JSON is authored and the document generated from it; or
there is one artefact and the "document" is a rendering of it. **The architecture rules out only the
fourth**, two hand-maintained artefacts, which is the one the roadmap warns about. Nothing in the
code forces it and nothing in the code prevents it: it is a process decision.

---

## The one thing this phase cannot decide alone

**Invariant 6's wording has expired, and rewording an invariant is the project owner's call.**

`CLAUDE.md` states it as: *"No abstraction without a real case in the MVP."* The MVP shipped on
25/08/2026. Read literally, the clause now has no subject, and both readings of it are damaging: taken
strictly, every post-MVP abstraction is forbidden; taken as void, the invariant stops constraining
anything.

The *rule* was never "build nothing" — it was "build for a case you can point at", and phase 04's
own record shows it working exactly that way, building trajectories and refusing patterns in the same
breath. Four levels and agent-authored content are cases that can be pointed at, with documents behind
them (`04-campaign-and-levels.md`, `post-mvp-roadmap.md`) rather than a hunch.

**Recommended wording**, for the owner to accept or refuse:

> **No abstraction without a real case you can point at.** A case is a written design or a shipped
> need, not an expectation. It was measured against the MVP; the standard did not change when the MVP
> shipped.

**Not applied.** `CLAUDE.md` was not edited by this phase. The invariants are described there as
decided and measured, 10b was the phase given permission to change that file, and this one was not.
Raised as [#91](https://github.com/LuchoC-Dev/little-spaceship/issues/91) and put to the owner
directly.

---

## What changed in the decision record

`docs/planning/08-decisions-and-open-items.md` gains one subsection under **Confirmed decisions**,
recording the verdict and the `CollisionLayer.PLAYER` decision from
[`issue-triage.md`](issue-triage.md). Nothing else in that document changed: this phase overturned no
existing decision.

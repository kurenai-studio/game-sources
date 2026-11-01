# Phase 11c — Movement as a described thing

**Lane:** code + content · **Owner:** `core-domain` for `core/`, `level-designer` for the shapes in `assets/data/` · **Depends on:** 11a, 11b

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "Movement as a described thing". Two paragraphs; this plan does not restate them.
2. [`../10c-architecture-review/assessment.md`](../10c-architecture-review/assessment.md), **area E**. It is the only area of that review that found a *missing* mechanism rather than a strained one, and it names every file involved.
3. [`../10c-architecture-review/decision.md`](../10c-architecture-review/decision.md), "Why not 'holds as is'".
4. `docs/planning/08-decisions-and-open-items.md`, "The wave system, 27/08/2026" — the movement binding is decided there.
5. `CLAUDE.md` — invariants 2, 5 and 6.

## Goal

**The same archetype enters differently at second 30 and at second 200 without being two archetypes.**

That is the whole phase, and it is [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86).

## What the code has today, so the size is not guessed

All of this is quoted from area E of the assessment, which checked it rather than assumed it:

- `Motion` is two mutable floats, `vx` and `vy` (`core/domain/component/Motion.java:12`), with no
  time, phase, origin or target. Its own javadoc says trajectories "are not here yet".
- `TrajectoryDefinition` is `id`, `vx`, `vy` and its javadoc says outright that "the MVP's
  trajectories are constant velocities, not curves" (`core/port/TrajectoryDefinition.java:7-8`).
- The resolution happens **once, at spawn**: `ComponentFactoryRegistry.attachMotion` (lines 95-99)
  copies the two floats and discards the id. After that the entity has no memory of the trajectory it
  was given.
- **No system anywhere modifies an enemy's `Motion` after spawn.** Six write sites, every enemy one at
  creation: `grep -rn "motions()\.set\|motions()\.get" core/src/main --include=*.java`.
- `SpawnEvent` (`core/port/SpawnEvent.java:19`) carries `at`, `enemyId`, `formationId`, `atX`,
  `dropId`, `dropSlot` — **no trajectory**. That is the field this phase adds.
- `assets/data/trajectories.json` holds four constant vectors and `assets/data/enemies.json` binds
  each of six archetypes to exactly one.

Two facts that make this cheaper than it looks, both established by 10c against the code:

- **`SystemOrder.MOTION`'s javadoc already reads "Applies velocities and trajectories"**
  (`SystemOrder.java:20`). The stage was named for this before it was built the narrow way, so
  evaluating a shape into a velocity fits inside the existing stage. **No reordering is implied**,
  which matters because reordering is invariant 5.
- The one-tick lag someone will worry about — an entity spawned at `SPAWN` (5th) is not moved until
  the next tick's `MOTION` (2nd) — **already exists**: `SpawnSystem.positionSpawned` (lines 170-180)
  writes the `Transform` directly. A phase-aware trajectory inherits that lag; it does not create one.

## What was decided, and by whom

Decided by the project owner on 27/08/2026, in the same conversation that produced this folder:

> **The shape is chosen in the spawn event, with the archetype supplying the default.** An archetype
> keeps its usual movement, and a spawn inside a wave may override it.

10c named this question — *"which movement shapes exist and where the binding is chosen — archetype,
spawn event, or wave"* — and put it out of scope on #86 rather than answering it. The binding half is
now answered. **Which shapes exist is still open and is this phase's design work**, in task 2.

## Tasks

1. **Per-entity movement state** — [#161](https://github.com/LuchoC-Dev/little-spaceship/issues/161). An entity's path becomes a function of its own elapsed time, which
   means a plain-data component holding that state and a system that advances it. Elapsed time
   accumulated from the fixed step is not reading the clock — invariant 2 is untouched — and anything
   wanting randomness has `World.rng()` (`core/domain/World.java:400`) waiting for it.
2. **Decide which shapes exist, and stop there** — [#162](https://github.com/LuchoC-Dev/little-spaceship/issues/162). The roadmap names three by example: a U-shaped
   attack run, a straight 30° diagonal, and a curve. Build the shapes level 1's fourteen beats and
   phase 12's two levels can point at, and refuse the rest. **Invariant 6 applies here more than
   anywhere in this group**, because a shape catalogue is exactly the kind of thing that grows on
   expectation. The four existing constant vectors stay valid: a constant velocity is a shape.
3. **A movement shape is named content** — [#163](https://github.com/LuchoC-Dev/little-spaceship/issues/163). New contract in `core.port`, new `ContentSource` lookup,
   loaded from `assets/data/`, in the same shape as the eight lookups that already exist. Read it with
   `JsonReader`/`JsonValue`, never the reflective `Json` class.
4. **`SpawnEvent` carries an optional shape id** — [#164](https://github.com/LuchoC-Dev/little-spaceship/issues/164) — and the archetype's own binding is the default when
   it does not. This is the N6 mechanism.
5. **Close [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86)**, and update `TrajectoryDefinition`'s and `Motion`'s javadocs, both of which currently
   state, correctly and about to be falsely, that curves are not here yet. A stale javadoc left behind
   by this phase is exactly the failure 10a spent a phase correcting.

## The running order

Decided by the project owner on 29/08/2026, when the phase opened. It is here rather than in
`status.md` because it is a decision about how the phase is run, not a record of how far it has got —
and because a coordinator who loses the session needs it before anything else.

**This is the first phase to run two agents in parallel over `core/` and `assets/data/` at once**,
which is the scenario phase 10d built its tools for. The coordinator creates every branch and
worktree and hands each worker an absolute path that already exists; an agent never runs
`git worktree add`. Agent memory is written in the main checkout — `tools/agent-memory-path <agent>`
prints the one correct directory.

| Round | Issues | Who | Why here |
|---|---|---|---|
| 1 | [#161](https://github.com/LuchoC-Dev/little-spaceship/issues/161) and [#162](https://github.com/LuchoC-Dev/little-spaceship/issues/162), in parallel | `core-domain` on `core/`; `level-designer` on `docs/` and `assets/data/` | They share no file. #162 is the design work the other two wait on, so it starts first rather than last |
| 2 | [#163](https://github.com/LuchoC-Dev/little-spaceship/issues/163) | `core-domain` for the contract, **`game-presentation` for the loader**, `level-designer` for the file | The shape list decided in #162 is what fixes the JSON's schema. Building the loader first would mean guessing it |
| 3 | [#164](https://github.com/LuchoC-Dev/little-spaceship/issues/164), then [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86) | `core-domain`, **then `game-presentation` for the spawn key** | #164 is where the phase's own acceptance criterion lives — one archetype, two shapes, demonstrated in a test. #86 closes the handover and corrects the javadocs this phase falsifies, which is last because it cannot be written until the code is |

**Corrected on 29/08/2026, while the phase ran.** Rounds 2 and 3 each named one agent too few. The plan's task 3 says "loaded from `assets/data/`" and its task 4 says `SpawnEvent` carries an id, and both readings assumed the JSON is read in `core` — **it is not**. `JsonContentSource` lives in `game/adapter/content/`, which belongs to `game-presentation`. `core-domain` stopped at the module boundary both times and wrote down the diff it could not make, which is the correct behaviour and cost nothing; the plan was what was wrong. **Any later plan that says "loaded from `assets/data/`" needs three agents, not two** — 11d's per-level document is the next one to read that way.

**If the session is lost, read this table and `status.md` in that order.** The table says what is meant
to happen; `status.md` and the fragments under `status/` say what has.

## Acceptance criteria

- One archetype appears twice in a level with two different shapes, and it is one archetype in
  `enemies.json`. Demonstrate it in a test, not in prose.
- A shape that is not a constant vector exists and is followed — name it and say what it does.
- The determinism replays pass. A shape evaluated from accumulated fixed steps reproduces exactly, and
  if it does not, the phase is not done.
- `DeterminismRulesTest` stays green: no clock, no `Math.random()`, no `com.badlogic.gdx` in `core`.
- **`SystemOrder` is unchanged.** If a shape seems to need a new stage, stop and ask — that is
  invariant 5 and 10c already rejected moving a stage for a smaller reason.
- Every javadoc this phase falsifies is corrected in the same pull request.

## What is out of scope

- **Redesigning level 1 to use the new shapes.** That is [11e](../11e-level-one-redesigned/plan.md).
  This phase proves the mechanism; the content decision is the level's.
- **Enemy fire patterns.** `EnemyWeaponSystem.java:85-93` switches on one value and 10c explicitly
  refused to generalise it: "probably" is what invariant 6 exists to refuse. Revisit when a level
  design names a second shot shape.
- **The boss's movement.** `BossSystem` is level 1's boss and its own problem
  ([#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88), phase 12).
- Wave parameters, the per-level document, balance.
- Performance work of any kind.

## Risks

**Building a shape catalogue on expectation.** The temptation here is a small library of curves
"levels will obviously want". Four levels *probably* wanting something is precisely what the invariant
refuses, and the assessment's Part 3 shows the ledger being applied honestly: three of eight
deferrals flipped, five did not. Build what a beat points at.

**A shape that quietly reads state it should not.** A shape is a function of the entity's own elapsed
time and its spawn state. A shape that reads the player's position is a homing behaviour, which is a
different thing and a game rule nobody has decided. If a beat asks for one, stop and ask.

**Falsifying documentation while fixing code.** Three javadocs and one design document describe the
current narrow behaviour accurately. They become false the moment this lands.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11c-movement-shapes`, then `status.md` before review.

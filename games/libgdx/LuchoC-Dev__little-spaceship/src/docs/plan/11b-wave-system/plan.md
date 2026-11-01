# Phase 11b — The wave system

**Lane:** code + content · **Owner:** `core-domain` for `core/`, `level-designer` for `assets/data/` · **Depends on:** 11a · **The centre of the 11 group**

## Before you start

**Read, in this order:**

1. [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md), "Waves, first — everything else depends on it". It states the problem and lists four questions as open. **This plan answers all four**; the section below says how, and those answers are decisions, not suggestions.
2. [`../10c-architecture-review/assessment.md`](../10c-architecture-review/assessment.md), areas A, B, C and D. Area B is the one that names what strains and why it is one missing fact rather than a wrong shape.
3. [`../10c-architecture-review/decision.md`](../10c-architecture-review/decision.md), in particular "Rejected: move `SPAWN` later in `SystemOrder`". Do not re-open it.
4. `docs/planning/08-decisions-and-open-items.md`, "Architecture review, 27/08/2026" and "The wave system, 27/08/2026".
5. `CLAUDE.md` — invariants 2, 4, 5 and 6.
6. Your agent memory in `.claude/agent-memory/core-domain/`, in particular `project_core-deferred-surface.md`. Per 10b's correction to that file, use `git grep` for **whether** something is still deferred and the file only for **why**.

## Goal

**A wave is a named, reusable unit of level design, and `level-01.json` is expressed in waves without
changing a single frame of what the game does.**

The second half is the acceptance criterion that makes this phase honest. The redesign of level 1 is
[11e](../11e-level-one-redesigned/plan.md); this phase changes the *mechanism* and proves it by
migrating the existing level to it with the behaviour unchanged.

## What was decided, and by whom

Decided by the project owner on 27/08/2026, in the planning conversation that produced this folder.
The roadmap left these four open on purpose and 10c refused to close them because they belong here.
They are now closed, and recorded in `docs/planning/08-decisions-and-open-items.md`.

- **What ends a wave: either, chosen per wave.** A wave declares a fixed duration or "cleared", and
  **fixed duration is the default** — unless a level says otherwise, a wave behaves as the timeline
  does today. "Cleared" means every entity the wave spawned has been destroyed **or has left the
  playfield**, which is why [#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84) and
  [#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85) are in this phase.
- **How a wave is placed: relative to the end of the one before it**, with an offset. A negative
  offset overlaps them, which is how the roadmap's "high-pressure combinations" beat gets built.
  A level carries no absolute timestamps any more.
- **Whether a wave takes parameters: no, not in the 11 group.** Level 1 is being rebuilt from fourteen
  beats and there is no case of reuse yet, because reuse appears when level 2 exists. Invariant 6.
  Revisited in phase 12, which is the phase that will name the concrete case. **The risk is accepted
  and stated:** if 12 asks for it, it is a format change with one level built on top.
- **Where waves live: their own file, as named content.** `assets/data/waves.json`, beside
  `formations.json` and `trajectories.json`; a level references waves by id. This is what makes "the
  opening of level 1" reusable in another level, which `post-mvp-roadmap.md`'s "How later levels get
  built" requires. Per area A of the assessment, a new content kind is a new interface plus a new
  `ContentSource` method, and that is additive.

## Tasks

1. **[#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84) — an entity that leaves the
   playfield leaves the simulation.** Today `LifetimeSystem` expires only the two projectile layers
   (its javadoc, lines 22-24, says so), so an enemy that survives its descent exists for ever and
   keeps `World.noEnemyLeft()` false for ever. This is a correctness defect on its own, independent of
   waves. Note the asymmetry it has to preserve: `MotionSystem`'s javadoc states "Enemies leave
   freely" (line 99), which is a movement rule, not a lifetime one.

   **The mechanism is decided** — by the project owner on 27/08/2026 — and it is two things, not one:

   - **A lifetime, which never kills an enemy on screen.** An enemy carries a maximum lifetime; when
     it expires, the enemy is removed **only once it is off screen**. An enemy still visible at the
     end of its lifetime waits. Nothing vanishes in front of the player, which is the rule the whole
     mechanism exists to protect. The duration is **data, per archetype, not a constant in code** —
     the same call `08-decisions-and-open-items.md` already made for attachment durability.
   - **A safety box, well outside the playfield, that removes anything touching it at once.** This is
     the backstop for an entity a lifetime never catches. It is a generalisation of what
     `LifetimeSystem` already does for projectiles: a position check with a `MARGIN` of 16 logical
     units past the playfield edge (`LifetimeSystem.java:33,62-65`) against
     `MotionSystem.PLAYFIELD_WIDTH` (208) and `SpawnSystem.PLAYFIELD_HEIGHT` (270).

   **The box's size is the part that can break the game silently, and it has a number to clear.**
   Enemies are spawned *outside* the playfield today: `SpawnSystem.positionSpawned` (lines 170-180)
   places a formation's lowest slot at `PLAYFIELD_HEIGHT + radius` and every other slot higher by its
   `offsetY` spread. Measured against `assets/data/formations.json` on 27/08/2026, the largest spread
   is **`column-3` at 44 units**, so its top slot is born at `y ≥ 270 + radius + 44 = 314` — while
   the existing 16-unit margin ends at 286. **A box at today's projectile margin would destroy two
   thirds of a `column-3` on the frame it spawns.** Write down the box's coordinates, write down what
   they clear, and make a test fail if a spawn ever lands inside them. 11c makes this worse, not
   better: a movement shape that leaves and re-enters is exactly what the box must not eat.
2. **[#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85) — an entity records which wave
   spawned it.** `git grep waveId` and `git grep originWave` return nothing today. `SpawnSystem.spawnWave`
   is the only place a wave's entities are created, so it is one component or one field plus one write
   site. **One game rule to decide and write down:** whether the children a carrier spawns count
   towards their parent's wave. 10c named it and refused to answer it; it is yours.
3. **The content contract for a wave.** A new interface in `core.port` and a new `ContentSource`
   lookup, in the shape the other eight already have. `WaveTimeline` is today a flat
   `List<SpawnEvent>` and its javadoc says so — decide whether it gains a layer above it or its name
   stops matching the thing, and do not leave the two disagreeing.
4. **`SpawnSystem` advances on waves, not on a cursor into a flat list.** Its three assumptions all
   break: position is no longer a function of accumulated time alone, `SimpleWaveTimeline`'s
   constructor can no longer guarantee the order by sorting on a timestamp that does not exist until
   the run happens, and spawning is no longer fire-and-forget. **`SPAWN` stays fifth in `SystemOrder`**
   and a cleared trigger resolves one tick late, deterministically — that is decided, and #85 asks for
   the rule to be written into `SystemOrder.SPAWN`'s javadoc, which is where every other ordering rule
   in this project lives.
5. **[#87](https://github.com/LuchoC-Dev/little-spaceship/issues/87) — `JsonContentSource` loads a
   level by id.** Three lines carry the hardcoding today and the class javadoc already names what it
   would take. Independent of the other three; it can go at any point in the phase.
6. **Migrate `level-01.json` to waves, one-to-one — `level-designer`'s task, not `core-domain`'s.**
   Same spawns, same times, same behaviour. Where a
   group of the existing 92 events is obviously one beat, it becomes one wave with a fixed duration;
   where it is not obvious, keep it mechanical rather than clever. **This is a translation, not a
   design.** The design is 11e.
7. **Load the new format.** `JsonContentSource` reads `waves.json` and the level's wave references
   with `JsonReader`/`JsonValue` — never the `Json` serialisation class, which is reflective and
   breaks under TeaVM.

## Acceptance criteria

- A wave exists as named content in `assets/data/waves.json` and a level references it by id. The
  same wave id is referenced twice, somewhere, to demonstrate reuse rather than assert it.
- Both end conditions work, and there is a test for each that fails when the rule is broken.
- Placement is relative: moving a wave earlier in the file changes no other wave's declaration.
- Nothing in `core` imports `com.badlogic.gdx` and nothing reads the clock. `DeterminismRulesTest` is
  the mechanical check and stays green.
- **The determinism replay of level 1 still passes after the migration**, and its recorded outcome is
  the same as before it. If a replay's seed-plus-input no longer produces the same run, the migration
  is not one-to-one and the phase is not done. This is the criterion the whole phase turns on.
- The web target still builds, and `assets/startup-logo.png` is still there.
- #84, #85 and #87 are closed, and the carrier-children rule is written into
  `docs/planning/08-decisions-and-open-items.md`.
- **`.claude/agents/level-designer.md` no longer says a level is a timeline of timestamped spawn
  events.** That paragraph is marked "Not built yet" today and this phase is what falsifies it — the
  agent that reads it to design level 2 is the one who pays if it is left stale.
- **No enemy is ever removed while it is on screen**, and there is a test that fails if one is. The
  safety box's coordinates are written down with what they clear, and a spawn landing inside them
  turns a test red rather than a level silently losing enemies.

## What is out of scope

- **Redesigning level 1.** Fourteen beats, the new length and the balance pass are
  [11e](../11e-level-one-redesigned/plan.md).
- **Movement shapes.** [#86](https://github.com/LuchoC-Dev/little-spaceship/issues/86) is
  [11c](../11c-movement-shapes/plan.md). A `SpawnEvent` gaining a trajectory field belongs there, not
  here.
- **Wave parameters.** Decided above: not in this group.
- **The per-level document.** [11d](../11d-per-level-document/plan.md).
- **A boss engine.** [#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88) is phase 12's.
- Moving anything in `SystemOrder`. Rejected with reasons in 10c's decision.

## Risks

**Migrating and redesigning at the same time.** The one-to-one migration is what proves the mechanism
did not change the game. If the level gets "improved" while being translated, the replay goes red and
nobody can tell whether the wave system broke it or the new pacing did. They are two different phases
on purpose.

**The format becoming a small language.** The roadmap names this explicitly, and the no-parameters
decision is the defence. Every field added to a wave is a field an agent has to understand in phase 12.

**"Cleared" meaning something the code cannot answer.** It is answerable only once #84 and #85 exist.
Do not write a cleared-based wave into any level before both are merged.

**Sizing the safety box by eye.** It is the one number in this phase that fails silently: too small
and a level quietly loses enemies at spawn or mid-shape, and the symptom is a wave that never clears
rather than an error. The 44-unit measurement above is the floor, not the answer — it is what exists
today, and 11c will add shapes that travel further.

**Treating the lifetime as a balance knob.** It is a safety mechanism. An enemy dying on a timer that
the player can perceive is a game rule nobody decided, and it is not this one.

**Deciding a game rule by implementing it.** The carrier-children question in task 2 is a real
decision. Write it in `08-decisions-and-open-items.md`; do not let it be whatever the first
implementation happened to do.

## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, a pull
request against `phase/11b-wave-system`, then `status.md` before review.

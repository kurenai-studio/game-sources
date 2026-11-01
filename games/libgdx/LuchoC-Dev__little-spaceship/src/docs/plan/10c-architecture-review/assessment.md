# Phase 10c — what the 11 group needs, and what the code does today

Written on 27/08/2026 by the coordinator session that owns the 10 group. This is the record tasks 1
and 2 of [`plan.md`](plan.md) ask for.

**Everything below was checked against the repository at commit `96e6878`**, the tip of `dev` when
this phase opened. Every claim names the file and, where it helps, the line. Where something was not
checked, it says **not checked** — the rule 10b wrote down, and this document is nothing but claims
about a system, so it is where the rule matters most.

**`core-domain` was consulted once**, read-only, on three questions: what `core` must grow for
movement to be a function of an entity's own elapsed time; what makes a cleared-based wave easy or
hard; and which of its deliberate omissions the 11 group turns into a real case. It wrote nothing —
no branch, no file, no memory. Where its answer sharpened or corrected a finding, this document says
so in place. Its memory file `project_core-deferred-surface.md` was read for *why* something was
deferred and, per 10b's own correction to that file, never for *whether* it still is.

**Assessed against the code, not against the design documents.** That is the plan's own instruction
and it is not a formality: `docs/planning/12-architecture.md` was the largest concentration of drift
in the repository (findings F20–F26 of [`../10a-honest-documentation/audit.md`](../10a-honest-documentation/audit.md))
and, although 10a corrected it, a review that assessed the architecture by reading its own
description would be reading a document about a document.

---

## Part 1 — What the 11 group needs

Taken from [`../post-mvp-roadmap.md`](../post-mvp-roadmap.md) and from
`docs/planning/04-campaign-and-levels.md`, stated as testable needs rather than as intentions. Each
one is a thing the architecture either supports, extends to support, or does not.

| # | Need | The test it has to pass |
|---|---|---|
| **N1** | **A wave is a named, reusable unit of level design.** | A level file can name a wave once and place it more than once, in the same level and in another level, without repeating its contents. |
| **N2** | **A wave can end on world state, not only on a clock.** | The next thing in the level can be made to start when this wave is *cleared*, and the run stays reproducible from seed plus input. |
| **N3** | **A wave can be placed relative to what precedes it.** | Moving a wave earlier does not require rewriting every timestamp after it. |
| **N4** | **A wave can take parameters.** | "The opening of level 1, harder" or "mirrored" is expressible without copying the wave. |
| **N5** | **Movement is a described, named thing.** | An enemy's path can be a shape — a run that turns, a curve — rather than one constant velocity, and the shape is named content. |
| **N6** | **The same archetype moves differently depending on where in the level it appears.** | A `enemy-light` entering at second 30 and one entering at second 200 can follow different paths **without being two archetypes**. |
| **N7** | **Five levels coexist.** | Loading and playing level 2 is content plus wiring, not a second copy of the simulation. |
| **N8** | **A per-level document is the interface an agent designs from**, and it cannot drift from the level the game actually plays. | There is exactly one authored artefact per level. Anything else is generated from it. |
| **N9** | **A rule can be asserted by a test**, not only reproduced. | [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44). Breaking a wave rule turns a test red. |

N8 is the one the roadmap flags as load-bearing and as inheriting this project's worst failure mode.
It is also, as the plan predicted, the need with an architectural answer rather than a format one —
Part 2, area E.

**Out of scope here, on purpose.** What a wave *is* — its fields, its file, whether "cleared" means
every entity destroyed or every entity gone — is the 11 group's design decision. This document says
whether the code can hold one; it does not say which one.

---

## Part 2 — The architecture against those needs, area by area

### A. The content contracts in `core.port` — **extend cleanly; nothing breaks**

`ContentSource` (`core/src/main/java/dev/luchoc/littlespaceship/core/port/ContentSource.java`) has
eight lookups, all of the same shape: an id in, an interface out, `IllegalArgumentException` when the
id does not resolve. `EnemyDefinition` is an id plus a list of `ComponentSpec` — a name and an
untyped bag — so **the core does not know what a component is**
(`core/port/ComponentSpec.java:26`, `core/domain/content/ComponentFactoryRegistry.java:55`).

The consequence, checked rather than assumed: adding a component type to the game is one line in
`ComponentFactoryRegistry.withDefaults()` (`ComponentFactoryRegistry.java:79-88`) and nothing else —
no change to `ContentSource`, to `SpawnSystem`, or to the JSON loader. Three components arrived that
way after the contract was written (`"health"` in phase 05, `"spawner"` and `"weapon"` in phase 07;
the registry's own javadoc, lines 64-76, records each one and why it was not built earlier).

A new *content kind* — a wave, a movement shape — is a new interface plus a new `ContentSource`
method. That is additive: `ContentSource` is implemented in exactly one production place,
`game/adapter/content/JsonContentSource.java:43`, and in test fakes.

**Verdict: holds. N1, N4, N5 need new contracts, not different ones.** The one caveat is that
`WaveTimeline` (`core/port/WaveTimeline.java:14`) is named for a concept the 11 group is about to
redefine: today it is a flat `List<SpawnEvent>` and its javadoc says so. If waves become the unit,
either that interface gains a level above it or the name stops matching the thing. Cosmetic, but it
is exactly the kind of gap that produced F20–F26.

### B. `SpawnSystem` — **the timeline cursor is the strain point**

`SpawnSystem` (`core/domain/system/SpawnSystem.java:44`) holds three pieces of state: the level id, an
accumulated `levelTime`, and a single integer `cursor` into the event list. Its `update` is nine lines
(`SpawnSystem.java:77-90`): add the step to `levelTime`, fire every event whose `at()` has passed,
advance the cursor, and mark the timeline exhausted at the end.

That shape encodes three assumptions, and the 11 group breaks all three:

1. **Position in the timeline is a function of accumulated time alone.** A wave that ends on being
   cleared (N2) means the cursor advances on an event that is not a clock reading.
2. **The list is totally ordered by timestamp, and `SimpleWaveTimeline` enforces it in its
   constructor** (`core/port/SimpleWaveTimeline.java:17-27`). Relative placement (N3) means a
   timestamp that is not known until the run happens, so a sort at load time cannot be the guarantee
   any more.
3. **A spawn event is spawn-and-forget.** Nothing records which entities came from which event —
   `git grep waveId` and `git grep originWave` over the whole repository return nothing, and the
   component list in `World` (`core/domain/World.java:57-86`) has no provenance field.
   `SpawnSystem.spawnWave` (`SpawnSystem.java:92-112`) attaches the archetype's own components plus
   a `Transform` and, optionally, a `Drop`, and nothing else. The one per-death signal that exists,
   `EnemyDestroyed` (`core/domain/event/EnemyDestroyed.java:24`), is a bare `(x, y)` record — not an
   entity id, not a source. This is the single hardest fact for N2: **"this wave is cleared" is not
   answerable today, because "this wave's enemies" is not a set the code can name.**

Point 3 is a genuine gap and it is small: it is one component, or one field, plus whoever sets it —
`SpawnSystem` already loops per slot (`SpawnSystem.java:103-111`) and is the only place a wave's
entities are created. It is not a redesign.

**Verdict: strains, and the strain is one missing fact, not a wrong shape.**

### C. A wave that reads world state — **determinism holds; the precedent already exists**

The plan asks whether reading world state instead of a clock breaks anything. It does not, and this
is not reasoning from the invariants — the code already does it.

`World.View.outcome()` (`core/domain/World.java:478-494`) decides whether a level is complete by
reading the world: `waveTimelineExhausted && noEnemyLeft() && alive`. `noEnemyLeft()`
(`World.java:510-517`) walks the collider store counting `CollisionLayer.ENEMY`. That is a
world-state trigger, in the domain, shipped, and it violates none of the three determinism rules
(`core/src/test/java/dev/luchoc/littlespaceship/core/architecture/DeterminismRulesTest.java` is the
mechanical check; the only `com.badlogic.gdx` string anywhere under `core/src` is the forbidden-name
rule inside that test, line 22).

**But `noEnemyLeft` is also where the honest problem lives**, and it is worth stating plainly because
it is a live defect that the 11 group will hit on its first cleared-based wave:

- **Nothing removes an enemy for leaving the playfield.** `LifetimeSystem`
  (`core/domain/system/LifetimeSystem.java:47-49`) expires only `PLAYER_PROJECTILE` and
  `ENEMY_PROJECTILE`; its own javadoc says so (lines 22-24). Every other call to
  `World.markForDestruction` is damage, a bomb, a pickup collection, or a boss part —
  `grep -rn "markForDestruction(" core/src/main --include=*.java`, with the declaration and the
  javadoc references filtered out, returns **ten** call sites: `BombSystem.java:116`,
  `BossSystem.java:423`, `DamageSystem.java:92,150,153`, `HealthDamage.java:32,37`,
  `LifetimeSystem.java:56`, `PickupSystem.java:122,140`. None of them is "off screen and not a
  projectile".
- So an enemy that survives its descent and exits the bottom of the playfield **exists forever**,
  carries an `ENEMY` collider forever, and makes `noEnemyLeft()` false forever.
- Today this is invisible for the same reason #23 was invisible: `level-01.json` is a boss level, and
  a boss level completes only on `markBossDefeated()` (`World.java:485-489`), never through
  `noEnemyLeft()`. The bossless branch is exercised by exactly one test,
  `SpawnSystemTest.completesOnceTheTimelineIsExhaustedAndNothingIsAlive`
  (`core/src/test/java/dev/luchoc/littlespaceship/core/domain/system/SpawnSystemTest.java:328-345`)
  — and that test **calls `world.destroyEntity(enemy)` by hand** (line 340). No test covers an enemy
  that escapes.

That is not an argument against a cleared-based wave. It is a statement that **"cleared" needs a
definition that includes "left", and that today nothing produces "left"** — which is a second small,
nameable piece of work sitting next to the first.

**Verdict: holds on determinism; a named prerequisite (despawn) that the 11 group must build before
"cleared" means anything.**

### D. Invariant 5, the fixed system order — **holds; SPAWN does not have to move**

Invariant 5 says execution order is a game rule. `SystemOrder`
(`core/domain/system/SystemOrder.java`) declares fourteen stages and carries a per-stage javadoc
saying what breaks if a stage moves — `BOMB` before `COLLISION` (lines 26-38) is the load-bearing one.

The question the plan poses: where does a world-state-triggered wave leave that order? `SPAWN` runs
fifth, before `COLLISION` (10th), `DAMAGE` (11th) and `CLEANUP` (14th). So a `SPAWN` stage asking
"is the previous wave cleared?" reads a world that is **one tick stale**, and for two reasons rather
than one: the kill has not been *detected* yet — `COLLISION` and `DAMAGE` both run later — and even a
kill detected on the previous tick is only removed by `CleanupSystem`, which is the sole caller of
`World.destroyEntity` precisely so that no store changes under a system mid-tick
(`core/domain/system/CleanupSystem.java:19-22`). The earliest point at which "no enemy of this wave
remains" is actually true is after `CLEANUP`, which is to say: visible to the *next* tick's `SPAWN`.

One tick at 1/60 s is not a gameplay problem and it is not a determinism problem: stale-by-one is
deterministic, and reproduces identically on replay. It is only a problem if someone assumes
otherwise. And there is precedent for exactly this class of mistake being caught here: phase 02's
finding F4 (`docs/plan/02-core-mechanics/status.md`, quoted in `SystemOrder.java:52-57`) was a system
reading a buffer refilled by a later stage.

**Verdict: holds, and `SPAWN` should stay where it is.** A cleared-based trigger resolves one tick
after the kill, which is correct and reproducible. Moving `SPAWN` after `CLEANUP` to make it
"immediate" would put wave spawning after collision detection, and a wave spawning after the tick's
collision pass is a different, worse rule. If the 11 group wants the tick-late behaviour written down
rather than discovered, that belongs in `SystemOrder.SPAWN`'s javadoc, which is where every other
ordering rule in this project already lives.

### E. Movement as a described thing — **the real gap**

This is the area where the current code has the least to build on.

- `Motion` (`core/domain/component/Motion.java:12`) is two mutable floats, `vx` and `vy`. It carries
  no time, no phase, no origin, no target. Its own javadoc (lines 9-11) says trajectories "are not
  here yet".
- `TrajectoryDefinition` (`core/port/TrajectoryDefinition.java:16`) is `id`, `vx`, `vy` — a constant
  vector, and its javadoc says so outright: "the MVP's trajectories are constant velocities, not
  curves".
- The resolution happens **once, at spawn**: `ComponentFactoryRegistry.attachMotion`
  (`ComponentFactoryRegistry.java:95-99`) looks the trajectory up and copies its two floats into a
  `Motion`. After that the entity has no memory of which trajectory it was given.
- `MotionSystem.integrate` (`MotionSystem.java:81-94`) is Euler integration and nothing else. **No
  system anywhere modifies an enemy's `Motion` after spawn.**
  `grep -rn "motions()\.set\|motions()\.get" core/src/main --include=*.java` returns six lines:
  `Simulation.java:206` (the player's, at creation), `ComponentFactoryRegistry.java:98` (an
  archetype's, at creation), `BossSystem.java:402`, `EnemyWeaponSystem.java:97` and
  `WeaponSystem.java:80` (projectiles, at creation), and `MotionSystem.java:59` — the player's, the
  only one that is read and mutated every tick. `MotionSystem`'s own javadoc states the rule from
  the other side: "Enemies leave freely" (`MotionSystem.java:99`).

So **N5 and N6 have no mechanism at all today**, and the workaround the content is already paying for
is visible in the data: `assets/data/trajectories.json` holds four constant vectors, and
`assets/data/enemies.json` binds each archetype to exactly one of them
(`"motion": { "trajectory": "slow-descent" }` and so on, six archetypes). A `SpawnEvent`
(`core/port/SpawnEvent.java:19`) carries `at`, `enemyId`, `formationId`, `atX`, `dropId`, `dropSlot`
— **no trajectory**. Making a `enemy-light` enter differently in the late level therefore requires a
*second archetype*, differing only in one field. That is the copy-paste N6 exists to remove.

What it needs is not large, and it is worth being precise so the 11 group is not handed a vague
worry: an entity's path becoming a function of its own elapsed time means per-entity movement state
(a clock, or a phase index) and a system that advances it. Both are ordinary ECS: a component of
plain data plus a stage that already exists. Nothing about it touches the three determinism rules —
elapsed time accumulated from the fixed step is not reading the clock, and a shape that wanted
randomness has `World.rng()` (`core/domain/World.java:400`) waiting for it.

Two details that make this cheaper than it looks, both from consulting `core-domain`:

- **`SystemOrder.MOTION`'s own javadoc already reads "Applies velocities and trajectories"**
  (`SystemOrder.java:20`). The stage was named for this before it was built the narrow way, so
  evaluating a shape into a velocity fits inside the existing stage. **No reordering is implied**,
  which matters because reordering is invariant 5.
- The one-tick lag people would worry about — an entity spawned at `SPAWN` (5th) is not moved until
  the next tick's `MOTION` (2nd) — **already exists today**: `SpawnSystem.positionSpawned`
  (`SpawnSystem.java:170-180`) writes the `Transform` directly. A phase-aware trajectory inherits
  that lag, it does not introduce one.

**Verdict: a real gap, and the only one in this review that is a *missing thing* rather than a
*strained thing*.** It is also the one place where invariant 6's ledger has genuinely flipped — see
Part 3.

### F. Five levels coexisting — **holds, and the coupling is two lines**

`core` has no notion of "the current level" beyond a `String levelId` handed to `SpawnSystem`'s
constructor (`SpawnSystem.java:64`) and to `Simulation`'s four-argument constructor
(`core/application/Simulation.java:97`). Every `ContentSource` level lookup is already keyed by that
id — `timeline(levelId)`, `hasBoss(levelId)`, `boss(levelId)`.

The whole hardcoding of "one level" lives in `game`, and
`grep -rn "LEVEL_ID" --include=*.java .` returns exactly three lines:

```
game/adapter/content/JsonContentSource.java:50:    public static final String LEVEL_ID = "level-01";
game/adapter/content/JsonContentSource.java:79:        loadLevel(reader, dataDir.child("level-01.json"), LEVEL_ID);
game/screen/PlayScreen.java:100: ... new Simulation(content, audioDirector, game.seed(), JsonContentSource.LEVEL_ID);
```

`JsonContentSource`'s own javadoc (lines 45-50) already says a second level would turn that constant
into a parameter, and names the reason it was not done: no second concrete case.

**Verdict: holds. N7 is a change in `game` and zero changes in `core`.** What N7 does *not* cover, and
what does not exist: moving between levels within one run, carrying power-ups across
(`08-decisions-and-open-items.md` decides that rule; nothing implements it), or a level-select. Those
are phase 12/13, and this review does not size them.

**One thing five levels does hit hard, and it is not waves.** `BossSystem`
(`core/domain/system/BossSystem.java`) is level 1's boss, not a boss engine: six parts, their offsets
and radii are compile-time constants (lines 74-93), the pattern state machine is a fixed
`SPREAD`/`SWEEP` alternation over three private enums (lines 153-157), and `BossDefinition`
(`core/port/BossDefinition.java`) carries thirteen accessors, every one of them a number — health,
timing, projectile speed — and nothing structural. Its own class javadoc says footprint is "an art
fact, not content". A second boss with a different shape is a second system or a generalisation of
this one. **That is real work and it belongs to phase 12/13, not to the 11 group** — but it should
not arrive as a surprise, so it is issue [#88](https://github.com/LuchoC-Dev/little-spaceship/issues/88).

### G. The per-level document — **an architectural answer, and the code already gives it**

The roadmap frames this as the need most likely to create two copies of one truth. The plan says the
answer is architectural rather than a matter of format. It is, and the reason is in the contract:

**`core` reads a `ContentSource`, never a file** (`core/port/ContentSource.java:7-9`).
`grep -rn "json" -i core/src/main --include=*.java` returns six lines and **every one of them is
inside a javadoc comment** — `SystemOrder.java:76`, `ComponentSpec.java:10`, `MapComponentSpec.java:7`
and `:12`, `SimpleEnemyDefinition.java:8`, `SimpleWaveTimeline.java:14`. No code in `core` opens,
names or parses a file. Parsing lives entirely in `game/adapter/content/JsonContentSource.java`,
which is one adapter behind one interface.

That is the whole answer to N8. Whatever the authored artefact turns out to be, **it can be the only
authored artefact**, because the thing the game reads is an interface and not a file format. There
are three ways to satisfy that and the architecture permits all three:

1. the document is authored and the JSON is generated from it;
2. the JSON is authored and the document is generated from it;
3. there is one artefact and the adapter reads it directly — the "document" is a rendering.

**The architecture rules out only the fourth option**, which is the one the roadmap warns about: two
hand-maintained artefacts. Nothing in the code forces that, and nothing in the code prevents it
either — it is a process decision, and it is the 11 group's to make. What this review contributes is
that **no architectural work is needed to enable any of the three**, so the choice can be made on
design grounds alone.

### H. Tests — **the net N9 asks for does not exist yet, and this is a prerequisite**

Not a new finding — [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) states it and the
roadmap repeats it. It is recorded here because it changes the *order* of the 11 group's work rather
than its content: the assessment above proposes changes to `SpawnSystem`, to `Motion`, and to what
"cleared" means, and each of those is a behaviour change under a suite that mostly asserts a run
reproduces itself. **Not checked:** this review did not re-count how many of the 289 tests assert a
rule versus reproducibility; the roadmap's figure is taken as given.

---

## Part 3 — Invariant 6, tested against the new evidence

`CLAUDE.md`'s sixth invariant: *no abstraction without a real case in the MVP*. The plan is explicit
that this is the honest place to test it rather than treat it as settled forever, and that both
treating it as untouchable and treating it as negotiable are available mistakes.

The invariant's own wording contains the answer: it says **in the MVP**. The MVP shipped on
25/08/2026. So the question is not whether the invariant bends — it is whether the sentence still has
a subject. It does not, exactly, and the honest reading is that the *rule* was never "build nothing"
but "build for a case you can point at". Four levels and agent-authored content are cases that can be
pointed at, with a document behind them (`04-campaign-and-levels.md`, `post-mvp-roadmap.md`) rather
than a hunch.

Applied item by item to what the core deliberately lacks, using
`.claude/agent-memory/core-domain/project_core-deferred-surface.md` for the **why** each was deferred
— and, per 10b's own correction to that file, `git grep` rather than that file for **whether** it
still is:

| Deferred | Why, originally | Does the 11 group make it a real case? |
|---|---|---|
| Per-entity movement state / curved trajectories | `TrajectoryDefinition.java:8-10` — "nothing in the level 1 design asks for one yet" | **Yes.** N5 and N6 are precisely the case. The premise of the deferral has expired. |
| Wave provenance (which entities came from which event) | never named as a deferral; simply never needed | **Yes**, if the 11 group chooses a cleared-based end. Not otherwise. |
| Enemy despawn on leaving the playfield | `LifetimeSystem.java:22-24` — "nothing yet asks an enemy to expire by leaving the playfield" | **Yes.** N2 asks. Also a correctness matter on its own, see area C. |
| `PatternDefinition` / `ContentSource.pattern()` | memory file, and `12-architecture.md`: a pattern is a string on the component, one entry would be an abstraction with no case | **Not yet.** Enemy patterns are one shape today (`EnemyWeaponSystem.java:85-93` switches on one value). Four levels *probably* want more, but "probably" is what invariant 6 exists to refuse. Revisit when a level design names a second shot shape. |
| `Lifetime` timer component | `LifetimeSystem.java:18-20` — projectiles expire by position | **No.** Nothing in the 11 group needs a timer-expiring entity. |
| Concrete `GameEvent`s beyond `EnemyDestroyed` | phase 01: do not invent an event's fields before a system emits it (`docs/plan/01-foundations/status.md`) | **No.** The HUD still reads snapshots. No wave need identified here creates a consumer. |
| Spatial grid, object pooling | measured: 0.028 ms for the MVP scenario (`11-technical-prototype-results.md`) | **No**, and `beyond-mvp.md:41,43` already fixes the rule: a profiler, not a hunch. Explicitly out of scope by the plan. |
| A boss engine rather than level 1's boss | `BossSystem` class javadoc: footprint is an art fact | **Yes, but not for the 11 group.** Phase 12 is the first level that needs a second boss. |

**Three of eight flip. Five do not.** That is the outcome of actually testing the invariant rather
than assuming either answer, and the five that hold are the more interesting half: the invariant is
doing its job, and the flips are traceable to a named document rather than to a preference.

---

## Summary

| Area | Verdict |
|---|---|
| A — content contracts in `core.port` | Holds. New kinds are additive; one interface (`WaveTimeline`) will need renaming or a layer above it. |
| B — `SpawnSystem`'s timeline cursor | Strains. Three assumptions to relax; the hard one is that no entity knows which wave it came from. |
| C — a wave reading world state | Holds on determinism — `noEnemyLeft()` is the shipped precedent. Prerequisite: nothing despawns an escaped enemy. |
| D — invariant 5, the fixed order | Holds. `SPAWN` stays where it is; a cleared-based trigger resolves one tick late, deterministically. |
| E — movement as a described thing | **Gap.** No per-entity movement state exists, and a `SpawnEvent` cannot override an archetype's trajectory. |
| F — five levels | Holds. Two lines in `game`, none in `core`. A second boss is a separate, later problem. |
| G — the per-level document | Holds, and the contract is the answer: `core` reads a `ContentSource`, never a file. |
| H — tests | Prerequisite, not a strain. [#44](https://github.com/LuchoC-Dev/little-spaceship/issues/44) gates the rest safely. |

The decision this feeds is `decision.md`, in this folder — written by tasks 4 and 5 of the same phase.

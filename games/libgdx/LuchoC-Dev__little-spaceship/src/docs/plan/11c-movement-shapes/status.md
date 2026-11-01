# Phase 11c — Movement as a described thing · status

**State:** done — merged into `dev` in [#174](https://github.com/LuchoC-Dev/little-spaceship/pull/174)
**Updated:** 29/08/2026

This file holds the phase's `State:` line and its narrative, and the coordinator writes it — at the phase's opening and at its close.

**Per-task progress does not live here.** It lives in `status/`, one file per task, written by whoever did that task on its own branch. Read those for what each one did; this is what the phase amounts to.

## Done

**The same archetype now enters differently at second 30 and at second 200 without being two archetypes**, which was the whole phase. One `enemy-rush` in `assets/data/enemies.json` enters on `dive` in one spawn and on `strike-run` in another, and the arc is followed as a curve — 300 ticks of strictly-decreasing descent, a climb after the turn, and `vy` at 5 s equal to the closed form `-110 + 27·5`. Demonstrated in `SpawnSystemTest` and `MotionSystemTest`, not in prose, which is what the acceptance criteria asked for.

All five tasks, in three rounds, five pull requests: [#168](https://github.com/LuchoC-Dev/little-spaceship/pull/168), [#169](https://github.com/LuchoC-Dev/little-spaceship/pull/169), [#170](https://github.com/LuchoC-Dev/little-spaceship/pull/170), [#171](https://github.com/LuchoC-Dev/little-spaceship/pull/171) and [#172](https://github.com/LuchoC-Dev/little-spaceship/pull/172). `reviewer` audited rounds 1, 2 and 3 and accepted each.

**The three things 10c deliberately left undesigned are now decided and built:**

| What 10c left open | What answers it |
|---|---|
| which shapes exist | `shape-catalogue.md` — two kinds, `constant {vx, vy}` and `arc {vx, vy, ay}`, seven entries, eight refusals |
| how they are described | `core/port/TrajectoryDefinition.java`, sealed over two records, read from `assets/data/trajectories.json` by `game/adapter/content/JsonContentSource.java` |
| where the binding is chosen | `SpawnEvent.trajectoryId`, optional, with the archetype's own trajectory as the default |

`SystemOrder` is unchanged — the diff against it is empty — and `SystemOrder.MOTION`'s javadoc had read "Applies velocities and trajectories" since long before this phase. The stage was named for this work and it fitted inside it, exactly as 10c predicted.

## What the phase learned, and it is not the code

**Three of the four defects this phase produced were one thing: a claim outliving the fact it was true about.**

- `Trajectory` carried `originX`/`originY` for five commits, on the reasoning that "any position-relative shape needs a fixed reference point". #162 then decided a shape reads no position, and the fields came out. **The agent had flagged the guess in its own report rather than burying it**, which is what made the correction cheap.
- `Motion`'s javadoc went on naming that origin two branches after it was deleted. **Three agents and two `reviewer` passes went past it**, because every audit reads what its own branch changed and this was a sentence in a file that branch did not touch, made false by a *removal* elsewhere. A javadoc rots in the diff nobody is reading.
- #168's pull-request description still described the origin fields after the commits that removed them — the same shape `reviewer` had already recorded from #120 in phase 11b.

The fourth was structural rather than textual, and is the one worth carrying forward: **the plan named one agent too few, twice.** Task 3 says "loaded from `assets/data/`" and task 4 says `SpawnEvent` carries an id, and both readings assume the JSON is read in `core`. It is not — `JsonContentSource` is in `game/`, which is `game-presentation`'s. `core-domain` stopped at the boundary both times and wrote down the diff it could not make, rather than crossing it or leaving it implicit. The plan's running-order table is corrected in place, dated, with the warning that **any later plan saying "loaded from `assets/data/`" needs three agents, not two** — 11d is the next one to read that way.

## Two things that were settled by measurement rather than argument

**TeaVM supports sealed interfaces.** Making `TrajectoryDefinition` sealed put a Java 17 language feature into code that is transpiled to JavaScript, and nothing in CI proves the web target still builds — `./gradlew build` reports `compileTeavmJava NO-SOURCE` ([#123](https://github.com/LuchoC-Dev/little-spaceship/issues/123)). `reviewer` ran the real task, `./gradlew :web:gdx_teavm_web_js_build`, and grepped the emitted `app.js`: `ArcTrajectoryDefinition` appears 20 times, `TrajectoryDefinition` 38. `WaveEndCondition` was already sealed and already shipping, which is the precedent the work claimed. The question does not need re-litigating.

**The uniform `Trajectory` attach reaches nothing it should not.** Every entity built through `ComponentFactoryRegistry` now carries one, constant shapes included. `reviewer` checked what that reaches rather than taking the claim: only `SpawnSystem` and `SpawnerSystem` call the registry, while the player, the boss and both weapon systems set `Motion` directly, so no hand-set velocity is overwritten per tick and no `cleared` wave can deadlock behind an entity whose movement changed hands.

## Decisions taken while implementing

- **A shape is a function from the entity's own elapsed time to its velocity, and nothing else goes in.** No player position — that would be a homing behaviour, a game rule nobody has decided — no randomness, and **every shape must leave the playfield unattended in finite time**, because `LifetimeSystem` removes an enemy only once it is off screen and a `cleared` wave would otherwise deadlock behind one that stops. That last rule is why `enterAndHold` was refused.
- **The arc is evaluated in closed form**, `vy + ay·t` from `Trajectory.elapsed`, never accumulated tick by tick — accumulation would drift and would falsify the turn times and apexes the catalogue states.
- **An unknown shape id is not caught at load.** It parses and fails when `SpawnSystem` resolves it, uncaught, which is the treatment `enemyId` and `formationId` already get. An unknown *key* is still rejected immediately.
- All of these are recorded in `docs/planning/08-decisions-and-open-items.md`.

## Notes for whoever comes next

**No level uses a shape.** `waves.json`, `level-01.json` and `enemies.json` are untouched, deliberately: pointing a wave at `strike-run` would redesign level 1, and that is [11e](../11e-level-one-redesigned/plan.md). This phase built the mechanism and proved it; the content decision belongs to the level.

**One constraint 11e must respect:** the veers have to spawn on the side they veer away from — `veer-left` at `atX >= 0.75`, `veer-right` at `atX <= 0.25` — or the shape happens off screen.

**The catalogue rests on level 1 alone.** #162 asked for shapes that level 1's fourteen beats *and phase 12's two levels* point at, but phase 12's levels have no beat list anywhere, so half the question was unanswerable and was reported as such rather than filled in with invented beats. A sine or weave shape is named in the catalogue as the first candidate to revisit when a beat asks for one.

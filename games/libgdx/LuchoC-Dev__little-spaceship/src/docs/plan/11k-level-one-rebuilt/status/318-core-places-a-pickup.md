# 318 — `core` exposes a way to place a pickup with no enemy involved

**Branch:** `feat/content-places-a-pickup`. **Closes:** [#318](https://github.com/LuchoC-Dev/little-spaceship/issues/318).
`core-domain`, `core/` only. First half of the split named in #255: the loader that reads the JSON
(`game/adapter/content/JsonContentSource.java`) is a separate branch, not touched here.

## What was built

A new `core.port` record, `PlacedPickup(float at, String kind, float atX, float atY)`, deliberately
shaped like `SpawnEvent`: `at` means "seconds since the wave that carries it started", `atX`/`atY` are
fractions of the playfield in `[0, 1]`, the same convention `SpawnEvent.atX()` already uses. It lives
on `WaveDefinition` — `List<PlacedPickup> pickups()`, a **default** method returning `List.of()` — not
as a level-level list of its own, so `SpawnSystem` schedules it with the `ActiveWave` clock and cursor
that already exist for spawns, instead of a second scheduling mechanism.

`SimpleWaveDefinition` gained a canonical `(id, spawns, pickups, endCondition)` constructor with the
same "sorted or reject" validation `spawns` already has, plus a back-compat `(id, spawns, endCondition)`
constructor defaulting `pickups` to `List.of()` — the record-constructor trick from phase 07 (`SpawnEvent`
grew `dropSlot` the same way). Confirmed this kept `game`'s existing calls compiling unchanged:
`./gradlew :game:compileJava` is green with no source change on that side.

`SpawnSystem.spawnDue` walks `wave.definition.pickups()` with a second cursor (`ActiveWave.pickupCursor`),
alongside the existing `spawns()` cursor, and creates the pickup entity through a newly package-visible
`CleanupSystem.createFallingPickup(world, x, y, kind)` — the same five components (`Transform`,
`Collider`, `Sprite`, `Pickup`, the falling `Motion` issue #252 already gave every pickup) a dropped
one gets, factored out of `CleanupSystem.spawnDropIfAny` rather than duplicated. An unrecognised kind
fails the moment the placement is due, naming the wave id and the timestamp — `requireRecognisedPickup`,
the same shape as `SpawnSystem`'s existing `requireRecognisedDrop` for an enemy's designed `Drop`, both
asking the one source of truth, `PickupSystem.isRecognisedKind`.

**A placed pickup carries no `WaveOrigin`**, matching a dropped pickup exactly (`CleanupSystem` never
gave one either). This was a deliberate check, not an oversight: `WaveEndCondition.Cleared` asks "does
any entity still carry this wave's id", and a reward the player has no obligation to collect must never
be able to block a level from completing. Pinned by
`placedPickupCarriesNoWaveOrigin` in `SpawnSystemTest`.

## Where it sits in `SystemOrder`

`SystemOrder.SPAWN`, inside the existing `SpawnSystem` — no new system, no new stage. The issue's own
"watch out for" section frames it exactly this way: "a placed pickup enters the world at a scheduled
time, like a spawn." `SpawnSystem` already owns turning a wave's timestamped content into entities at
this stage; a placed pickup is a second kind of timestamped content on the same `WaveDefinition`, not a
different concern needing its own place in the pipeline. Building a new `PickupPlacementSystem` for one
shipped level and a handful of test scenarios would be the general placement engine invariant 6 refuses.

## What the loader (the other half) will need

- `PlacedPickup(float at, String kind, float atX, float atY)` — construct one per JSON entry, same
  validation shape as `SpawnEvent` (throws on a negative/non-finite `at`, an empty `kind`, or an
  `atX`/`atY` outside `[0, 1]`).
- `WaveDefinition`/`SimpleWaveDefinition` now take an optional fourth argument: use the four-argument
  `SimpleWaveDefinition(id, spawns, pickups, endCondition)` constructor when a wave's JSON has a
  `"pickups"` array, the existing three-argument one otherwise — both are still there, so no existing
  call needs to change unless it actually gains pickups.
- The unrecognised-kind message names the **wave id and the timestamp** ("wave 'x' places a pickup at
  Ys with an unrecognised kind 'z'") — `game` should wrap it with the file name the same way it already
  does for every other `ContentSource` failure, per that interface's own class javadoc.

## Ambiguity found in the issue/plan

None that blocked the work. One judgment call worth flagging: "refused at load" (acceptance criterion)
reads most literally as "at content-load time," but the existing precedent for the exact same shape of
problem — an enemy's unrecognised `Drop` kind — is refused when the wave's placement is *due* during
simulation (`SpawnSystem.spawnWave` → `requireRecognisedDrop`), not when the level file is parsed. I
matched that precedent for `PlacedPickup` rather than inventing a second failure point, since content
in this codebase is otherwise never eagerly walked start-to-finish at load for this kind of check (a
level with a wave a player never reaches would never surface a bad drop id either). `SpawnSystemTest`'s
`unrecognisedPlacedPickupKindFailsWithMessage` pins the message; it fires the tick the placement is due,
same as `unrecognisedDropIdFailsAtSpawnTime` already does for `Drop`.

#252 is unaffected by this change, one way or the other: a placed pickup gets the exact same falling
`Motion` a dropped one already does (post-#252 fix), so it does not make the neighbouring issue better
or worse.

## Defect found by `reviewer`, fixed on this branch

`reviewer` reproduced a real bug in `hasEnded`'s `Cleared` branch: it checked `wave.cursor >=
spawns().size()` and `noEntityCarries` but never `wave.pickupCursor >= pickups().size()`. A `Cleared`
wave whose entities all die before its own later-scheduled `PlacedPickup` is due gets resolved and
removed from `activeWaves` early — the pending pickup is then never spawned, silently, no exception, no
log. Fixed with the one-line symmetric guard `&& wave.pickupCursor >= wave.definition.pickups().size()`,
mirroring the guard `spawns()` already gets structurally from `wave.cursor`.

**Confirmed the addition actually catches it**: `clearedWaveWaitsForAPendingPlacedPickup` in
`SpawnSystemTest` — a `Cleared` wave with one spawn at local `t=0` (destroyed on the second tick) and
one `PlacedPickup` at local `t=30s` — failed before the guard was added (`./gradlew :core:test --tests
"*clearedWaveWaitsForAPendingPlacedPickup*"` red) and passes after it. My original
`placedPickupCarriesNoWaveOrigin` test could never have caught this: it places its pickup at `at=0f`,
always already due before the wave's own end condition is even checked.

**Not touched, on `reviewer`'s own instruction**: a *spawn* scheduled past a `FixedDuration` wave's own
duration is also silently lost today. Pre-existing, symmetric to the pickup case, and not part of this
issue's scope.

## A timing difference nobody decided, found by `reviewer`

**A placed pickup is collectable one tick earlier than a dropped one, for the same reason `#252`'s own
javadoc names.** `SpawnSystem` (which creates a placed pickup) runs at `SystemOrder.SPAWN` (5), before
`COLLISION` (10) — the placed pickup is visible to this very tick's collision pass. `CleanupSystem`
(which creates a dropped pickup) runs at `SystemOrder.CLEANUP` (14), after `COLLISION` already ran —
per that class's own javadoc, a dropped pickup "only becomes collectable from the next tick's
`CollisionSystem` pass." Both paths build the identical entity through the same
`createFallingPickup(world, x, y, kind)` — "same entity" is true, "same timing" is false. Nobody has
decided this should be the rule; it falls out of the fixed `SystemOrder` each path already runs at, not
from anything this task chose. Documented in `createFallingPickup`'s own javadoc (`CleanupSystem.java`)
rather than only asserted here, so the loader author and whoever authors content both see it before it
surfaces on screen as an unexplained one-tick difference.

## Acceptance criteria

- [x] `core` exposes a way for content to place a pickup of a given kind at a given time and position,
  with no enemy involved — `PlacedPickup` + `WaveDefinition.pickups()` + `SpawnSystem`.
- [x] Its place in `SystemOrder` is stated and justified — `SystemOrder.SPAWN`, above.
- [x] The rule is asserted by tests named after it — `SpawnSystemTest.placedPickupExistsAtItsScheduledTimeAndPosition`,
  `placedPickupNotDueYetDoesNotExist`, `placedPickupNeedsNoEnemyOrFormation`,
  `placedPickupFallsLikeADroppedOne`, `placedPickupCarriesNoWaveOrigin`,
  `clearedWaveWaitsForAPendingPlacedPickup`, `unrecognisedPlacedPickupKindFailsWithMessage`;
  `PlacedPickup`'s own validation and `SimpleWaveDefinition`'s pickup-list validation are pinned in
  `ContentDefinitionsTest`.
- [x] `core` still has no libGDX on its classpath — `grep -rn "com.badlogic.gdx" core/src/main/java`
  prints nothing. Still reads no clock, still calls no `Math.random()` — no new code touches either.
- [x] `./gradlew build` green, and `:rngparity` (the replay-reproduction module) builds clean as part
  of it.

## Commands run

- `./gradlew :core:test` — green, all new and existing tests pass.
- `./gradlew :game:compileJava` — green, confirms the back-compat constructor kept `game` compiling
  with no source change on that side.
- `./gradlew build` — green across every module (`core`, `game`, `web`, `desktop`, `rngparity`).
- `grep -rn "com.badlogic.gdx" core/src/main/java` — no output.

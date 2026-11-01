# Phase 11b — The wave system · status

**State:** done — merged into `dev` in [#131](https://github.com/LuchoC-Dev/little-spaceship/pull/131)
**Updated:** 28/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

- Task 5 / #87 — `JsonContentSource` no longer hardcodes `LEVEL_ID = "level-01"`. The constructor now
  takes a `levelId` parameter and reads `<levelId>.json` from the data directory. Per review, the id
  itself lives on `LittleSpaceshipGame` (`levelId()`, exposed the same way `seed()` is) rather than on
  `PlayScreen` — both `PlayScreen` and `ShipSelectScreen` already read session-wide state off that
  object, so this avoids coupling one screen to a sibling's constant. No directory listing was added —
  `FileHandle.list()` has no answer under TeaVM's asset packaging, and there is still exactly one level
  file, so eager single-level loading stays. See `feat/level-by-id` PR against this branch.
- **Task 1, [#84](https://github.com/LuchoC-Dev/little-spaceship/issues/84) — an entity that leaves
  the playfield leaves the simulation.** Branch `feat/entity-lifetime`. Built the two decided
  mechanisms: a `Lifetime` component (optional per archetype, `"lifetime": {"seconds": N}`, never
  removes an entity still on screen) and a safety box in `LifetimeSystem`, 128 units past every
  playfield edge, that removes an `ENEMY`-layer entity outright regardless of whether it carries a
  `Lifetime`. See `docs/planning/08-decisions-and-open-items.md`, "The 11 group, 27/08/2026", for the
  box's exact coordinates and what they clear. **The project owner then decided, on 28/08/2026, the
  game rule the first version of this branch had correctly refused to decide by implementation: an
  enemy that escapes gives the player nothing** — no score, no drop, no `EnemyDestroyed` (which would
  otherwise have played an explosion sound off screen through `AudioDirector`, the simulation's
  `GameEventSink`). `LifetimeSystem` now strips an escaping entity's `ScoreValue`, `Drop` and
  `Collider` before marking it for destruction, so `ScoreSystem` and `CleanupSystem` need no change at
  all — each already does nothing when the component it reads is absent.
- **Task 3, [#111](https://github.com/LuchoC-Dev/little-spaceship/issues/111) — the wave content
  contract.** Branch `feat/wave-contract`. Added `WaveDefinition` (id, spawns, endCondition — three
  things, nothing else) and `WaveEndCondition` (`FixedDuration` or `Cleared`, sealed to those two) as
  the ninth content kind, plus a `ContentSource.wave(id)` lookup — a **default** method, so `game`'s
  `JsonContentSource` keeps compiling untouched until #113 overrides it; #112's issue now carries
  flipping it to abstract once that loader lands. **Correction after the first review pass:** the
  offset was first placed on `WaveDefinition` itself, which the project owner caught — a wave that
  carries its own placement can only ever sit in one spot, defeating the reuse the whole type exists
  for. The offset now lives on a new `WavePlacement` record (`waveId`, `offsetSeconds`), the type a
  level's ordered sequence becomes; the same `WaveDefinition` can back as many `WavePlacement`s as a
  level (or two levels) need, each with its own offset. `SpawnSystem` was not touched, per the task's
  scope. `WaveTimeline` was left with its existing shape and behaviour (`SpawnSystem` still walks it
  as a flat, level-scoped `SpawnEvent` list) because changing its shape would have broken
  `SpawnSystem`'s compile, which this task may not touch — its javadoc now says so explicitly instead
  of silently disagreeing with the new contract, and names #112 as the task that migrates
  `SpawnSystem` onto `WaveDefinition` and `WavePlacement` and retires or repoints it. `SpawnEvent`'s
  own doc no longer assumes one reference frame, since it is now reused wave-relative (inside
  `WaveDefinition.spawns()`) as well as level-relative (inside the legacy `WaveTimeline`). See
  `feat/wave-contract` PR against this branch.

- **Task 2, [#85](https://github.com/LuchoC-Dev/little-spaceship/issues/85) — an entity records which
  wave spawned it.** Branch `feat/entity-wave-id`. New component `WaveOrigin` (`core/domain/component/`),
  a `World.waveOrigins()` store, attached by `SpawnSystem.spawnWave` — one wave instance is still one
  call to that method until the wave content contract exists, so its id is the timeline cursor
  position. `SpawnerSystem.spawnChild` copies the holder's `WaveOrigin` onto every child it creates,
  when the holder has one — the carrier-children rule the project owner decided on 28/08/2026, written
  into `docs/planning/08-decisions-and-open-items.md`. No other entity-creation site (`CleanupSystem`'s
  dropped pickup, `EnemyWeaponSystem`'s and `WeaponSystem`'s projectiles, `BossSystem`'s parts and
  projectiles) inherits a `WaveOrigin` — the decided rule names carriers and their `Spawner`-spawned
  children specifically. Nothing reads the component yet; the `cleared` end condition is #112.

- **Task 7, [#113](https://github.com/LuchoC-Dev/little-spaceship/issues/113) — `JsonContentSource`
  reads `waves.json` and a level's wave references.** Branch `feat/wave-loader`. `waves.json` is
  optional (a data directory without it loads with an empty wave registry, since `level-01.json`
  still carries `"events"` and no shipped content uses the new format yet) and, when present, is
  parsed into `WaveDefinition`s keyed by id, backing `ContentSource.wave(id)` directly — each spawn's
  `at` left exactly as declared, relative to the wave's own start. Its `"end"` block discriminates on
  a `"type"` string (`"fixedDuration"` needs `"seconds"`, `"cleared"` needs nothing else); any other
  value is rejected rather than defaulted.
  A level file's top-level block gained a third allowed key, `"waves"`, an ordered list of
  `{"wave", "offset"}` placements — mutually exclusive with the legacy `"events"` list, and one of
  the two is required. **First cut flattened a level's placements at load time into an absolute-time
  `SpawnEvent` list**, bridging the gap while `SpawnSystem` still only read the flat `WaveTimeline`
  — and rejected any placement naming a `Cleared` wave, since flattening cannot know a `Cleared`
  wave's end ahead of time. **Once #112 merged into this branch** (`SpawnSystem` now reads
  `ContentSource.wave(id)`/`placements(levelId)` directly and resolves `Cleared` itself), that
  bridge was deleted: `placements(levelId)` now returns the level's `List<WavePlacement>` exactly as
  declared — offsets and wave ids untouched, each wave id resolved against `waves.json` at load time
  so a typo fails loudly naming the level and the id, but no shifting, no merging, no rejecting
  `Cleared`. `timeline(String)` stays abstract in `ContentSource` (per #112) and this class still
  implements it for a level using the legacy `"events"` block; a level using `"waves"` populates
  `placements(levelId)` instead and is not present in `timelines`. `level-01.json` was not touched
  (out of scope, #114) and still loads exactly as before, through `timeline()`.
  Verified with a scratch program compiled against the real `core.jar`/`game` classes (rebuilt after
  merging #112) and a small fixture `waves.json` (two waves, one `FixedDuration` referenced twice in
  a level to demonstrate reuse, one `Cleared`) — eleven checks, including the two that changed
  meaning after #112: a `Cleared` placement now loads intact instead of being rejected, and
  `placements()` itself is what rejects an unknown wave id. See the task's PR description for the
  full list.

- **Task 6, [#114](https://github.com/LuchoC-Dev/little-spaceship/issues/114) — `level-01.json`
  migrated to waves, one-to-one.** Branch `content/level-01-waves`, `level-designer`. The 92 events
  became 13 `WaveDefinition`s in the new `assets/data/waves.json`, referenced through 15
  `WavePlacement`s in `level-01.json`'s new `"waves"` block. The `"boss"` block is untouched.
  - **Grouping principle:** the file's own blank-line separation, already 11 groups summing to
    exactly 92 events, became the base waves. Three of those groups were further split around a spawn
    that turned out to repeat verbatim elsewhere (below), for 15 placements total.
  - **The reuse pair, found rather than forced:** `enemy-tank`/`single`/`atX 0.5`, with no drop. It
    appears three times — at the original 86.0s, 126.5s and 297.0s — so it was
    pulled out as its own one-spawn wave, `l1-tank-solo`, carved out of whichever block it fell inside
    (splitting that block into an `-a`/`-b` pair around it). Referenced by three separate
    `WavePlacement`s, not two, which is stronger evidence than the acceptance criterion asks for.
    **Corrected on 28/08/2026:** this entry originally called it *the only* exact
    spawn-composition duplicate among the 92 events. That was false, and `reviewer` disproved it
    while auditing #125 with a three-line frequency count over
    `(spawn, formation, atX, drop, dropSlot)`: `enemy-rush`/`column-3`/`atX 0.5` repeats six times
    and `enemy-basic`/`line-5`/`atX 0.5` five, among others. Neither the migration nor the reuse
    criterion depends on the claim — the tank reuse is genuine and the times reproduce exactly — but
    the sentence was wrong and is not left standing. Those other repeats are candidates for further
    reuse whenever someone has a reason to take them; a one-to-one translation was not that reason.
  - **Why `l1-tank-solo`'s own duration is 1.0s, not the real gap to what follows it:** a
    `WaveDefinition`'s `FixedDuration` is one value shared by every placement that references it, but
    the three real gaps after each occurrence differ (6.0s, 2.5s, and "nothing — it's the level's last
    placement"). The wave's own duration is pinned to a value smaller than the tightest real gap
    (2.5s), and each following placement's own `offset` makes up the rest — `5.0` after the first
    occurrence, `1.5` after the second. Verified both by a from-scratch Python reconstruction of all
    92 absolute spawn times from the wave/placement model (see the task's PR description) and by a
    live run: a scratch program (`core.jar` + `game.jar` + `gdx.jar` on the classpath, `FileHandle`
    over the real `assets/data`, no `Gdx.app`) ticking a real `Simulation` for 310s of `level-01`
    logged every sprite-count change; every formation-sized jump lands within one 1/60s tick of its
    original `at` value, including all three `l1-tank-solo` occurrences (86.02s, 126.52s, 297.13s) —
    the residual is the same one-tick-late detection `SpawnSystem`'s own javadoc already documents for
    any chained placement, not a migration error. The boss still enters right after its own
    `entersAt: 302.0`, unaffected, since `BossSystem` reads that value directly rather than through the
    wave chain.
  - **Negative offsets were not used.** A negative offset always resolves to `previousEndTime +
    0.0` here, since `scheduleNext`'s `previousEndTime` argument is always exactly the current
    `levelTime` at the instant it is called — never earlier — so there is nothing for a negative value
    to subtract from. Every placement's own `offset` in this migration is `>= 0`.
  - `./gradlew build` (all modules except `:web`) and `./gradlew :web:build` both pass; neither
    touches `assets/data`, so this was mechanical confirmation, not a live check of the new content —
    the scratch program above is what actually exercised it.
  - **Not this task's to fix, flagged for whoever owns it:** the acceptance criterion "`.claude/agents/
    level-designer.md` no longer says a level is a timeline of timestamped spawn events" was not
    actioned by this branch — that file is outside `assets/data/`, which is this agent's whole
    boundary per its own "What you own" section ("Nothing else"). It still needs updating before
    `level-designer` is asked to design level 2 against it.

- **[#122](https://github.com/LuchoC-Dev/little-spaceship/issues/122) — `ContentSource`'s defaulted
  wave lookups retired.** Branch `refactor/abstract-wave-lookups`, PR #124. `wave(String)` and
  `placements(String)` are abstract again, so the interface is back to **zero** defaulted methods,
  where it was before this phase. Both were bridges across a module boundary `core-domain` may not
  cross — `JsonContentSource` lives in `game/` — and the bridge's reason expired the moment #113
  landed. A defaulted contract method would let a future `ContentSource` resolve no waves silently,
  where the compiler used to stop it.
- **[#126](https://github.com/LuchoC-Dev/little-spaceship/issues/126) — a negative offset did
  nothing, and now overlaps two waves.** Branch `fix/negative-offset-overlap`, PR #127. **Found by
  `level-designer` while migrating the level, not by a test.** `resolveEnded` scheduled the next
  placement with `scheduleNext(world, levelTime)`, and `scheduleNext` computed
  `Math.max(previousEndTime + offsetSeconds, levelTime)` — where `previousEndTime` *was* `levelTime`,
  so every negative offset was clamped away and behaved exactly like zero. Overlapping waves are a
  decided behaviour of this phase and they did not work.

  The fix schedules a `FixedDuration` wave's follower **predictively**, from the end its own duration
  already determines, chaining through consecutive `FixedDuration` placements; the reactive clamp
  stays only for `Cleared`, whose true end is genuinely discovered a tick late. That shape was forced
  rather than chosen: `resolveEnded` removes an ended wave from `activeWaves` before scheduling its
  follower in the same pass, so **no reactive formula could ever have produced overlap** — two waves
  could not be active at once by construction.

  `SpawnSystemTest.negativeOffsetOverlapsTwoWaves` was part of the defect: it asserted that both
  waves' entities exist after one tick, which **a zero offset satisfies equally well**. It was
  rewritten and then falsified twice, independently, by its author and by `reviewer`: reverting to
  reactive scheduling fails exactly one assertion, the `-2s` one, while the `0s` assertion stays
  green.

## In progress

Nothing else yet.

## Blocked

Waiting on 11a. Every task here is a behaviour change and 11a is the net.

## Decisions taken while implementing

- **First cut: an escaped enemy still awarded its `ScoreValue` and resolved its `Drop`**, deliberately
  not special-cased — issue #84 explicitly left "does escaping cost or gain the player anything" open,
  and special-casing it would have been deciding an undecided game rule by implementation. **The
  project owner then decided it, on 28/08/2026: an escaped enemy gives nothing.** Implemented by
  having `LifetimeSystem` — the only place that knows an entity is escaping rather than being
  defeated — strip that entity's `ScoreValue`, `Drop` and `Collider` before calling
  `World.markForDestruction`. `ScoreSystem` and `CleanupSystem` needed no change: both already do
  nothing when the component they read is absent, and `CleanupSystem`'s own "converges every
  destruction path uniformly, regardless of what killed its holder" stays exactly true — no
  source-aware branch was added to it. Two passes over `world.colliders()` inside `expireEnemies`
  (collect escaping entities first, strip and mark them only after the loop finishes) rather than one,
  because stripping an entity's own `Collider` while a loop is still walking that same store reorders
  its dense array and skips an element — `ComponentStore`'s own documented hazard. Recorded in
  `docs/planning/08-decisions-and-open-items.md`.
- **The safety box applies only to the `ENEMY` collision layer**, not to pickups or the boss's parts.
  Pickups do not move on their own (`CleanupSystem` spawns them at their source's position, `Motion`
  and `Lifetime` are never attached to one), so they cannot leave the playfield; the boss's parts stay
  on screen for the whole fight and the box never triggers on them either way. Projectiles keep the
  existing, separate, tighter `PROJECTILE_MARGIN` (16 units) — the safety box's 128-unit margin would
  leave them on screen for a very visible extra distance.
- **`Lifetime` is optional per archetype**, attached only when an archetype's `"lifetime"` spec is
  present, the same pattern `"health"`, `"spawner"` and `"weapon"` already use. No archetype in
  `assets/data/enemies.json` declares one yet — the safety box alone is what fixes #84 for existing
  content, since `assets/data/` is outside this agent's boundary (`core/` only). Whether any archetype
  should get an explicit, shorter lifetime is a content decision for `level-designer`.
- The golden fingerprint in `LevelScoreReplayTest` went through two values before settling: the
  original bug (`entities=12`, the escaped `enemy-rush` never removed) to the first-cut fix
  (`score=1600 entities=11`, escaping scored) to the final rule (`score=1350 entities=11`, escaping
  scores nothing — the entity count is fixed, the score is exactly what it was before #84 since
  nothing was ever credited for an escape). Only the final value is committed; see the test's own
  comment for the accounting.

## Notes for whoever comes next

- The other three per-task worries in the plan (#85 wave-origin tracking, the wave content contract,
  `SpawnSystem` advancing on waves) are unaffected by this branch: no `core.port` interface changed,
  only a new component, a new `World` store and `ComponentFactoryRegistry` registration, and
  `LifetimeSystem`'s internals. `./gradlew build -x test` passes across every module including `web`.
- `LifetimeSystemTest` now documents the safety box's worst-case-spawn measurement directly in a test
  (`safetyBoxClearsTheWorstCaseSpawn`), so a future change to `formations.json`'s spreads or
  `enemies.json`'s radii that outgrows the 128-unit margin has to be caught by hand — the test only
  guards the number as it stood on 27/08/2026, not a live read of the JSON (out of `core`'s reach).

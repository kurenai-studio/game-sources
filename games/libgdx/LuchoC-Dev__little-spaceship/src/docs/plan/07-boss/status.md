# Phase 07 — Boss · status

**State:** all three lanes done. `core` (boss, spawner, victory condition), content (level 1's real
curve plus the boss/carrier numbers, "Content lane — level 1 written" below), and now rendering —
`JsonContentSource`'s two parsing gaps closed, the boss wired to the screen. See "Rendering lane —
the boss on screen" at the end of this file. Enemy fire across the roster and the boss's cadence were
tuned afterwards — see "25/08/2026 — enemy fire across the roster" below.
**Updated:** 25/08/2026

## 25/08/2026 — enemy fire across the roster

A play session found that the player saw no enemy fire at all in the first ~166 s of level 1, because
`enemy-shooter` was the only archetype with a `"weapon"` component. `02-mvp-functional-spec.md`'s
roster prose (around line 176) says four of the six archetypes should shoot; this closes that gap in
content, using `EnemyWeapon`'s new `"firstShotDelay"` field (`core`, this same day) so an archetype
with no `Health` — one player hit destroys it — actually gets to fire before it can die, instead of
waiting out a full `"rate"` cooldown first.

**Roster-to-id mapping**, `02-mvp-functional-spec.md`'s prose against `assets/data/enemies.json`'s
real ids:
- Basic → `enemy-basic`
- Fast light → `enemy-light`
- Evolved basic/shooter → `enemy-shooter`
- Super-fast → `enemy-rush`
- Tank → `enemy-tank` (no shot in the spec; unchanged)
- Heavy carrier → `enemy-carrier` (no shot in the spec; unchanged)

**Numbers added**, all `"pattern": "straight-single"` — no second pattern exists, per the deferred
decision; a "different" shot for `enemy-light` is expressed only through cadence and projectile speed
for now:

| id | rate (cooldown) | speed | firstShotDelay | reasoning |
|---|---|---|---|---|
| `enemy-basic` | 3.2 | 70 | 1.0 | slowest cooldown and slowest projectile of the four, matching "slow shot"; short delay so it fires once even though it dies to one hit |
| `enemy-light` | 2.4 | 130 | 0.9 | faster cooldown and markedly faster projectile than the basic — the only two levers available to read as a "different" shot without a second pattern |
| `enemy-shooter` | 1.8 (unchanged) | 90 (unchanged) | 0.7 (new) | already the fastest cooldown of the four, satisfying "higher rate of fire than the basic" relative to `enemy-basic`'s new 3.2; only `firstShotDelay` is new, so it stops needing 1.8 s before its first shot |
| `enemy-rush` | 4.0 | 120 | 1.4 | slowest cooldown of the four (`shoots little`), checked against `dive`'s screen time (`vy -80`, ~3 s crossing a ~240-unit playfield): a 4.0 s cooldown all but guarantees at most one shot per rush enemy, which is the read the spec asks for |

`enemy-tank` and `enemy-carrier` were left unarmed — the spec names no shot for either.

**The low-health/slow-shot tension, stated as a recommendation, not silently resolved.** `enemy-basic`
and `enemy-light` still carry no `Health` component, so a single player projectile destroys either
outright regardless of `firstShotDelay`. A short delay (1.0 s / 0.9 s here) makes each individually
likely to get one shot off against a player who is not already aiming at it the instant it spawns, and
the visual check below confirms both do fire when left alone briefly — but a player clearing waves
aggressively will still rarely see either fire more than once, and never see the higher-rate-of-fire
contrast against `enemy-shooter` read clearly from a `enemy-basic` that is usually dead before its
second shot. The honest alternative is giving `enemy-basic` and `enemy-light` a small `Health` (2-3
points, i.e. surviving one player hit before the second in most weapon levels) so the rate difference
is actually visible in play — but that is a real balance change with real consequences (clear time,
chip damage against the player, `weaponProjectileDamage` currently 10 makes even 2 points a
non-trivial change) that this pass does not make. Recorded here as open rather than picked silently;
whoever plays this next should watch specifically whether `enemy-basic`/`enemy-light` ever fire twice
in ordinary play, and if the answer is consistently no, that is the concrete case for adding `Health`.

**Boss `patternCooldown`: `1.3` → `0.7`.** Reported from real play as firing far too little for a
boss. The cycle is `patternCooldown` + the fixed `0.75 s` tell (`BossSystem.TELL_DURATION`), so `1.3`
meant one attack every `2.05 s`; `0.7` brings that to `1.45 s`, roughly 30% more frequent, while
leaving the tell itself — the thing actually teaching the player to read spread vs. sweep — untouched.
Chosen by feel against "the fight's own description", not computed: `08-decisions-and-open-items.md`
and this file both already treat the tell as the fixed, load-bearing part of the pattern and the
cooldown around it as the free dial.

**Verified visually, not only reasoned about.** Using the established throwaway-content technique
(`.claude/agent-memory/game-presentation/project_temp-content-edit-for-boss-verification.md`):
`level-01.json` was overwritten locally to spawn `enemy-basic` and `enemy-shooter` at `t=1.0` (offset
to the sides, `atX 0.2`/`0.8`, to avoid an immediate ram at the player's centre spawn), launched
through `:desktop:run`, and screenshotted at `t≈2s` into the run. Both archetypes had already fired —
a pink `shot-e-small` projectile visible below each sprite, descending toward the player. This is
concrete confirmation the `firstShotDelay` fix works through the real content pipeline, not only
through `core`'s unit tests. `enemy-light` and `enemy-rush` were not separately screenshotted firing
(their `firstShotDelay` is reasoned from the same code path and the same
`ComponentFactoryRegistry.attachEnemyWeapon` that was visually confirmed for the other two, not
independently observed). The boss `patternCooldown` change was not re-verified visually against the
real fight in this pass — the earlier boss-verification session already confirmed the tell/fire cycle
renders correctly at the old cooldown, and this change only shortens the wait between cycles, not the
cycle's shape. The file was restored from a backup afterwards; `git status` on `level-01.json` and
`enemies.json` shows only the intended numeric changes.

**What the next play session should watch first:** whether `enemy-basic` reads as noticeably weaker
than `enemy-shooter` in fire frequency now that both fire, or whether `enemy-basic` still dies too
fast to ever prove it; whether the boss at `0.7` feels like enough pressure or still needs to move
further (the tell itself is the hard floor — it cannot go faster without redesigning it); and whether
`enemy-rush`'s single likely shot per spawn actually reads as "shoots little" rather than "does not
shoot" from the player's seat, since a single projectile against a fast-moving dive is easy to miss
entirely.

Update this file when the phase moves. It is the only place phase progress is recorded — the
`plan.md` next to it says what to do and does not change to reflect progress.

## Done

- **`BossDefinition` / `SimpleBossDefinition`** (`core.port`), looked up by level id through a new
  `ContentSource.hasBoss(String)` / `.boss(String)`, the same pattern as `WaveTimeline`. Carries only
  what varies with balancing — per-part health and score, entrance speed, the fight's combat `y`,
  the cooldown between attacks, and the two patterns' projectile speeds. The parts' footprint
  (offsets, radii, sprite ids) is *not* here: it is fixed in
  `docs/design/02-sprite-sizes.md`/`06-boss-presentation.md` and hardcoded in `BossSystem` as
  constants, the same treatment `Simulation` already gives the player's collider radius.
- **`BossStatus`** (`core.port`), a `(present, hp, hpMax)` snapshot, and `WorldView.bossStatus()`.
  `present` is exactly "spawned and not yet defeated" — the signal for the health bar
  `docs/design/04-hud-layout.md` shows only during the fight, and the signal for the music change on
  entry the plan's task 4 asks for (see "Decisions taken while implementing"). `hp`/`hpMax` are the
  sum across every part, so the bar shortens the instant any part is hit or dies, not only the core.
- **`BossSystem`** (`core.domain.system`, new `SystemOrder.BOSS` stage, after `SPAWNER` and before
  `LIFETIME`). Stateful like `SpawnSystem`: tracks its own elapsed level time, the part entity ids,
  and the pattern state machine. Phases: `AWAITING` → `ENTRANCE` (descends at `entranceSpeed()` until
  the core reaches `combatY()`) → `FIGHT` (cooldown, then a fixed-order, three-beat 0.75 s tell, then
  fire, alternating spread/sweep every cycle — no randomness anywhere in the pattern) → `DEFEATED`
  (core destroyed; whatever keel, pods or arms remain are marked for destruction with it, so the boss
  never lingers as a headless husk).
- **Six parts, not five — the collider gap fix.** `visual-designer` found, drawing the parts against
  `02-sprite-sizes.md`'s map, that 25 px of the core's keel was pass-through: a shot straight into the
  boss's own aim point registered nothing. Closed exactly as proposed in `06-boss-presentation.md`:
  a sixth entity, `core-keel`, radius 13.0 at offset (0, −27); the arms move from offset y −18 to −22.
  The keel carries its own `Health`/`ScoreValue` — the core's own numbers, since it reads as part of
  the core rather than a fourth kind of part — and no `Sprite` of its own: it only extends where a hit
  against the core's existing drawn sprite registers. It behaves exactly like a pod or an arm
  otherwise — dies with the core, its own death alone ends nothing. See "Decisions taken while
  implementing" for the judgement call this involved (independent health pool vs. a shared one).
- **The tell's whole contract is the ordinary `Sprite.frame` channel.** The charging parts' frame
  steps 1, 2, 3 across the three beats and drops to 0 the instant the shot leaves — no second,
  boss-specific contract exists on `BossStatus` for "which part, how far through the tell", since
  `forEachSprite` already carries per-entity animation state for everything else in the game.
- **Damage, ram, bomb and score need zero boss-specific code.** Every part, keel included, is an
  ordinary `ENEMY`-layer, non-fragile `Collider` carrying `Health` and `ScoreValue`, so
  `DamageSystem`, `BombSystem` and `ScoreSystem` already resolve a hit, a detonation and the points
  it awards.
- **The heavy carrier now actually spawns basic enemies periodically**, per
  `02-mvp-functional-spec.md:183`. New `Spawner` component (`core.domain.component`) — named in
  `12-architecture.md`'s component table from the MVP's first draft, unbuilt until the strong
  encounter gave it a real consumer — holding which archetype to spawn, the interval, and an offset
  from the holder, all data-driven through a new `"spawner"` `ComponentFactoryRegistry` entry. New
  stateless `SpawnerSystem`, new `SystemOrder.SPAWNER` stage between `SPAWN` and `BOSS`. This is why
  the strong encounter was chosen in the first place — two carriers now produce sustained pressure,
  not just two large, stationary targets — and it is what makes the encounter's own reason for
  existing real again. See "Notes for whoever comes next" for exactly what `level-designer` should
  write to tune it.
- **A spawn inside a spawn, kept deterministic.** `SpawnerSystem` never mutates the `Spawner` store it
  iterates — a spawned child never itself carries a fresh `Spawner` — and walks that store as a plain
  index loop over its dense array, never a `HashMap`/`Set`, so which carrier's child is created first
  when several are due the same tick is exactly the carriers' own creation order. Reasoning recorded
  in full on `SystemOrder.SPAWNER`'s own javadoc, citing phase 02's finding F4 as the precedent for
  this class of same-tick ordering mistake. `SpawnerReplayTest` proves the combination — `SpawnSystem`
  placing two carriers, `SpawnerSystem` spawning their children, all in the same run — reproduces
  identically twice through the real pipeline, not only in `SpawnerSystemTest`'s isolation.
- **The strong encounter needs no new archetype.** Two `enemy-carrier` waves, each carrying a
  `"spawner"` component, is content, not code — see "Notes for whoever comes next" for exactly what
  `level-designer` should write.
- **Issue #23, the drop-slot fix.** `SpawnEvent` gained a sixth field, `dropSlot` (which formation
  slot carries the drop), with a five-argument constructor kept for source compatibility that
  defaults to slot 0. `SpawnSystem.spawnWave` now attaches `Drop` to exactly that slot's entity, and
  fails at spawn time, naming the formation, if `dropSlot` names a slot the formation does not have.
- **`WorldView.outcome()` learned about the boss.** A new `World.bossLevel` flag, set every tick by
  `BossSystem` once it resolves `hasBoss(levelId)` true, makes a boss level complete *only* by
  `World.markBossDefeated()` — never by the older "wave timeline dry, no enemy left" rule, which
  would otherwise report `COMPLETED` the instant the boss's own pre-entrance quiet gap left no enemy
  on screen, long before the fight even started. A level with no `BossSystem` registered, or one
  whose content has no boss, keeps the exact pre-phase-07 rule. `DEFEATED` is still checked first in
  both branches, so it wins a same-tick tie against a boss dying on the very tick the player's last
  life is lost.
- **`SystemOrder` gained two stages**, `SPAWNER` and `BOSS`, both between `SPAWN` and `LIFETIME` in
  that order — stated explicitly per the "fixed system order" invariant, with the reasoning in each
  stage's own javadoc.
- **Tests, all inline, none reading a file**: `BossSystemTest` (spawn timing, six parts as
  `ENEMY`/non-fragile, the health bar present only during the fight, the entrance settling at
  `combatY`, the tell stepping 1→2→3→fire→0 with real per-tick steps, core death clearing the
  remaining parts and winning with a life left, `DEFEATED` winning a same-tick tie), `BossReplayTest`
  (a full victory and a full defeat run through the real `Simulation` pipeline, each reproduced
  twice), `SpawnerSystemTest` (interval timing, offset positioning, repeated firing, creation-order
  determinism across two holders due the same tick, a destroyed holder not spawning, an unknown
  enemy id failing by name), `SpawnerReplayTest` (two carriers through the real pipeline, reproduced
  twice), `ComponentFactoryRegistryTest`'s new `"spawner"` case, plus `SpawnEvent`/`SpawnSystem` cases
  for the drop-slot fix (a two-slot formation with the drop tied to slot 1, and an out-of-range slot
  failing at spawn time), `WorldTest`'s reflection guard extended for the new `Spawner` store, and
  `SystemPipelineTest`'s canonical-order fixture updated for both new stages.
- **266 tests total, all passing.**

Acceptance criteria against `plan.md` and issue #27:

| Criterion | Status | Where |
|---|---|---|
| The boss can be defeated and can kill the player, both to the right screen | **met on the `core` side** | `BossReplayTest.victoryIsDeterministic` proves `LevelOutcome` reaches `COMPLETED` through a real boss fight. For the defeat half, read the citation exactly: `.defeatIsDeterministic`'s `defeatContent()` never calls `.withBoss(...)`, so it proves `DEFEATED` through the ordinary rammer path, not a boss kill. The boss-specific rule — `DEFEATED` winning a same-tick tie against the boss's own defeat — is covered by `BossSystemTest.defeatWinsATieWithBossDefeat`, at the unit level. Which screen `game` shows for each is that module's job, not built here |
| Its health bar appears only during the fight | **met** | `BossStatus.present`, `BossSystemTest.presentOnlyDuringTheFight`; drawing the bar itself is `game-presentation`'s |
| Music changes on entry and returns correctly if the player dies | **hook provided, not implemented** | `BossStatus.present` flipping false→true is the entry edge; `game-presentation` detects it and plays/stops audio — see "Notes for whoever comes next" |
| The fight is deterministic: same seed and inputs, same outcome | **met** | `BossReplayTest`, both scenarios run twice with identical fingerprints; no `Rng` use anywhere in `BossSystem` — the pattern alternates by a fixed rule, never a roll |
| A replay covers a full victory and a full defeat | **met, with one caveat** | `BossReplayTest.victoryIsDeterministic`, `.defeatIsDeterministic`. Only the victory replay runs against a configured boss; the defeat replay is a boss-free scenario, as noted three rows above |
| Victory requires surviving with at least one life | **met** | `World.View.outcome()`'s `bossLevel` branch, `BossSystemTest.defeatWinsATieWithBossDefeat` |
| The strong encounter hands over the attachment, tied to one slot | **met on the `core` side** | the drop-slot fix; the actual two-carrier wave is `level-designer`'s content, not built here |
| The strong encounter is two carriers producing sustained pressure | **met** | `Spawner`/`SpawnerSystem`, `SpawnerReplayTest` |
| The boss is hittable everywhere it is drawn (the keel gap) | **met on the `core` side** | `core-keel`; the actual boss art/collider alignment is `game-presentation`'s to verify visually |

## Blocked

Nothing on the `core` side. The health bar's rendering, the tell's visual beats, the boss art, the
music itself and the actual `level-01.json`/`assets/data` boss and carrier content are all outside
`core`'s boundary and are not part of this pass.

## Decisions taken while implementing

- **No `GameEvent` for "boss entered".** No concrete `GameEvent` implementation exists anywhere in
  this codebase yet — every earlier phase deferred it for lack of a real consumer, per
  `core-deferred-surface.md`. Rather than being the first to invent one, the music-change hook is
  `BossStatus.present` itself: `game-presentation` already has to poll `WorldView` every frame for
  the HUD, and detecting `present` go `false → true` (start music) or `true → false` without
  `outcome() == COMPLETED` (the player died — stop/revert) is the same edge-detection shape it needs
  for other feedback the HUD row table names. Revisit if a second, unrelated consumer ever needs the
  same edge, at which point a real event earns its place.
- **One phase, two alternating patterns — the recommendation from the plan and the decision recorded
  in `08-decisions-and-open-items.md` — confirmed, not re-litigated.** The pattern order is
  `SPREAD, SWEEP, SPREAD, SWEEP, …`, alternated by a plain boolean flip, never by `Rng`. Determinism
  for a stateful fight like this is easiest to keep by removing randomness from the one place it
  would have mattered, not by being careful with it.
- **The boss holds position once it reaches `combatY`; it does not move during the fight.** The plan
  explicitly leaves "whether it moves or holds position" open. Holding position is the simpler,
  more readable choice the plan's own recommendation argues for, and it keeps the tell — the thing
  actually teaching the player to read the boss — as the only thing demanding attention during a
  cycle.
- **`core-keel` gets its own independent `Health`, not a hitbox that forwards damage into the core's
  own pool.** The alternative considered — attaching the *same* `Health` object reference to both the
  core and the keel entities, so a hit on either reduces one shared number — was rejected: `HealthDamage`
  marks for destruction whichever single entity was actually hit, so a shared object would leave the
  core entity itself "alive" (undestroyed) forever if the keel absorbed the killing blow, breaking
  `updateSpawned`'s `!world.isAlive(core)` check without extra, boss-specific bookkeeping to compensate.
  An independent pool is exactly the model the other five parts already use, needs no special case
  anywhere, and the cost — the keel region being incrementally tougher than a single hitbox would be,
  since a shot purely inside it does not also chip the core — is a fine trade for closing a
  pass-through gap. `reportStatus`'s `hp`/`hpMax` sum, and `handleCoreDeath`'s clean-up list, both
  simply grew by one more part.
- **A new enemy projectile is the first one this codebase has ever created.** No enemy has fired at
  all before this phase (`enemy-shooter`'s "higher rate of fire" in the functional spec was never
  built — the roster's own `ComponentFactoryRegistry` has no `"weapon"` factory yet). The boss's shot
  needed a `SpriteId`; `"boss-shot"` was invented here and needs art — flagged below.
- **Projectile angles are fixed ratios, not runtime trigonometry.** `Math.sin`/`cos` are not
  guaranteed to produce the identical float on the JVM and under TeaVM, which a replay cannot afford;
  the spread and sweep shapes are baked-in constants, the same treatment `WeaponSystem.SHOT_SPACING`
  already gets for the player's own volleys.
- **`ContentSource` gained two more methods.** `game`'s `JsonContentSource` does not implement them
  yet and will not compile until it does — the same kind of cross-module step every earlier content
  addition (`EnemyDefinition`, `AttachmentDefinition`, `WaveTimeline`) has required. Confirmed by
  running `./gradlew :game:compileJava` from this worktree, which fails naming exactly
  `boss(String)` as the missing override; adding `Spawner` did not introduce a second one, since it
  only touches `core.domain`, never `ContentSource`.
- **`SpawnerSystem` positions a child at the holder's own current position plus a fixed offset, never
  off-screen the way `SpawnSystem` places a wave's anchor.** A carrier's companion appearing at a
  station already on screen, wherever the carrier currently is, is the correct behaviour; the
  off-screen-entry trick exists for a wave's anchor specifically because a wave enters from beyond the
  playfield edge, which a carrier's own child does not need to.
- **The structure collider gap (31×39 sprite, no single radius-15 circle covers it) is recorded as
  open, not fixed.** `visual-designer` proposed two radius-11.0 colliders at offsets (0, ±10). Unlike
  the boss, no `structure-*` archetype exists anywhere yet — not in `enemies.json`, not spawned by any
  level, not referenced by any phase's content — so closing this would mean inventing the *general*
  capability for one archetype to carry more than one collider through the generic, data-driven
  content pipeline (`ComponentFactoryRegistry` currently attaches exactly one `"collider"` per
  entity), not a boss-specific fix the way `core-keel` was. That is real, unbuilt machinery with zero
  current consumer — precisely what this project avoids building ahead of a real need — so per the
  coordinator's own instruction ("if it drags, record it as open"), it is left open here rather than
  forced in. Worth a follow-up issue once a level actually places a destructible structure.

## Notes for whoever comes next

### For `level-designer`, in `level-01.json`

- **The boss.** No boss content file/schema exists yet — `game-presentation` needs to add
  `ContentSource.boss("level-01")` support first (see below) and decide where the JSON lives (a new
  `boss-l1.json`, or a `"boss"` object inside `level-01.json` — either is fine, `core` only cares
  about the shape of `BossDefinition`). Fields needed, exactly: `id`, `entersAt` (seconds since the
  level started), `coreHealth`, `podHealth`, `armHealth`, `corePoints`, `podPoints`, `armPoints`,
  `entranceSpeed`, `combatY`, `patternCooldown`, `spreadProjectileSpeed`, `sweepProjectileSpeed`. None
  of these numbers are decided by this phase — `10-mvp-initial-values.md` has no boss row yet. Nothing
  about `core-keel` needs a content entry: its health/points are the core's own numbers, read
  automatically.
- **The strong encounter is a `SpawnEvent` with `formationId` naming a two-slot formation and
  `enemyId` = `"enemy-carrier"`**, no new archetype. Give it a `dropId` of `"attachment"` and a
  `dropSlot` naming exactly one of its two slots — `0` or `1` — so the encounter hands over exactly
  one attachment, not two. This is the fix for issue #23, landed in this phase specifically so this
  encounter can rely on it.
- **`enemy-carrier` in `enemies.json` needs a `"spawner"` component added**, exactly:
  `"spawner": { "enemyId": "enemy-basic", "interval": <seconds>, "offsetX": <units>, "offsetY": <units> }`.
  None of these four values are decided by this phase — tune the interval and offset to taste; a
  negative `offsetY` (below the carrier, since `Transform.y` grows upward) reads most naturally for a
  companion trailing behind it, but nothing enforces that.
- **The boss's `entersAt` should land after the final escalation**, per
  `04-campaign-and-levels.md`'s beat 10, and the level's own four-minutes-or-more target already
  agreed in `08-decisions-and-open-items.md` under "Level 1 climax and length".

### For `game-presentation`

- **`ContentSource.boss(String)` / `.hasBoss(String)` are new abstract methods.**
  `game/adapter/content/JsonContentSource.java` does not compile until both are implemented — verified
  directly, this is not a guess.
- **The health bar reads `WorldView.bossStatus()`**: `present` for whether to draw the `BOSS` label
  and the bar frame at all (`04-hud-layout.md`'s `362,44`/`347,20` positions), `hp`/`hpMax` for
  `round(228 * hp / hpMax)` filled rows, exactly as that document already specifies.
- **The tell reads each boss part's ordinary `Sprite.frame`** through `forEachSprite`, the same
  channel as everything else. Frame `0` is idle/no tell; `1`, `2`, `3` are the tell's three beats
  (`06-boss-presentation.md`'s beats 1–3, each held for a quarter second); frame drops back to `0` the
  exact tick the shot leaves. Which two parts are charging is not a separate signal — it is simply
  whichever pods or arms currently report a nonzero frame, since the core's frame never changes.
  `core-keel` never carries a `Sprite` at all, so it never appears in `forEachSprite` — nothing to
  draw for it, by design.
- **Music change on entry**: watch `WorldView.bossStatus().present()` go `false → true` to start the
  boss track, and `true → false` to stop it — check `outcome()` at that same moment to tell victory
  (`COMPLETED`) from the player dying mid-fight (`DEFEATED`), since the spec asks the music to
  "return correctly" only for the latter.
- **`boss-shot` needs a sprite.** Invented in this phase for the boss's projectile — nothing in
  `02-sprite-sizes.md` covers it, since no enemy fired before this phase. Same rough scale as the
  player's own `shot-p1`/`shot-p2` (`PROJECTILE_RADIUS = 2.0f` in `BossSystem`).
- **`boss-core`/`boss-pod`/`boss-arm` sprites are drawn** in the art lane's worktree
  (`docs/design/06-boss-presentation.md`, `06-boss-presentation.md`'s mockups). `BossSystem` assumes
  exactly those three ids, mirrored by the renderer for the right-hand pod/arm as that document
  specifies. **The arms now sit at offset y −22, not −18** — re-check any mock or layout already built
  against the earlier number.

### A gap this phase did not close

`enemy-shooter`'s "higher rate of fire" from `02-mvp-functional-spec.md`'s minimum roster is built on
the `core` side but unused by content. This entry said "no enemy `"weapon"` component factory exists
yet"; that was true when it was written and was closed by this branch's own final commit, `b33f302`,
which added `EnemyWeapon`, `EnemyWeaponSystem` and the `"weapon"` entry in
`ComponentFactoryRegistry.withDefaults()`. What remains open is the content half: no archetype in
`assets/data/enemies.json` carries a `"weapon"` component, so nothing in the shipped level fires
through it. The carrier's periodic spawn, previously listed here as the same kind of gap, is
now built — see "Done" above. The structure collider gap is recorded as open above, in "Decisions
taken while implementing", for the reason given there.

---

# Content lane — level 1 written (`level-designer`, 22/08/2026)

Appended, not edited into the sections above: everything before this line is `core-domain`'s and
stays as written. This section covers `assets/data/level-01.json`, `formations.json` and the
carrier's `spawner` entry — issue #20's "replace the test fixture deliberately".

## What replaced the fixture

What shipped before was six events in 9.5 seconds, one of each archetype in a row, copied from a test
fixture. What ships now is **92 events across 297 seconds, then the boss at 302 s**. The boss's
entrance takes 5.4 s at the numbers below, so the fight starts around **5:07** and the level runs
roughly **5:45–6:00** end to end depending on how fast the core dies. That clears the four-minute
floor decided in `08-decisions-and-open-items.md` and lands at the top of the provisional 5–6 min
table in `10-mvp-initial-values.md`.

## The curve, stretch by stretch

Each stretch is named by what it is *for*. Whoever balances this later should tune inside a stretch's
intention, not across it — that is the whole reason this table exists.

| Time | Stretch | What it is for |
|---|---|---|
| 0:00–0:08 | **Calm** | Nothing spawns. The setting, the ship's handling and the background do the talking. Eight seconds is the low end of the spec's 5–10; the level is long enough already. |
| 0:08–0:34 | **Basics, isolated** | Three lone `enemy-basic` at different columns, then three `line-3` walls, then one `column-3`. Teaches the shot, the kill, and that a column can be occupied. The **weapon upgrade** lands at 0:21 on the centre of a three-wide wall. |
| 0:35–0:58 | **Fast light** | `enemy-light` alone first, entering high and right so its `swoop` drift to the left is legible on its own before anything else moves. Then `diagonal`, its mirror, then `vee-5`. Teaches leading a target that does not fall straight. |
| 0:59–1:24 | **First combination** | Basics and lights interleaved: a slow wall to shoot through while fast movers arrive from a different side. The pair of `column-3` at atX 0.15/0.85 (1:11) is the first time both edges are busy at once and the centre is the only answer. |
| 1:26–1:47 | **Tank, priority shift** | One tank alone in empty space — at `crawl` it lives about 30 s, so it is still there when the next waves arrive, which *is* the lesson. Then two tanks framing atX 0.3/0.7, leaving the centre lane as the read. |
| 1:52–2:14 | **Super-fast** | One `enemy-rush` alone, far from where the player is likely standing, then `column-3` triples (three darts down one lane 0.27 s apart), then rush pressure over a standing tank. Second **weapon upgrade** at 2:14 on the leading dart. |
| 2:18–2:40 | **Heavy carrier, alone** | A single carrier and nothing else for 13 s. This is the teaching beat for the spawner: the player must see one carrier make enemies before two of them mean anything. Light side pressure only after the lesson has landed. |
| 2:46–2:57 | **Evolved basic / shooter** | Singles, then `line-3`. The lightest stretch of the second half on purpose — it is a breath before the peak, and see the caveat below about what this archetype currently does. |
| 3:03–3:22 | **Pre-encounter peak** | Everything learned, at once, for twenty seconds: shooters, rush columns at both edges, a five-wide wall, two tanks, lights across the top. **Extra life** at 3:03. The **shield** lands at 3:21 on a lone basic in the centre, in a deliberate hole in the wave pattern — a guaranteed drop has to be collectable, not thrown at a fast target near an edge. |
| 3:28–4:00 | **The strong encounter** | Two carriers, formation `pair`, **attachment on slot 0**. Their spawn lanes are their own columns, so damaging a carrier means standing where its children appear; the 49 px gap between them is the escape. Two rush columns straight down that gap at 3:35 and 3:44, and a pair of lights at 3:51/3:53, keep it from becoming a shooting gallery once the carriers are the only thing left. |
| 4:00–4:16 | **Rest** | One lone basic at 4:05 carrying the **bomb recharge**, and nothing else for 11 s either side. Longer than the spec's 5–10 s because what follows is 40 s with no let-up. |
| 4:16–4:57 | **Final escalation** | No new archetype, no new lesson: recombination at a higher rate, alternating edges, twenty-four waves in 41 s. Third **weapon upgrade** at 4:24 — a power spike aimed straight into the climax, so the player reaches the boss at maximum. It peaks on a carrier under fire (4:47) while lights, rushes and a final tank arrive. |
| 5:02 | **Boss** | Five seconds after the last wave. Deliberately short: the escalation should crash into the boss, not fade out before it. |

## Guaranteed drops (`10-mvp-initial-values.md`'s four)

| Drop | At | Carried by | Why there |
|---|---|---|---|
| `weapon-upgrade` | 0:21 | centre slot of a `line-3` of basics | first third, and the earliest point at which "more projectiles" is legible against a static wall |
| `shield` | 3:21 | a lone basic, centre | before the strong encounter, in a quiet hole so it cannot be missed |
| `attachment` | 3:28 | slot 0 of the two-carrier `pair` | the encounter itself; `dropSlot` is what keeps two carriers from handing over two attachments |
| `bomb-recharge` | 4:05 | a lone basic, centre, alone in the rest | before the boss, and it doubles as the signal that something big is coming |

Three drops beyond the guaranteed four, placed for pacing: `weapon-upgrade` at 2:14 and 4:24 (so the
weapon reaches level 3 mid-level and level 4 immediately before the boss, rather than maxing at 2:20
and flattening everything after it) and `extra-life` at 3:03, on the peak that will cost the most
lives.

## Numbers chosen here

- **`enemy-carrier`'s `spawner`: `enemy-basic`, interval `4.0`, offset `(0, -24)`.**
  - `4.0 s` because a carrier that is never shot lives about 30 s crossing at `crawl`, so one alone
    yields six or seven children — enough to read the rule — while two in lockstep yield one every two
    seconds, which is sustained pressure without becoming a wall.
  - `offsetX 0` is the deliberate part: children come down the carrier's own column, the same column
    the player has to occupy to damage it. That tension is the encounter.
  - `offsetY -24` clears the carrier's radius-15 collider by 3.5 px against the child's own 5.5, so a
    child is never born inside its parent's silhouette, and `slow-descent` (-18) pulls it away from
    `crawl` (-9) immediately, so the two separate on their own.
- **Boss:** `entersAt 302`, `combatY 175`, `entranceSpeed 25` (a 5.4 s descent), `patternCooldown 0.7`
  (a 1.45 s cycle with the fixed 0.75 s tell — moved down from `1.3`/2.05 s during the enemy-fire pass,
  see "25/08/2026 — enemy fire across the roster" below), `spreadProjectileSpeed 95`,
  `sweepProjectileSpeed 140`, health 1800/500/500, points 1500/500/500.
  - **`combatY 175` is a pacing number, not an art one.** `BossSystem`'s spread and sweep ratios are
    fixed, so where a projectile leaves the playfield is decided entirely by how high the boss sits. At
    `combatY 175` a spread shot crosses the side edge at y≈41 and a sweep shot at y≈25 — inside the
    band the player actually flies in. Twenty units higher and both patterns exit the sides above the
    player's head, and the fight becomes unloseable. This is the single most fragile number in the file.
  - Spread fans outward from the pods and sweep converges inward from the arms, so the two patterns
    punish opposite places: spread makes the centre safe, sweep makes it lethal. That is the whole
    read the player has to learn, and it is why they alternate.
  - Points sum to exactly 5000, `10-mvp-initial-values.md`'s figure for the boss — remembering that
    `corePoints` is awarded twice, once for the core and once for `core-keel`.

## Formations added

`formations.json` gained five: `line-5`, `column-3`, `diagonal-mirror`, `vee-5` and `pair`. None
needs code — `JsonContentSource` reads any slot list — and all five are used. `pair` (±44) exists
because the strong encounter needs a two-slot formation and none existed; its 88 px separation leaves
a 49 px lane between the two carriers and about 40 px outside each. Every formation was checked
against the 208 px playfield at every `atX` used: no slot's collider crosses an edge.

## What was verified, and what was not

- **Verified**: every `spawn`, `formation` and `drop` id resolves; the timeline is sorted; every `atX`
  is in [0, 1]; every `dropSlot` names a slot its formation has; every drop kind is one of
  `PickupSystem`'s six; every spawned collider fits inside the playfield at its anchor; the boss block
  carries all thirteen `BossDefinition` fields and enters after the last wave.
- **Not verified: nothing was played.** `:game:compileJava` still fails on
  `JsonContentSource is not abstract and does not override abstract method boss(String)` — the known,
  documented blocker above — so the content cannot be loaded through `JsonContentSource` this session,
  let alone run. Everything above is arithmetic and static checking, not playtesting.

## What `game-presentation` must add before any of this loads

Two parsing gaps, both in `game/adapter/content/JsonContentSource.java`:

1. **`loadLevel` does not read `dropSlot`.** It calls `SpawnEvent`'s five-argument constructor, which
   defaults the slot to 0. Until it reads the sixth field, the four drops written on slot 1 land on
   slot 0 instead — harmless-looking, but it silently discards issue #23's whole point.
2. **The boss block is a `"boss"` object at the top of `level-01.json`**, sibling to `"events"`, with
   keys named exactly after `BossDefinition`'s accessors. A separate file was the alternative; one
   level with one boss did not justify a second file. `JsonContentSource` ignores unknown top-level
   keys today, so the file loads clean without it — and the level then has no boss at all and can
   never complete, which is worse than a parse error. Worth failing loudly on a missing boss block for
   a level that expects one.

## Open items recorded, not guessed

Added to `10-mvp-initial-values.md`: the boss's thirteen numbers, the carrier's four spawner numbers,
and the one that actually threatens this level's pacing — **the strong encounter's carriers currently
die in about three seconds**. At the placeholder `weaponProjectileDamage` of 10 and
`weaponFireCooldown` of 0.15, a single stream does about 67 damage per second against a carrier's
placeholder 80 hit points. The timeline reserves a 32-second window for the encounter, and only enemy
health decides whether it fills it. The same arithmetic makes the tank (40 hp) a sub-second obstacle
rather than the priority shift the 1:26 stretch is built around. Those are balance numbers, not pacing
ones, so they are recorded there rather than changed here.

## A gap this lane did not close — closed on 25/08/2026

**`enemy-shooter` does not shoot.** *(No longer true. Closed on 25/08/2026, before the MVP shipped:
`enemy-basic`, `enemy-light`, `enemy-shooter` and `enemy-rush` all carry a `"weapon"` component in
`enemies.json`, and `EnemyWeapon` gained a `"firstShotDelay"` because initialising the cooldown to
its full value meant an enemy that dies to one hit never fired at all. Recorded in `docs/STATUS.md`.
Struck through here on 26/08/2026 by phase 10a; the paragraph is kept because the pacing consequence
below is still live.)*

The machinery to make it shoot now exists — `core-domain` records
above how `b33f302` closed that half — but no archetype in `enemies.json` declares a `"weapon"`
component, so the behaviour is still absent from the game. So beat 9 of `04-campaign-and-levels.md`'s sequence currently reads as
"a larger, slower basic worth more points" rather than as the pressure it is meant to introduce, and
the 2:46–2:57 stretch will need rewriting, not just retuning, once enemies can fire. It is written to
be replaced: the shooter waves sit in their own contiguous stretch rather than being scattered
through the level.

**The rewrite the last sentence asks for has not happened.** Enemies fire now and that stretch was
never rebuilt around it; it belongs to the 11 group's wave work.

---

## `enemy-shooter` now shoots (`level-designer`, 25/08/2026)

Closes the gap the section above named. `enemies.json`'s `enemy-shooter` archetype now carries:

```json
"weapon": { "pattern": "straight-single", "rate": 1.8, "speed": 90 }
```

`"pattern"` is fixed — `EnemyWeaponSystem` only knows `"straight-single"`, and it is the only shape
`02-mvp-functional-spec.md`'s minimum roster needs. `"rate"` (1.8 s between shots) and `"speed"` (90
logical units/s) are **not** decided anywhere in `docs/planning/`; they are this lane's own judgement,
a starting point for the playing-based balance pass `08-decisions-and-open-items.md` already commits
this project to, not a computed optimum:

- 90 u/s is well under the player projectile's placeholder 220 u/s (`10-mvp-initial-values.md`) —
  the genre convention of enemy fire reading slower and more dodgeable than the player's own, and
  slow enough to be legible against `05-legibility-rules.md`'s reserved bullet colour on a first
  encounter. At that speed a bullet fired near the top of the playfield takes roughly 2.5 s to reach
  the bottom, comfortably inside the player's reaction window at the placeholder `playerSpeed` of 140
  u/s.
- 1.8 s between shots is a single, readable shot per enemy — not a curtain — since only one pattern
  exists and stacking several shooters (the `line-3` waves already in `level-01.json`) is what is
  meant to build the pressure, not the rate of any one enemy.

No other archetype was given a `"weapon"`. `02-mvp-functional-spec.md`'s roster prose also mentions a
"slow shot" for the basic and "shoots little" for the super-fast, but `08-decisions-and-open-items.md`'s
22/08/2026 entry frames `enemy-shooter` specifically as "the archetype that shoots" and the whole gap
this section closes was scoped to it — giving other archetypes a weapon now would be inventing
behaviour beyond what was asked and decided for this pass. Worth raising as a follow-up open item, not
folded into this change.

**Not touched:** `level-01.json`'s existing `enemy-shooter` waves (166.0–183.0 and the two later
appearances) needed no edit — they were already authored as isolated singles before combining into
`line-3`, which is exactly the "teach it alone before it arrives mixed" shape a first appearance of
live enemy fire needs. They simply do nothing until now.

**What to watch for in the balance pass:** whether 1.8 s reads as too slow to threaten (a shooter that
fires once and is dead before its second shot) or too fast once three are stacked in a `line-3` and
firing independently — three simultaneous 1.8 s timers can still cluster by chance since they are not
synchronised; whether 90 u/s gives enough reaction time at the player's own placeholder speed once
that speed itself is tuned; and whether the 2:46–2:57 stretch (still the lightest stretch of the
second half by design) now reads as a fair introduction or needs more space once bullets are actually
on screen.

**Verification.** `./gradlew build` is green. `core`'s and `game`'s test suites do not exercise
`assets/data/enemies.json` at all — no test in `game` loads it — so the only real check is booting the
game: `:desktop:run` started clean, past content loading, with no exception in the log before the
window opened (a bad `"weapon"` key would have failed loudly and early, per `JsonContentSource`'s
`requireOnlyKeys`). I could not get a screenshot of a shooter actually firing in this environment —
no visual confirmation, only the absence of a load-time failure. That last check is the first thing
the balance pass should do.

---

# Rendering lane — the boss on screen (`game-presentation`, 22/08/2026)

Appended, not edited into the sections above. Closes the two `JsonContentSource` gaps and wires
`BossStatus`/the tell to the screen — issue #27's remaining half.

## The loader

`ContentSource.boss(String)`/`.hasBoss(String)` are implemented in `JsonContentSource` (a new
`Map<String, BossDefinition> bosses`, populated from an optional `"boss"` object read in the same
pass as `"events"` — one file, not two, since `level-01.json` already carries it that way).

Both gaps `level-designer` found are closed:

- **`dropSlot` is read.** `loadLevel` now calls `SpawnEvent`'s six-argument constructor with
  `entry.getInt("dropSlot", 0)`, so the strong encounter's attachment lands on slot 0 as authored
  instead of silently defaulting there regardless of what the file says.
- **An unrecognised key now fails, naming the file and the key.** A new `requireOnlyKeys` helper
  walks a `JsonValue` object's own children (its public `child`/`next`/`name` fields — no new
  dependency, `JsonReader`/`JsonValue` only, per `CLAUDE.md`'s web-target rule) and throws if any key
  is not on an explicit allow-list. Applied to three places: the level file's two top-level keys
  (`"boss"`, `"events"`), each event entry's six keys, and the boss block's thirteen. This is
  deliberately scoped to what this phase touches, not every content file — `balance.json`,
  `enemies.json`, `trajectories.json`, `formations.json` and `attachments.json` keep the old
  "unknown key ignored" behaviour, since widening the check there risks breaking content nobody
  audited this pass and wasn't the reported gap. A follow-up issue could extend it once someone
  checks every existing file's keys against its schema.
- Verified directly, not inferred: a throwaway program loaded the real `assets/data` through
  `JsonContentSource` (`hasBoss("level-01")` true, `boss("level-01")` returns the thirteen numbers
  `level-designer` wrote), then loaded a copy of `level-01.json` with `combatY` typo'd to `combatYY`
  and confirmed it fails with `level-01.json: boss block has an unrecognised key 'combatYY'` — file
  name and offending key both present, per the acceptance criterion. `./gradlew build` passes, core's
  266 tests included, unaffected by anything in this lane.

## The boss on screen

- **`WorldRenderer` draws the tell.** `BossSystem` steps a charging pod's/arm's `Sprite.frame` 1→3
  and back to 0; `WorldRenderer.accept` now reads that frame and overlays beat 1 as a `W4` tint, beat
  2 as `F1`, beat 3 as a 1 px `N7` outline traced around the part's region (reusing the existing
  `pixel` texture, the same trick `drawAura` already uses for the power-up ring) — no new texture, no
  new per-frame allocation. `boss-core` never receives a nonzero frame, so it never overlays.
- **`HudRenderer` draws the boss bar**, exactly `04-hud-layout.md`'s geometry (frame `347,20` 8x230,
  fill `348,21` 6x228, `round(228*hp/hpMax)` filled rows in `W4` with a 1 px `W3` right-edge column,
  anchored top so the fill shrinks from the bottom as `hp` falls) and its "Feedback" note — the row
  strip lost in the most recent hit flashes `N7` for 2 ticks before going dark, tracked the same
  frame-over-frame diff way the life/bomb/shield flashes already are. Drawn only while
  `BossStatus.present()`, per "only during the fight"; the bar never reacts to the tell (a separate
  channel, per `06-boss-presentation.md`'s explicit warning), only to `hp` changing. `PlayScreen`
  passes `WorldView.bossStatus()` into `HudRenderer.draw`'s new third parameter.
- **Placeholder art added for `boss-core`/`boss-pod`/`boss-arm`/`boss-shot`** in `PlaceholderAtlas`,
  sized exactly per `06-boss-presentation.md` (47x87, 25x25, 31x45) and `BossSystem.PROJECTILE_RADIUS`
  (4x4), reusing the existing generic enemy/projectile silhouette generators. This is scaffolding for
  visual verification, not visual direction: the real art is `boss-core`/`boss-pod`/`boss-arm` on
  `feat/sprite-production`, unmerged; once that lands, `PackedSpriteAtlas` picks it up automatically
  and these four placeholder entries are simply deleted.
- **Not done: mirroring the right-hand pod/arm at draw time.** `06-boss-presentation.md` asks for it
  (one sprite, mirrored), but `SpriteVisitor.accept` carries no per-side flag and the placeholder
  silhouette is symmetric anyway, so there is nothing to verify against yet. Left for whoever wires
  the real, asymmetric art.
- **Not done: the music-change hook.** `BossStatus.present`'s false→true/true→false edge is exactly
  what `docs/plan/07-boss/status.md`'s "Notes for whoever comes next" names as the signal, but no
  audio playback code exists anywhere in `game` in this worktree — that lane runs in parallel on
  `feat/audio`, which this session was explicitly told not to touch. Wiring actual playback here
  would mean inventing audio machinery with no consumer, the thing this project avoids; `feat/audio`
  is the natural place to read this same `WorldView.bossStatus().present()` edge once it exists.

## What was verified live, and what was not

Verified with a real LWJGL3 window on a real GPU (not headless), per this agent's own memory on why
that matters here — screenshots taken, not just "it didn't crash":

- **The tell reads correctly and unmistakably.** Screenshotted mid-fight with a temporarily
  low-health boss (local-only edit to `assets/data/level-01.json`, reverted before commit — `git
  status` on it is clean): one capture shows both **arms** traced in a white outline (sweep's tell),
  a later capture shows both **pods** traced in white (spread's tell) — confirms the pattern alternates
  and that "pods for spread, arms for sweep" actually renders as designed, not just as asserted by
  `core`'s tests. Did not separately catch beats 1/2 (`W4`/`F1` tint) on screen — same code path,
  reasoned correct by inspection, but not eyeballed; the 0.9 s screenshot cadence against a 0.25 s
  beat is why.
- **The boss health bar renders and shrinks.** Present with the `BOSS` label only once the boss
  exists, orange (`W4`) fill visibly shorter in a later capture at a higher score than an earlier one
  at the same run.
- **Victory was reached twice**, through the real menu → ship select → play flow, holding fire via a
  simulated held key, not a debug shortcut: both runs ended on the `VICTORY` screen with the correct
  score breakdown (`5100` + `3000` lives bonus + `600` bombs bonus = `8700`), proving
  `LevelOutcome.COMPLETED` reaches `PlayScreen`'s branch and `VictoryScreen` renders correctly for a
  boss level, not only for the pre-boss "wave timeline empty" rule.
- **Defeat was not reached this session.** `PlayScreen`'s `DEFEATED` branch is unmodified code from
  an earlier phase and was not touched by this lane; `core.application.BossReplayTest
  .defeatIsDeterministic` already proves the boss can kill the player and `LevelOutcome.DEFEATED` is
  reached deterministically on the `core` side. Forcing a live defeat would have meant either
  reducing the player to one life and hoping a sweep shot lines up, or hand-tracing the boss's fixed
  projectile ratios to engineer a guaranteed hit — judged not worth the time against the stop rule,
  given the rendering path for `DEFEATED` is identical, pre-existing code to the `COMPLETED` path just
  verified.
- **Not attempted: a full, real-time run of the actual ~5:45 level.** Every screenshot above used a
  temporary, drastically shortened local copy of `level-01.json` (never committed) specifically to
  reach the boss in seconds rather than five minutes. The real level's own pacing, its escalation, and
  whether the strong encounter's carriers survive their 32 s window (the balance gap `level-designer`
  already flagged as open) were not exercised live.

---

## The tank gets a weapon; the basic/light `Health` question is closed (`level-designer`, 25/08/2026)

Reported from play: "these enemies do nothing" — `enemy-tank`. It carries `motion`, a non-fragile
`Collider` and 40 `Health`, and nothing that lets it act; it only absorbs bullets. `02-mvp-functional-
spec.md`'s roster says only "slow and resistant" for the tank and assigns it no shot, but does not
forbid one either. **Deciding as the coordinating lead's explicit call, not a roster requirement:**
the tank gets a weapon. "Resistant" is a property, not a behaviour; an enemy the player can only ever
shoot at, never be threatened by, is not a design choice recorded anywhere — it is an absence nobody
made on purpose. Recorded here so a later reader can tell this was a deliberate deviation, not an
oversight the roster prose settled.

```json
"weapon": { "pattern": "straight-single", "rate": 4.8, "speed": 60, "firstShotDelay": 1.6 }
```

Checked against the roster's other three shooting archetypes already tuned this same day
(`enemy-basic` 3.2/70/1.0, `enemy-light` 2.4/130/0.9, `enemy-shooter` 1.8/90/0.7, `enemy-rush`
4.0/120/1.4):

- **`rate 4.8`** is the slowest cooldown in the roster, on purpose — the tank is the one archetype
  whose 40 `Health` guarantees it survives long enough for even a very slow cadence to actually be
  seen twice, so it is the right place to spend the heaviest, slowest shot rather than trying to make
  a one-hit-kill archetype (`enemy-basic`/`enemy-light`) carry it.
- **`speed 60`** is the slowest projectile in the roster too (next slowest is `enemy-shooter` at 90).
  A tank that is itself slow and stationary-feeling firing a fast bullet would read as a different
  archetype wearing the tank's sprite; a heavy, lumbering shot matches the body it comes from.
- **`firstShotDelay 1.6`** is the longest in the roster, matched to `rate` the same proportionate way
  the other four archetypes were tuned (`firstShotDelay` ≈ 30-50% of `rate`) — the tank does not need
  a short delay to guarantee one shot before dying, since nothing here kills it quickly.

**The one thing this shot cannot do yet: look heavy.** `EnemyWeaponSystem` hardcodes `"shot-e-small"`
as the sprite for *every* enemy projectile — there is no per-weapon sprite selection, only a single
constant. The atlas already contains an unused `shot-e-heavy` region sized for exactly this case
(`02-sprite-sizes.md`), but wiring it in needs `EnemyWeapon` to carry its own sprite id (or
`EnemyWeaponSystem` to look one up per pattern/archetype) — a `core` change, out of this lane's
boundary and out of scope today. Until that lands, the tank's shot can only read as heavy through
cadence and speed, not silhouette; **worth an issue**: give `EnemyWeapon` a `spriteId` field (or
equivalent) so content can select `shot-e-heavy` for the tank instead of every enemy sharing one
projectile sprite.

### The `enemy-basic`/`enemy-light` `Health` question — decided, not deferred again

Earlier in this file (25/08/2026, "the low-health/slow-shot tension") this lane flagged but did not
make a recommendation: giving `enemy-basic`/`enemy-light` a small `Health` (2-3 points) so their
rate-of-fire contrast against `enemy-shooter` becomes visible in play. Re-examined now, against
`DamageSystem`'s actual rule rather than only against the spec prose — and the answer has changed
from "open, worth trying" to **no, do not make this change, because it does nothing**.

`DamageSystem.resolveEnemyHit` subtracts a flat `BalanceValues.weaponProjectileDamage()` — `10` in
`balance.json` — from an enemy's `Health` on every player-projectile hit, and this number does not
vary with the player's weapon level; only the *number* of simultaneous shots scales with level, not
the damage each one carries. An enemy with no `Health` component is already treated as having exactly
one point (`DamageSystem`'s own class javadoc states this explicitly). Giving `enemy-basic`/
`enemy-light` `Health: 2` or `Health: 3` therefore changes nothing observable: `10 > 3` in every case,
so either enemy still dies to the very first player projectile that reaches it, exactly as today.
Making the rate-of-fire contrast actually visible would need `Health` above `10` — a materially larger
change than the "small chip damage" the earlier entry described, and one that would cost real clear
time and real player-facing chip damage risk against every other archetype's own untouched `Health`,
for a benefit (seeing a `enemy-basic` survive to fire a second, slower shot next to a `enemy-shooter`
firing its second, faster shot) that a 2-3 point `Health` cannot deliver anyway. **Decision: leave
`enemy-basic` and `enemy-light` with no `Health` component.** The open item is closed, not deferred —
if the rate-of-fire contrast still needs to read more clearly after more play, the real lever is
`firstShotDelay`/`rate` tuning on the two archetypes themselves, or a `Health` value well above `10`,
not the 2-3 point range this lane originally floated.

### Verified visually, and what was not

Using the established throwaway-content technique
(`.claude/agent-memory/game-presentation/project_windows-desktop-screenshot-verification.md`):
`level-01.json` was temporarily edited to spawn one `enemy-tank` at `t=1.0`, `atX 0.5`, launched
through `:desktop:run` via the real menu → ship select → play flow (no debug shortcut), and
screenshotted around `t≈3.5s`. The tank (purple sprite) and a `shot-e-small` projectile it had already
fired, descending toward the player, are both visible in the same frame — direct confirmation the
tank's `EnemyWeapon` fires through the real content pipeline, not only reasoned from the code. The
player was not moved (no input simulated) and was hit; the run ended in `GAME OVER` a couple of
seconds later, consistent with an armed tank actually threatening a stationary target rather than
proof of a bug — this was not a dodging test. The edit was reverted before committing;
`git status`/`git diff --stat` on `level-01.json` shows no change, and only `enemies.json`'s two added
lines are in the commit. `./gradlew build` is green (`BUILD SUCCESSFUL`, core's test suite included,
unaffected by a content-only change).

Not verified: the tank's cadence (`rate 4.8`) over a longer window — one shot was seen, not two, since
the throwaway run ended on the first hit. Whether 4.8 s between shots reads as "heavy and deliberate"
versus "so slow it might as well not fire" across a real several-tank stretch of the level (the
1:26-1:47 "tank, priority shift" stretch, or the later solo/paired tank waves) is exactly what the
next balance pass should watch for, the same way earlier entries in this file leave `enemy-rush`'s
single likely shot as an open question.

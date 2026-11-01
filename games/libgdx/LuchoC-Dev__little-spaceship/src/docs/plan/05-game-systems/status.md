# Phase 05 — Game systems · status

**State:** done — merged in [#22](https://github.com/LuchoC-Dev/little-spaceship/pull/22)
**Updated:** 21/08/2026 (revised same day: `Health` added after a coordinator review caught it missing; revised again: `game-presentation` closed its side; revised again: review round 1 rejected on the bomb and a test guard, see below; revised again: `game-presentation` closed the silent-skip and placeholder-art gaps and added a third guaranteed drop, see round 2 below)

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

- `WeaponSystem` (`SystemOrder.WEAPON`): sustained automatic fire, cooldown-gated, reading the
  player's `shotLevel` and firing the exact 1/2/3/5-projectile volley shapes from
  `docs/design/02-sprite-sizes.md`'s weapon level table (`shot-p1`/`shot-p2`, radii 1.5/2.0).
- A new `Weapon` component (cooldown timer) and `Pickup` component (what a pickup grants), plus
  `Player.score`.
- `BombSystem` (`SystemOrder.BOMB`, a new stage inserted between `WEAPON` and `SPAWN`): spends a
  bomb charge, destroys every enemy projectile and every fragile enemy on screen outright, and
  subtracts `BalanceValues.bombDamage()` from a non-fragile ("resistant") enemy's `Health` —
  destroying it too, once that reaches zero. This is what turns "deals heavy damage to resistant
  enemies" (`02-mvp-functional-spec.md`) from an unimplemented phrase into an actual, tested rule.
- `LifetimeSystem` (`SystemOrder.LIFETIME`): expires a player or enemy projectile once it has fully
  left the playfield, by position rather than by a timer. Needed for `WeaponSystem` to not leak
  entities over a multi-minute level; no `Lifetime` timer component was built, since nothing needs
  one yet.
- A `Health` component, `12-architecture.md`'s own — `{"points": 40}` is that document's example
  for a tank — attached from content through `ComponentFactoryRegistry`'s new `"health"` factory,
  the same way `motion`/`collider`/`sprite`/`scoreValue` already are. See "Decisions taken" below
  for why this was missing from the first version of this phase and had to be added mid-review.
- `DamageSystem` now also resolves `PLAYER_PROJECTILE_VS_ENEMY`: a player projectile always
  destroys itself and subtracts `BalanceValues.weaponProjectileDamage()` from the enemy's `Health`,
  destroying the enemy once that reaches zero. An enemy with no `Health` component is treated as
  having exactly one point — shorthand for the weakest case of the same rule, not a second mechanism
  that could disagree with it, and shared with `BombSystem` through a small `HealthDamage` helper so
  both damage sources apply it identically. The defensive-chain logic `DamageSystem` already owned
  (invulnerability → shield → attachment → life) is untouched.
- `CleanupSystem` now spawns an actual `Pickup` entity from an entity's `Drop`, at the moment it is
  destroyed — the one place every path to destruction (ramming, weapon fire, bomb) converges, so a
  designed drop is honoured the same way regardless of what killed its holder.
- `PickupSystem` (`SystemOrder.PICKUP`): the five fixed power-up kinds (`weapon-upgrade`, `shield`,
  `extra-life`, `bomb-recharge`, `invulnerability`) plus `attachment`, each with its own consumption
  rule. A pickup already at its cap attaches a `ScoreValue` bonus to itself instead of being wasted,
  swept by the ordinary `ScoreSystem` pass — one mechanism for every point in the game, not two.
- `ScoreSystem` (`SystemOrder.SCORE`): sweeps `pendingDestruction()` for `ScoreValue`, removing it
  once awarded so an entity marked twice in one tick is never double-scored. Also exposes a static,
  pure `completionBonus(BalanceValues, Player)` for the end-of-level bonus — nothing in the core
  detects "level complete" yet (boss/victory is phase 07), so nothing calls it yet either.
- `AttachmentDefinition`/`SimpleAttachmentDefinition` and `ContentSource.attachment(String)`:
  durability is content, looked up by id, not a constant — the MVP's one attachment type uses
  `"attachment"` as both its pickup kind and its content id.
- `BalanceValues` gained eight new values, all placeholders pending balancing except the two
  completion bonuses (1000/300, already in `10-mvp-initial-values.md`): `weaponFireCooldown`,
  `weaponProjectileSpeed`, `pickupRadius`, `invulnerabilityPickupDuration`, `lifeCompletionBonus`,
  `bombCompletionBonus`, `weaponProjectileDamage`, `bombDamage`. The last two, plus every
  per-archetype `Health` value, are recorded as open in `10-mvp-initial-values.md` the same way
  `playerSpeed`/`playerStartX/Y` already are.
- `Simulation`'s MVP pipeline now includes `WeaponSystem`, `BombSystem`, `LifetimeSystem`,
  `PickupSystem` and `ScoreSystem`; the player is created with a `Weapon` component.
- Test suite grew from 167 to 223 (`./gradlew :core:test`), including two replay tests
  (`BombReplayTest`, `LevelScoreReplayTest`) exercising the full pipeline across a scripted,
  content-driven level.

## In progress

Nothing — review round 1's findings are all addressed, below.

## Blocked

Nothing.

**Task 8 (guaranteed drops) is now 3 of 4, not fully done, and 2 of the remaining gap are not this
branch's to close.** `assets/data/level-01.json` carries:

- a weapon upgrade in the first third — added in this round, on the `enemy-basic` wave at `t=1.0`
  of the level's current ~9.5 s span;
- a shield and the attachment, both present since before review round 1, on the `enemy-tank`/
  `enemy-carrier` waves.

What is still missing, and why it stays missing here: `docs/plan/07-boss/plan.md` states plainly
that **"the strong encounter" is itself undefined so far** — "also undefined so far, and needed for
phase 05's guaranteed drops" is that plan's own words — and is phase 07's decision to make, alongside
the boss. The shield/attachment placement on `enemy-tank`/`enemy-carrier` above is this content's
best current stand-in for "the strong encounter," not a confirmed instance of it; phase 07 may need
to move both once the real encounter is designed. **A bomb recharge before the boss cannot be placed
honestly at all: there is no boss content anywhere in `level-01.json` yet — that is also phase 07's
task, not built here or before.** So the remaining gap is not `game`/content design's to close on this
branch; it is blocked on phase 07 defining both anchors first.

Three of `PickupSystem`'s six kinds (`extra-life`, `bomb-recharge`, `invulnerability`) remain
unreachable by playing the shipped content — down from four before this round — even though every one
of them is built and tested at the system level.

## Review round 1

`reviewer` rejected the phase on pull request #22, narrowly: five of seven acceptance criteria were
genuinely earned, and the rejection was the bomb plus one test guard. What changed:

| # | Finding | Fix |
|---|---|---|
| F1 | `BombSystem` spent a bomb charge on every tick `input.bomb()` was true. `GameLoop.advance` feeds the *same* `InputFrame` to every tick of one rendered frame; at 30 fps or after a stall's catch-up, one press could reach several ticks and spend several charges. | A new `BombState` component tracks whether the control was held on the previous tick, so `BombSystem` only spends a charge on the tick-level rising edge — the first tick a press is seen, not every tick it stays true. `fire` has no such problem, since it is deliberately level-shaped; `bomb` was the first edge-shaped input the core consumed. `BombSystemTest.holdingAcrossTwoTicksSpendsOnlyOneCharge`/`releaseThenPressSpendsASecondCharge` pin both halves. |
| F2 | The bomb only marked entities for destruction; `CollisionSystem` never filtered `pendingDestruction`, so an enemy or enemy projectile the bomb "cleared" still produced a `CollisionHit` against the player the same tick, and `DamageSystem` still consumed a shield, the attachment or a life for it. | `CollisionSystem` now skips any entity already in `World.pendingDestruction()` this tick, regardless of what marked it — the general fix, not a `BOMB`-specific one, since the same hazard exists for anything `LifetimeSystem` expires too. `SystemOrder.BOMB` and `.COLLISION`'s javadoc now state why `BOMB` running before `COLLISION` is what makes this protection real, not merely a scheduling nicety. `CollisionSystemTest` gained four tests for the filter. |
| F3 | `BombSystem.detonate` had no positional bound, so it could destroy a wave that had just spawned fully off screen — proven by the branch's own `BombReplayTest`, which detonated at a tick where the enemy's centre was still 4.75 units above the playfield's top edge. | `detonate` now skips any candidate whose `Transform` falls outside `[0, PLAYFIELD_WIDTH] x [0, PLAYFIELD_HEIGHT]` — a simple centre-in-bounds rule, not a circle/rectangle overlap test, so the exact "barely poking into view" case that motivated the finding is excluded rather than argued about. `BombSystemTest` gained on-screen/off-screen/edge-inclusive tests; `BombReplayTest`'s script now waits until each wave has genuinely descended into the playfield before firing. |
| F4 | `WorldTest.destroyStripsEveryComponent`'s javadoc claimed to guard every `World` component store against `destroyEntity` forgetting one — the exact hazard phase 01 recorded — but it only asserted four of the thirteen (soon fourteen) stores by hand, and had already silently drifted once. | Rewritten to discover every `ComponentStore` field on `World` by reflection, populate all of them, and assert every discovered one is both non-empty before destruction and empty after. Adding a fifteenth store without extending the populate step now fails the test with a named message, instead of passing vacuously. |
| F5 | `ScoreSystem.completionBonus` was `public` with zero production callers, and its second parameter is a mutable `domain.component.Player` — machinery nothing outside `core` can obtain, since `WorldView` exposes no player state. | Made package-private. The phase-07 caller this exists for lives in the same package and can call it directly; going public happens when a real cross-boundary need exists, not ahead of one. |
| F6 | Task 8 (guaranteed drops) was not built — `level-01.json` carries 2 of 4 — while this file's "In progress" section said the task list was complete. | Corrected above, in "In progress"; the gap itself is still open, and building it means editing content data outside `core/`, so it stays `game`/content design's task. |
| F7 | `PickupSystem.resolvePickup` threw on an unrecognised `Pickup.kind`, but nothing checked a level's `drop` id before that — a typo loaded clean and only crashed a running level minutes later, the moment a player reached the pickup it produced. | `SpawnSystem.spawnWave` now calls a new package-private `PickupSystem.isRecognisedKind(String)` before attaching a `Drop`, and fails immediately, naming the enemy and the bad id, the moment the wave carrying it spawns — not content-load time exactly (a `port` cannot depend on `domain.system`'s machinery to check earlier than that), but the earliest point inside `core` that is architecturally reachable. `SpawnSystemTest` gained coverage for both the rejection and all six real kinds. |
| F8 | `BombReplayTest` and `LevelScoreReplayTest` compared two runs of the same build against each other, like `DamageReplayTest` (issue #12) — but unlike that one, both fixtures are fully in-test and fully deterministic, so a regression could slip through as long as it broke both runs identically. | Both gained a committed `GOLDEN_FINGERPRINT` constant, computed after every other fix in this table and compared against a live run in addition to the two-runs-agree check. `LevelScoreReplayTest` also gained a `scoredSomething` non-vacuity test and now gives `enemy-tank`/`enemy-carrier` the same `Health` (40/80) `assets/data/enemies.json` does, so `Health` is exercised at level scale instead of silently absent from the one integration-scale fixture that could catch drift in it. |
| F9 | The per-unit reading of the completion bonus — the reviewer agrees it is the better one — was recorded only in this file, though this file's own template says a decision touching a game rule also belongs in `08-decisions-and-open-items.md`. | Added there, under "Resolved contradictions". |
| F10 | `.claude/agent-memory/core-domain/project_game-systems-design.md` opened with "load-bearing for whoever eventually adds a `Health` component", written before `Health` existed; the next paragraph already said it did. | Fixed. |
| F11 | Four commit subjects on this branch exceed `CLAUDE.md`'s 72-character limit. | **Not fixed.** Fixing it means rewriting those commits' messages, which needs an interactive rebase or a force-push to update the already-pushed branch — both explicitly disallowed (`CLAUDE.md`: "never force-push"; this environment does not support `rebase -i` either). Recorded here as a known, deliberately unfixed nit rather than silently ignored; every commit from this point on respects the limit. |

Suite: 236 tests, all green, up from 223 before this round.

## Decisions taken while implementing

The plan named these as things to design, not things already decided, so they are recorded here and
also belong in `docs/planning/08-decisions-and-open-items.md`'s open-item list if not already
implied by it:

- **`Health` was missing from the first version of this phase, and that was a defect in the plans,
  not a deferred-on-purpose gap.** `12-architecture.md`'s component table lists `Health` explicitly
  ("health points, enemies and boss") and its JSON schema example gives a tank
  `"health": {"points": 40}` — the shape and even an illustrative value were decided from the start.
  It fell through a gap between phases: phase 04 read that document but modelled "does this enemy
  die outright" as `Collider.fragile` instead of building `Health`, and this phase's `plan.md` did
  not list `12-architecture.md` among its required reading, so nobody revisited the gap until a
  coordinator review caught it. Fixed two ways: `Health` is now built (see "Done" above), and
  `plan.md`'s "Before you start" now names `12-architecture.md`'s component table and schema section
  explicitly, so the next phase that needs a component's shape does not have to rediscover it either.
- **`Collider.fragile` and `Health` answer different questions, on purpose, so they cannot
  disagree.** `fragile` decides whether a ramming or the bomb kills an enemy's whole body outright —
  unchanged from phase 02, and the bomb still checks it first, before ever touching `Health`.
  `Health` decides how much sustained weapon damage an enemy can take, and is what the bomb applies
  to a *non*-fragile ("resistant") enemy instead. An enemy with no `Health` component is treated as
  having exactly one point everywhere damage is applied — weapon fire and the bomb alike — which is
  shorthand for the weakest case of the one rule, not a second rule that could disagree with the
  first. This does mean a non-fragile archetype that content forgets to give `Health` is destroyed
  in one hit despite being "resistant" on paper — unlike `"fragile"`, which fails loudly when
  omitted (`content-pipeline-design.md`), a missing `"health"` is *not* an error here: it is
  read as the deliberate one-point default. `game`'s content authoring has to know a resistant
  archetype always needs an explicit `"health"` entry; nothing in `core` enforces that pairing.
- **`BOMB` is a new `SystemOrder` stage**, inserted between `WEAPON` and `SPAWN`. The bomb destroys
  entities directly (`World.markForDestruction`) rather than through a `CollisionHit` — its range is
  the whole screen, not a shape two colliders can overlap — so it does not need to run near
  `COLLISION`.
- **`DamageSystem`'s scope widened** to also resolve `PLAYER_PROJECTILE_VS_ENEMY`, not only the
  defensive chain against the player. Both are damage resolution against a hit reported the same
  tick by `CollisionSystem`; `SystemOrder.DAMAGE`'s own stage name already reads as generic damage
  resolution, not specifically player defense, and only one system may claim a stage.
- **Six power-up/pickup kinds are fixed string constants on `PickupSystem`**
  (`KIND_WEAPON_UPGRADE` = `"weapon-upgrade"`, `KIND_SHIELD` = `"shield"`, `KIND_EXTRA_LIFE` =
  `"extra-life"`, `KIND_BOMB_RECHARGE` = `"bomb-recharge"`, `KIND_INVULNERABILITY` =
  `"invulnerability"`, `KIND_ATTACHMENT` = `"attachment"`). `Drop.pickupId` and `Pickup.kind` must
  use these exact strings; `game`'s content pipeline needs to match them.
- **Pickups do not move.** No `Motion` is attached to a spawned pickup entity; nothing in the
  planning docs asks for pickups to drift or fall.
- **The end-of-level score bonus interprets "1000 and 300 respectively" as per-unit**, not a flat
  amount: `lives * lifeCompletionBonus + bombs * bombCompletionBonus`. `10-mvp-initial-values.md`'s
  wording is ambiguous between the two readings; per-unit is the standard arcade convention and
  scales with "finishing in good shape," which is the stated intent. Now also recorded in
  `08-decisions-and-open-items.md` (review round 1, F9).
- **The tick-level rising edge lives in a component (`BombState`), not in `GameLoop` or the
  adapter.** Neither of those layers can fix it: `GameLoop` genuinely must feed one `InputFrame` to
  every tick of a frame — that is what makes a variable-length frame simulate a whole number of
  fixed steps — and an adapter's "just pressed" is inherently a per-render-frame concept, with no
  visibility into how many ticks that frame will produce. Tracking "was this held last tick" inside
  the simulation is the only layer that actually sees every tick, so it is the only layer that can
  detect the edge at the granularity that matters. `fire` needed no such state because it is
  deliberately level-shaped (sustained fire); `bomb` is the first, and so far only, edge-shaped
  input the core consumes — the next one-shot input (a boss trigger, say) will need the same
  pattern, not a shared abstraction invented ahead of that second real case.
- **`CollisionSystem` filters `pendingDestruction`, rather than moving `BOMB` to run after
  `COLLISION`.** The reviewer flagged both as defensible; the filter is the one actually used,
  because moving the stage does not work on its own — `BombSystem` only marks entities, it does not
  remove their collider, so even running after `COLLISION` would still need `DamageSystem` (or
  something) to skip a marked entity's hit, which is the same fix one stage later and one layer
  removed from where the hit was produced. Filtering in `CollisionSystem` also protects against a
  second case for free: `LifetimeSystem` (`SystemOrder.LIFETIME`, before `COLLISION` too) expiring a
  projectile the instant before it would have overlapped the player.
- **"On screen" for the bomb means the entity's `Transform` — its centre — falls inside `[0,
  PLAYFIELD_WIDTH] x [0, PLAYFIELD_HEIGHT]`, not "any part of its collider overlaps the playfield
  rectangle."** The generous, collider-overlap reading was considered and rejected: it would still
  have counted the exact reproduction from review round 1 (a wave a fraction of a unit past the
  edge) as on screen, since a sliver of the collider genuinely does overlap the boundary at that
  point. A simple, unambiguous position check is both easier to defend and actually excludes the
  case the finding was about.

## Notes for whoever comes next

**This section described a `game`-compile gap that no longer exists**; kept below, historically, as
the record of what happened, since `game-presentation`'s own section right after this one explains
how it closed it. Review round 1 did not touch `BalanceValues` or `ContentSource` further, so
`./gradlew :game:compileJava` is green again as of this revision — verified, not assumed.

Original note: extending `BalanceValues` and `ContentSource` — both owned by `core` — broke the two
adapters that implement them:

- `game/.../adapter/content/JsonBalanceValues.java` needed `weaponFireCooldown()`,
  `weaponProjectileSpeed()`, `pickupRadius()`, `invulnerabilityPickupDuration()`,
  `lifeCompletionBonus()`, `bombCompletionBonus()`, `weaponProjectileDamage()` and `bombDamage()`.
- `game/.../adapter/content/JsonContentSource.java` needed `attachment(String id)`, reading an
  `AttachmentDefinition` from content.

Both were `game-presentation`'s module, not `core-domain`'s, so they were not touched from this side.

**`enemies.json` needed a `"health"` entry for every archetype that should survive more than one
hit** — tank and heavy carrier, per `02-mvp-functional-spec.md`'s roster — and `game-presentation`
added it (40/80), matched in `LevelScoreReplayTest`'s fixture as of review round 1 (F8). Nothing in
`core` enforces that a non-fragile archetype actually has `Health`, on purpose — see "Decisions
taken" above.

## `game-presentation`'s side of this phase

Closed the compile gap `core-domain` left, per the "Notes for whoever comes next" section above.
`./gradlew :game:compileJava` named exactly two gaps and both are now filled:

- `JsonBalanceValues` gained the eight new record components (`weaponFireCooldown`,
  `weaponProjectileSpeed`, `pickupRadius`, `invulnerabilityPickupDuration`, `lifeCompletionBonus`,
  `bombCompletionBonus`, `weaponProjectileDamage`, `bombDamage`), read from `balance.json` with the
  same no-default `get*(String)` policy the rest of the record already uses. `balance.json` got the
  matching keys, values copied from the placeholders already recorded in `10-mvp-initial-values.md`
  for `lifeCompletionBonus`/`bombCompletionBonus`/`weaponProjectileDamage`/`bombDamage` (1000, 300,
  10, 50), and new placeholders for the four values that document did not have yet — now added there
  under a new "Weapon and pickup values — missing" subsection, same pattern as `playerSpeed`'s.
- `JsonContentSource.attachment(String id)` reads a new `assets/data/attachments.json`
  (`{"attachments": [{"id": ..., "durability": ...}]}`), parsed the same way as
  `trajectories.json`/`formations.json` — one `SimpleAttachmentDefinition` per entry, looked up by
  id, unknown id throwing through the same `require` helper every other lookup uses. The MVP ships
  one entry, `{"id": "attachment", "durability": 1}`, matching `PickupSystem.KIND_ATTACHMENT`.
- `enemies.json`'s two non-fragile archetypes (`enemy-tank`, `enemy-carrier`) each got a `"health"`
  entry (40, 80) through the existing `ComponentFactoryRegistry` factory — no loader change needed.
  The four fragile archetypes were left without one, on purpose: a fragile hit destroys them outright
  regardless of `Health`, per that component's own javadoc. Recorded as open placeholders in
  `10-mvp-initial-values.md`'s existing "Enemy health and weapon/bomb damage" section.

**What was verified, not just inferred:** `./gradlew build` is green, including `./gradlew :core:test`
re-run with `--rerun` to force actual execution rather than trust the up-to-date cache (223 tests,
all passing). `./gradlew :desktop:run` was started and left running under LWJGL for ~17 real seconds
with no exception in its log — past the level's first spawn events, including the `enemy-tank`/
`enemy-carrier` waves with `Health` and their drops, at `t=9.0`/`9.5`s. That is evidence the new
systems execute inside an actual running build without an exception surfacing, not a claim that the
new content was seen on screen — nobody watched the window, and the placeholder atlas
(`PlaceholderAtlas`) has no registered region for `shot-p1`/`shot-p2`/any `pickup-*` id yet, so
`WorldRenderer` silently skips drawing them (`region == null` early return, already built for exactly
this "content id with no placeholder registered yet" case) rather than throwing. Adding those
placeholder sprites is presentation work for a later pass, not required for this phase's acceptance
criteria, and is not blocking anything that was asked for here.

## `game-presentation`'s side, round 2: the silent skip, placeholder art, and a third guaranteed drop

A coordinator review of the round above found the silent-skip note directly above ("nobody watched
the window ... `WorldRenderer` silently skips drawing them") a real gap, not just an honestly reported
one, and asked for three things.

- **`WorldRenderer.accept` now logs an unknown sprite id once**, via `Gdx.app.error`, guarded by a
  `Set<String> missingSpritesLogged` field so a genuinely missing id cannot spam the log every frame.
  The early return itself is unchanged — skipping still beats crashing the render loop over an asset
  that has not arrived — but a typo'd content id is now loud instead of invisible, which matters more
  starting phase 06, when real art gets wired against these same strings.
- **`PlaceholderAtlas` now covers every sprite id phase 05 introduced**: `shot-p1`/`shot-p2` (player
  projectiles, 3x9/5x11 per `docs/design/02-sprite-sizes.md`'s "Projectiles" table, drawn cyan —
  `C1` body, `C2` core — matching "player fire is cyan and elongated") and the six pickup ids
  `CleanupSystem` actually produces (`pickup-weapon-upgrade`, `pickup-shield`, `pickup-extra-life`,
  `pickup-bomb-recharge`, `pickup-invulnerability` at 11x11, `pickup-attachment` at 13x13, per the
  "Pickups and structures" table's capsule/attachment-capsule rows), all drawn as one green capsule —
  `G2` body, `G3` highlight, matching R17 in `docs/design/05-legibility-rules.md` ("green, larger than
  any bullet") and the palette's own "pickup body"/"pickup highlight" entries. Telling the six pickup
  kinds apart by icon is production art's job per `02-sprite-sizes.md` itself ("told apart by the icon
  inside it") — out of scope for a placeholder, which only has to get size and colour right so no
  hitbox rework is forced later. No enemy fire exists yet in this phase (nothing enemy-side fires —
  see `ComponentFactoryRegistry`'s own note on `"weapon"` staying unregistered), so the reserved
  magenta band (`H1`/`H2`/`H3`) was not touched; there is nothing to draw in it yet.
- **`level-01.json` gained a third guaranteed drop**, `"weapon-upgrade"` on the `enemy-basic` wave at
  `t=1.0`, inside the level's current first third. The remaining two anchors (shield/attachment tied
  to "the strong encounter," a bomb recharge before the boss) are not built here — see "Blocked"
  above for why both are phase 07's decision, not a gap this branch can close.

**What was verified, not just inferred:** `./gradlew build` green; `./gradlew :core:test --rerun`
forced re-execution, 236 tests passing (confirmed after pulling `core-domain`'s review-round-1 fixes,
not re-tested by this branch's own changes — this branch touched no `core` file). `./gradlew
:desktop:run` was started and run for ~15 real seconds, past every spawn event in the level including
the new `t=1.0` drop and the `t=9.0`/`9.5` `enemy-tank`/`enemy-carrier` waves — no exception at all, and
no "no placeholder region for sprite id" line either, for whichever sprite ids that pass actually
exercised.

**What that does *not* prove, and is inferred from code instead:** the automated run drives no input —
`fire` is never held and nothing rams the player — so `WeaponSystem` never emits a `shot-p1`/`shot-p2`
projectile and no enemy is destroyed to produce a `pickup-*` entity either. Both this run and the
previous round's ~17 s run are silent on those ids not because they resolve, but because neither run
ever asked the renderer to draw one. That every id `PlaceholderAtlas` now registers
(`shot-p1`/`shot-p2`, all six `pickup-*` ids) matches the string every producer actually emits
(`WeaponSystem.SHOT_P1`/`SHOT_P2`, `CleanupSystem`'s `"pickup-" + drop.pickupId`, `PickupSystem.KIND_*`)
was checked by reading both sides side by side, not by watching one draw on screen. Confirming this at
runtime needs either driven input or a human playing the build — neither happened here.

**Acceptance criteria** (`docs/plan/05-game-systems/plan.md`):

| Criterion | Status |
|---|---|
| Every power-up covered by a test for its own consumption rule | Met — `PickupSystemTest` |
| Picking up a maxed power-up increases the score | Met — `PickupSystemTest.maxedPickupIncreasesTheScoreOnceSwept` runs `PickupSystem` then `ScoreSystem` together |
| The attachment absorbs exactly one hit, disappears, no life lost | Already covered by phase 02's `DamageSystemTest`, unchanged this phase |
| Attachment durability raised from data, no code change | Met — `PickupSystemTest.attachmentDurabilityComesFromDataNotAConstant`, `ContentDefinitionsTest` |
| The bomb clears projectiles and damages enemies in the same tick, deterministically | Met, as of review round 1 — on screen only (`BombSystemTest.enemyAbovePlayfieldIsUntouched`), protects the player the same tick (`CollisionSystemTest`'s marked-entity tests), spends exactly one charge per press (`BombSystemTest.holdingAcrossTwoTicksSpendsOnlyOneCharge`), and damages a resistant enemy's `Health` (`resistantEnemyWithEnoughHealthSurvives`/`resistantEnemyDestroyedOnceHealthIsExhausted`, `BombReplayTest`) |
| Score matches the table in `10-mvp-initial-values.md` | Met for per-enemy and maxed-pickup values (unchanged content-driven `ScoreValue`, `maxedPickupBonus`); the completion bonus's per-unit reading is a decision, now also recorded in `08-decisions-and-open-items.md` |
| A full-level replay produces the same final score twice | Met, and now a real regression net as of review round 1: both `LevelScoreReplayTest` and `BombReplayTest` compare a live run against a committed `GOLDEN_FINGERPRINT`, not only against each other. `DamageReplayTest` (issue #12) still lacks one — a smaller, separate fixture, not touched this phase |

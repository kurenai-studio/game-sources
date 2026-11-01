# 260 — a dropped pickup falls

Closes #260, closes #252. Branch `fix/pickups-fall` against `phase/11i-path-vocabulary`.

## What changed

- `core/domain/system/CleanupSystem.java` — `spawnDropIfAny` now attaches a `Motion` to the spawned
  pickup: `new Motion(0f, -balance.pickupFallSpeed())`. Negative because `Transform.y` grows upward
  (documented on `BalanceValues.playerStartY`), the same sign convention every trajectory in
  `assets/data/trajectories.json` already uses for a downward shape. `MotionSystem.integrate` needs
  no change: it already walks every `Motion` generically, with no dependency on `Trajectory`.
- `core/port/BalanceValues.java` — new `pickupFallSpeed()`, **a `default` method**, not abstract. See
  "Why a default method, and what it costs" below — this is the one non-obvious decision in this
  change.
- `assets/data/balance.json` — new key `pickupFallSpeed: 20.0`, next to `pickupRadius`.
- `core/domain/system/LifetimeSystem.java` — `expireProjectiles` (its position-based expiry, distinct
  from the enemy safety box) now also matches `CollisionLayer.PICKUP`. A pickup that reaches the
  bottom of the playfield uncollected is now removed the same tick, by the same margin check used for
  projectiles. Before this change nothing in the pipeline ever inspected a `PICKUP`-layer entity's
  position for expiry — checked by reading the method before editing it: the layer guard named exactly
  `PLAYER_PROJECTILE` and `ENEMY_PROJECTILE`, nothing else. A pickup could never have left the
  playfield before this issue (it had no `Motion`), so this was never a live bug, only a gap that this
  change would have exposed if left unclosed.
- Tests: `LifetimeSystemTest` gained `keepsAPickupInsideThePlayfield` and
  `expiresAPickupThatFellPastTheBottom` (named after the rule, per the issue's own requirement).
  `CleanupSystemTest` gained `spawnedPickupFalls`, asserting the exact `Motion` values, sign included.

## The two decisions the issue asked for, written down

**What speed.** `pickupFallSpeed = 20` (units/second, magnitude). Candidate, not final — the issue is
explicit this is a feel question for the project owner to play, not compute. Reasoning for the
starting number: `assets/data/trajectories.json`'s slowest enemy descent is `slow-descent` at `-18`
and `crawl` at `-9`; `20` sits just past the slower end of that range, close enough to read as part of
the same falling world the enemies already move through, not dramatically faster or slower than
anything else on screen. No background-scroll-rate constant exists anywhere in the repository to
compare against directly — checked with `grep -rn "scroll" docs/planning/ core/ game/` and found
nothing naming a rate, so "the background's own rate" from the issue has no existing number to match;
`20` is a reasoned guess bounded by the enemy speeds that do exist, not an arithmetic derivation.

**What removes one that reaches the bottom.** Checked `LifetimeSystem.expireProjectiles` before
assuming it was covered, per the issue's own instruction — it was not: the layer guard named only
`PLAYER_PROJECTILE` and `ENEMY_PROJECTILE`. Fixed by adding `CollisionLayer.PICKUP` to that same
check, reusing `PROJECTILE_MARGIN` (16 units), which already clears `pickupRadius` (6 units) with
room to spare. A pickup that falls off the bottom uncollected is now destroyed, silently, with no
event and no score consequence — matching the issue's own framing that a missed pickup is "a reward
the player can now miss," not a special case needing its own signal.

## Why a default method on `BalanceValues`, and what it costs

`BalanceValues` has exactly two implementers: `core`'s own `TestBalance` (mine, updated with a real
field) and `game`'s `JsonBalanceValues` (`game/src/main/java/.../adapter/content/JsonBalanceValues.java`,
a record enumerating every `balance.json` key by hand — checked by reading it). `game` is not mine to
touch under this task's boundary. An abstract `pickupFallSpeed()` would fail `JsonBalanceValues`'s
compile immediately, breaking the whole-repo build `tools/pre-pr-check` runs — the same reasoning
already recorded for `ContentSource.wave(String)` in phase 11b (`docs/plan/11b-wave-system`, this
agent's own memory `project_wave-content-contract.md`). So `pickupFallSpeed()` is a `default` method
returning `20f`, matching `balance.json`'s own value.

**This leaves a real gap, and it is not closed by this PR**: until `game-presentation` updates
`JsonBalanceValues` to read the new `pickupFallSpeed` key, the running game uses the interface's
hardcoded default rather than the value in `balance.json` — the two currently agree (both `20`) by
construction, but a future edit to `balance.json` alone would silently do nothing until that record is
updated. This is the same trade the wave-system precedent made and resolved by a follow-up PR
(`hasBoss()`/`boss()` went abstract once `JsonContentSource` implemented it, per the same memory file).
Filed as follow-up: **issue [#261](https://github.com/LuchoC-Dev/little-spaceship/issues/261)**,
`game-presentation`, "wire `pickupFallSpeed` into `JsonBalanceValues` and make it abstract again."

## What this costs level 1

Per the issue: five pickup drops in level 1 (`weapon-upgrade` ×3, `shield`, `extra-life`,
`attachment`, `bomb-recharge` — seven spawn events across five kinds, per
`docs/levels/level-01.md`'s "Pickups" table, lines 464-470) are now missable if the player does not
reach them before they fall off the bottom of the playfield. Before this change they hung in place
forever and could only ever be collected eventually. **No number in `assets/data/level-01.json`,
`waves.json` or `formations.json` was touched** — the difficulty change is entirely a consequence of
this behavioural fix, exactly as the issue describes, and rebalancing it is explicitly out of scope
here: a play verdict, not a number to pre-empt.

## Invariants

- `core` imports no libGDX — unchanged, no new import touches `com.badlogic.gdx`.
- No clock read, no `Math.random()`, no thread spawned — `pickupFallSpeed()` is a pure balance read,
  same shape as every other `BalanceValues` accessor.
- Determinism / replays: `./gradlew :core:test` — 335 tests, 0 failures, 0 errors (see command below).
  Replay tests (`BombReplayTest`, `BossReplayTest`, `DamageReplayTest`, `LevelScoreReplayTest`,
  `SpawnerReplayTest`) all still pass.

## Commands run and their output

```
$ ./gradlew :core:test --console=plain
BUILD SUCCESSFUL in 6s

$ ./gradlew build --console=plain
BUILD SUCCESSFUL in 3s
(all modules: core, rngparity, game, web, desktop — green)

$ find core/build/test-results -name "*.xml" -exec grep -oh \
    'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' {} \; \
    | awk -F'"' '{t+=$2;s+=$4;f+=$6;e+=$8} END{print "tests="t, "skipped="s, "failures="f, "errors="e}'
tests=335 skipped=0 failures=0 errors=0
```

## Running the game

Not checked. Per the task's own rule, launching once to confirm startup is allowed but playing to
see a pickup fall is exactly the thing this rule exists to forbid — not done.

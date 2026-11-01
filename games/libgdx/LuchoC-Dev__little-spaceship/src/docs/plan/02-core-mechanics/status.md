# Phase 02 — Core mechanics · status

**State:** done — merged in [#10](https://github.com/LuchoC-Dev/little-spaceship/pull/10)
**Updated:** 20/08/2026

Update this file when the phase moves. It is the only place phase progress is recorded — the `plan.md` next to it says what to do and does not change to reflect progress.

## Done

Everything the plan's task list asks for, on branch `feat/core-mechanics-02`.

- **`MotionSystem`.** Integrates every entity's velocity, drives the player's `Motion` from `InputFrame`'s already-summed vector by clamping its *magnitude* to a configured top speed — not per axis, which is what makes a diagonal input no faster than a single axis, above that cap. Slow movement reduces the same cap; it is not a separate code path. The player is clamped to the 208 px playfield width; enemies are left untouched and leave freely.
- **`CollisionSystem`.** Layer-pair detection for the four confirmed pairs: player projectile × enemy, enemy projectile × player, enemy × player, pickup × player. Three of the four resolve the player once through `World.playerEntity()` and walk only the other layer; player projectile × enemy is the one genuinely many-against-many pair and stays a naive double comparison, which is the confirmed decision. Results land in `World.collisionHits()`, an internal per-tick buffer, not a `GameEvent` — it never crosses towards presentation and is fully resolved within the same tick.
- **`DamageSystem`.** The single place the defensive chain lives: invulnerability → shield → attachment → life, in that order, each layer consumed at most once per hit. Invulnerability absorbs a hit completely, with no side effect at all — no layer consumed, no enemy destroyed, no projectile removed. This is also the only system that grants invulnerability, after *any* absorbed damage and not only after a life is lost, with a shorter duration for shield/attachment than for a life. Granting it immediately is what stops several hits from chaining within one tick: a second hit processed in the same call sees the invulnerability the first one just granted.
- **Collision damage.** A weak enemy (`Collider.fragile == true`) is destroyed by crashing into the player; a tank or heavy carrier is not. An enemy projectile is always consumed on contact.
- **Respawn.** Implicit rather than a destroy-and-recreate: the player entity is never destroyed on losing a life, so it is already exactly where it died. Losing a life only decrements `Player.lives`; bombs, shot level, the shield and the attachment are untouched unless the hit itself consumed them.
- **`CleanupSystem`.** The only system that calls `World.destroyEntity`. Every other system marks an entity via `World.markForDestruction`, resolved here at the end of the tick.
- **New domain types.** `Player`, `Invulnerable`, `Shield`, `Attachment` components; `Collider` gains a `fragile` flag; `CollisionHit`/`CollisionPair` in a new `domain.collision` package. `World` grows the four new component stores, `playerEntity()`, `collisionHits()` and `pendingDestruction()`/`markForDestruction()`.
- **`Simulation.mvpPipeline()`** now registers Motion, Collision, Damage and Cleanup — the first real systems this project ships, replacing the empty pipeline from phase 01.
- **Tests.** 129 total (91 inherited, 38 new), all passing, none needing libGDX: `MotionSystemTest`, `CollisionSystemTest`, `DamageSystemTest`, `CleanupSystemTest`, and `DamageReplayTest`, which runs a scripted damage sequence through the real MVP pipeline twice and compares the final state.

Acceptance criteria against `plan.md`:

| Criterion | Status | Where |
|---|---|---|
| Full defensive chain, order and one-consumption-per-layer | met | `DamageSystemTest` |
| Shield/attachment invulnerability shorter than respawn's | met | `DamageSystemTest.shieldDamageGrantsTheShorterInvulnerability`, `.lifeLossGrantsTheLongerInvulnerability` |
| Losing a life keeps persistent power-ups | met | `DamageSystemTest.losingALifeDoesNotClearPersistentPowerUps` |
| Keyboard/mouse opposite directions cancel | **deferred** | `MotionSystemTest.oppositeDirectionsCancel` only proves "zero in, zero out": it feeds `InputFrame(0, 0)` directly. Summing two devices into that vector is the input adapter's job, and no adapter exists yet (`game/`, `desktop/` and `web/` have no Java). The rule this phase actually delivers is that `MotionSystem` treats an already-summed vector correctly; the criterion is earned once phase 03 (`docs/plan/03-first-playable/`) builds the adapter and a test exercises both devices together. |
| Diagonal not faster than axis | met, above the cap only | `MotionSystemTest.diagonalIsNotFasterThanAxis`. The clamp only ever scales down (`belowCapIsUntouched` locks that in), so this holds for any input at or above the configured top speed. Below the cap, an adapter that does not scale a device's contribution to `playerSpeed()` at full deflection could still produce a diagonal faster than an axis — `InputFrame`'s javadoc now states the unit contract this relies on. |
| Weak enemies die, heavy ones survive | met | `DamageSystemTest.weakEnemyDiesOnCollision`, `.heavyEnemySurvivesCollision` |
| Replay reproduces the same final state twice | met | `DamageReplayTest` |

## In progress

Addressing `reviewer`'s round-1 findings on pull request #10 (verdict: accept, with seven findings to fix before merge). See "Decisions taken while implementing" below for what changed and why.

## Blocked

Nothing.

## Review round 1

`reviewer` accepted the phase on pull request #10 with seven findings to fix before merge. What changed:

| # | Finding | Fix |
|---|---|---|
| F1 | `CollisionSystem.detectPair` scanned the whole collider store per candidate, for all four pairs — ≈178,500 inner iterations for the benchmarked MVP scenario, not the 3,540 the quoted figure describes. | Three of the four pairs resolve `World.playerEntity()` once and walk only the other layer; the one genuinely many-against-many pair keeps the naive double comparison. `CollisionSystemTest`'s player fixtures needed a `Player` component added — the old tests passed only because layer-only matching never needed one. |
| F2 | The 0.028 ms figure and the "no change needed" claims quoted evidence that did not measure this shape. | `CollisionSystem`'s javadoc now says what `collisionbench` actually measured (a flat per-layer `float[]`, not `ComponentStore`) and that it is evidence for staying naive, not a measurement of this class. |
| F3 | The keyboard/mouse-cancel criterion was marked met; the test only proves `InputFrame(0,0)` produces no movement, since the summing adapter does not exist yet. | Acceptance table above now marks it **deferred** to phase 03, which builds the adapter. `InputFrame.moveX`/`moveY` also now states its unit contract (logical units per second, full deflection = `playerSpeed()`), which is where phase 04 (or whichever phase writes further adapters) reads what to emit. |
| F4 | The note claiming `WeaponSystem` could read `World.collisionHits()` unchanged is wrong: `SystemOrder.WEAPON` (2) runs before `COLLISION` (5), so it would consume the previous tick's hits. `PickupSystem` at `PICKUP` (7) is fine. | Corrected below and in `.claude/agent-memory/core-domain/`; phase 05 has to decide how `PLAYER_PROJECTILE_VS_ENEMY` gets resolved, not assume the existing buffer works as-is for it. |
| F5 | Two rules invented this phase — invulnerability suppressing consequences for the other entity, and the missing `playerSpeed`/`playerSlowFactor` values — were recorded here and in agent memory but never reached `08-decisions-and-open-items.md` or `10-mvp-initial-values.md`. | Both now recorded there as **open**, not decided; see those documents for the exact wording, including the respawn-overlap gap the reviewer additionally identified. |
| F6 | Agent memory (`project_core-deferred-surface.md`) had absorbed phase-progress phrasing that duplicates this file. | Trimmed; see that file's own note. |
| F7 | Trivia: stale branch name in this file, two `"no system reads balance values yet"` stubs now false, `SimulationTest` hand-rolling `BalanceValues` instead of using `TestBalance`, and `MotionSystem.PLAYFIELD_WIDTH`'s javadoc citing the weaker of two sources. | All four fixed. |

## Decisions taken while implementing

Record here anything decided that the plan did not specify, and why. If it changes a game rule, it also belongs in `docs/planning/08-decisions-and-open-items.md`.

- **`10-mvp-initial-values.md` does not fix a player top speed or a slow-movement multiplier.** It fixes the *policy* — additive devices, clamped result, slow as a multiplier — but no concrete numbers. Added `BalanceValues.playerSpeed()` and `.playerSlowFactor()` with placeholder values (140 units/s, ×0.45), documented on the interface as pending a real number from balancing. Recorded as an open gap in `10-mvp-initial-values.md` itself (added in review round 1), not only here.
- **"Weak enemies die in the crash" is modelled as a boolean, not as hit points.** `Collider` gained a `fragile` flag rather than the architecture's eventual `Health` component. Enemy hit points are not decided anywhere yet (no numbers exist for them), and a full `Health` mechanic would need `WeaponSystem` to matter, which is phase 05's job. The flag captures exactly the confirmed rule — weak archetypes die on collision, tanks and heavy carriers do not — without inventing balance data ahead of the phase that owns it.
- **`CollisionSystem` detects all four confirmed layer pairs, but `DamageSystem` only consumes two of them this phase** (enemy × player, enemy projectile × player). Player projectile × enemy and pickup × player are detected and tested the same way, but nothing consumes them yet: `WeaponSystem` and `PickupSystem` arrive in phase 05. This mirrors the precedent already set by `SystemOrder` — a stage with no system registered is simply skipped — at the granularity of a collision pair instead of a pipeline stage. **Phase 05 caveat (F4):** this is safe as written only for `PickupSystem`; `WeaponSystem` runs three stages before the buffer is refilled and cannot simply read it as-is. See "Notes for whoever comes next".
- **While the player is invulnerable, a weak enemy is not destroyed and an enemy projectile is not consumed.** `resolvePlayerHit` returns before either consequence when invulnerability absorbs the hit, treating invulnerability as a layer that absorbs completely rather than only protecting the player's own state. `02-mvp-functional-spec.md` states weak enemies "are destroyed in that crash" with no condition attached, so this is a narrower reading than the letter of the spec. Recorded as open in `08-decisions-and-open-items.md`, not decided.
- **No `GameEvent` is emitted by `DamageSystem` or `CollisionSystem` this phase**, even though `12-architecture.md` lists `PlayerHit` and `AttachmentLost` as eventually-decided events. Nothing in `core` consumes them yet — HUD and audio are `game`-module work, not built. Adding event shapes without a concrete consumer risked guessing fields that would need to change once phase 06 actually reads them. Flagged here rather than silently skipped, since the architecture document does list them as expected.
- **The player is clamped to the playfield only on the x axis**, matching the plan's literal wording ("the playfield is 208 px wide and clamps the player"). No vertical bound exists anywhere in the planning docs, so none was invented.
- **Respawn does not destroy and recreate the player entity.** "Reappears near where it died" is satisfied trivially by never moving it: the position at the moment of the fatal hit *is* the respawn position. This avoids inventing a separate spawn-point tracking mechanism that nothing in the plan asks for. **Gap (F5):** a slow, non-fragile enemy overlapping the player at death is still overlapping when the grace period ends, forcing the player to move or take a second hit immediately. Recorded as open in `08-decisions-and-open-items.md`.
- **`Shield` is a marker component with no fields**, since the confirmed rule is that any hit it absorbs removes it entirely — unlike `Attachment`, which carries `durability` as the architecture already decides.

## Notes for whoever comes next

- **Collision detection lives in `World.collisionHits()`, not a `GameEvent`.** It is cleared and refilled by `CollisionSystem` at the start of every tick and consumed by `DamageSystem` right after, within the same tick.
  - **`PickupSystem` (phase 05) can read the same buffer unchanged.** `SystemOrder.PICKUP` (7) runs after `COLLISION` (5), so `PICKUP_VS_PLAYER` hits are still the current tick's.
  - **`WeaponSystem` (phase 05) cannot.** `SystemOrder.WEAPON` is ordinal 2, three stages *before* `COLLISION` refills the buffer, so reading it from `WeaponSystem.update` would resolve the *previous* tick's `PLAYER_PROJECTILE_VS_ENEMY` hits — a one-tick-late impact that would pass every test that does not specifically check timing. Phase 05 needs to either consume that pair from a different stage (something between `COLLISION` and `CLEANUP`, the way `DamageSystem` does today) or add a `SystemOrder` stage for it. This was recorded wrong in the phase 02 pull request and in agent memory; corrected in review round 1.
- **`World.markForDestruction(int)` is how any system retires an entity.** Only `CleanupSystem` calls `World.destroyEntity` — mirroring the same hazard `ComponentStore`'s own javadoc already warns about (removing from a dense array mid-iteration reorders it and skips an entry).
- **`core.testsupport`** (test-only, `src/test/java`) holds `TestBalance` and `TestContent`, a configurable `BalanceValues`/`ContentSource` pair for any test that needs a `World` without a real content pipeline. Architecture tests only scan `src/main/java`, so this package is invisible to them by construction. All of `WorldTest`, `SystemPipelineTest` and `SimulationTest` use it now instead of their own inline fixtures.
- **`CollisionSystem` needs a `Player` component on whatever entity plays the player in a test**, not just a `Collider` on the `PLAYER` layer: the three "versus player" pairs resolve through `World.playerEntity()`, which looks up `Player`, not `CollisionLayer.PLAYER`.

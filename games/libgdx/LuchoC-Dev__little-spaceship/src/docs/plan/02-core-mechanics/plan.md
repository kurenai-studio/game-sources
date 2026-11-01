# Phase 02 — Core mechanics

**Lane:** code · **Owner:** `core-domain` · **Depends on:** 01 · **Target:** day 2

## Before you start

**Read, in this order:**

1. `CLAUDE.md` — the invariants, especially determinism.
2. `docs/planning/03-game-systems.md` — sections on survival, damage and power-ups. These rules are decided in detail.
3. `docs/planning/02-mvp-functional-spec.md` — the ship, collision and controls sections.
4. `docs/planning/10-mvp-initial-values.md` — every number this phase needs.

**Do not re-decide:** the defensive chain and its order, invulnerability after any damage, additive keyboard and mouse, and which enemies die on collision. All confirmed in `08-decisions-and-open-items.md`.

**Watch out:** power-up persistence was corrected mid-planning. The first draft said everything is lost on death; the confirmed rule is the opposite. If a source seems to say otherwise, `08` records the correction.

## Goal

The rules that decide whether the player lives or dies: movement, collision by layer pairs, and the damage chain. This is the phase where the game's most-decided rules become code.

## Preconditions

Phase 01 accepted: ECS, loop, `Rng` and `InputFrame` in place.

## Tasks

1. **`MotionSystem`.** Applies velocities and trajectories. The playfield is 208 px wide and clamps the player; enemies leave freely.
2. **Player movement.** Additive keyboard and mouse: both contribute a vector, the vectors are summed, opposite directions cancel, and the result is clamped to top speed so using both is never faster than using one. Slow movement is a multiplier, not a separate mode.
3. **`CollisionSystem`.** By layer pairs, never everything against everything: player shot × enemy, enemy shot × player, enemy × player, pickup × player. Naive comparison — measured at 0.028 ms for the MVP scenario, so optimising now would be work without a cause.
4. **`DamageSystem`.** The single place where the defensive chain lives: **invulnerability → shield → attachment → life**. Also the only place that grants invulnerability, which happens after *any* damage, not only on death.
5. **Collision damage.** Hitting an enemy costs the player a defensive layer. Weak enemies — basic, light, fast — die in the crash; tanks and heavy carriers do not.
6. **Respawn.** The ship reappears near where it died, with invulnerability. Persistent power-ups survive; each is consumed by its own rule instead.
7. **`CleanupSystem`.** Destroys what was marked and frees identifiers, at the end of the tick and nowhere else.

## Acceptance criteria

- The full defensive chain is covered by tests, including the order between layers and each layer being consumed exactly once.
- Damage absorbed by shield or attachment grants invulnerability, shorter than the respawn one.
- Losing a life does **not** clear persistent power-ups.
- Keyboard and mouse in opposite directions produce zero movement.
- Diagonal movement is not faster than axis movement.
- Weak enemies die on collision; heavy ones survive it.
- A replay of a scripted damage sequence reproduces the same final state twice.

## Risks

**The defensive chain is the rule that decays most in refactors.** It has four layers, an ordering, and a side effect (invulnerability). If it ever spreads into conditionals across several systems, it stops being testable. Keep it in `DamageSystem`.

**Invulnerability after any damage is a late addition** to the spec and is not in the older documents' first drafts. It is easy to implement only for death. `03-game-systems.md` has the confirmed wording.

## Notes

The values — 2.0 s respawn invulnerability, 1.0 s after absorbed damage, 3 lives, cap of 5 — are in `10-mvp-initial-values.md` and belong in configuration, not in constants scattered through the code.


## Workflow

See [how to run a phase](../how-to-run-a-phase.md). One issue per task, one branch per issue, PR closing it, `reviewer` accepts against the criteria above, then update `status.md` and your agent memory.

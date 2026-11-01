---
name: defensive-chain-and-collision-design
description: How CollisionSystem and DamageSystem communicate internally, and where the defensive chain's boundary cases were decided
metadata:
  type: project
---

Built in phase 02 (`docs/plan/02-core-mechanics/`). Two design choices here are load-bearing for any
later phase that touches collision, weapons, pickups or the player's defensive state.

**Internal collision results are not `GameEvent`s.** `CollisionSystem` writes `CollisionHit` records
into `World.collisionHits()`, a plain list cleared and refilled every tick — not the
`GameEventQueue`, which drains only once per tick to an external sink. Conflating the two would let
a mid-tick internal signal sit in the same queue as end-of-tick presentation events; they have
different lifetimes on purpose. `DamageSystem` reads `collisionHits()` in the very next stage, same
tick.

**Not every future consumer of that buffer can just read it as-is — check `SystemOrder` first.**
`PickupSystem` (`SystemOrder.PICKUP`) runs after `COLLISION`, so it would see the current tick's
`PICKUP_VS_PLAYER` hits, same as `DamageSystem` does. `WeaponSystem` (`SystemOrder.WEAPON`) runs
*before* `COLLISION`, so reading `PLAYER_PROJECTILE_VS_ENEMY` from it would resolve the *previous*
tick's hits — one tick late, silently, since nothing about that is a compile error or an obviously
failing test. An earlier version of this note claimed both systems could read the buffer unchanged;
that was wrong for `WeaponSystem` and was caught in review, not by a test. Phase 05 resolved
`PLAYER_PROJECTILE_VS_ENEMY` from `DamageSystem` itself (`SystemOrder.DAMAGE`, right after
`COLLISION`) rather than giving it a stage of its own — `DamageSystem`'s stage is generically "damage
resolution against a hit reported this tick," not specifically the player's defensive chain, so
widening its scope kept one system per concern instead of adding a stage nothing else needed. Check
the *ordinal position relative to `COLLISION`*, not just "does a consuming system exist yet", before
assuming a buffer written earlier in the pipeline is readable from a stage that runs before it is
refilled. Ordinal numbers themselves are not stable across phases — phase 05 inserted `BOMB` between
`WEAPON` and `SPAWN` — so reason about order relative to `COLLISION`, never a hardcoded number.

**Invulnerability, when active, absorbs a hit with zero side effects.** Not just "no life lost" —
also no enemy destroyed, no projectile consumed. This was a genuine design call, not stated
explicitly anywhere in `docs/planning/`: the literal reading of "the defensive chain: invulnerability
→ shield → attachment → life" as four *layers* implies the first one that catches a hit absorbs it
completely, same as a shield does. If this reading turns out wrong once there is real gameplay
feedback (e.g. a ramming enemy should maybe still die even while the player is invulnerable), it is
a one-line change in `DamageSystem.resolvePlayerHit`, but it changes the observed acceptance
criterion "weak enemies die on collision" under that specific combination.

**Removing a component while iterating its `ComponentStore` reorders the dense array**, exactly like
destroying an entity does (`ComponentStore`'s own javadoc warns about entity destruction, but the
hazard is really about the store, not the entity). `DamageSystem.decayInvulnerability` collects
expired entities into a side list first and removes them after the loop — the same pattern
`CleanupSystem` uses for entity destruction, just one level down.

**`World.markForDestruction` does not remove a collider, so `CollisionSystem` has to filter
`pendingDestruction` itself, or anything marked earlier in the same tick keeps colliding.** This bit
`BombSystem` in phase 05's review round 1: the bomb marked an enemy for destruction, but
`CollisionSystem` (which runs right after `BOMB`) had no idea, produced a `CollisionHit` for it
anyway, and `DamageSystem` consumed a shield/attachment/life for an enemy that had already
"stopped existing" as far as the bomb was concerned. The fix is in `CollisionSystem`, not in
`BombSystem`: build a `Set<Integer>` from `World.pendingDestruction()` once per `update()` call
(empty in the common case, so no allocation when nothing was marked) and skip any candidate — either
side of any pair, the player included — that appears in it. This is deliberately general, not
`BOMB`-specific: `LifetimeSystem` also runs before `COLLISION` and also only marks, so a projectile
it expires gets the same protection for free. **Any future system that marks something for
destruction before `COLLISION` runs is automatically covered — nothing needs updating in
`CollisionSystem` itself when a new marker shows up**, which is exactly why the general fix beats a
`BOMB`-only special case.

See [[core-boundary-decisions]] and [[core-deferred-surface]] for what else was deferred and why, and
[[game-systems-design]] for the tick-level input-edge lesson from the same review round.

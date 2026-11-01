---
name: pickup-fall-and-lifetime
description: Giving a dropped pickup Motion (#252/#260) — LifetimeSystem's expiry check silently excluded the PICKUP layer, generic MotionSystem.integrate needed zero changes, and the default-method-on-BalanceValues trade repeats the wave-content-contract precedent one interface over.
metadata:
  type: project
---

Phase 11i, task 4 (#260, closing #252, PR #262 against `phase/11i-path-vocabulary`). A dropped pickup
had `Transform`/`Collider`/`Sprite`/`Pickup` but no `Motion`, so it hung exactly where its carrier
died instead of falling with the rest of the scrolling world.

**`MotionSystem.integrate` needed no change at all.** It already walks every `Motion` in the store
generically, with no dependency on `Trajectory` — only `advanceTrajectories` (a separate, earlier
step) cares whether an entity also has a `Trajectory`. Giving the pickup a plain `Motion(0f,
-fallSpeed)` was enough; nothing else in `MotionSystem` needed to know pickups exist.

**`LifetimeSystem.expireProjectiles` never covered `CollisionLayer.PICKUP`, and nothing else did
either — checked by reading the method before assuming the issue's warning was hypothetical.** The
layer guard named exactly `PLAYER_PROJECTILE` and `ENEMY_PROJECTILE`. Before this change a pickup
could never have left the playfield (it had no `Motion`), so this was a latent gap, not a live bug —
adding `Motion` without also touching this method would have created a real leak, one pickup entity
per unclaimed drop, for the rest of the run. Fixed by adding `CollisionLayer.PICKUP` to the same
check and reusing `PROJECTILE_MARGIN` (16 units), already generous enough to clear `pickupRadius`
(6 units in `balance.json`).

**`BalanceValues` has exactly two implementers — `core`'s `TestBalance` and `game`'s
`JsonBalanceValues` — and the second is a record enumerating every key by hand, same shape as
`JsonContentSource`.** Same trade as `ContentSource.wave(String)` in phase 11b (see
[[project_wave-content-contract]]): a new **abstract** method on an interface implemented outside
`core` breaks the whole-repo `./gradlew build`, which `pre-pr-check` runs whenever `core/` changes.
Added `pickupFallSpeed()` as a `default` method returning a hardcoded placeholder that must match
`balance.json`'s own value by hand until `game-presentation` wires the record field and the method
goes abstract again — filed as issue #261 rather than left as an unstated gap. Worth checking, next
time a `core`-only agent adds any method to an interface implemented by `game`: `grep -rln "implements
<Interface>"` across the whole repo, not just `core/`, before deciding abstract vs. default.

**No background-scroll-rate constant exists anywhere in the repository** — checked with `grep -rn
"scroll" docs/planning/ core/ game/`, nothing names a rate. So "falls at the background's own rate"
from the issue had no existing number to anchor against; the candidate value (20 units/s) was reasoned
from the slowest existing enemy descent shapes in `trajectories.json` (`slow-descent` -18,
`crawl` -9) instead, explicitly flagged as a play-verdict candidate, not a computed number.

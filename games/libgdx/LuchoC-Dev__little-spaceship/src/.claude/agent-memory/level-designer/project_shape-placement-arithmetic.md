---
name: shape-placement-arithmetic
description: How far a drifting shape carries a formation off the playfield, the atX windows that keep swoop and the veers on screen, and what the doc generator's swept-extent check actually thresholds
metadata:
  type: project
---

Derived while rebuilding level 1 as fourteen waves (phase 11e, #198) and checked against
`tools/build-level-docs.js`'s own `sweptExtent`, which is the thing that fails a pull request.

**A shape with a horizontal component drags its whole formation sideways by `vx × screen time`, and
the spawn-instant footprint cannot see it.** This is what produced the two findings 11b left open.
The arithmetic:

- `constant` shape: screen time is `(270 + radius) / |vy|`, drift is `vx × that`.
- `arc`: the window that matters is how long it is *inside the playfield*, not how long until
  `LifetimeSystem` eats it — it turns at `-vy/ay` and climbs back out the top at `-2·vy/ay`, so for
  the veers (`vy -95, ay 20`) that is 9.5 s and the drift is **±304 units**, wider than the 208-unit
  playfield.

**The generator flags a spawn only when the sweep is off screen AND at least 50% of the swept span
sits outside `0 .. 208`.** So a veer at the catalogue's minimum (`veer-left` at `atX 0.75`) lands at
48.7% and passes by a hair; `atX 0.88` lands at 40% and is comfortable. The catalogue's rule and the
generator's threshold agree because they were derived from the same numbers, not independently.

**The `atX` windows that keep `enemy-light` on `swoop` (drift 69 left) fully inside the playfield**,
worth keeping because `swoop` is the light's archetype default and the light is in half of level 1:

| formation | min `atX` | max `atX` |
|---|---|---|
| `single` | 0.36 | 0.98 |
| `diagonal` / `diagonal-mirror` | 0.43 | 0.90 |
| `vee-5` | 0.51 | 0.82 |

The general form: `min atX = (|widest left offset| + radius + drift) / 208`, and the max ignores the
drift entirely because the drift is leftward.

**A wave cannot be empty.** `JsonContentSource.loadWaves` throws *"wave 'x' has no spawns"*, so a
beat that is meant to occupy time and spawn nothing — an intro, a silence — has no representation.
The only lever for silent time is a placement `offset`, which belongs to the level, cannot be named
and cannot be reused.

**`cleared` became expensive when #199 raised the health numbers.** A `cleared` wave holding a tank
(300) or a carrier (1000) is no longer a few seconds; and one `cleared` wave anywhere makes every
absolute time after it a lower bound, including `boss.entersAt`, which the generated document then
refuses to compare. Level 1 is deliberately all `fixedDuration` for that reason.

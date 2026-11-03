# Method

How the reference table is put together and how to rebuild its mechanisms without the
original session. Read `SKILL.md` for the workflow; this file holds the constants and
derivations that are hard to infer from a screenshot.

## 1. Coordinate contract

Everything in the table is local to `tableGroup`:

```text
x  lateral     −5 … +5
y  up          0 playfield, 2.72 visual glass, 2.8 ceiling collider
z  down-table  −11 backglass … +11 front/drain
```

`tableGroup.rotation.x = 6.6°`. The stage/city/grid/lights are world-space and are not
children of the table group.

Gravity is projected once in `initPhysics`:

```js
theta = 6.6 * Math.PI / 180
world.gravity.set(0, -9.82 * Math.cos(theta), 9.82 * Math.sin(theta))
```

Why projection: rotating the bodies would also rotate the camera-relative up vector and
complicate every position. Projecting gravity keeps all colliders in the simple local
frame and still accelerates the ball toward `+z` (the drain).

## 2. Build order

`boot()` order is load-bearing:

1. `initRenderer` — renderer, scene, fog, camera, `tableGroup`.
2. `makeEnvMap` — needs the renderer for PMREM.
3. `buildMaterials` — needs `envMap`.
4. `buildStage`, `buildLights` — world-space backdrop.
5. `initPhysics` — the world must exist before `buildCabinet` adds walls.
6. `buildCabinet`, `buildLaneGuides`, `buildPegs` — static visual + collider pairs.
7. `buildBumpers`, `buildDropTargets`, `buildSlingshots`, `buildLoops` — dynamic objects
   and collision listeners.
8. `buildPlunger`, `buildFlippers`, `createBall`, `initSparks`.
9. `scoreStore.load`, `updateHUD`, `bindUI`, then `requestAnimationFrame(animate)`.

If `initPhysics` is moved after the cabinet, `phys.wall` is undefined when walls are
created and the bodies get no material.

## 3. Starter geometry

```js
TABLE = { width: 10, length: 22, halfW: 5, halfL: 11, tiltDeg: 6.6, ballR: 0.32 }
FIXED_STEP = 1/120
FLIPPER = { restLeft: -0.34, activeLeft: 0.6, restRight: 0.34, activeRight: -0.6,
            upSpeed: 20, downSpeed: 11 }
```

| Feature | Position |
| --- | --- |
| Bumpers | `(-1.7,-3.4)`, `(0,-5.4)`, `(1.7,-3.4)` |
| Drop targets | `x = -3.3,-2.1,-0.9,0.3`, `z = 1.45` |
| Slingshots | `x = ±1.95`, `z = 5.8`, rotation `±0.68` rad |
| Flipper pivots | `x = ±2.55`, `z = 7.6`, arm half-length 1.05 |
| Plunger | `x = 4.3`, `z = 10.42` visual; ball spawn `(4.3, 0.35, 9.35)` |
| Shooter lane | `3.62 < x < 5.0`, `5.2 < z < 10.7` |
| Drain | `x < 3.55 && z > 9.7 && y < 1.6` |
| Side seals | `x = ±3.0`, `z = 8.475`, half-length 1.225 |
| Lower backstops | `(-3.98, 0.65, 8.475)`, `(3.24, 0.65, 8.475)` |
| Hard boundary | `x = ±4.58`, `z = -10.45` minimum |

The left/right lane guides are mirrored but not identical: the right side must leave the
shooter lane open at `x > 3.62`, so its return guide and slingshot sit slightly inboard
(`x = 3.5 … 2.95`) compared with the left (`-4.95 … -3.15`). Copying the left side
verbatim creates a blocked shooter lane or a new pinch point.

## 4. Containment stack

Use all four layers. Each one catches a different failure:

1. **Thin walls** (`0.32` thick side walls, `0.24` lane divider) for normal play.
2. **Hard boundary clamp** after `world.step`:
   `x = ±4.58`, `z ≥ -10.45`, reflect with `0.65` and spark.
3. **Lower backstops** behind the side seals (left 1.86 × 1.3 × 2.45, right
   0.48 × 1.3 × 2.45). The right block must stop at `x = 3.24` so it does not enter the
   shooter lane.
4. **Glass ceiling** box half-extents `(5.1, 0.08, 11.0)` at `y = 2.8`.

Then a speed clamp before and after the step:

```js
if (speed > 22) velocity.scale(22 / speed, velocity)
```

22 units/s at 1/120 s is 0.183 units per step, below the ball radius (0.32), which is why
it prevents tunnelling through a 0.24–0.36 wall.

## 5. Fixed-step loop

```js
accumulator += dt                       // dt clamped to 0.05 s
while (accumulator >= 1/120 && steps < 6) {
  fixedUpdate(1/120)
  accumulator -= 1/120
  steps++
}
if (steps === 6) accumulator = 0         // drop the backlog, do not spiral
```

`fixedUpdate` must be the only place that calls `world.step`. Do not step from a pointer
handler or a timer; that decouples physics from the render/charge loop and makes impacts
depend on input speed.

## 6. Flippers

The reference uses kinematic bodies rather than hinge constraints:

```js
body.type = CANNON.Body.KINEMATIC
body.quaternion.setFromAxisAngle(new CANNON.Vec3(0, 1, 0), angle)
body.angularVelocity.set(0, delta / Math.max(dt, 0.0001), 0)
body.aabbNeedsUpdate = true
```

The angular velocity is what transfers momentum to the ball. A kinematic body with only
a teleported quaternion will push weakly; the solver needs the angular velocity. The
sweep is 0.94 rad at 20 rad/s, about 47 ms to full flip.

Rest/active angles are intentionally not symmetric in sign: left `-0.34 → +0.60`, right
`+0.34 → -0.60`. Both tips sweep up-table across the centre gap.

## 7. Plunger and charge

The spring is a visual stack of torus coils. On charge, the group moves back and the
spring compresses by `charge * 0.3`.

```js
charge += dt * 0.72 + dragBoost        // dragBoost ≤ 0.6, charge clamped to 1
power = clamp(charge, 0.12, 1)
impulse = (0.025 + rand*0.02, 0.16, -(1.25 + 1.55 * power))
```

Ball mass is 0.25, so `Δv ≈ 5 … 11.2` units/s. The charge oscillator starts at 70 Hz and
rises to `70 + charge * 460` Hz.

`startCharge` is valid only when `inShooterLane()` is true. The lane box is
`x > 3.62 && x < 5.0 && z > 5.2 && z < 10.7`; without this guard the player can charge
mid-play and fire from anywhere.

## 8. Bumpers, targets, slingshots

Bumper collider: upright cylinder radius 0.9, height 1.3, centre `y = 0.65`. The kick:

```js
power = clamp(4.4 + impact * 0.5, 4.6, 7.4)
ball.position = bumper + normal * (1.0 + ballR + 0.04)   // clear the skirt
ball.velocity = (normal.x * power, 0.55, normal.z * power)
```

The position nudge is important: without it the ball can rest against the core and score
repeatedly as the cooldown expires.

Drop target: box half-extents `(0.43, 0.58, 0.12)` at `(x, 0.62, 1.45)`. On hit, set
`collisionResponse = false`, sleep the body, increment `targetsDown`, and start a 3 s
re-arm timer when the bank clears. `resetTargets` must refuse to re-arm within 1.05
units of a live ball (`bp.y < 1.3`); otherwise a node can appear inside the ball.

Slingshot: static angled box, kick inward and up-table:

```js
inward = side === -1 ? 1 : -1
velocity.x = inward * (2.9 + clamp(impact * 0.35, 0, 1.8)) + velocity.x * 0.15
velocity.z = -2.7 - clamp(impact * 0.15, 0, 1.2) + velocity.z * 0.15
```

## 9. Loop rails

Each loop is a `CatmullRomCurve3` from 7 points. The sensor is a non-solid sphere at
`curve.getPointAt(0)`, radius 0.72, at `y = 0.56`.

Capture:

1. `body.type = KINEMATIC`, `mass = 0`, `updateMassProperties()`, no collision response.
2. `railT = 0`, `railSpeed = 1 / clamp(1.05 + index * 0.08, 0.8, 1.6)`.
3. Each step, `railT += dt * railSpeed`, position = `curve.getPointAt(t)`.
4. At `t ≥ 1`, restore `DYNAMIC`, mass 0.25, then release with tangent velocity
   `(tangent.x*8.5 + 0.8, 0.25, abs(tangent.z)*3.5 + 2.4)`.
5. Entry is 2500 points, exit 500; cooldown 2.2 s.

The exit velocity deliberately adds `+0.8` in x and a positive z component so the ball
comes back toward the flippers instead of re-entering the loop mouth.

## 10. Player-facing formulas

| Thing | Formula |
| --- | --- |
| Score | `round(base × multiplier)` |
| Bumper | 500 |
| Drop target | 900 |
| Bank clear | 5000, `multiplier = min(8, multiplier + 1)` |
| Slingshot | 120 |
| Loop entry / exit | 2500 / 500 |
| Extra ball | first time `score ≥ 100000`, once per session |
| Multiplier reset | on drain or new game (not on target re-arm) |
| Balls | 3 per session |
| Recovery | within 0.8 units for 3.5 s → respawn, no ball lost |

## 11. Persistence

Four keys, no game-state resume:

```text
neon_horizon_scores_v1    JSON array, max 30, sorted by score desc
neon_horizon_best_v1      mirrored decimal best
neon_horizon_callsign_v1  last callsign
neon_horizon_muted_v1     "1" | "0"
```

Entry shape and clamps are in `sanitizeScoreEntry`. Exports add `app`, `version`,
`exportedAt`, `highScore`, `currentSession` and `credits`. Imports accept an array,
`{scores: []}` or `{leaderboard: []}`; reject over 2 MB; merge by
`name|score|date.slice(0,16)`.

If a future version changes the entry shape, either version the key
(`neon_horizon_scores_v2`) or migrate on load. Do not silently reinterpret old entries.

## 12. Tuning order

When the table feels wrong, change in this order and retest after each:

1. **Flipper angle/speed** — changes aiming and the centre gap.
2. **Slingshot angle and kick** — changes side-to-side flow.
3. **Bumper kick/restitution** — changes chaos and score rate.
4. **Launch impulse/charge** — changes whether the ball clears the top.
5. **Tilt** — last, because it invalidates all of the above.

Do not tune by editing many constants at once; the table is a coupled system. A 60
units/s shot probe into each wall and a 30-second random-flipper run catch most
regressions.

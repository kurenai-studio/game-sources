# Architecture

## Load order

```text
index.html  →  style.css  →  script.js
```

`index.html` is the DOM shell and HUD. `style.css` is the visual system and responsive
layout. `script.js` is one IIFE that owns the Three.js scene, the Cannon.js world, the
audio graph, the score archive and all interaction. There is no framework, no module
loader, no bundler and no server code.

```text
index.html
  ├─ #stage > #game-canvas        WebGL canvas (aria-hidden)
  ├─ .boot                        boot/loading screen
  ├─ .hud                          header, side panels, launch/flip controls
  ├─ overlays                      start hero, game over, help, confirm
  ├─ #toast-stack, #a11y-live
  └─ three CDN scripts in order
       three.min.js r128
       cannon.min.js 0.6.2
       script.js
```

`script.js` sections, in source order:

| # | Section | Main identifiers |
| --- | --- | --- |
| 0 | Utilities & constants | `VERSION`, `STORAGE`, `TABLE`, `FIXED_STEP`, `FLIPPER`, `clamp`, `lerp`, `formatScore`, `formatTime`, `sanitizeName`, `safeStorageGet`, `safeStorageSet` |
| 1 | Synthesised audio | `Synth`, `synth` |
| 2 | Persistence | `sanitizeScoreEntry`, `makeEntryId`, `scoreStore`, `entryKey`, `dedupeEntries` |
| 3 | DOM & HUD | `dom`, `updateHUD`, `statusLabel`, `renderLeaderboard`, `toast`, `announce` |
| 4 | Renderer/camera | `initRenderer`, `updateCameraLayout`, `onResize` |
| 5 | Procedural textures | `makePlayfieldTexture`, `makeBackglassTexture`, `makeCityTexture`, `makeGridTexture`, `makeTextSprite`, `makeEnvMap` |
| 6 | Materials | `buildMaterials`, `neonMaterial`, `pureNeon` |
| 7 | Scene | `buildStage`, `buildLights`, `buildCabinet`, `buildLaneGuides`, `buildPegs` |
| 8 | Physics world | `initPhysics`, `addStaticBox`, `addUprightCylinder` |
| 9 | Game objects | `buildBumpers`, `buildDropTargets`, `buildSlingshots`, `buildLoops`, `buildPlunger`, `createBall`, `buildFlippers` |
| 10 | Ball/plunger/rail | `spawnBall`, `startCharge`, `updateCharge`, `releaseCharge`, `launchBall`, `captureBallInLoop`, `updateRail`, `updateFlippers`, `setFlipper` |
| 11 | Sparks | `initSparks`, `burstSparks`, `updateSparks` |
| 12 | Game flow | `game`, `startGame`, `loseBall`, `endGame`, `requestNewGame`, `abandonAndRestart`, `addScore`, `updateBallRecovery`, `recoverBall` |
| 13 | Simulation | `fixedUpdate`, `animate`, `updateVisuals` |
| 14 | Export/import | `exportScores`, `importScoresFile` |
| 15 | Input | `bindUI`, `onKeyDown`, `onKeyUp`, `openHelp`, `closeHelp` |
| 16 | Self-test | `selfTest` |
| 17 | Boot | `bootStep`, `boot` |

## Boot sequence

`boot()` runs 40 ms after `DOMContentLoaded` (or immediately if the document is already
interactive). It aborts with a visible `SYSTEM FAULT` boot screen if `THREE` or `CANNON`
is missing.

```text
initRenderer()        renderer, scene, fog, camera, tableGroup (tilt applied)
makeEnvMap()          canvas equirectangular env map → PMREM → envMap
buildMaterials()      MAT.* (chassis, chrome, ball, glass, playfield, backglass, city, grid)
buildStage()          city plane, floor grid, horizon plane
buildLights()         hemisphere + shadow-casting key + cyan/magenta/violet/under lights
initPhysics()         world, materials, contact materials, floor, ceiling, backstops
buildCabinet()        chassis, rails, playfield, glass, legs, backglass, underglow
buildLaneGuides()     outer walls, shooter-lane divider, curved launch guide, return guides, side seals
buildPegs()           three neon posts
buildBumpers()        three cylinder cores + colliders + collision listeners
buildDropTargets()    four drop-target bars + colliders + listeners
buildSlingshots()     two angled kickers + colliders + listeners
buildLoops()          two Catmull-Rom tubes, rails, rings, entrance sensors
buildPlunger()        visual spring, head, cap, glow
buildFlippers()       two kinematic flipper bodies + visuals
createBall()          sphere mesh, trail, glow, Cannon body, wall-impact listener
initSparks()          240-point spark buffer
scoreStore.load()     localStorage archive
updateHUD(false)      initial score/leaderboard paint
bindUI()              all DOM, pointer and keyboard listeners
sceneReady = true;    requestAnimationFrame(animate)
```

`window.NEON_HORIZON` is published after boot with `game`, `startGame`, `launchBall`,
`recoverBall`, `setFlipper`, `addScore`, `exportScores`, `selfTest`, `getSnapshot`,
`getBall`, `getRenderInfo`, `setCamera`, `forceDrain` and `_debug` (world, bodies,
bumpers, targets, slings, flippers). The headless verification runs use this surface.
`?selftest=1` stores `selfTest()` in `window.__SELFTEST__` and logs it.

## Coordinate system and table

All table content lives under `tableGroup`, rotated about X by `TABLE.tilt` (6.6°).
The playfield is the local `y = 0` plane.

```text
x  lateral       −5 (left) … +5 (right)
y  up            playfield 0, glass 2.72 (visual) / ceiling collider 2.8
z  down-table    −11 (top/backglass) … +11 (front/drain)
```

The stage (city plane, floor grid, horizon), the scene lights and the fog are in world
space, not in `tableGroup`.

Static geometry:

| Object | Position / extent |
| --- | --- |
| Cabinet body | 11.35 × 1.2 × 23.3 at `(0, −0.62, 0)` |
| Playfield plane | 10 × 22 at `y = 0.005` |
| Outer walls | `x = ±5.06`, half-thickness 0.16, half-length 11.0 |
| Top wall | `z = −10.95`, half-extent 5.05 |
| Shooter-lane divider | `x = 3.6`, `z = 2.55`, half-length 7.75 |
| Shooter lane | `3.62 < x < 5.0`, `5.2 < z < 10.7` |
| Ball spawn | `(4.3, 0.35, 9.35)` |
| Drain zone | `x < 3.55 && z > 9.7 && y < 1.6` |
| Hard boundary | `x = ±4.58`, `z ≥ −10.45` |
| Glass-ceiling collider | box half-extents `(5.1, 0.08, 11.0)` at `y = 2.8` |
| Lower backstops | left `(−3.98, 0.65, 8.475)`, right `(3.24, 0.65, 8.475)` |
| Side seals | `x = ±3.0`, `z = 8.475`, half-length 1.225 |

`playfield` texture mapping is explicit:

```js
P(x, z) = [ ((x + 5) / 10) * 1024, ((z + 11) / 22) * 2048 ]
```

so a world-space playfield coordinate maps directly to the 1024 × 2048 canvas used for
traces, node rings, arrows and the sector watermark.

## Rendering pipeline

`initRenderer` creates a `WebGLRenderer` on `#game-canvas` with antialiasing and
`powerPreference: "high-performance"`. Pixel ratio is capped at 2 (1.7 when
`window.innerWidth < 900`). It enables sRGB output, ACES Filmic tone mapping
(exposure 1.18), PCF soft shadows and scene fog from 48 to 105 world units.

Camera layout is aspect-driven (`updateCameraLayout`):

| Aspect `w/h` | FOV | Camera position | Look target |
| --- | --- | --- | --- |
| < 0.72 | 55 | `(0, 25, 32.5)` | `(0, 0.2, 0.3)` |
| < 0.95 | 54 | `(0, 26, 34)` | `(0, 0.1, 0.2)` |
| < 1.25 | 48 | `(0, 24.5, 30.5)` | `(0, −0.05, −0.1)` |
| < 1.75 | 45 | `(0, 23.5, 28.5)` | `(0, −0.05, −0.35)` |
| otherwise | 45 | `(0, 23, 27.5)` | `(0, −0.05, −0.4)` |

`updateVisuals` adds pointer parallax (smoothed with `lerp(…, 0.045)`) and a decaying
`game.shake` offset. There is no post-processing pass; the neon look is emissive
materials, additive sprites, point lights and tone mapping.

Procedural canvases:

| Texture | Size | Use |
| --- | --- | --- |
| `makePlayfieldTexture` | 1024 × 2048 | playfield map + emissive map |
| `makeBackglassTexture` | 1024 × 512 | backglass panel |
| `makeCityTexture` | 2048 × 1024 | city backdrop |
| `makeGridTexture` | 512 × 512, repeated 16 × 16 | floor grid |
| `makeEnvMap` | 1024 × 512 equirectangular | chrome reflections via PMREM |

Draw order for a frame: `updateVisuals(dt, now)` (sparks, material pulses, target sink,
ball trail, plunger, camera) then `renderer.render(scene, camera)`. Three.js sorts
objects by render order/material; transparent glow sprites and the glass set
`depthWrite: false`.

## Physics pipeline

`initPhysics` creates a `CANNON.World` with SAP broadphase, 22 solver iterations and
`0.0005` tolerance. Gravity is the projected table gravity:

```js
θ = 6.6° · π / 180
world.gravity.set(0, −9.82·cos θ, 9.82·sin θ)
```

so the ball accelerates down local `+z` without rotating every body.

Contact materials:

| Pair | Friction | Restitution |
| --- | ---: | ---: |
| ball / table | 0.04 | 0.16 |
| ball / wall | 0.00 | 0.80 |
| ball / bumper | 0.00 | 0.92 |
| ball / flipper | 0.04 | 0.48 |
| ball / target | 0.00 | 0.40 |
| ball / sling | 0.00 | 0.65 |

Default contact: friction 0.08, restitution 0.35. The ball is a `Sphere(0.32)` with mass
0.25, linear damping 0.015, angular damping 0.18, sleeping disabled.

Fixed-step loop:

```text
animate(now):
  dt = min(0.05, (now − lastFrame) / 1000)
  accumulator += dt
  while accumulator ≥ 1/120 and steps < 6:
      fixedUpdate(1/120); accumulator −= 1/120
  if steps == 6: accumulator = 0
  updateVisuals(dt); renderer.render(scene, camera)
```

`fixedUpdate` order: `updateFlippers` → `updateCharge` → cooldown timers → `updateRail` →
clamp pre-step speed to 22 → `world.step(1/120)` → clamp post-step speed → hard-boundary
bounce → drain/outside/recovery checks → sync mesh transform. While the ball is on a
loop rail its body is kinematic, so the solver still steps but the position is driven by
the curve.

Collision responses:

- **Bumper:** cooldown 0.3 s; impact must exceed 0.75; ball is pushed to at least
  `1.0 + ballR + 0.04` from the core, then kicked with
  `clamp(4.4 + impact·0.5, 4.6, 7.4)` plus 0.55 upward. 500 points.
- **Drop target:** one-shot per arm cycle; `collisionResponse = false`, body slept,
  visual sinks 1.05 units. 900 points.
- **Slingshot:** cooldown 0.25 s; impact must exceed 1.0; kick is inward/up-table,
  120 points.
- **Loop sensor:** sphere of radius 0.72 at the entrance, `collisionResponse = false`;
  capture only when the ball is dynamic and not already on a rail.
- **Wall/other:** a single wall voice is rate-limited to one sound per 55 ms and only
  above impact 1.4; sparks above 3.5.

### Rail ride

`captureBallInLoop` sets the ball body to `KINEMATIC`, mass 0, and records
`railSpeed = 1 / clamp(1.05 + index·0.08, 0.8, 1.6)`. `updateRail` advances `railT`,
sets the body position to `curve.getPointAt(t)`, and at `t ≥ 1` restores `DYNAMIC`
mass 0.25 and releases with the curve tangent:

```js
velocity = (tangent.x·8.5 + 0.8, 0.25, |tangent.z|·3.5 + 2.4)
```

Entry is 2500 points, exit 500. Cooldown 2.2 s.

### Flippers

The flippers are `KINEMATIC` Cannon boxes, not hinge constraints. `updateFlippers`
integrates the angle toward the target at 20 rad/s upward or 11 rad/s downward, writes
the quaternion and sets `angularVelocity.y = delta / dt`, which is what transfers
momentum through the solver. Rest/active angles are `∓0.34` and `±0.60` radians.

### Plunger

The spring is visual. `startCharge` is allowed only in the shooter lane and outside
menu/drain/over/paused. Charge grows at `0.72/s` (plus up to 0.6 from a drag gesture),
clamped to 1. Release clamps power to `0.12…1` and applies an impulse of
`(0.025 + rand·0.02, 0.16, −(1.25 + 1.55·power))`. With mass 0.25 that is roughly
5.0…11.2 units/s of launch speed.

### Ball recovery

`updateBallRecovery` ignores the rail and shooter lane, and ignores a deliberate flipper
cradle. If the ball has stayed within 0.8 units (squared distance 0.64) of its anchor for
3.5 s, `recoverBall("auto")` returns it to the spawn. `R`, the **RECOVER STUCK BALL**
button and table-escape detection call the same function. Recovery does not spend a ball.

## State and persistence

Runtime state is the `game` object:

```js
{
  phase: "menu" | "ready" | "play" | "drain" | "over",
  score, multiplier, maxMultiplier, ballsLeft, combo,
  targetsDown, targetsCleared, loops, bumperHits,
  charge, isCharging, startedAt, ballStartedAt, endedAt,
  paused, shake, extraBallAwarded,
  callsign, archiveId, timeouts: []
}
```

`paused` is a boolean, not a phase: the help dialog sets it and `fixedUpdate` returns
early while it is true. `statusLabel` has a defensive `"paused"` branch, but normal play
never assigns that value to `phase`.

Dynamic pointer fields (`pointerId`, `pointerStartY`, `pointerBoost`) are added by
`bindUI`. Runtime scene collections are module-scoped: `bumpers`, `targets`, `slings`,
`loops`, `loopSensors`, `flippers`, `ball`, `plunger`, `sparks`, `tableMeshes`,
`glowSprites`, `neonStripMaterials`.

Phases:

```text
menu → startGame → ready → launchBall → play → loseBall → drain
     → (balls > 0) spawnBall → ready
     → (balls = 0) endGame → over
help open → game.paused = true; help close → false
```

`loseBall` subtracts a ball, resets combo and multiplier to 1, hides the ball and
schedules `endGame` after 1.2 s or a respawn after 1.45 s. `endGame` archives any score
above 0 and fills the summary modal.

`localStorage` keys:

| Key | Value |
| --- | --- |
| `neon_horizon_scores_v1` | JSON array of score entries (max 30, sorted descending) |
| `neon_horizon_best_v1` | decimal string, mirrored all-time best |
| `neon_horizon_callsign_v1` | last callsign, 1–14 characters |
| `neon_horizon_muted_v1` | `"1"` muted, `"0"` unmuted |

Score entry:

```json
{
  "id": "nh-<base36 time>-<random>",
  "name": "RUNNER-01",
  "score": 12345,
  "date": "2026-11-01T00:00:00.000Z",
  "maxMultiplier": 3,
  "loops": 2,
  "targets": 1
}
```

`sanitizeScoreEntry` rejects non-positive/non-finite scores, clamps score to
`0…999999999999`, strips `<>\"'&` and caps names at 14 characters, clamps
`maxMultiplier` to `1…99` and `loops`/`targets` to `0…999999`. `scoreStore.sort`
de-duplicates nothing; `dedupeEntries` does, keyed by `name|score|date.slice(0,16)`.
`add` appends, re-sorts and caps at 30. `merge` returns the number of new entries.

Export payload (`exportScores`):

```json
{
  "app": "NEON HORIZON 2088",
  "version": "1.0.0",
  "exportedAt": "ISO-8601",
  "highScore": 0,
  "scores": [],
  "currentSession": { "callsign": "", "score": 0, "multiplier": 1, "maxMultiplier": 1, "loops": 0, "targets": 0 },
  "credits": { "harness": "OpenCode", "model": "DeepSeek V4.1 Flash", "engines": ["Three.js r128", "Cannon.js 0.6.2"] }
}
```

Import accepts a top-level array, `{ scores: [] }` or `{ leaderboard: [] }`, rejects
files over 2 MB, validates each entry and merges. Nothing is resumed; a new page load
starts at the hero screen.

## Audio pipeline

One `AudioContext` is created lazily in `Synth.ensure` on the first gesture. The graph is
`source → gain → master → DynamicsCompressor → destination`; there is one short noise
buffer per `noise()` call, generated in memory.

| Method | Character |
| --- | --- |
| `tone` | oscillator, exponential pitch/gain envelope, optional stereo pan |
| `noise` | procedurally filled buffer through a bandpass/lowpass filter |
| `startAmbient` | 55 / 82.5 / 110.2 Hz saw/sine bed, lowpass LFO at 0.09 Hz, 1760 Hz shimmer |
| `bumper` | two tones + noise, per-bumper pitch and pan |
| `launch` | saw sweep + square thump + noise, power-scaled |
| `loop` | rising sine/triangle pair + noise |
| `target`, `sling`, `flipper`, `wall` | short transient voices |
| `drain`, `multiplier`, `extraBall`, `gameOver` | descending/ascending motifs |
| `startCharge` / `setCharge` / `stopCharge` | continuous sawtooth whose pitch follows charge |

Muting sets master gain to 0 over 0.05 s and writes `neon_horizon_muted_v1`. Ambient
level drops to 0.15 when the tab is hidden and returns to 1 (0.28 after game over).

## Invariants that matter

1. **One frame of reference.** Every table mesh and body uses local table coordinates;
   only the stage/lights are world-space. A collider placed in world space will drift
   away from its visual as soon as the tilt changes.
2. **Upright cylinders.** Cannon's `Cylinder` is built along Z. `addUprightCylinder`
   rotates it −90° about X. Bumpers and pegs must use it; a raw cylinder lies down and
   the ball rolls over the post.
3. **Body type transitions are explicit.** Ball: `DYNAMIC` in play, `KINEMATIC` on a
   loop rail, `STATIC` after a drain. Targets: `collisionResponse = false` and asleep
   when down; restored position/velocity and awake on re-arm.
4. **Never re-arm a target under a live ball.** `resetTargets` checks the ball's `x/z/y`
   and defers up to 900 ms; otherwise a node can materialise inside the ball.
5. **Score is integer.** `addScore` rounds `base × multiplier`; the HUD formats with
   `toLocaleString("en-US")`.
6. **Self-test counts are part of the contract.** `selfTest` asserts 3 bumpers, 4
   targets, 2 loops, 2 flippers and a 16-check total. Adding table objects means updating
   the self-test and the docs together.

## Extension points

| Change | Where |
| --- | --- |
| Add/relocate a bumper | `bumperDefs`, `buildBumpers`, self-test count |
| Add/relocate a drop target | `targetPositions`, `targetZ`, `buildDropTargets`; the bank logic uses `targets.length` |
| Add a loop | `loopDefs`, `buildLoops`; sensor and curve are generated from the points |
| Tune flippers | `FLIPPER` constants; geometry in `buildFlippers` |
| Tune launches | `updateCharge`, `releaseCharge`, `launchBall` |
| Add scoring events | `addScore` call sites; keep the multiplier rule in `knockTarget` |
| Change visuals | `buildMaterials`, `neonMaterial`, `pureNeon`, CSS tokens in `:root` |
| Change camera framing | `updateCameraLayout` aspect table |
| Change persistence | `STORAGE`, `sanitizeScoreEntry`, `scoreStore`, `exportScores`, `importScoresFile` |
| Add UI copy | `index.html` + `style.css` (single language; no i18n layer) |
| Add automation hooks | the `window.NEON_HORIZON` object in `boot` |

Do not add a build step merely to split `script.js`; the single-file delivery is part of
the release contract.

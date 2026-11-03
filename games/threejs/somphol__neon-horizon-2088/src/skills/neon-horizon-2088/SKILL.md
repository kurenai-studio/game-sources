---
name: neon-horizon-2088
description: Build a cyberpunk 3D pinball table with Three.js and Cannon.js — inclined cabinet, railgun plunger, flippers, bumpers, drop targets, loop rails, Web Audio and a local score archive — as three static files.
version: 1.0.0
---

# NEON HORIZON 2088

A working reference for a single-page 3D pinball game: an inclined 10 × 22 unit cabinet
rendered with Three.js r128, simulated with Cannon.js 0.6.2 at a fixed 120 Hz, with a
railgun plunger, two flippers, three bumpers, four drop targets, two hyper-loop rails,
synthesised Web Audio and a `localStorage` score archive with JSON export/import.

The template is the released game, not a blank starter. Copy it, then rebuild the table
identity and geometry — do not just recolour it.

## When to use

- The user asks for a 3D pinball table, arcade cabinet, or a physics-driven browser game
  with flippers and bumpers.
- The result must be three static files (`index.html`, `style.css`, `script.js`) with no
  build step, no package manager and no backend.
- You need a proven starting point for Cannon.js table geometry, ball tunnelling guards,
  touch/keyboard controls, procedural textures and a score archive.
- You want the same architecture adapted to another arcade table (different layout,
  scoring, theme) without inventing the physics plumbing again.

**Not for:** an offline-first app (the template loads Three.js, Cannon.js and fonts from
CDNs), a realistic rigid-body simulation, a multiplayer/server game, a mobile-native app,
or a project that must avoid WebGL. If the user needs a 2D canvas game, use a different
pattern.

## What it produces

```text
<project>/
├── index.html      # HUD, overlays, canvas, three CDN script tags
├── style.css       # cyberpunk design system, responsive HUD
└── script.js       # scene, physics, audio, flow, persistence
```

Runtime dependencies, pinned in `index.html`:

```text
https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js
https://cdnjs.cloudflare.com/ajax/libs/cannon.js/0.6.2/cannon.min.js
Orbitron + Rajdhani from Google Fonts
```

The release has a 16-check self-test at `?selftest=1` and exposes
`window.NEON_HORIZON` for automation.

## Quick start

```sh
# from this skill directory, or adjust the path if it is installed elsewhere
cp -R ~/.config/opencode/skills/neon-horizon-2088/assets/template/. ~/Projects/my-pinball-table/
cd ~/Projects/my-pinball-table
python3 -m http.server 8080
# open http://localhost:8080/ and http://localhost:8080/?selftest=1
```

No install. `node --check script.js` is the only static syntax gate. If the target
project has `scripts/check.mjs`, run it; the template itself does not include one.

## Workflow

1. **Fix the table contract.** Choose the table size, tilt, ball radius, drain box and
   coordinate convention before editing geometry. The reference uses 10 × 22 units,
   6.6°, `ballR = 0.32`, local `+z` down-table, local `y = 0` playfield.
2. **Copy the template.** Keep the three-file structure, the boot order and the
   `window.NEON_HORIZON` surface.
3. **Rebrand.** Change `VERSION`, the `<title>`/meta/OG tags, HUD copy, `--cyan` /
   `--magenta` / `--violet` tokens, the callsign default and the export filename in
   `exportScores`. Update `index.html` canonical/OG URLs last.
4. **Rebuild the playfield.** Move `bumperDefs`, `targetPositions`, `targetZ`, `loopDefs`
   and the lane-guide walls. Keep mesh and collider positions in the same local frame.
5. **Re-tune physics.** Change one variable at a time: restitution, flipper angles,
   launch impulse, speed clamp. Re-run the 60 units/s wall tests after any change.
6. **Re-theme the art.** `makePlayfieldTexture`, `makeBackglassTexture`,
   `makeCityTexture` and `makeGridTexture` are plain canvas code.
7. **Verify.** `node --check script.js`; serve; `?selftest=1` must report 16/16; run the
   manual matrix in `references/verification.md`.
8. **Document and release.** Copy the release-doc pattern from the source repository:
   `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/REPRODUCTION.md`, `docs/TESTING.md`,
   `docs/DEPLOYMENT.md`, `scripts/check.mjs`, `.nojekyll`, Pages on `main` / root.

## Module map

`script.js` is one IIFE with 17 numbered sections. Edit by section, not by line.

| Section | Responsibility | Key identifiers |
| --- | --- | --- |
| 0 | Constants/helpers | `VERSION`, `STORAGE`, `TABLE`, `FIXED_STEP`, `FLIPPER` |
| 1 | Audio | `Synth`, `synth` |
| 2 | Persistence | `scoreStore`, `sanitizeScoreEntry` |
| 3 | HUD | `dom`, `updateHUD`, `renderLeaderboard` |
| 4 | Renderer/camera | `initRenderer`, `updateCameraLayout` |
| 5 | Procedural textures | `makePlayfieldTexture`, `makeEnvMap` |
| 6 | Materials | `buildMaterials`, `neonMaterial`, `pureNeon` |
| 7 | Scene | `buildCabinet`, `buildLaneGuides`, `buildPegs` |
| 8 | Physics world | `initPhysics`, `addStaticBox`, `addUprightCylinder` |
| 9 | Game objects | `buildBumpers`, `buildDropTargets`, `buildLoops`, `buildFlippers` |
| 10 | Ball/plunger/rail | `launchBall`, `captureBallInLoop`, `updateRail` |
| 11 | Sparks | `initSparks`, `burstSparks` |
| 12 | Flow | `startGame`, `loseBall`, `endGame`, `recoverBall` |
| 13 | Simulation | `fixedUpdate`, `animate` |
| 14 | Export/import | `exportScores`, `importScoresFile` |
| 15 | Input | `bindUI`, `onKeyDown` |
| 16 | Self-test | `selfTest` |
| 17 | Boot | `boot` |

Boot order must stay: renderer → environment map → materials → stage → lights → physics
world → cabinet → lane guides → pegs → bumpers → targets → slingshots → loops →
plunger → flippers → ball → sparks → score load → HUD → input → animation.

## Core recipes

### 1. Add or move table objects

```js
// Bumpers: x, z, colour
var bumperDefs = [
  { x: -1.7, z: -3.4, color: 0x35f0ff, name: "CYAN" },
  { x: 0.0, z: -5.4, color: 0xff3bdc, name: "MAGENTA" },
  { x: 1.7, z: -3.4, color: 0x9d6bff, name: "VIOLET" }
];

// Drop targets: x positions at a shared z
var targetPositions = [-3.3, -2.1, -0.9, 0.3];
var targetZ = 1.45;
```

1. Edit the definition array.
2. Keep the visual group and the Cannon body at the same world position.
3. If the object is a post/bumper, use `addUprightCylinder(body, …)`; a raw
   `CANNON.Cylinder` lies along Z.
4. Update `selfTest` counts (`bumpers.length === 3`, `targets.length === 4`,
   `loops.length === 2`) if the object count changes.
5. Re-run the wall and recovery probes; a moved object can create a new pinch point.

### 2. Build a stable lower third

The reference uses an "Italian bottom" simplification:

- Flippers at `x = ±2.55`, `z = 7.6`, rest `∓0.34` rad, active `±0.60` rad.
- Slingshots at `x = ±1.95`, `z = 5.8`, rotated `±0.68` rad, kicking inward and up-table.
- Return guides feed side balls back toward the flippers.
- Side seals at `x = ±3.0` close the outlanes; only the centre flipper gap drains.
- The drain test is `x < 3.55 && z > 9.7 && y < 1.6`.

Keep the seal narrower than the ball diameter. If you reopen the outlanes for a harder
table, add posts and re-test every wall; the original "fun" problem was that the ball
escaped sideways almost every time.

### 3. Add a Hyper-Loop

```js
var loopDefs = [
  {
    name: "A",
    color: 0xa855ff,
    points: [
      [-3.85, 0.55, -8.1], [-4.5, 0.9, -6.6], [-4.6, 1.5, -3.1],
      [-4.35, 1.95, 0.9], [-3.7, 1.65, 4.1], [-2.8, 0.95, 6.1],
      [-2.25, 0.58, 6.75]
    ]
  }
];
```

1. Add the points; the code builds a `CatmullRomCurve3`, tube, rails and rings.
2. The entrance sensor is a `Sphere(0.72)` with `collisionResponse = false`.
3. On capture the ball body becomes `KINEMATIC` and follows `curve.getPointAt(t)`.
4. At `t ≥ 1` it returns to `DYNAMIC` with tangent velocity
   `(tangent.x·8.5 + 0.8, 0.25, |tangent.z|·3.5 + 2.4)`.
5. Keep the entry/exit clear of walls and other sensors; the sensor is intentionally
   non-solid so it cannot block the ball.

### 4. Add a scoring event

```js
game.combo += 1;
addScore(500, true);          // base × game.multiplier, rounded
```

Use `addScore`, never `game.score += n`, or the multiplier and the 100,000-point extra
ball are bypassed. Bank clears are the only place that raises the multiplier:

```js
game.multiplier = Math.min(8, game.multiplier + 1);
```

## Invariants and failure boundaries

- **One local frame.** Every table mesh and body sits under `tableGroup`; stage, city,
  grid and lights are world-space. Mixing them makes colliders drift from visuals.
- **Fixed step is physics, not fps.** Keep `FIXED_STEP = 1/120`; all impulses were tuned
  against it. Rendering follows the display refresh.
- **Four containment layers.** Thin walls, hard boundary clamp, lower backstops and a
  glass ceiling. A 22 units/s pre/post clamp prevents tunnelling. Do not remove a layer
  because another one "should" catch the ball.
- **Upright posts need `addUprightCylinder`.** Cannon cylinders are built along Z.
- **Collision callbacks run inside `world.step`.** Guard the ball and phase, use
  cooldowns, and never throw; an exception repeats every step.
- **Body type changes are explicit.** `DYNAMIC` → `KINEMATIC` on a rail → `DYNAMIC` on
  release; `STATIC` after a drain. Restore mass and `updateMassProperties()`.
- **Do not re-arm a target under a live ball.** Defer with a timer.
- **Score archives are untrusted.** Clamp values, strip markup, cap name length, cap the
  file at 2 MB and de-duplicate on merge.
- **CDN versions are API-bound.** Three r128 uses `outputEncoding`/`sRGBEncoding` and
  `PMREMGenerator.fromEquirectangular`; Cannon 0.6.2 uses `Body.KINEMATIC`,
  `SAPBroadphase` and `addShape` offsets. Upgrading is a migration.
- **Not offline.** The template requires network access for libraries and fonts. Vendor
  them deliberately if offline is a requirement.
- **Browser coverage is not universal.** Headless Chrome/SwiftShader was used; Safari,
  Firefox and real mobile GPUs need their own pass.

## Verification

```sh
node --check script.js
# serve, then:
# http://localhost:8080/?selftest=1   → 16/16
```

`?selftest=1` checks formatting, callsign sanitisation, Three.js/Cannon presence, table
tilt, 3 bumpers, 4 targets, 2 loops, 2 flippers, ball collider, physics world,
leaderboard storage, JSON serialisability, audio API and the export filename. It does not
test gameplay. Use `references/verification.md` for the full manual matrix: launch,
flippers, bumpers, targets, loops, slingshots, drain, recovery, export/import,
persistence, mobile layout and wall stress shots.

Stop and fix before shipping if: the self-test is below 16/16, the console logs
exceptions during a 30-second run, a 60 units/s shot leaves the cabinet without being
recovered, or the ball can wedge for more than 3.5 s without recovery.

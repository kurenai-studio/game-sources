# AGENTS.md — NEON HORIZON 2088

> Handoff for the next maintainer or agent. Rebuild/verification detail is in
> [docs/REPRODUCTION.md](docs/REPRODUCTION.md); the technical map is
> [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 1. What this is

A static, single-page **cyberpunk 3D pinball studio**: one inclined 10 × 22 unit cabinet,
rendered with Three.js r128 and simulated with Cannon.js 0.6.2, plus a Web Audio
synthesiser and a local score archive. It is three source files (`index.html`,
`style.css`, `script.js`) with no build step, no bundler and no package manager. It is
**not** offline — both libraries and the two display fonts load from CDNs — not a
server-backed arcade, not a mobile app, and not a general physics engine. Current
release: **v1.0.0**.

Live copy: <https://somphol.github.io/neon-horizon-2088/>
Local master: `~/Projects/neon-horizon-2088`

## 2. Commands

```bash
cd ~/Projects/neon-horizon-2088

# run (no install, no build)
python3 -m http.server 8080       # open http://localhost:8080/

# verification (no dependencies)
node --check script.js
node scripts/check.mjs
node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088

# in-browser self-test
# http://localhost:8080/?selftest=1  → window.__SELFTEST__

# deploy = push main; GitHub Pages serves the repository root
git push origin main
```

`scripts/check.mjs` verifies required files, local HTML references, relative Markdown
links, JavaScript syntax, JSON parsing and byte-identical skill templates. It is not a
physics or gameplay test; that record is in [docs/TESTING.md](docs/TESTING.md).
Use the HTTP server rather than `file://`; the HTTP path is the one the release was
verified on, and it gives the CDN scripts and `localStorage` a normal origin.

## 3. Architecture

Load order is `index.html` → `style.css` → `script.js`. `script.js` is one IIFE with
17 numbered sections:

1. **Constants** — `VERSION`, `STORAGE`, `TABLE`, `FIXED_STEP`, `FLIPPER`, helpers.
2. **Audio** — `Synth` (`tone`, `noise`, `bumper`, `launch`, `loop`, `gameOver`) and the
   `synth` singleton; one `AudioContext`, created on the first user gesture.
3. **Persistence** — `scoreStore` (`load`, `sort`, `save`, `add`, `merge`) and
   `sanitizeScoreEntry`.
4. **DOM/UI helpers** — `dom`, `updateHUD`, `renderLeaderboard`, `toast`, `announce`.
5. **Renderer** — `initRenderer`, `updateCameraLayout`, `onResize`.
6. **Procedural textures/materials** — `makePlayfieldTexture`, `makeBackglassTexture`,
   `makeCityTexture`, `makeGridTexture`, `makeEnvMap`, `buildMaterials`.
7. **Scene** — `buildStage`, `buildLights`, `buildCabinet`, `buildLaneGuides`,
   `buildPegs`; `bumperDefs`, `targetPositions`, `targetZ`, `loopDefs`.
8. **Physics** — `initPhysics`, `addStaticBox`, `addUprightCylinder`.
9. **Game objects** — `buildBumpers`, `buildDropTargets`, `buildSlingshots`,
   `buildLoops`, `buildPlunger`, `createBall`, `buildFlippers`.
10. **Ball/plunger/rail** — `spawnBall`, `startCharge`, `releaseCharge`, `launchBall`,
    `captureBallInLoop`, `updateRail`, `updateFlippers`.
11. **Sparks** — `initSparks`, `burstSparks`, `updateSparks`.
12. **Flow** — `game`, `startGame`, `loseBall`, `endGame`, `addScore`,
    `updateBallRecovery`, `recoverBall`.
13. **Simulation** — `fixedUpdate`, `animate`, `updateVisuals`.
14. **Export/import** — `exportScores`, `importScoresFile`.
15. **Input** — `bindUI`, `onKeyDown`, `onKeyUp`.
16. **Self-test** — `selfTest` (16 checks), exposed with `?selftest=1`.
17. **Boot** — `boot` builds the scene in a fixed order and publishes
    `window.NEON_HORIZON` for automation.

Boot order inside `boot()`: `initRenderer` → `makeEnvMap` → `buildMaterials` →
`buildStage` → `buildLights` → `initPhysics` → `buildCabinet` → `buildLaneGuides` →
`buildPegs` → `buildBumpers` → `buildDropTargets` → `buildSlingshots` → `buildLoops` →
`buildPlunger` → `buildFlippers` → `createBall` → `initSparks` → `scoreStore.load` →
`updateHUD` → `bindUI` → start `requestAnimationFrame(animate)`.

Key numbers and formulas (all in `script.js`, all verified):

```text
TABLE = { width: 10, length: 22, tiltDeg: 6.6, ballR: 0.32 }
world.gravity = (0, -9.82·cos θ, 9.82·sin θ)          θ = 6.6° in radians
FIXED_STEP = 1/120                                     accumulator clamp 0.05 s, max 6 steps
ball speed clamp = 22 units/s                          before and after world.step
plunger impulse = 1.25 + 1.55·power                    ball mass 0.25
flippers: rest ∓0.34 rad, active ±0.60 rad, 20 rad/s up, 11 rad/s down
drain zone: x < 3.55, z > 9.7, y < 1.6
recovery: < 0.8 units of horizontal movement for 3.5 s → back to railgun
```

The table group (`tableGroup`) carries the tilt; the stage, city backdrop, floor grid
and lights stay in world space. Local `+z` points down-table toward the player, local
`x` is lateral, and the playfield surface is `y = 0`.

Scoring is `Math.round(base × multiplier)`: bumper 500, sling 120, drop target 900,
bank clear 5000, hyper-loop entry 2500, loop exit 500. A bank clear raises the
multiplier by 1 up to ×8; 100,000 points awards one extra ball per session.

Persistence uses four keys: `neon_horizon_scores_v1` (array of
`{id,name,score,date,maxMultiplier,loops,targets}`, sorted, capped at 30),
`neon_horizon_best_v1`, `neon_horizon_callsign_v1`, `neon_horizon_muted_v1`. No game
session is resumed.

## 4. Decisions and constraints

- **CDN versions are pinned, not decorative.** Three r128 and Cannon 0.6.2 are loaded
  from exact cdnjs URLs. The code uses r128-era APIs (`outputEncoding`,
  `THREE.sRGBEncoding`, `PMREMGenerator.fromEquirectangular`) and Cannon 0.6.2 behaviour
  (`Body.KINEMATIC`, `SAPBroadphase`, `Cylinder` built along Z, `applyImpulse`). Upgrading
  either library is a migration, not a version bump; re-test the whole table.
- **The table coordinate system is the contract.** `x` lateral, `z` down-table, `y` up;
  `tableGroup.rotation.x = 6.6°`; gravity is projected, not re-rotated per body. Every
  collider is positioned in the same local frame as its mesh. Changing tilt, origin or
  table size without re-deriving the lane geometry, camera thresholds, drain box and
  boundary clamps will break aiming.
- **120 Hz is a simulation rate.** `animate` accumulates real time and runs up to six
  `1/120` steps per frame. It is not a 120 fps render claim. Keep the step fixed; changing
  it invalidates every restitution/impulse value tuned against it.
- **Thin walls alone are not enough.** The release relies on four layers: thin visual and
  physics walls, a hard inner-face clamp (`x = ±4.58`, `z ≥ -10.45`), lower-side backstops,
  and a glass-ceiling collider at `y = 2.8`. A 22 units/s pre/post-step clamp prevents
  tunnelling. Do not remove a layer because "the wall is there".
- **Collision callbacks run inside `world.step`.** They must be cheap, must guard the ball
  and phase, and must use cooldowns rather than mutating scene arrays during iteration.
  An exception here repeats every step.
- **Procedural assets only.** The game uses no runtime image, audio or model assets:
  textures are drawn to canvases and every sound is synthesised. `favicon.svg` is the
  only static icon. Do not add runtime asset downloads.
- **Score archives are untrusted input.** `sanitizeScoreEntry` clamps values, strips markup
  from names and caps length; imports are de-duplicated by `name|score|date`. Keep that
  boundary if the import format changes.
- **`state.json` and `STATE.md` are historical.** They record the build session, token
  counts and deployment. Do not load them at runtime or refresh them to hide history.
- **The HUD is DOM, the table is Canvas.** `#stage` is `aria-hidden`; live score text,
  buttons and dialogs are real DOM. Keep keyboard focus and `aria-live` announcements
  when changing overlays.

## 5. Known issues

- **Network required.** Three.js, Cannon.js and Google Fonts are remote. There is no
  service worker, no vendored copy and no offline mode. A blocked CDN produces the
  built-in boot-failure screen.
- **Browser coverage is narrow.** Verified in headless Chrome with SwiftShader at
  1600×1000, 768×1024, 390×844 and 320×568. Safari, Firefox and real mobile GPUs were not
  automated.
- **No session resume.** Only scores, callsign and mute persist. Reloading starts a new
  table.
- **Escape recovery is a safety net, not a proof.** A ball can still leave the cabinet in
  rare high-energy cases; `recoverBall("auto")` returns it to the railgun without costing
  a ball. That is intentional, not a substitute for collision testing.
- **Randomness is not seeded.** Playfield dust, sparks and texture speckle use
  `Math.random`; physics is fixed-step but frame timing still varies between runs.
- **Audio needs a gesture.** Browsers suspend `AudioContext`; the first click, keypress or
  pad press starts it. Muting is stored, but audio does not autoplay.
- **Reduced motion is CSS only.** `prefers-reduced-motion` stops CSS animation; the
  Three.js camera parallax, pulses and sparks continue.
- **Canvas accessibility is limited.** The table itself is not a navigable grid; keyboard
  users control flippers and the plunger, not ball aim.
- **Scores are local and unauthenticated.** Import validation prevents malformed data, not
  a determined forger.

## 6. Continuity

- **Deployed copy:** GitHub Pages, branch `main`, folder `/ (root)`, with `.nojekyll`.
  <https://somphol.github.io/neon-horizon-2088/>
- **Local master:** `~/Projects/neon-horizon-2088`.
- **History:** [CHANGELOG.md](CHANGELOG.md) is the release log; `state.json` and
  [STATE.md](STATE.md) are the build-time record (session, duration, tokens, deployment).
- **Documentation map:** [README.md](README.md) is the human entry point;
  [docs/REPRODUCTION.md](docs/REPRODUCTION.md) the rebuild book;
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) the module/algorithm map;
  [docs/TESTING.md](docs/TESTING.md) what was actually run and what was not;
  [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) Pages operations;
  [skills/neon-horizon-2088/SKILL.md](skills/neon-horizon-2088/SKILL.md) the reusable
  build skill.
- **Policies:** [CONTRIBUTING.md](CONTRIBUTING.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md),
  [SECURITY.md](SECURITY.md), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md),
  [LICENSE](LICENSE).
- **Publishing rules:** keep Pages on `main` / root and keep the repository public (MIT).
  If the repository is renamed, update the absolute URLs in `index.html` (canonical, OG
  and Twitter tags), `README.md`, `AGENTS.md`, `docs/DEPLOYMENT.md`,
  `skills/neon-horizon-2088/ATTRIBUTION.md` and `state.json`. Do not commit credentials,
  tokens or local secret files.

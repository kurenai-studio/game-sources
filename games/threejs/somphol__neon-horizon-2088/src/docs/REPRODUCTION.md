# Reproduction book

This is the rebuild book for **NEON HORIZON 2088**. It is written so another agent can
recreate the released project without the original session. Read
[ARCHITECTURE.md](ARCHITECTURE.md) first for the module map, then use this document for
scope, build order, provenance and acceptance.

> **If the three source files exist, they are the source of truth.** Rebuild from this
> book only when the source is lost or you are deliberately making a new variant. The
> release is the code in `index.html`, `style.css` and `script.js`; the skill template in
> `skills/neon-horizon-2088/assets/template/` is a byte-identical copy.

## 1. What is being reproduced

A single-page **cyberpunk 3D pinball studio**:

- **Table:** an inclined, glass-topped cabinet, 10 × 22 units, tilted 6.6°, with a
  matte-black chassis, chrome rails, legs, backglass, neon underglow, city backdrop and
  floor grid.
- **Physics:** Cannon.js 0.6.2 rigid bodies, fixed 120 Hz simulation, projected gravity,
  a chrome sphere, two flippers, three bumpers, four drop targets, two slingshots, two
  hyper-loop rails, a plunger and a drain.
- **Presentation:** Three.js r128, procedural 1024 × 2048 playfield art, procedural
  backglass/city/grid/environment textures, emissive neon materials, glow sprites,
  point lights, shadows, ACES tone mapping.
- **Audio:** 100% synthesised Web Audio (ambient bed, impacts, launch, loops, targets,
  drain, game over). No audio files.
- **Scores:** local leaderboard in `localStorage`, top five on screen, 30 retained,
  portable JSON export/import.
- **Languages:** English only. There is no i18n layer.
- **Delivery:** three source files, no build, no package manager, CDN libraries and
  fonts. GitHub Pages, `main` / root.
- **Release:** **v1.0.0** (`VERSION` in `script.js`).

## 2. Requirements matrix

Original brief:

| # | Requirement | Implementation | File |
| --- | --- | --- | --- |
| 1 | Inclined glass-topped cabinet, Three.js meshes synced to Cannon colliders | `TABLE.tiltDeg = 6.6`, `tableGroup`, `buildCabinet`, `buildLaneGuides`, `initPhysics` | `script.js`, `style.css` |
| 2 | Chrome fusion ball, sphere body, low friction / high restitution | `MAT.ball`, `createBall`, ball/wall restitution 0.80 | `script.js` |
| 3 | Railgun plunger, Space hold/release and touch drag, linear impulse | `buildPlunger`, `startCharge`, `updateCharge`, `releaseCharge`, `launchBall`, pointer handlers in `bindUI` | `script.js` |
| 4 | Dual flippers, Z/← and //→, pivot motion, high angular velocity | `FLIPPER`, `buildFlippers`, `updateFlippers`, `setFlipper`, `onKeyDown` | `script.js` |
| 5 | Three Quantum Plasma Cores, neon flash, scale pulse, outward impulse | `bumperDefs`, `buildBumpers`, `hitBumper`, per-bumper lights and `updateVisuals` | `script.js` |
| 6 | Cyber Security drop targets, multiplier | `targetPositions`, `buildDropTargets`, `knockTarget`, `resetTargets` | `script.js` |
| 7 | Hyper-Loop wire ramps routing the ball | `loopDefs`, `buildLoops`, `captureBallInLoop`, `updateRail` | `script.js` |
| 8 | Dark chassis, neon circuit traces, Web Audio ambience | `makePlayfieldTexture`, `buildCabinet`, `Synth.startAmbient`, `synth` | `script.js`, `style.css` |
| 9 | High-score memory and leaderboard in localStorage | `scoreStore`, `renderLeaderboard`, four `STORAGE` keys | `script.js` |
| 10 | Export `neon_horizon_scores.json`, import/sync | `exportScores`, `importScoresFile`, `scoreStore.merge` | `script.js`, `index.html` |
| 11 | Glassmorphic HUD: score, multiplier, balls; responsive canvas | `.hud`, `.score-cluster`, `.panel`, `updateHUD`, `onResize`, `updateCameraLayout` | `index.html`, `style.css`, `script.js` |
| 12 | Output exactly `index.html`, `style.css`, `script.js` | Three sources at repository root | repo |

Late requirements from the build session:

| Requirement | Implementation | File |
| --- | --- | --- |
| A stuck ball must recover | `updateBallRecovery` (0.8 units / 3.5 s), `recoverBall`, `R`, **RECOVER STUCK BALL** | `script.js`, `index.html` |
| The right side had a pinch point | widened bumper/sling/peg clearances from the shooter-lane divider; right backstop at `x = 3.24` | `script.js` |
| The left wall must bounce | wall restitution 0.80 and hard-boundary reflection at `x = ±4.58` | `script.js` |
| Remove the side escape rails | old outlane funnels deleted; return guides + sealed side lanes at `x = ±3.0`; only the centre gap drains | `script.js` |
| Follow a real pinball lower third | slingshots angled inward/up-table, inlane return guides, outlane posts; research notes in `references/lessons.md` | `script.js` |
| Ball still escaped past walls | glass-ceiling collider, lower backstops, pre/post speed clamp 22, hard boundary, table-escape recovery | `script.js` |
| Document the build honestly | README, AGENTS, docs set, `state.json`, `STATE.md` | repo |

## 3. Non-negotiable constraints

| Constraint | Why | Enforcement |
| --- | --- | --- |
| Three source files, no build | `file://`-friendly, lifetime simplicity, the brief asked for three blocks | repository layout; no `package.json` |
| Pinned CDN versions | r128/Cannon 0.6.2 APIs are used directly | exact URLs in `index.html`; `scripts/check.mjs` checks local references, not upgrades |
| Fixed 120 Hz step | all impulses and restitutions were tuned at this step | `FIXED_STEP = 1/120`; six-step cap |
| Local table frame | visuals and colliders must agree | `tableGroup`; `addUprightCylinder` |
| Procedural art only | no external assets to lose | canvas textures, `Synth` |
| Single-language UI | no translation layer was built | HTML copy only |
| Local-only scores | privacy, offline-friendly scoring | `localStorage` + Blob download |
| No analytics / backend | static hosting | no network calls in `script.js` |
| Historical build record | honest provenance | `state.json`, `STATE.md` are never loaded at runtime |

## 4. Reference environment

The app needs a modern browser with WebGL and Web Audio. The release verification used:

| Tool | Version / note |
| --- | --- |
| macOS | Darwin, Apple Silicon |
| Node.js | 26.13.0 local (no npm dependencies) |
| Python | 3.x, only for `python3 -m http.server` |
| Chrome | headless Chrome with SwiftShader, CDP-driven |
| Git | system Git, `main` branch |
| Runtime deps | Three.js r128, Cannon.js 0.6.2, Orbitron/Rajdhani (CDN) |
| Build deps | none — no `npm install` |

```bash
cd ~/Projects/neon-horizon-2088
python3 -m http.server 8080        # http://localhost:8080/
node --check script.js
node scripts/check.mjs
```

## 5. Repository map

| Path | Role |
| --- | --- |
| `index.html` | DOM shell, HUD, overlays, script tags (280 lines) |
| `style.css` | Design tokens, layout, responsive rules, reduced motion (1937 lines) |
| `script.js` | Scene, physics, audio, flow, persistence (3758 lines) |
| `scripts/check.mjs` | Dependency-free release checker |
| `docs/` | Architecture, reproduction, testing, deployment, social card |
| `skills/neon-horizon-2088/` | Reusable skill and byte-identical source template |
| `assets/` | No runtime art directory; the game generates textures and audio, and `favicon.svg` is the only static icon |
| `state.json`, `STATE.md` | Historical build metrics and verification record |
| `.nojekyll` | Pages passthrough |

## 6. Build from empty directory

Follow the stages in order. Each stage ends with an acceptance check; do not start the
next stage until it passes.

### Stage 0 — Scaffold

```bash
mkdir neon-horizon-2088 && cd neon-horizon-2088
git init -b main
touch .nojekyll
```

Create `index.html`, `style.css`, `script.js`, `favicon.svg`, `LICENSE` (MIT) and a
`.gitignore`. No package manager, no node_modules, no bundler.

**Accept:** `python3 -m http.server 8080` serves a blank page with no 404s.

### Stage 1 — HTML shell

Build the semantic shell in `index.html`:

1. `<head>`: charset, viewport with `viewport-fit=cover`, theme color, description,
   title, favicon, canonical, Open Graph and Twitter tags, font preconnect + Google Fonts
   link, `style.css`.
2. `#stage` with `#game-canvas` and the glow/scanline/vignette layers
   (`aria-hidden="true"`).
3. `#boot` with ring, eyebrow, title, bar and hint.
4. `.hud`: topbar (brand, status pill, score/multiplier/balls cluster, scores/audio/new
   game buttons), left controls panel, right scores panel, bottom HUD (launch hint,
   charge meter, launch button, help/fullscreen), touch flip pads.
5. Overlays: start hero with callsign form; game-over modal; help modal; confirm modal.
6. `#toast-stack`, `#a11y-live`, `<noscript>`.
7. Script tags in this exact order: Three.js r128, Cannon.js 0.6.2, `script.js`.

**Accept:** every id referenced by `script.js` exists; the page renders without CSS; no
404 for `style.css`, `script.js` or `favicon.svg`.

### Stage 2 — CSS system

Implement `style.css` around the `:root` tokens:

```css
--bg:#04060d; --cyan:#5ff6ff; --cyan-hot:#00e5ff; --magenta:#ff3bdc;
--violet:#a888ff; --amber:#ffb545; --danger:#ff4d6d;
--font-display:"Orbitron"; --font-body:"Rajdhani"; --radius:16px;
```

Sections: stage canvas, boot sequence, HUD shell, side panels, bottom HUD, touch
controls, hero, modals, toasts, utility/noscript, responsive. Breakpoints are
`1380`, `1080`, `900`, `560` and `(max-height:760px) and (min-width:901px)`; reduced
motion is handled with `@media (prefers-reduced-motion: reduce)`.

**Accept:** at 1600 × 1000 the left panel is visible; below 1380 it is hidden; below 900
the right panel becomes a slide-in drawer, touch pads appear and the brand subtitle hides;
at 390 × 844 there is no horizontal overflow.

### Stage 3 — Constants and utilities

In `script.js` section 0:

- `VERSION = "1.0.0"`.
- `STORAGE` with the four keys.
- `TABLE = { width:10, length:22, halfW:5, halfL:11, tiltDeg:6.6, ballR:0.32, halfW2:5.1 }`
  and `TABLE.tilt = tiltDeg * Math.PI / 180`.
- `FIXED_STEP = 1/120`.
- `FLIPPER = { restLeft:-0.34, activeLeft:0.6, restRight:0.34, activeRight:-0.6, upSpeed:20, downSpeed:11 }`.
- `clamp`, `lerp`, `rand`, `formatScore`, `formatTime`, `sanitizeName`, safe storage
  wrappers, `$`, `createEl`, `escapeRegExp`, `prefersReducedMotion`.

**Accept:** `formatScore(1234567) === "1,234,567"` and `formatTime(65000) === "01:05"`.

### Stage 4 — Renderer, camera and procedural art

1. `initRenderer`: antialias, pixel ratio cap, sRGB, ACES 1.18, PCF soft shadows, fog.
2. `updateCameraLayout`: aspect table from [ARCHITECTURE.md](ARCHITECTURE.md).
3. `makeEnvMap`: 1024 × 512 equirectangular canvas, PMREM, dispose the source.
4. `makePlayfieldTexture` 1024 × 2048 with the `P(x,z)` mapping.
5. `makeBackglassTexture` 1024 × 512, `makeCityTexture` 2048 × 1024,
   `makeGridTexture` 512 × 512 repeated 16 × 16.
6. `buildMaterials` and the two neon helpers.
7. `buildStage`: city plane at `(0,11,-42)`, grid at `y=-4.6`, horizon plane.
8. `buildLights`: hemisphere, shadow key (2048² desktop / 1024² small), cyan/magenta/violet
   rim, under light.

**Accept:** the scene renders the table area against the city backdrop; no console errors
about missing `envMap`.

### Stage 5 — Cabinet, lane guides, pegs

Build the visual and physics geometry together:

- Cabinet base `11.35 × 1.2 × 23.3` at `y=-0.62`; trim; playfield plane.
- Side rails at `x=±5.25`; front/top rails at `z=±11.15`; drain strip.
- Shooter lane at `x≈4.3`, lane edge at `x=3.62`.
- Glass plane at `y=2.72`; posts; edge glow.
- Legs and feet; backglass frame/panel and neon bars; underglow sprites.
- Outer walls `x=±5.06`; top wall `z=-10.95`; shooter-lane divider `x=3.6`.
- Curved launch guide from `(4.95,-5.0)` through `(1.55,-9.78)` to `(-0.1,-9.72)`.
- Lower return guides and their end posts; side seals at `x=±3.0`.
- Three pegs at `(-3.7,2.7)`, `(2.2,-1.0)`, `(-1.35,-8.9)`.

**Accept:** every mesh has a matching static body at the same local position; a test ball
rolled into each wall reverses direction.

### Stage 6 — Physics world and table objects

1. `initPhysics`: SAP broadphase, 22 iterations, projected gravity, contact materials,
   floor box (top at `y=0`), ceiling box at `y=2.8`, left/right backstops.
2. `buildBumpers`: three cores at `(-1.7,-3.4)`, `(0,-5.4)`, `(1.7,-3.4)` with upright
   cylinder colliders and collide listeners.
3. `buildDropTargets`: four bars at `x=-3.3,-2.1,-0.9,0.3`, `z=1.45`.
4. `buildSlingshots`: two angled bodies at `x=±1.95`, `z=5.8`.
5. `buildLoops`: two Catmull-Rom tube paths from `loopDefs`, entrance sphere sensors at
   radius 0.72.
6. `buildPlunger`, `buildFlippers` at `x=±2.55`, `z=7.6`.
7. `createBall`: sphere, trail, glow, point light, Cannon body, wall-impact listener.
8. `initSparks`: 240-point buffer.

**Accept:** the self-test reports 3 bumpers, 4 targets, 2 loops, 2 flippers, one ball
collider and a tilted table group.

### Stage 7 — Game flow

Implement `game`, `startGame`, `spawnBall`, `startCharge`, `updateCharge`,
`releaseCharge`, `launchBall`, `loseBall`, `endGame`, `requestNewGame`,
`abandonAndRestart`, `addScore`, `updateBallRecovery`, `recoverBall`, `setPhase`.

Phases: `menu → ready → play → drain → (ready | over)`. The help dialog does not change
the phase; it sets `game.paused`, which makes `fixedUpdate` return early. `startGame`
resets score/multiplier/balls and re-arms all table objects. `loseBall` decrements,
resets combo/multiplier and either respawns after 1.45 s or ends after 1.2 s. `endGame`
archives a positive score and fills the summary.

**Accept:** launch → play; forced drain → ball countdown; three drains → game over; the
score appears in the leaderboard.

### Stage 8 — HUD, audio, persistence, input

1. `updateHUD` writes score, best, multiplier, combo, balls, targets, loops, bumpers,
   status and charge; animate changed metrics with `is-bumped`.
2. `renderLeaderboard` prints the top five; empty state has its own copy.
3. `Synth` graph and voices; `startAmbient` after the first gesture.
4. `scoreStore` load/save/add/merge and `sanitizeScoreEntry`.
5. `exportScores` (Blob + object URL + temporary `<a download>`), `importScoresFile`
   (2 MB limit, array / `scores` / `leaderboard` shapes).
6. `bindUI`: start form, new game, save/load, rescue, sound, launch pointer (hold + drag
   boost), touch pads, canvas halves, help/confirm dialogs, scores drawer, fullscreen,
   keyboard, blur/visibility reset.
7. `onKeyDown` / `onKeyUp`: Space, Z/←, //→, R, M, H/?, Escape.

**Accept:** keyboard and touch launch/flip work; mute and callsign survive reload; export
downloads `neon_horizon_scores.json`; import merges without duplicates.

### Stage 9 — Hardening pass

Add the layers that make the table stable:

- Glass-ceiling collider at `y=2.8` and lower backstops.
- Hard boundary clamp `x=±4.58`, `z≥-10.45` with 0.65 reflection.
- Pre/post speed clamp 22.
- Table-escape recovery (`outside` check) without spending a ball.
- Displacement watchdog: 0.8 units / 3.5 s, skipped in the shooter lane, on a rail, or
  while a flipper is held.
- Avoid target re-arm under a live ball.

**Accept:** 60 units/s test shots into the left, right and top walls stay inside; a
lower-seam escape is recovered without losing a ball; a deliberately parked ball
returns to the railgun after 3.5 s; a drained ball still counts down.

### Stage 10 — Automation surface and self-test

Expose `window.NEON_HORIZON` with the methods listed in
[ARCHITECTURE.md](ARCHITECTURE.md). Implement `selfTest()` with 16 checks and run it when
`?selftest=1`.

**Accept:** console logs `16/16` and `window.__SELFTEST__.pass === 16`.

### Stage 11 — Documentation, checker, skill

Create `AGENTS.md`, the `docs/` set, `scripts/check.mjs` and the skill directory. Copy the
three source files byte-for-byte into `skills/neon-horizon-2088/assets/template/`. Run
both checkers.

### Stage 12 — Deploy

Push `main`; enable Pages from `main` / `/`; verify the live root, `script.js` and
`docs/social-card.png` return 200. See [DEPLOYMENT.md](DEPLOYMENT.md).

## 7. Where the non-obvious numbers came from

| Number | Value | Provenance |
| --- | --- | --- |
| Table size | 10 × 22 units | Chosen so the 10-unit width leaves a readable shooter lane and the 22-unit length fits the camera framing; all lane coordinates derive from it |
| Tilt | 6.6° | Visual compromise: enough slope for gravity-driven play, shallow enough that the cabinet reads as a table rather than a ramp |
| Ball radius | 0.32 | Slightly over 1/32 of the table width; fits between the lane divider at `x = 3.6` and the outer wall at `x = 5.06`, and through the centre flipper gap |
| Ball mass | 0.25 | Keeps the plunger impulse in the 5–11 units/s range |
| Fixed step | 1/120 s | The solver was unstable/tunnelling at 60 Hz with 22 units/s speeds; 120 Hz plus substepping was the smallest change that held |
| Speed clamp | 22 units/s | Derived from failed 60 units/s stress shots: above roughly 20 units/s the ball could cross thin walls between steps |
| Restitution | wall 0.80, bumper 0.92, sling 0.65, flipper 0.48, table 0.16 | Tuned by playtest and headless probes for lively but controllable bounces |
| Flipper angles | rest ∓0.34, active ±0.60 rad | Gives a ~54° sweep without the tip crossing the lane seal |
| Flipper speeds | 20 rad/s up, 11 rad/s down | Fast enough to transfer momentum, slow enough not to tunnel |
| Charge rate | 0.72/s | A full charge takes ~1.4 s of holding |
| Launch impulse | 1.25 + 1.55·power | Produces a full-lane launch at power 1 and a weak dribble at the 0.12 floor |
| Drain box | `x<3.55, z>9.7, y<1.6` | Covers the centre gap and the open front, but not the shooter lane at `x>3.62` |
| Recovery | 0.8 units / 3.5 s | Long enough not to interrupt a slow cradle, short enough to feel automatic |
| Bank clear | +1 multiplier, max ×8, 5000 points | Eight bank clears would be a very long session; ×8 is the visible ceiling |
| Extra ball | 100,000 points, once | Roughly one good session |
| Camera distances | 23–26 up, 27.5–34 back | Framing the 22-unit table at each aspect without clipping the backglass |
| Palette | cyan `#5ff6ff`, magenta `#ff3bdc`, violet `#a888ff`, amber `#ffb545`, danger `#ff4d6d` | Brief asked cyan/magenta/violet; the extra amber/danger are HUD semantics |

The lower-third layout was informed by public pinball-design references found during the
session, including the [FAST Pinball lower-third cookbook](https://fastpinball.com/cookbook/lower-third/)
and [Kineticist's "Italian bottom" explainer](https://www.kineticist.com/news/understanding-the-italian-bottom).
The implementation is an original simplification, not a traced layout.

## 8. Verification procedure

```bash
cd ~/Projects/neon-horizon-2088
node --check script.js
node scripts/check.mjs
node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088
python3 -m http.server 8080
```

Expected static result: `OK <n> checks` from `scripts/check.mjs` and an `OK` line from the
skill checker (the exact count is printed by the script; it grows when checks are added).
Then open `http://localhost:8080/?selftest=1` and confirm `16/16` in the console and
`window.__SELFTEST__`.

The manual/headless matrix in [TESTING.md](TESTING.md) is the release evidence. At
minimum, reproduce:

1. Start with a callsign; hold Space; release; the ball travels up the shooter lane.
2. Flip with Z and /; the ball changes direction.
3. Bumper hit → flash, sparks, score.
4. Drop target → sink; clear four → multiplier +1, re-arm after 3 s.
5. Hyper-loop capture → rail ride → release.
6. Drain → countdown → respawn; three drains → game over.
7. `R` and the panel button recover a parked ball.
8. Export, clear storage, import; scores merge.
9. Mute; reload; mute persists.
10. Resize 1600 × 1000 → 768 × 1024 → 390 × 844 → 320 × 568; no overflow.

## 9. What was tried and rejected

| Attempt | Why it failed | Replacement |
| --- | --- | --- |
| Thin collision walls only | A fast ball could tunnel out during a solver step | Hard boundary clamp, lower backstops, glass ceiling, 22 units/s pre/post clamp |
| Horizontal Cannon cylinders for bumpers and pegs | The visual posts were upright but the colliders lay along Z; balls rolled over them | `addUprightCylinder` rotates the cylinder −90° about X |
| Old side outlane funnels | User feedback: the ball "almost always" escaped that way, and the left wall did not bounce | Funnels removed; side return guides, inward slingshots, sealed side lanes, wall restitution 0.80 |
| Stuck-ball rescue by a small impulse after 5.5 s | The "BALL UNSTUCK · TABLE NUDGED" toast appeared but the ball did not move | 3.5 s displacement watchdog that respawns the ball in the railgun |
| Reopening the outlanes as a "hard mode" | Offered after the rebuild, not implemented in 1.0.0 | Documented as a future option only |

## 10. Honest deviations and unfinished parts

| Item | State |
| --- | --- |
| Flippers | Kinematic bodies with a controlled angle and `angularVelocity`, not Cannon hinge constraints. The visual and physical pivot agree. |
| Plunger | A visual spring plus an applied impulse, not a simulated spring constraint. |
| Glass | A transparent plane for looks and a separate box collider for containment; no thickness simulation. |
| Offline | Not offline: Three.js, Cannon.js and Google Fonts are CDN-only. |
| Browser coverage | Headless Chrome/SwiftShader only; Safari, Firefox and real mobile GPUs are unverified. |
| Session resume | Not implemented; only scores/callsign/mute persist. |
| Accessibility | Canvas is `aria-hidden`; no per-object keyboard navigation or screen-reader table model. |
| Reduced motion | CSS animations stop; Three.js motion continues. |
| Ball escape | Still possible in rare cases; recovery is a safety net, not a guarantee. |
| Language | English only; no bilingual layer. |
| Score integrity | Import validation is shape/clamping only; local scores are not authenticated. |
| Rendering rate | "120 Hz" refers to simulation steps; rendering follows the display refresh. |

## 11. Recreate or restore?

| Situation | Action |
| --- | --- |
| Source exists and `scripts/check.mjs` passes | Use it; read the docs for context |
| Source exists but behaviour differs from docs | Inspect the diff; update docs rather than silently changing physics |
| Source missing, docs intact | Rebuild with this book, then run the checker and the manual matrix |
| Only README survives | Recover the repository or the skill template in `skills/neon-horizon-2088/assets/template/` |
| Live site broken | Roll back the bad commit; see [DEPLOYMENT.md](DEPLOYMENT.md) |

## 12. Handoff checklist

- [ ] `node --check script.js` passes.
- [ ] `node scripts/check.mjs` prints `OK <n> checks`.
- [ ] `node ~/.config/opencode/skills/skill-publish/scripts/check-skill.mjs skills/neon-horizon-2088` passes.
- [ ] `?selftest=1` reports 16/16 in a browser.
- [ ] `git remote -v` points at the expected repository.
- [ ] `python3 -m http.server 8080` serves the app.
- [ ] Live root, `script.js` and `docs/social-card.png` return 200.
- [ ] The three template files are byte-identical to the release sources.
- [ ] `state.json` / `STATE.md` are treated as historical, not runtime data.
- [ ] Any new table object updates `selfTest`, the docs and the skill template.

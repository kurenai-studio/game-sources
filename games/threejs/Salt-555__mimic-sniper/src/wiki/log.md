# Wiki Log

> Chronological record of all wiki actions. Append-only.
> Format: `## [YYYY-MM-DD] action | subject`
> Actions: ingest, update, query, lint, create, archive, delete
> When this file exceeds 500 entries, rotate: rename to log-YYYY.md, start fresh.

## [2026-07-11] create | Wiki initialized for Mimic Sniper project
- Domain: Low-poly Three.js multiplayer game (Prop Hunt + Hitman sniper)
- Structure created with SCHEMA.md, index.md, log.md
- Initial concept page: [[game-scope]]

## [2026-07-11] create | Mimic Movement mechanic research (v2 — spider approach)
- Researched procedural leg IK: closed-form two-bone solver using Law of Cosines (not iterative FABRIK/CCD)
- Reference: threejs-procedural-spider (8-leg IK, no physics engine), Little Polygon game dev blog, Tim Wheeler 3D IK
- 6 legs × 2-bone chains with phase-offset gait cycle. Stance feet stay planted to avoid sliding.
- Triangle budget: ~464 per Mimic (body + 6 legs). 4 draw calls via shared material.
- Tunable parameters: leg count, proportions, gait rate, lift height, step distance
- Created concepts/mimic-movement.md with full IK solver + gait code

## [2026-07-11] create | Mimic Transformation mechanic research
- Decision: instant asset swap + particle poof VFX (no mesh morphing) — same pattern as all prop hunt games
- Transformable props pre-placed in scene as invisible meshes, toggled visible on transform
- Poof effect: 40-point particle burst with gravity fade, zero triangle cost (THREE.Points)
- Transform range: 3 units. Cooldown: 0.7s to prevent flicker spam
- Poof VFX is intentional "tell" for Sniper — creates gameplay tension
- Created concepts/mimic-transformation.md with full implementation code

## [2026-07-11] create | Sniper Camera mechanic research
- PointerLockControls for mouse look (built into Three.js addons)
- Scope zoom: smooth FOV transition 75° → 12°. Right-click or scroll wheel to toggle.
- Breathing sway: dual-frequency sinusoidal micro-offsets on pitch/yaw. Shift key holds breath with depleting meter.
- CSS-only scope overlay (vignette + crosshair + range marks + breath bar) — no JS in overlay, works in Chromium kiosk.
- Seafoam green (#7FB3A8) crosshair for ALLMIND branding.
- Recoil system: kick up + random lateral, exponential recovery curve.
- Created concepts/sniper-camera.md with full camera class + CSS scope overlay code

## [2026-07-11] create | Sniper Ballistics mechanic research
- Hitscan raycasting from camera center — no simulated bullets for MVP (stationary sniper, known distances)
- Magazine system: 5 rounds + 10 reserve. 2s reload time. 0.5s fire cooldown prevents spam.
- Tight scoped spread (0.001) vs wide unscoped (0.02) — encourages scoping in.
- Hit VFX: 12-particle spark burst oriented along surface normal. Optional bullet tracer line.
- Target registration system: shootable objects tracked separately for efficient raycasting.
- Created concepts/sniper-ballistics.md with full ballistics class + hit effect code

## [2026-07-11] create | Sniper UI mechanic research
- All CSS overlays — no Three.js rendering overhead. Ammo counter, breath/reload dual-purpose bar, countdown timer.
- Hit feedback: scope flash (CSS animation), crosshair color change to red, impact sparks from ballistics.
- Round-end screen: winner announcement + stats (shots fired, accuracy, time) + next round button.
- Low ammo warning at 2 rounds (amber text). Empty state prompts reload.
- Created concepts/sniper-ui.md with complete HUD HTML/CSS/JS integration code

## [2026-07-11] create | Game state and multiplayer architecture
- Created concepts/game-state-machine.md for countdown, timed round, and winner resolution.
- Created concepts/multiplayer-architecture.md. Corrected product goal: online matchmaking with separate clients and an authoritative WebSocket server; local shared-machine play is not the target.

## [2026-07-11] create | Playable MVP implementation
- Built a modular Vite + Three.js MVP with low-poly arena, six-legged Mimic, prop-copy swap + poof VFX, sniper scope/sway/hitscan/reload, HUD, and timed win conditions.
- Added Vitest coverage for weapon state, state-machine transitions, and transformation target selection.
- Verified production build and browser rendering; corrected the sniper vantage orientation after visual testing.

- Initial approach used sine-wave FK chains (jellyfish pattern). User requested spider-like ground-contact movement instead.

# Build State

| Field | Value |
| --- | --- |
| Project | NEON HORIZON 2088 — Cyberpunk 3D Pinball Studio (`neon-horizon-2088`) |
| Started | 2026-11-01 03:47:45 UTC |
| Packaged | 2026-11-01 05:49:08 UTC |
| Duration | **2h 1m 22s** (7,282 seconds) |
| Harness | OpenCode 2.2.5 |
| Model | DeepSeek V4.1 Flash (`opencode-go/deepseek-v4.1-flash`) |
| Session | `ses_e6ac7942effe0GS7Yi86hbJntl` |
| Repository | <https://github.com/somphol/neon-horizon-2088> |
| Live demo | <https://somphol.github.io/neon-horizon-2088/> |

## Token usage

| Metric | Tokens |
| --- | ---: |
| Input | 673,032 |
| Output | 167,539 |
| Reasoning | 207,638 |
| **Total (input + output + reasoning)** | **1,048,209** |
| Cache read | 90,040,064 |
| Cache write | 1,218 |
| Total including cache | 91,089,491 |

> Snapshot taken from the OpenCode session record when the project was packaged at 2026-11-01 05:49:08 UTC. The final commit, push, Pages verification and closing response happen outside this snapshot, so the live session totals will be marginally higher. Total cost reported by the session: **$0.00**.

## What was built

- A complete 3D cyberpunk pinball game in three modular files:
  - `index.html` — 14,025 bytes, 263 lines
  - `style.css` — 44,081 bytes, 1937 lines
  - `script.js` — 129,844 bytes, 3712 lines
- An inclined 6.6° glass-topped cabinet with a matte-black chassis, chrome rails, legs, backglass marquee, neon underglow, city skyline and grid floor.
- Procedural playfield art: circuit traces, node rings, lane arrows, warning bands and a sector watermark, drawn to a 1024 × 2048 canvas.
- Three Quantum Plasma Cores (cyan, magenta, violet) with point-light flashes, emissive pulses, scale pops, spark bursts and outward physics kicks. Physics uses upright cylinder colliders.
- Four Cyber Security drop targets: scoring hits, bank clear bonus, multiplier increase up to ×8 and timed re-arm. Re-arm is deferred if a live ball is in the bank.
- Two translucent neon-purple Hyper-Loops with trigger sensors, Catmull-Rom rail rides and tangent release toward the flippers.
- Railgun plunger with keyboard hold/release and touch hold/drag; spring compression animation, charge meter and rising charge oscillator.
- Dual kinematic flippers with pivots, angular velocity transfer, neon edges and key/touch mapping.
- A real lower third based on the standard Italian-bottom layout: inward/up-table slingshot snap kicks, inlane return guides, outlane guide posts and sealed side lanes. Only the centre flipper gap drains.
- Bouncy side walls (0.8 restitution) so the ball rebounds off the left and right rails instead of sticking.

- A hard inner-face cabinet boundary clamps and reflects fast balls at the left/right/top rails, and solid lower-side backstops sit behind the side seals. A pre/post-step 22-unit speed clamp prevents tunnelling.
- A glass-ceiling collider that keeps hard flipper or bumper pops on the table; a ball that leaves the cabinet is recovered to the railgun without losing a ball.
- Chrome fusion ball with a generated reflection environment, dynamic glow, point light and comet trail.
- Outlane-side return guides and sealed side lanes, plus pegs, drain detection and 120 Hz fixed-step simulation.
- **Anti-trap recovery:** a displacement watchdog returns a ball that has made no progress for 3.5 s to the shooter lane without spending a ball; **R** and the **RECOVER STUCK BALL** button trigger the same recovery manually. A deliberate flipper cradle resets the watchdog.
- **Right-side clearance:** the bumper, slingshot and peg are positioned more than one ball diameter from the shooter-lane divider, eliminating the pinch points that could wedge the ball against the right wall.
- 100% synthesised Web Audio: ambient hum, laser/plasma bumper voices, flipper thunks, target chirps, loop whooshes, drain, multiplier arpeggio, extra ball and game-over chord.
- localStorage leaderboard, callsign and mute persistence; top-five HUD and 30-entry archive.
- `neon_horizon_scores.json` export and validated merge import, with HTML stripping and de-duplication.
- Glassmorphic HUD with score, multiplier, balls, best, combo, target/loop/bumper telemetry and archive controls.
- Start hero, operator manual, new-game confirmation, game-over summary and toast system.
- Responsive desktop/tablet/mobile layouts; large touch flip pads, hold-drag launch pad, slide-in score drawer and resize-safe canvas/camera.
- Built-in `?selftest=1` surface with **16/16** checks.

## Verification

- **16/16** self-tests pass: formatting, sanitisation, Three.js/Cannon.js presence, table tilt, 3 cores, 4 targets, 2 loops, 2 flippers, ball collider, physics world, storage, serialisation, audio API and export filename.
- Headless Chrome end-to-end runs verified:
  - full-charge railgun launch through the curved lane guide,
  - Hyper-Loop capture, rail ride and flipper-side release,
  - plasma core hit, light flash, sparks and outward kick with an upright collider,
  - drop-target hit, bank clear, multiplier increase and re-arm,
  - left/right flipper motion and ball momentum transfer,
  - slingshot hits with a strong inward/up-table snap,
  - drain → ball countdown → respawn,
  - left and right wall rebound with reversed horizontal velocity,
  - side return guides feeding balls from the side rails back to the flippers,
  - sealed side outlanes; a forced centre drain still starts the countdown and game over,
  - glass ceiling keeping a popped ball under the glass,
  - table-escape recovery preserving the ball count,
  - automatic anti-trap recovery after 3.5 s of no progress,
  - manual **R** and **RECOVER STUCK BALL** recovery preserving score and ball count,
  - three-ball game over, auto-archive, final summary and archive rank,
  - `neon_horizon_scores.json` export and merge import,
  - callsign, audio mute and leaderboard persistence,
  - mobile touch launch and touch flippers,
  - viewport resize 1600×1000 → 768×1024 → 390×844 → 320×568,
  - 60 units/s test shots into the left, right and top walls stay inside the table,
  - a 30-second aggressive random-flipper run with no out-of-table ball or floor fall-through,
  - 25-second random run with no side drains,
  - **0** uncaught exceptions and **0** console errors in the final run.
- Screenshots: `screenshot.png` (1600×1000), `screenshot-mobile.png` (390×844 @2×), `screenshot-start.png` (1600×1000).

## Files

| File | Size |
| --- | ---: |
| `index.html` | 14,025 bytes |
| `style.css` | 44,081 bytes |
| `script.js` | 131,747 bytes |
| `README.md` | 20,104 bytes |
| `screenshot.png` | 841,136 bytes |
| `screenshot-mobile.png` | 779,331 bytes |
| `screenshot-start.png` | 568,146 bytes |

## Credits

Built with [OpenCode](https://opencode.ai) 2.2.5 and **DeepSeek V4.1 Flash** (`opencode-go/deepseek-v4.1-flash`) in a single agent session. The game code, cabinet and playfield geometry, procedural textures, physics tuning, HUD, audio synthesis, score archive, lower-third redesign, anti-trap recovery and verification harness were generated for this project.

Runtime libraries: [Three.js](https://threejs.org/) r128 (MIT) and [Cannon.js](https://schteppe.github.io/cannon.js/) 0.6.2 (MIT). Typefaces: **Orbitron** and **Rajdhani** from Google Fonts (SIL OFL 1.1). No image, texture, audio or 3D model assets were used. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

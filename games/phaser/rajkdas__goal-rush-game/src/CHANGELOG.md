# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-02

### Added
- Pinball × slots hybrid gameplay: Matter.js rigid-body table (flippers, plunger, pop bumpers, slingshots, drop-target bank, spinner, saucer) wired into a slot machine.
- Casino-grade reel math: physical 64-stop reel strips, Web Crypto RNG with rejection sampling (no modulo bias), outcomes decided up-front and animated to land. PAR sheet in `docs/MATH.md`, verified by exact computation plus 2,000,000-spin Monte-Carlo per mode (`docs/RTP-RESULTS.md`).
- Core rules: SPIN saucer captures the ball for a base spin, Golden Bank drop targets award a Golden Spin (jackpot odds 1-in-13), G·O·A·L rollover lanes raise a global multiplier (×2–×5), left-orbit loop awards a FREE SPIN after 5 spinner passes, HAT-TRICK bonus for 3 bumper hits in 3.5 s, progressive jackpot fed by every scoring event.
- Hall of Fame leaderboard: Prisma + SQLite, `GET /api/leaderboard` (top 10), `POST` with zod validation (2–3 char initials) and per-IP rate limiting (1 submit / 5 s), table auto-trimmed to 200 rows.
- Procedural audio via WebAudio synthesis and a runtime texture atlas — zero binary game assets.
- Performance engineering: fixed-timestep physics accumulator (identical ball speed on 60/120/144 Hz), single-draw-call playfield, zero-allocation hot loop, 540×960 portrait-first scaling.
- Input: keyboard, touch (visible neon buttons) and gamepad; 9-second ball save, anti-stuck watchdog with escalating auto-nudges.
- One-click free deploy to Render: `render.yaml` blueprint, `npm run start:cloud` (schema sync → demo leaderboard seed → standalone server), health check on `/api`.
- QA hooks: `window.__goalrush` deterministic bridge, `?debug=1` Matter wireframe overlay, headless e2e driver and physics regression probes in `scripts/`.

[1.0.0]: https://github.com/rajkdas/goal-rush-game/releases/tag/v1.0.0

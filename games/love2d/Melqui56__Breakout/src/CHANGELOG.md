# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Level 4 data (`src/levels.lua`): “Corona final,” preserving the existing
  data-driven numeric codes.
- Enriched HUD (`src/ui.lua`): labeled score, heart-based lives, level badge,
  and boxed messages.

### Changed

- `StrongBrick` now scores 5 points on a damaging first hit and 20 when
  destroyed; destruction-only effects and power-ups are conditional on the
  destroyed state.
- `PowerUp` dimensions, fall speed, spawn centering, and off-screen cleanup
  now use shared `Config` constants.

## [0.2.0] - 2026-09-20

### Added

- AABB collision system (`src/collision.lua`): detection plus axis resolution
  (smallest overlap) and angle-based paddle bounce.
- Reusable finite state machine (`src/statemachine.lua`) with six states
  (`states/title`, `serve`, `play`, `pause`, `gameover`, `victory`).
- `StrongBrick` — inherits from `Brick` and overrides `onHit()` (polymorphism).
- `PowerUp` — multiball, wide paddle and extra life; the effect is a function.
- Data-driven levels (`src/levels.lua`) with three levels.
- Game feel: particles, screen shake, tweening (paddle width, hit flash) and
  sound effects (`assets/*.wav`).
- Sub-stepping in the ball integration to avoid tunneling.
- Shared world rendering (`src/scene.lua`).

### Changed

- `Game` is now a shared world-state module; the FSM lives in `main.lua`.
- `Ball` uses an AABB bounding box and exposes `moveStep` / `launch`.

## [0.1.0] - 2026-09-03

### Added

- Object-oriented architecture for Breakout (Lua / LÖVE 2D).
- Six classes, one per file: `Ball`, `Paddle`, `Brick`, `Level`, `Game`, `UI`.
- Game state machine (title, play, pause, game over) with edge cases
  (ball lost, lives exhausted, level complete).
- Delta-time driven game loop (input → update → render).
- Skeleton scope per assignment: one class per file with correctly signed
  placeholder methods and a runnable LÖVE project that opens a titled window.
- HUD interface (score, lives, level, messages) as placeholder methods.
- Documentation: architecture (UML), state machine, game loop, Lua
  fundamentals, OOP in Lua, design justification.
- Cross-platform environment scripts: `setup.sh` / `setup.ps1`.
- Manual release tooling: `build.sh` / `build.ps1` (portable `.love`,
  Linux tarball, Windows self-contained `.exe`), `RELEASING.md`.
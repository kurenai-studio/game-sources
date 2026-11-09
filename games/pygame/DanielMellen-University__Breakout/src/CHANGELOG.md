# Changelog

## 1.0.0 (unreleased)

First versioned release. The game itself is unchanged from the October 2026 version; this release is about packaging and presentation.

Gameplay, as of this release:

- Random brick fields built from a smoothed noise grid, regenerated every level.
- Rising difficulty: more rows, tougher bricks, and a 5% faster ball each level.
- Multi-hit bricks (1 to 4 hits) with color by remaining durability.
- Five power-ups: slow time, extend platform, extra ball, extra life, and bomb bricks.
- Multiball, paddle-angle bounces, particles, bomb ripples, and the slow-time warp.
- Title, level select (1 to 4), and pause menus with a resume countdown.
- Clean exit when the window is closed.

Project changes:

- Added `requirements.txt` (`pygame>=2.1`), `.gitignore`, and an MIT `LICENSE`.
- Added a gameplay GIF to the README.
- Rewrote the README: badges, demo GIF, features, one-command quick start, controls, architecture diagram, screenshots, limitations, and project structure.

Known limitations: fullscreen only, speed tied to resolution and frame rate, no sound or high scores, and no automated tests or CI yet.

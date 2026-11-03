# Changelog

This changelog tracks notable Glowshift changes.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.0.0] - 2026-10-27

### Added

- Arena gameplay: collect sparks, dodge hunters, dash through them to destroy them.
- Dash kills refill the dash, so kills chain.
- Combo multiplier up to x10 for quick spark pickups, with "COMBO LOST" feedback when a combo of x3 or more runs out.
- Close calls: a hunter that brushes past without touching you scores 5 points times your combo.
- Four hunter types: chaser, dart (telegraphs its path), splitter, and mini. Arrows on the screen edge show where hunters are about to come in.
- Three power-ups: shield, slow time, and magnet.
- A new level every 20 seconds, with faster and more frequent hunters.
- Neon bloom, a spring grid that ripples with explosions, a nebula and parallax star background, and screen effects on hits.
- Sound effects and a synthwave music loop, all synthesized in code. The music builds a slice at a time across the first frames so nothing stalls, including in the browser.
- Keyboard and gamepad controls.
- Settings for sound (`M`), music (`N`), and reduced effects (`V`), saved with your best score.
- Auto-pause when the window loses focus, fullscreen toggle, and a hidden cursor while you play.
- The game over screen names what caught you and shows your run stats.
- macOS, Windows, and Linux downloads with `SHA256SUMS.txt`, plus a browser build on GitHub Pages.
- Headless smoke test, CI, and a tag-driven release workflow.

[Unreleased]: https://github.com/gabrimatic/glowshift/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/gabrimatic/glowshift/releases/tag/v1.0.0

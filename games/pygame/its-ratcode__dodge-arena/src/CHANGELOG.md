# Changelog

All notable changes to Dodge Arena are listed here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-11-08

The first release: a remaster of an earlier single-file prototype, rebuilt as a structured project.

### Gameplay
- Click-to-move dodging (hold to follow the cursor) in an arena that grows more dangerous over two minutes.
- Threats: bolts from every edge, sometimes in pairs, and lasers that warn before they fire.
- Abilities: Shield, Wall and Dash. Utility spells: Sprint and Blink.
- Power-ups: Stasis, Time Warp, Warp, Nova and Coin Rush, one held at a time.
- Coins on the field, a survival bonus, and close calls that pay for risky dodges.
- A shop with eight permanent upgrades, including Second Wind, which saves you from one fatal hit.
  Every level can be sold back for exactly what it cost.

### Interface
- Main menu with your profile, a pause menu and a game over card with your run's numbers.
- An in-game guide with your own key bindings and upgraded numbers, tables and tips.
- Tooltips on the ability bar, confirm dialogs before a run is thrown away, and smooth screen fades.
- Every key rebindable; menus work with mouse or keyboard.
- Interface accent: Cyan (default), Gold or Violet.

### Sound
- Every sound effect and the adaptive soundtrack are generated in code; no audio files.

### Accessibility
- Color modes for deuteranopia, protanopia, tritanopia and high contrast, plus your own colors.
- Threat outlines, reduced flashing, reduced motion and a laser audio cue.
- Assists: slower game speed, longer laser warnings, or no lasers at all.

### Project
- One JSON save file in your user data folder, written safely.
- A test suite of 68 tests, run on every push by GitHub Actions.

[1.0.0]: https://github.com/its-ratcode/dodge-arena/releases/tag/v1.0.0

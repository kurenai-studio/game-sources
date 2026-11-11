# Attribution

- **Name:** Golf Tycoon
- **Upstream:** https://github.com/GolfTycoon/Golf-Tycoon
- **License:** GPL-3.0
- **Commit:** 6ed9d344cc014d9e4beaea98f0a2001a010d653c
- **Collected by:** a
- **Engine:** Godot 4.6 (Forward+)

A playable 2D isometric golf course builder and management game (v0.6.3): design holes, run the club, and host tournaments. Upstream `LICENSE` (GPL-3.0) is copied next to this file and also kept under `src/`. The official Godot 4.6 Linux editor zip shipped in the upstream root (`Godot_v4.6-stable_linux.x86_64.zip`, ~69MB) was omitted from `src/`; use a local Godot 4.6+ install instead.

## Icon

`src/icon.png` (md5 `a363e1c844b676dd6168ce5579255f85`) is a custom pixel-art golfer / wordmark that shipped upstream; it is not the default Godot icon.

## Third-party assets

- **Pixelify Sans** (SIL OFL 1.1) by The Pixelify Sans Project Authors, in `src/assets/fonts/` with `OFL.txt`.
- **Anonymous Pro**, **Courier Prime**, and **Lobster Two** (SIL OFL 1.1) ship with the GUT unit-test addon under `src/addons/gut/fonts/` with `OFL.txt`.
- **Godot Engine logo** on the boot splash: © 2017 Andrea Calabró, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). See `src/assets/ui/GODOT-LOGO-LICENSE.txt`.

Building, golfer, tree, flower and decoration sprites under `src/assets/sprites/` were produced in-repo by `src/tools/building_art/` (documented in `src/docs/systems/course-design/isometric-buildings.md`) and are covered by the project's GPL-3.0 license. Sound is generated procedurally by `src/scripts/audio/procedural_audio.gd` (no third-party music or SFX files).

## Engine

Godot Engine (MIT), https://godotengine.org/license/

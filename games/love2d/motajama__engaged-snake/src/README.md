# divadelni-utopie

`divadelni-utopie` is a data-driven Love2D / LÖVE 11.x snake game built so the engine and the content pack can evolve separately. The current version includes a playable vertical slice, Wolf3D-style menu and stats presentation, localized story content, mobile touch controls, and safe placeholder assets when files are missing.

Credit line: `design&concept->motajama coding->Codex @ GPL3 2026`

## Features

- Logical game space `320x240`, default window `640x480`, nearest-neighbor scaling
- Dataset-driven title, subtitle, gameplay tuning, levels, HUD quotes, food metadata, colors, and localization
- Dataset-driven title screen plus intro, game-over, and victory screen images/text keys
- Per-level backgrounds, per-level food types, and per-level color themes
- Dataset-configurable UI fonts with safe fallback to built-in fonts
- `cs` and `en` localization loaded from JSON
- Keyboard, mouse, touch, and configurable virtual controls
- Wolf3D-style text-pointer main menu and difficulty selection
- Animated end-of-level stats screen with generated SFX fallbacks
- Save/load for settings and highscores through `love.filesystem`
- Optional online score upload through the PHP backend in `backend/`
- Online high-score display with local fallback when the score server is unavailable
- Embeddable JavaScript/CSS top-5 score widget for external pages
- Color and monochrome CRT video modes
- Browser-export-friendly Lua; desktop online score upload uses LuaSocket/LuaSec, and web export uses a browser `fetch` bridge

## Run

```sh
love .
```

Or:

```sh
make run
```

## Checks

```sh
make check
```

This runs `luac -p` over the Lua sources.
It also decodes the bundled dataset/localization JSON and runs the pure-Lua regression specs in `tests/`.

## Controls

- Move: arrow keys or `WASD`
- Confirm: `Enter` or `Space`
- Back: `Escape`
- Mouse/touch: menu selection, story skip, stats continue
- Touch gameplay controls:
  auto-hidden on desktop by default
  enabled automatically on Android/iOS
  can be forced `ON` or `OFF` in Settings

## Game Flow

1. Boot
2. Intro
3. Main menu
4. Difficulty selection
5. Story screen
6. Gameplay
7. Animated level stats
8. Next level or victory

## Project Layout

- `src/core/`: engine services, save/settings/localization/renderer/audio
- `src/states/`: state-machine screens and flows
- `src/systems/`: gameplay systems and UI helpers
- `src/util/`: small pure-Lua helpers
- `datasets/base/`: replaceable content pack
- `backend/`: optional PHP/MySQL score backend, public scoreboard, JSON endpoint, and embeddable widget

## Dataset Authoring

See [DATASET.md](DATASET.md) for the dataset format, required JSON fields, localization workflow, theming, fonts, and asset rules.

## Web Export

See [WEB.md](WEB.md) for a step-by-step guide to:

- build a `.love` package
- export the game for the browser with `love.js`-style tooling
- host it as a standalone webpage
- embed it into an existing website

## Online Scores

See [ONLINE_SCORES.md](ONLINE_SCORES.md) for the MySQL schema, PHP backend setup, password-hash generation, desktop LuaSocket/LuaSec runtime setup, web export setup, client config, public scoreboard page, and embeddable top-5 widget.

## Credits And License

`design&concept->motajama coding->Codex @ GPL3 2026`

The project is distributed under GPL-3.0. See [LICENSE](LICENSE).

## Notes

- Missing PNGs and SFX should not crash the game; the engine falls back to generated placeholder visuals and generated tones.
- New content should be added through the dataset and language JSON files whenever possible rather than by hardcoding strings in Lua.
- The current sample dataset is intentionally small and serves as a reference pack.

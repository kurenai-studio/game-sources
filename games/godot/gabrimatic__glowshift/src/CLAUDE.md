# Glowshift

Godot 4.7.2 arena game, all procedural: no image, texture, or audio assets in the game. Gameplay and drawing live in `main.gd` (`_draw()`), sound in `scripts/synth.gd`, saved settings in `scripts/settings.gd`, effects in `shaders/`. `assets/` holds README images only and is excluded from exports.

## Commands

- `make run`, `make test` (must print `SMOKE OK`, exit 0, no `SCRIPT ERROR`), `make export`, `make serve` (web build at `http://127.0.0.1:8060`).
- Export templates: `~/Library/Application Support/Godot/export_templates/4.7.2.stable`.
- Release: update `CHANGELOG.md`, `config/version` in `project.godot`, and the macOS versions in `export_presets.cfg`, then push a `vX.Y.Z` tag. `.github/workflows/release.yml` re-runs CI, checks versions, exports four platforms, publishes the release with `SHA256SUMS.txt`, and deploys the web build to GitHub Pages.
- README hero GIF: record with Godot movie mode (`--write-movie` with an auto-play script and `grain` set to 0 on `post_mat`), then encode with ffmpeg at about 760px, 15 fps, 112 colors.

## Rules

- Inner classes must not shadow Godot native class names (`Popup` broke the parse once).
- Polygons passed to `draw_colored_polygon` must not self-intersect.
- Glow comes from HDR colors (channels above 1.0) with `rendering/viewport/hdr_2d`; keep HUD text below the glow threshold. The web build (Compatibility renderer) has no bloom, so `soft_glow` draws halo strokes instead; check both.
- Tests set `game.persist = false` so they never write the player's `settings.cfg`.
- `build/` and `.godot/` are generated; `*.import` and `*.uid` files are committed.

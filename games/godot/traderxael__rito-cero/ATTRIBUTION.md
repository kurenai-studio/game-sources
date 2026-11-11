# Attribution

- **Name:** rito cero
- **Upstream:** https://github.com/traderxael/rito-cero
- **License:** MIT
- **Commit:** 34631b6de2058d91dace0675642aa6f974ef06b2
- **Collected by:** a
- **Engine:** Godot 4

A playable 3D action game: you explore an open world as Rito, a Roman character, with melee and thrown weapons, missions, pickups, a companion moloso, caves, and a tech/inventory board. Upstream `LICENSE` is copied next to this file and also kept under `src/`. See also `src/THIRD_PARTY.md`.

## Icon

`src/icon.svg` (md5 `84774114ce019e130d39fba3058a22cf`) is an original galea-and-crest mark made for this snapshot, replacing the default Godot icon that shipped upstream.

## Third-party assets

- `src/` Quaternius models and animations — @Quaternius, CC0 1.0 (`src/License.txt`)
- Terrain textures Ground037 and Rock023, and related Terrain3D demo rocks/tunnel props under `src/demo/` — ambientCG / Terrain3D demo assets, CC0 1.0 (`src/demo/assets/textures/asset_licenses.txt`). The game world builder loads some of these via `res://demo/...`.

## Addons

- `src/addons/terrain_3d/` — Terrain3D, MIT, Copyright (c) 2023-2026 Cory Petkovsek, Roope Palmroos, and Contributors (`src/addons/terrain_3d/LICENSE.txt`)
- `src/addons/kanban_tasks/` — Kanban Tasks, MIT, Copyright (c) 2022-2026 HolonProduction (`src/addons/kanban_tasks/LICENSE`)

## Fonts and audio

No custom fonts or audio files are bundled.

## AI-generated art

Upstream design doc `docs/superpowers/specs/2026-11-02-rito-cero-web-design.md` (§7 "Arte generado con IA") states that these two images were generated with `ImageGen` (appearance notes in §6.5). The character sheet was then post-processed locally with Pillow.

- `src/assets/rito_face.png` (md5 `b31a9a2462fcbb58387e38006fe10193`) — AI-generated frontal portrait used as the character face texture
- `src/assets/rito_sheet.png` (md5 `2916dd446c99607ccda7f579163b92be`) — AI-generated full-body character sheet used for the boot overlay

## Engine

Godot Engine (MIT), https://godotengine.org/license/

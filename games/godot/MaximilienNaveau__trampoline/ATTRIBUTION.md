# Attribution

- **Name:** trampoline ("Un jeu pour faire rebondir les mots")
- **Upstream:** https://github.com/MaximilienNaveau/trampoline
- **License:** GPL-3.0-only
- **Commit:** da4bd4c87bd7708ab15c11a3e2586d8e83cc20db
- **Collected by:** a
- **Engine:** Godot 4.7

A released word / crossword game by Michel Cheenne (rules and crosswords) and Maximilien Naveau (Godot implementation). Upstream `NOTICE` and `LICENSE` are copied next to this file and also kept under `src/`.

## Art

Board, box-lid, ribbon, menu, and splash textures / icons in `src/assets/` are original work by the authors (ImageMagick-generated paintings and hand-written SVGs), covered by the project's GPL-3.0-only license. `src/assets/icon/desktop_icon.png` (md5 `0b6f8c37485a18503ee19ad660d6c573`) is the upstream custom project icon.

`src/assets/textures/godot_logo.svg` is the Godot Engine logo by Andrea Calabró, CC BY 4.0, copied from Godot 4.7.1 and shown on the loading splash to credit the engine.

## Fonts

- `src/assets/fonts/Caveat-Variable.ttf` — Caveat, SIL Open Font License 1.1 (`Caveat-OFL.txt`)
- `src/assets/fonts/Jost-Variable.ttf` — Jost, SIL Open Font License 1.1 (`Jost-OFL.txt`)

## Dictionary

`src/data/dictionaries/` contains a French word list derived from the Dicollecte "Classique" dictionary by Olivier R., Mozilla Public License 2.0 (`src/data/dictionaries/README_dict_fr.txt`).

## Audio

Instrument samples used to build the game's music are not present in this snapshot; upstream fetches them at build time. See `src/tools/audio/README.md` and `NOTICE`.

## Omitted

`src/keys/debug.keystore` (a documented public Android debug signing key; password is the standard "android") was omitted from this snapshot. `src/keys/README.md` and `.gdignore` were kept.

## Engine

Godot Engine (MIT), https://godotengine.org/license/

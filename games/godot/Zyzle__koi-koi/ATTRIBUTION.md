# Attribution

- **Name:** Koi-koi (こいこい)
- **Upstream:** https://github.com/Zyzle/koi-koi
- **License:** GPL-3.0
- **Commit:** 0ef8f866460b7e2277ad92579b33a9c7d662337b
- **Collected by:** a
- **Engine:** Godot 4.5 (Forward+)

A playable implementation of the Japanese hanafuda card game Koi-Koi, with a main menu, capture/scoring (yaku) UI, win/lose flow, and an MCTS computer opponent. Upstream `LICENSE` (GPL-3.0) is copied next to this file and also kept under `src/`. The unused GUT unit-test submodule (`Gut`, SSH URL `git@github.com:bitwes/Gut.git`) and its `addons/gut` symlink were omitted from `src/`; they are not required to play the game.

## Icon

`src/assets/icon.png` (md5 `6d6454342ef15b6b33a6878f23f954cf`) is the custom app icon referenced by `project.godot` (`config/icon`, uid `uid://baswp1dqo8x30`). A leftover default Godot `icon.svg` is still present under `src/assets/` but is not used as the application icon.

## Third-party assets

- **Hanafuda card artwork** under `src/art/`: derivative of work by [Louie Mantia](https://commons.wikimedia.org/wiki/User:Louiemantia), [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). See `src/art/README.md` and the upstream README.
- **Sour Gummy** (SIL OFL 1.1) by Stefie Justprince / The Sour Gummy Project Authors, in `src/assets/SourGummy-VariableFont_wdth,wght.ttf`.
- **Zen Maru Gothic Black** (SIL OFL 1.1) by Yoshimichi Ohira / The Zen Maru Gothic Authors, in `src/assets/ZenMaruGothic-Black.ttf`.

Additional original artwork in the game is by the upstream author and is covered by the project's GPL-3.0 license.

## Engine

Godot Engine (MIT), https://godotengine.org/license/

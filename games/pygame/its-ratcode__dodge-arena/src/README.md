# Dodge Arena

[![tests](https://github.com/its-ratcode/dodge-arena/actions/workflows/tests.yml/badge.svg)](https://github.com/its-ratcode/dodge-arena/actions/workflows/tests.yml)
![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue)
![Windows](https://img.shields.io/badge/platform-Windows-lightgrey)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A fast-paced top-down arena dodging game built with Python and pygame.
Every shape is drawn and every sound is synthesized in code: no image or audio files.

## Demo

https://github.com/user-attachments/assets/b1e90ea2-38fc-4b24-97b0-cdd1e8dcd081

## About this version

Dodge Arena 1.0 is a remaster of an earlier prototype of mine, a single-file pygame dodge game.
The core idea is the same; this version rebuilds it as a structured, documented project with a new
interface, synthesized sound and music, accessibility options, measured balance and a test suite.

## How to play

The full guide is in the game: **How to play** on the main menu or the pause menu (key H).
It always shows your current keys and the game's real numbers.

Bolts fly in from every edge, each one aimed at where you stood when it appeared.
Lasers sweep across the whole arena: a pink lane warns you first, then the beam fires.
Keep moving: one hit ends the run. Survive as long as you can.

Danger rises from 0% to 100% over two minutes: bolts get faster and more frequent,
sometimes come in pairs, and lasers fire more often with shorter warnings.

Three abilities help you survive, each aimed with the mouse cursor and on its own cooldown:

| Ability | Effect |
|---|---|
| Shield | A bubble that blocks the next hit (bolt or laser) for 1.5 s |
| Wall | A wall in front of you, across the cursor direction, that destroys bolts for 3 s. Lasers pass through |
| Dash | A fast 200 px dash toward the cursor. You can still be hit on the way |

Two utility spells have long cooldowns, so keep them for emergencies:

| Utility spell | Effect |
|---|---|
| Sprint | +50% movement speed for 3 s |
| Blink | Instantly teleport toward the cursor, up to 220 px. Cancels a dash |

## Power-ups

Every so often a power-up appears on the map (one at a time; it blinks before it vanishes).
Walk over it to pick it up, then press Space to use it. It has one use and expires 25 s after pickup.

| Power-up | Effect |
|---|---|
| Stasis | Frozen in place for 1.5 s: nothing can hit you, but you can't move or cast |
| Time Warp | Bolts, lasers and their spawning slow to 40% for 3 s. You keep your speed |
| Warp | A long Blink, up to 320 px toward the cursor |
| Nova | Destroys every bolt and laser on screen, even lasers still warning |
| Coin Rush | For 8 s coins spawn ~3x as often, more fit on the field, and each is worth double |

## Coins and upgrades

Coins appear around the arena and vanish after 8 s (they blink first). Big coins are worth 5.
At the end of a run you also get 1 coin for every 5 s you survived, and every **close call**
(a bolt or laser passing within 26 px without hitting you) is worth 1 coin.

Spend coins in the **Shop** (from the main menu or the game over screen) on permanent upgrades.
Selling a level refunds exactly what it cost, and "Refund all" resets your build:

| Upgrade | Per level | Max |
|---|---|---|
| Swift Boots | +5% movement speed | 5 |
| Ability Haste | -6% Shield / Wall / Dash cooldowns | 5 |
| Thick Bubble | +0.3 s Shield | 4 |
| Long Wall | +25 px Wall length | 4 |
| Long Sprint | +0.5 s Sprint | 4 |
| Far Blink | +30 px Blink range | 3 |
| Coin Magnet | +40 px coin pull radius | 4 |
| Second Wind | Survive one fatal hit, then 1.5 s untouchable. Recharges in 120 s, 30 s less per extra level | 3 |

Progress and settings are saved to `save.json` in your user data folder. Delete it to start over:

| OS | Folder |
|---|---|
| Windows | `%APPDATA%\Dodge Arena` |
| macOS | `~/Library/Application Support/Dodge Arena` |
| Linux | `~/.local/share/Dodge Arena` (or `$XDG_DATA_HOME/Dodge Arena`) |

## Accessibility

Everything is in **Settings** and saved right away:

| Tab | Options |
|---|---|
| Accessibility | Color modes (Deuteranopia, Protanopia, Tritanopia, High contrast), your own color for the player, bolts and lasers, threat outlines, reduce flashing, reduced motion |
| Gameplay | Game speed (50-100%), laser warning time (100-200%), lasers on/off, starting danger, pause on focus loss, frame rate |
| Display | Screen shake, movement path preview, control hints (your keys in the top-left corner), interface accent (Cyan, Gold or Violet) |
| Audio | Master, sound effect and music volume, adaptive music, menu sounds, laser audio cue (beeps and a charge-up before lasers fire) |

Every sound and the music are synthesized in code when the game starts: there are no sound files.
The soundtrack is adaptive: it gains layers (drums, arpeggio, lead) as danger rises.
Without an audio device the game simply runs silently.

Runs with a slower game speed, longer laser warnings or lasers turned off still earn coins but don't set best times.

## Getting started

Requires Python 3.10+ on Windows. The game is designed for Windows: on macOS or Linux it runs,
but uses different fonts, so some text may not fit exactly.

Run it straight from the folder:

```bash
pip install -r requirements.txt
python -m app
```

Or install it, which adds a `dodge-arena` command:

```bash
pip install .
dodge-arena
```

Your progress and settings are saved in `%APPDATA%\Dodge Arena\save.json`. Delete that file to start over.
See [CHANGELOG.md](CHANGELOG.md) for what each version contains.

## Controls

These are the defaults. Every key and the move button can be changed in **Settings**
(click a control, then press the new key; a key already in use swaps places with it).

| Input | Action |
|---|---|
| Right-click | Walk to the clicked point |
| Hold right-click | Keep following the cursor |
| Q / W / E | Shield / Wall / Dash (toward the cursor) |
| D / F | Sprint / Blink (toward the cursor) |
| Space | Use the held power-up |
| Esc | Pause / resume (the game also pauses when its window loses focus) |
| R | Play again (game over) / restart (pause menu) |

Menus work with the mouse or the keyboard: arrows (or Tab) to choose, Enter or Space to confirm,
arrow keys move between cards in the shop, and the key shown on a button triggers it directly
(S = shop, M = main menu, Esc = back). Restart, Main menu and Quit game in the pause menu ask
before ending your run. Leaving a run early still banks the coins you picked up.

## Running the tests

```bash
pip install -r requirements-dev.txt
python -m pytest
```

The tests run in a hidden window with no sound, so they also work on a server without a screen.
Each test uses its own temporary save file and never touches your progress.

| File | What it checks |
|---|---|
| `tests/test_world.py` | Hits, Shield, Second Wind, walls, lasers, close calls, coins, danger, power-ups |
| `tests/test_skills.py` | Cooldowns, Ability Haste, Blink and Dash distances, tooltip numbers |
| `tests/test_progression.py` | Upgrade prices, refunds, best times, and the balance rules |
| `tests/test_settings.py` | Defaults, saving, key rebinding, cleaning up hand-edited files |
| `tests/test_storage.py` | The save file: missing, broken, and safe writes |
| `tests/test_scenes.py` | Menus, pause, shop, settings and guide, driven with keys and clicks |
| `tests/test_utils.py` | Time format and collision shapes |

GitHub Actions runs them on every push (see the badge at the top).

## License

[MIT](LICENSE) © 2026 RatCode

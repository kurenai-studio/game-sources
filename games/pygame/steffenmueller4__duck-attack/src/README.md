# duck-attack
A small Pygame where you need to shoot ducks.

## Download

Ready-to-play builds for Windows and macOS (no Python needed) are attached to the
[GitHub Releases](https://github.com/steffenmueller4/duck-attack/releases):

- **Windows:** `DuckAttack-<version>-windows-x64.zip`. Unzip it and start
  `DuckAttack\DuckAttack.exe` (keep the folder together).
- **macOS:** `DuckAttack-<version>-macos-arm64.zip` (Apple Silicon) or `-macos-intel.zip`
  (Intel). Unzip it and move `DuckAttack.app` to Applications.

The builds are not code-signed yet, so the system warns the first time:

- **Windows** ("Windows protected your PC"): click "More info", then "Run anyway".
- **macOS** ("cannot be opened" / "not verified"): open the app once, then go to System
  Settings → Privacy & Security and click "Open Anyway". Alternatively run
  `xattr -dr com.apple.quarantine /Applications/DuckAttack.app` once.

## Setup

Requires Python 3.12+ (developed on 3.14). The repo's `.python-version` points at a
pyenv virtualenv named `duck_attack_venv`:

```sh
pyenv virtualenv 3.14.2 duck_attack_venv   # once; activates automatically in this folder
pip install -r requirements-dev.txt
```

Without pyenv, any virtualenv works:

```sh
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Run

```sh
duck-attack          # or: python -m duck_attack
```

Press `Esc` or close the window to quit.

## How to play

Before each round, type your name and press `Enter` (or click) to start. The name is
remembered, so next time it is already filled in and one `Enter` or click is enough.

Aim with the crosshair and click ducks to shoot them; every shot goes bang. A round lasts
30 seconds; the time left is shown top-left (red in the last 10 seconds), your score
top-right.

Ducks fly in at random distances. Close (big) ducks are worth 10 points; farther (smaller)
ones are worth more, up to 30. Every missed shot costs 5 points, so the score can go
negative. Duck calls play in the background from time to time.

After the round, your score is shown for 10 seconds, followed by the top-10 high-score
list with player names (your round is highlighted). Click to get back to the name entry
for the next round.

High scores are saved in `~/.duck-attack/highscores.json`, the last player name in
`~/.duck-attack/player.txt`. Delete the files to reset them.

Round length, points, duck size/speed, sound volume and more can be tuned in
`src/duck_attack/settings.py`.

## Develop

The game's behavior is specified in [`specs/`](specs/README.md), one file per capability
with numbered requirements. New features start as a change proposal in `specs/changes/`
(copy `TEMPLATE.md`), are discussed there, then implemented and folded into the specs.

```sh
pytest               # tests (run headless)
ruff check .         # lint
ruff format .        # format
```

Dependabot (`.github/dependabot.yml`) opens weekly pull requests that bump the pinned
Python packages in `requirements*.txt` and the GitHub Actions used by the workflows.

## Build packages

The apps are built with [PyInstaller](https://pyinstaller.org) from
`packaging/duck_attack.spec`. PyInstaller can't cross-compile, so build on the target OS:

```sh
pip install -r requirements-package.txt
pyinstaller packaging/duck_attack.spec --noconfirm
```

This creates `dist/DuckAttack/` (Windows: `DuckAttack.exe` plus its libraries) or
`dist/DuckAttack.app` (macOS). After changing the duck image, regenerate the app icon
with `python packaging/make_icon.py`.

GitHub Actions (`.github/workflows/release.yml`) builds Windows x64, macOS Apple Silicon
and macOS Intel and smoke-tests each build:

- **Test build:** Actions → Release → "Run workflow"; the zips appear as artifacts of the run.
- **Release:** bump `version` in `pyproject.toml`, then push a matching tag, e.g.
  `git tag v0.2.0 && git push origin v0.2.0`. The workflow creates the GitHub Release
  with the three zips. If the release already exists (e.g. created in the GitHub UI, or
  the workflow is re-run), it only uploads the zips to it, replacing older ones.

## Layout

```
src/duck_attack/
  __main__.py        entry point
  game.py            main loop and round flow (name -> playing -> round over -> high scores)
  settings.py        tunable constants
  duck.py            duck sprite: flight, distance/size, hit test, points
  crosshair.py       crosshair mouse cursor
  hud.py             score and timer display, text rendering
  screens.py         name-entry, round-over and high-score screens
  highscores.py      high-score list (JSON file)
  player.py          remembered player name (text file)
  sounds.py          shot sound and ambient duck calls
  assets/images/     background, duck, crosshair
  assets/sounds/     shot sound and ambient duck calls
tests/               pytest tests
specs/               behavior specs; specs/changes/ holds feature proposals
packaging/           PyInstaller spec, launcher script and app icon
.github/             CI (lint + tests), release builds, Dependabot
```

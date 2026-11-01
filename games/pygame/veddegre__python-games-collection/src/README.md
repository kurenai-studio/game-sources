# Games Collection

A collection of 15 arcade and puzzle games built with Python and pygame. Windows and macOS users can grab a pre-built release and play straight away. Linux users and anyone who prefers running from source just need Python and pygame.

![Python](https://img.shields.io/badge/Python-3.8%2B-blue) ![pygame](https://img.shields.io/badge/pygame-2.0%2B-green) ![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)

---

## Screenshots

<p align="center">
  <img src="screenshots/menu.png" alt="Menu" width="800"/>
  <br/><em>Main Menu</em>
</p>

| | | |
|:---:|:---:|:---:|
| <img src="screenshots/dodge_game.png" alt="Dodge Game" width="260"/> | <img src="screenshots/snake.png" alt="Snake" width="260"/> | <img src="screenshots/space_asteroids.png" alt="Space Asteroids" width="260"/> |
| <p align="center">Dodge Game</p> | <p align="center">Snake</p> | <p align="center">Space Asteroids</p> |
| <img src="screenshots/space_defenders.png" alt="Space Defenders" width="260"/> | <img src="screenshots/helicopter_dash.png" alt="Helicopter Dash" width="260"/> | <img src="screenshots/hyper_bounce.png" alt="Hyper Bounce" width="260"/> |
| <p align="center">Space Defenders</p> | <p align="center">Helicopter Dash</p> | <p align="center">Hyper Bounce</p> |
| <img src="screenshots/stack_attack.png" alt="Stack Attack" width="260"/> | <img src="screenshots/maze_explorer.png" alt="Maze Explorer" width="260"/> | <img src="screenshots/mine_field.png" alt="Mine Field" width="260"/> |
| <p align="center">Stack Attack</p> | <p align="center">Maze Explorer</p> | <p align="center">Mine Field</p> |
| <img src="screenshots/sudoku.png" alt="Sudoku" width="260"/> | <img src="screenshots/hangman.png" alt="Hangman" width="260"/> | <img src="screenshots/2048.png" alt="2048" width="260"/> |
| <p align="center">Sudoku</p> | <p align="center">Hangman</p> | <p align="center">2048</p> |
| <img src="screenshots/solitaire.png" alt="Solitaire" width="260"/> | <img src="screenshots/spider_solitaire.png" alt="Spider Solitaire" width="260"/> | <img src="screenshots/tripeaks.png" alt="TriPeaks" width="260"/> |
| <p align="center">Solitaire</p> | <p align="center">Spider Solitaire</p> | <p align="center">TriPeaks</p> |

---

## Games

### Action
| Game | Description | Controls |
|------|-------------|----------|
| **Dodge Game** | Dodge falling objects. Speed increases with score. | ← → arrows |
| **Snake** | Eat fruit and grow. Don't hit yourself. | Arrow keys |
| **Space Asteroids** | Shoot rotating asteroids before they hit you. | ← →, Space to shoot |
| **Space Defenders** | Waves of enemies. Watch for the boss at 20pts! | ← →, Space to shoot |
| **Helicopter Dash** | Hold to thrust through a twisting cave. Gaps are sized for the helicopter—no impossible pinch points. | Hold Space or click, R to restart |
| **Hyper Bounce** | Smash energy cells with an electric ball across 8 unique levels. | ← →, Space to launch |

### Puzzle
| Game | Description | Controls |
|------|-------------|----------|
| **Stack Attack** | Stack falling blocks and clear rows. Deep space theme with hold piece and combos. | Arrows, Space, C hold, P pause |
| **Maze Explorer** | Room-style mazes with one route; finish in as few moves and as little time as possible. | Arrow keys, R to restart |
| **Mine Field** | Clear the minefield. First click is always safe. | Left click, right click to flag |
| **Sudoku** | Fill the grid. Every row, column and box needs 1–9. Three difficulty levels. | Click cell, type number |
| **Hangman** | Guess the word before the man is hung. Easy, Medium and Hard word lists. | Type letters or click keyboard |
| **2048** | Merge tiles to reach 2048. Simple to learn, hard to master. | Arrow keys or WASD |

### Cards
| Game | Description | Controls |
|------|-------------|----------|
| **Solitaire** | Classic Klondike. Build foundations from Ace to King. | Click to move, double-click to foundation |
| **Spider Solitaire** | Build 8 K-to-A runs. Choose from 1, 2 or 4 suit difficulty. | Click to select and move |
| **TriPeaks** | Clear three peaks by playing cards ±1 from the waste pile. | Click free cards |

Most games save **high scores** (higher is better). **Maze Explorer** tracks **fewest moves** and **fastest time** (lower is better). **Mine Field** tracks **best completion time**. All games support **ESC to return to the menu** and **R to restart** where noted above.

### Score management

From the main menu, click **Manage scores** (top right) to:

- View each game’s saved score on the panel
- **Reset** an individual game (including related keys, e.g. maze moves and maze time)
- **Reset all** scores at once

Packaged builds store scores and logs under your platform user folder (see [RELEASE_TESTING.md](RELEASE_TESTING.md#log-and-data-file-locations)). Source installs use `scores.json` in the repo directory.

---

## Recent updates (v1.5.4)

- **Maze Explorer** — Recursive-division mazes; picks the longest start→goal layout among many candidates. Scores fewest moves and best time (not highest).
- **Helicopter Dash** — Rotor-sized collision box, minimum gap between cave walls, segment overlap checks so transitions are always passable; fixed crash when generating segments.
- **Menu** — **Manage scores** UI (per-game and reset all); control hints wrap instead of clipping; game tiles show correct labels for time-based and move-based bests.
- **High scores** — `save_low_score` / `get_low_score`, `clear_score` / `clear_all_scores`, legacy mine-field key migration (`minesweeper` → `minesweeper_time`).
- **Launcher** — `game_runtime.py` handles source subprocess launch vs packaged in-process exec, logging, and user data paths; fast menu restore after games exit.
- **Tests** — `tests/test_game_runtime.py` (path safety, migration), `tests/test_highscores.py` (save/clear logic).

---

## Requirements

- Python 3.8 or newer
- pygame 2.0 or newer

---

## Installation

macOS (Homebrew Python) and many Linux distros **block** `pip install` into the system Python ([PEP 668](https://peps.python.org/pep-0668/)). Use the project virtual environment instead.

**Python version:** Use **3.8 through 3.13**. **Python 3.14 is not supported** — pygame installs but `pygame.font` is missing. On Mac with Homebrew: `brew install python@3.11` then `./setup.sh`.

```bash
# 1. Clone the repo
git clone https://github.com/veddegre/python-games-collection.git
cd python-games-collection

# 2. One-time setup (creates .venv/ and installs pygame)
chmod +x setup.sh GameCollection.command
./setup.sh

# 3. Run
./GameCollection.command
```

**Windows:** run `setup.bat` once, then `GameCollection.bat`.

**Manual venv (optional):**

```bash
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
python -m pip install -r requirements.txt
python -B run.py
```

Do **not** use `brew install pygame` — there is no Homebrew formula for pygame.

---

## Running

### Command line
```bash
python run.py
```

Any game can also be launched standalone:
```bash
python snake_game.py
python sudoku.py
python hyper_bounce.py
# etc.
```

### Linux desktop shortcut

To add Games Collection to your application menu or desktop:

```bash
# Make the launcher executable
chmod +x GameCollection.command

# Copy the .desktop file to your applications menu
cp GameCollection.desktop ~/.local/share/applications/

# Or place a shortcut on your desktop
cp GameCollection.desktop ~/Desktop/
chmod +x ~/Desktop/GameCollection.desktop
```

You may need to edit `GameCollection.desktop` first to set the correct path:
```bash
# Open it and update the Exec and Icon paths to match where you put the folder
nano GameCollection.desktop
```

The relevant lines to update:
```
Exec=python3 /path/to/games-collection/run.py
Icon=/path/to/games-collection/icon.png
Path=/path/to/games-collection
```

### Pre-built releases (Windows and macOS)

Head to the [Releases page](https://github.com/veddegre/python-games-collection/releases) and download the file for your platform.

**Maintainers:** Before tagging a release, complete the [pre-release validation checklist](RELEASE_TESTING.md). Do not tag unless packaged Windows and macOS builds pass all required lifecycle tests.

**Windows**
1. Download `GamesCollection-setup.exe`
2. Your browser may warn the file "isn't commonly downloaded" — click the **...** menu next to the file and choose **Keep**
3. A second prompt may appear — click the arrow next to **Delete** and select **Keep anyway**
4. Run the installer and follow the wizard (Next → Next → Install → Finish)
5. A shortcut appears on your Desktop and in the Start Menu under **Games Collection**
6. To uninstall: Start Menu → Games Collection → Uninstall, or via Add/Remove Programs

**macOS**
1. Download `GamesCollection-mac.dmg`
2. Double-click to open the disk image — a window appears with the app and an Applications folder
3. Drag **GamesCollection** into the **Applications** folder
4. Eject the disk image (drag it to Trash or press Cmd+E)
5. Go to Applications and double-click **GamesCollection**
6. First launch only: macOS will say it can't verify the developer. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**
7. After that it opens normally

**Linux**
No pre-built app is available for Linux. Follow the Installation steps below — you just need Python and pygame.

---

## Project structure

```
python-games-collection/
├── run.py                      ← source entry point (imports menu)
├── menu.py                     ← main menu, game grid, score UI; PyInstaller entry for releases
├── game_runtime.py             ← launch (subprocess vs in-process), logging, scores path, icons
├── highscores.py               ← load/save scores, best time, low score, clear helpers
├── RELEASE_TESTING.md          ← pre-release checklist (packaged + source tests)
│
├── tests/
│   ├── test_game_runtime.py    ← resolve_game_path, subprocess cmd, score migration
│   └── test_highscores.py      ← high/low score save, clear, best time
│
├── .github/workflows/
│   └── build.yml               ← tagged releases → macOS DMG + Windows installer
│
├── Action games
│   ├── dodge_game.py
│   ├── snake_game.py
│   ├── space_asteroids.py
│   ├── space_defenders.py
│   ├── helicopter_dash.py
│   └── hyper_bounce.py
│
├── Puzzle games
│   ├── stack_attack.py
│   ├── maze_explorer.py
│   ├── mine_field.py
│   ├── sudoku.py
│   ├── hangman.py
│   └── game2048.py
│
├── Card games
│   ├── solitaire.py
│   ├── spider_solitaire.py
│   └── tripeaks.py
│
├── words_easy.txt              ← Hangman word lists
├── words_medium.txt
├── words_hard.txt
│
├── screenshots/                ← menu and game screenshots (README)
│
├── icon.png                    ← window / packaging icon
├── icon.bmp                    ← macOS-friendly window icon fallback
├── app.manifest                ← Windows UTF-8 manifest (card suit symbols)
├── GamesCollection.spec        ← PyInstaller spec (CI / local builds)
├── requirements.txt
├── setup.sh                    ← macOS/Linux venv + pygame (Python 3.8–3.13)
├── setup.bat                   ← Windows venv + pygame
├── GameCollection.command      ← macOS source launcher
├── GameCollection.bat          ← Windows source launcher
├── GameCollection.desktop      ← Linux desktop entry template
└── .gitignore                  ← excludes scores.json, .venv, __pycache__
```

`scores.json` is created on first play and is gitignored — each player keeps their own scores. Packaged apps use the user data directory instead (see [RELEASE_TESTING.md](RELEASE_TESTING.md)).

### Running tests

```bash
python3 -B -m unittest discover -s tests -v
```

Same command is used in CI and in [RELEASE_TESTING.md](RELEASE_TESTING.md) before tagging a release.

---

## Notes

- **Windows SmartScreen** — Your browser may flag the download as uncommon. Click **...** → **Keep**, then the arrow next to Delete → **Keep anyway**. The app is safe — it just isn't commercially signed.
- **macOS Gatekeeper** — If blocked on first launch, go to **System Settings** → **Privacy & Security** → scroll to **Allow applications from** and click **Open Anyway**.
- **Scores** — Packaged builds: `~/Library/Application Support/GamesCollection/` (macOS) or `%APPDATA%\GamesCollection\` (Windows). Source: `scores.json` in the repo. Use **Manage scores** on the menu to reset after upgrades if old maze entries look wrong (pre-v1.5.4 saved highest move count by mistake).
- **Logs** — Packaged and source subprocess runs write to `games_collection.log` in the same user data folder (or repo when running from source).
- **`__pycache__`** is suppressed via `python -B` in the launcher scripts.
- **Icons** — Games load `icon.bmp` or `icon.png` for the window. The bundled Mac `.app` uses the packaged icon; source runs may show the Python Dock icon unless launched via `GameCollection.command`.

---

## About this project

This started as a personal project to mess around with Python and AI-assisted coding and ended up as something my kids and I could actually sit down and play together without needing wifi, a subscription, or an app store. Nothing fancy, just a bunch of games that run locally and don't phone home.

If you find it useful, fun, or want to build on it, go for it.

---

## Disclaimer

This is a hobby project made for personal and family use. It's provided as-is — no guarantees, no warranties, no support obligations. Run it at your own risk, though the worst that's likely to happen is a Python error.

---

## License

MIT — do whatever you like with it.

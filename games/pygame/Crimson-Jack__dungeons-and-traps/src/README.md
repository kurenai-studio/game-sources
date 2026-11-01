# Dungeons and Traps: Willy's First Adventure

[![Tests](https://github.com/Crimson-Jack/dungeons-and-traps/actions/workflows/tests.yml/badge.svg)](https://github.com/Crimson-Jack/dungeons-and-traps/actions/workflows/tests.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Simple maze game with a view - from the top. The hero can move blocks and explore new terrain. He fights with monsters, collects keys and diamonds.
The goal: teaching how to create a simple game, Pygame exploratory, checking features.

### Screenshots

<p align="center">
  <img src="screenshots/studio-page.png" width="30%" />
  <img src="screenshots/loading-page.png" width="30%" />
  <img src="screenshots/start-page.png" width="30%" />
</p>

<p align="center">
  <img src="screenshots/gameplay-01.png" width="45%" />
  <img src="screenshots/gameplay-02.png" width="45%" />
  <img src="screenshots/gameplay-03.png" width="45%" />
  <img src="screenshots/gameplay-04.png" width="45%" />
  <img src="screenshots/gameplay-05.png" width="45%" />
  <img src="screenshots/gameplay-06.png" width="45%" />
  <img src="screenshots/gameplay-07.png" width="45%" />
  <img src="screenshots/gameplay-08.png" width="45%" />
</p>

### Gameplay

Use **arrow keys** or **WASD** to move the hero through the maze.

| Key | Action |
|---|---|
| Arrow keys / WASD | Move |
| Left Ctrl / Left Shift | Use weapon |
| X / Z | Next / previous weapon |
| Space | Pause |
| Escape | Options |

The hero has limited energy — when it runs out, a life is lost. Collect energy pickups to restore health. The game tracks your score across levels.

Each level requires collecting all diamonds to open the exit. Keys unlock locked doors.

### Features

- Top-down 2D maze exploration across multiple levels
- Push stones to open new paths
- Collect diamonds and keys to unlock exits
- Fight enemies: spiders, bats, goblins and a boss (Octopus)
- Avoid ghosts — you can't fight them, only run
- Avoid fire flames — block them with a stone
- Use different weapons: sword, bow or explosion spell
- Enemies with pathfinding (Breadth-First Search / Greedy Best-First Search)
- Teleports and checkpoints
- Dynamic lighting system
- Level select via secret codes
- Kill statistics per level (spiders, monsters, bats) with score breakdown
- Extra bonus for defeating all enemies in a level
- Original pixel-art graphics and sound effects

### Requirements

- Python 3.11.x
- [pygame-ce](https://pyga.me/) 2.5.6
- [PyTMX](https://pytmx.readthedocs.io/) 3.32
- [pytest](https://pytest.org/) (for running tests)

### How to run the game?
    
**Option 1 — launcher scripts (recommended).** Automatically create the venv if missing, install dependencies, and start the game:

Windows
```cmd
start.bat
```

Linux
```bash
./start.sh
```

**Option 2 — manual.** Activate the venv first, then install dependencies and run:

Windows
```cmd
venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

Linux
```bash
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

### Project Structure

```
dungeons-and-traps/
├── main.py                  # Entry point
├── settings.py              # Global constants (screen size, FPS, colors, tile size)
├── data/
│   ├── tmx/                 # Level maps (Tiled Map Editor)
│   └── tsx/                 # Tilesets
├── img/                     # Sprite sheets (PNG)
├── screenshots/             # Gameplay screenshots for README
├── sound/sfx/set_01/        # Sound effects (OGG)
├── font/silkscreen/         # Silkscreen font
├── font/trade_winds/        # Trade Winds font (first page title)
├── tests/
│   ├── enums/               # Tests for enums
│   ├── search_path_algorithms/  # Tests for BFS, Greedy Best-First Search, UniquePriorityQueue
│   ├── test_enemy_kill_record.py
│   ├── test_bonus_record.py
│   ├── test_collectable_record.py
│   ├── test_level_stats.py
│   ├── test_level_catalog.py
│   ├── test_game_manager.py
│   └── test_geometry_helper.py
└── src/
    ├── game.py              # Main game loop
    ├── screen_manager.py    # Current screen: surfaces, level, panels, dialogs
    ├── keyboard_controller.py  # Keyboard input per game status
    ├── custom_event_controller.py  # Reactions to custom game events
    ├── game_manager.py      # Shared state (score, lives, weapons, events)
    ├── level_catalog.py     # Ordered list of levels (maps, names, secret codes)
    ├── events.py            # Custom Pygame event type IDs
    ├── level.py             # Level loading and sprite management
    ├── level_sprite_builder.py  # Builds the world of a level from a TMX map
    ├── level_sprite_groups.py  # Visible layers and functional sprite groups of a level
    ├── camera.py            # Camera offset that follows the player, with the tilt shake
    ├── level_stats.py       # Per-level statistics (kills, diamonds, keys, bonus)
    ├── enemy_kill_record.py # Single enemy type kill record (count, killed, score)
    ├── obstacle_map.py      # 2D grid used by enemy pathfinding
    ├── obstacle_map_factory.py  # Creates the obstacle map from the blocking layers of a TMX map
    ├── sound_manager.py     # Sound playback (Singleton)
    ├── sprites/             # All game objects (player, enemies, items, weapons…)
    ├── effects/             # Visual effects (blast, explosion, particles…)
    ├── panels/              # UI panels (header, dashboard, dialogs)
    ├── search_path_algorithms/  # BFS and Greedy Best-First Search
    ├── abstract_classes/    # Base classes for enemies
    ├── enums/               # Game enums (GameStatus, WeaponType, SoundEffect, EnemyType…)
    ├── utilities/           # Debug info and debug overlay
    └── tile_details/        # TMX object property parsers per sprite type
```

### Credits

- **Tiny Dungeon** tileset by [Kenney](https://kenney.nl/assets/tiny-dungeon) — CC0, used as inspiration for original graphics
- **ChipTone** by [SFBGames](https://sfbgames.itch.io/chiptone) — used to create sound effects
- **Silkscreen** font by Jason Kottke — [SIL Open Font License 1.1](font/silkscreen/OFL.txt)
- **Trade Winds** font by Sideshow (Font Diner, Inc) — [SIL Open Font License 1.1](font/trade_winds/OFL.txt)

### License

**Code** (`src/`, `main.py`, `settings.py`) — [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)
> You are free to use, modify and distribute the code, provided that any derivative work is also published under GPL v3 and includes attribution to the original author.

**Graphics and sounds** (`data/`, `img/`, `sound/`) — [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/)
> You are free to use and adapt the assets, provided that you credit the original author and publish your modifications under the same license.

**Fonts** (`font/silkscreen/`, `font/trade_winds/`) — [SIL Open Font License 1.1](font/silkscreen/OFL.txt)

© Crimson-Jack

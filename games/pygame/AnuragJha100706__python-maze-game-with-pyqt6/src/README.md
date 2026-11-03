# CYBER MAZE RUNNER 2.0
## Publication-Grade Pure Pygame Arcade Action Game

[![Python Version](https://img.shields.io/badge/Python-3.12%2B-blue.svg?logo=python&logoColor=white)](https://www.python.org/)
[![Pygame Engine](https://img.shields.io/badge/Pygame-2.6.1-green.svg?logo=pygame&logoColor=white)](https://www.pygame.org/)
[![Database](https://img.shields.io/badge/Database-SQLite3-003B57.svg?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Display](https://img.shields.io/badge/Display-1280x720%20Virtual%20Backbuffer-00f0ff.svg)](#universal-display-scaling)
[![Controller](https://img.shields.io/badge/Input-Gamepad%20%26%20Hotplug-ff007f.svg)](#gamepad--controller-support)
[![Build](https://img.shields.io/badge/Build-Windows%20Executable%20(.exe)-orange.svg)](#standalone-windows-executable)
[![Tests](https://img.shields.io/badge/Tests-100%25%20Passing-brightgreen.svg)](#testing--verification)

A fast-paced, high-octane cyberpunk arcade maze action game engineered with a pure Pygame single-window architecture. Features graph-theoretic procedural maze generation, real-time heuristic pathfinding AI, tactical HUD telemetry, procedural audio synthesis, universal letterbox resolution scaling, and plug-and-play gamepad support.

---

## Short Description (for GitHub About / Tagline)

> **High-performance cyberpunk arcade maze game built with Pure Pygame. Features 5 distinct action game modes, graph-theoretic maze generators (Kruskal, Prim, Wilson, DFS), real-time A* pathfinding AI, universal aspect-ratio scaler (F11 fullscreen), plug-and-play gamepad hotplugging, procedural audio synthesis, and SQLite leaderboards.**

### Recommended GitHub Topics
`python` `pygame` `game-development` `arcade-game` `cyberpunk` `procedural-generation` `maze-generator` `pathfinding` `astar-algorithm` `gamepad-support` `sqlite3` `pyinstaller` `single-window`

---

## Key Highlights

- **Pure Single-Window Pygame Architecture**: Locked 60 FPS in $1280 \times 720$ virtual backbuffer with zero popup windows or Qt dependencies.
- **Universal Aspect-Ratio Scaler (`F11`)**: Seamless scaling to 1080p, 1440p, 4K, and 21:9 ultrawide with pixel-perfect pillarbox/letterbox margins and inverse mouse projection.
- **Plug-and-Play Gamepad Subsystem**: Controller auto-detection, runtime hotplugging, analog stick deadzone filtering ($\pm 0.35$), and unified cross-device input bindings.
- **In-Engine Authentication & Hall of Fame**: Native login, registration with PBKDF2 cryptographic hashing, instant 1-click guest access, and SQLite leaderboards.
- **Procedural Audio Synthesizer**: Synthesizes audio waveforms directly in memory (no external audio files needed) with real-time Master and SFX volume sliders.
- **Standalone Windows Executable**: One-click build script (`build_game.py`) compiles a single-file portable `CyberMazeRunner.exe` (~30 MB).

---

## 5 Gameplay Modes

| Mode | Title | Objective | Controls & Mechanics |
| :--- | :--- | :--- | :--- |
| **Mode 0** | **Solo Time Trial** | Race against the clock from start to exit. | **Gamepad / Arrows / WASD**. Live digital millisecond stopwatch, step counter, path optimality scoring ($\frac{\text{Optimal Steps}}{\text{Actual Steps}} \times 100\%$), and victory particle fireworks. |
| **Mode 1** | **Two Player PvP** | Local 1v1 split race to opposite exit portals. | **Dual Gamepads** or **P1: Arrows (Cyan)** vs **P2: WASD (Purple)**. Symmetrical polling eliminates input lag; live HUD displays distance-to-goal for each racer. |
| **Mode 2** | **Race vs AI** | Compete head-to-head against an optimal AI pathfinder. | **Gamepad / Arrows / WASD**. AI navigates using true optimal heuristic search ($A^*$) with non-blocking step dispatching. |
| **Mode 3** | **Chase Survival** | Evade the relentless Hunter AI stalking your path! | **Gamepad / Arrows / WASD**. Hunter AI activates after a 3-second grace period; HUD features dynamic threat proximity radar flashing alerts as danger nears. |
| **Mode 4** | **Escape Heist** | Collect 8 keys to unlock the exit while evading pursuit. | **Gamepad / Arrows / WASD + Space (Button A/X)**. Blast corridors open with **Wall Breakers** featuring explosive particle demolition. Bonus demolition charges awarded every 2 keys. |

---

## Procedural Maze Generation Algorithms

Customize generation algorithms via the Settings screen:
1. **Randomized Kruskal's (MST)**: Balanced branch density with uniform distribution.
2. **Randomized Prim's (MST)**: High branching factor with numerous short dead-ends.
3. **Wilson's Algorithm (UST)**: Generates completely unbiased Uniform Spanning Trees using loop-erased random walks.
4. **Recursive Backtracker (DFS)**: Deep, winding corridors with long exploration paths.

---

## Controls Reference

| Action | Keyboard | Gamepad (Xbox / PS / Generic) |
| :--- | :--- | :--- |
| **Movement** | Arrow Keys / `W` `A` `S` `D` | D-Pad / Left Analog Stick |
| **Player 2 (PvP)** | Arrow Keys or Numpad | Gamepad 2 (Controller 1) |
| **Demolish Wall (Mode 4)**| `SPACE` into wall | Button `A` / `X` / Right Trigger |
| **Toggle Fullscreen** | `F11` or `Alt` + `Enter` | - |
| **Pause / Resume** | `ESC` | `Start` / `Menu` Button |
| **Restart Mission** | `R` | Button `Y` / `Triangle` / `Select` |
| **Confirm / Select** | `ENTER` / `SPACE` | Button `A` / `Cross` |
| **Back / Cancel** | `ESC` / `BACKSPACE` | Button `B` / `Circle` |

---

## Project Architecture

```
python game maze/
│
├── main.py                     # Master Game Launcher (Hardware Accelerated)
├── config.py                   # Global constants, color palettes, modes mapping
├── maze_master.db              # SQLite relational database (Users, Records, Settings)
├── build_game.py               # Automated PyInstaller build pipeline
│
├── core/                       # Core Engines & Algorithms
│   ├── display_manager.py      # Virtual backbuffer scaler & mouse projection
│   ├── input_manager.py        # Gamepad hotplugging, deadzones & unified actions
│   ├── graph.py                # Graph data structure with O(1) query performance
│   ├── maze_generators.py      # Kruskal, Prim, Wilson, and DFS algorithms
│   ├── solvers.py              # A*, Dijkstra, Bidirectional A*, BFS, DFS, GBFS
│   └── heuristics.py           # Manhattan, Euclidean, Chebyshev metrics
│
├── game/                       # Game Loop, State Machine & Modes
│   ├── state_manager.py        # Central FSM routing screens & inputs
│   ├── game_state.py           # BaseGameMode with physics, particles & viewport
│   ├── hud.py                  # Tactical telemetry HUD & Game Over modals
│   ├── audio.py                # In-memory procedural audio synthesizer
│   └── modes/                  # All 5 playable game modes
│       ├── mode_solo.py        # Mode 0: Solo Time Trial
│       ├── mode_two_player.py  # Mode 1: Two Player PvP
│       ├── mode_race.py        # Mode 2: Race vs AI
│       ├── mode_chase.py       # Mode 3: Chase Survival
│       └── mode_escape.py      # Mode 4: Escape Heist
│
├── ui/                         # Cyberpunk UI Screen System
│   ├── widgets.py              # Buttons, TextInputs, CyberToggles, CyberSliders
│   ├── screen_auth.py          # Native In-Engine Login / Register / Guest Access
│   ├── screen_menu.py          # Animated Starfield Main Menu
│   ├── screen_mode_select.py   # Mode Cards Carousel & Grid Dimension Sizer
│   ├── screen_leaderboard.py   # Hall of Fame with mode filtering & pagination
│   └── screen_settings.py      # Dual-column Hardware, Audio & Generation config
│
├── database/                   # SQLite Relational Database Subsystem
│   ├── db_manager.py           # Thread-safe connection pool & migrations
│   └── security.py             # Salted PBKDF2 password hashing
│
├── tests/                      # Automated Verification Test Suite (100% Green)
│   ├── test_display_scaler.py  # Resolution scaling & projection tests
│   ├── test_input_manager.py   # Gamepad actions & deadzone tests
│   ├── test_audio_volume.py    # Master/SFX volume modulation tests
│   ├── test_pure_game.py       # All screens & native game modes integration
│   ├── test_modes.py           # 5 gameplay modes mechanics verification
│   ├── test_algorithms.py      # Graph & search algorithm optimality tests
│   └── test_full_system.py     # Master end-to-end integration test
│
└── dist/
    └── CyberMazeRunner.exe     # Standalone portable Windows binary (~30 MB)
```

---

## Installation & Running

### Option 1: Run Pre-Compiled Windows Executable (No Python Required)
Run the standalone binary directly:
```powershell
.\dist\CyberMazeRunner.exe
```

### Option 2: Run via Python Source Code

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/cyber-maze-runner.git
   cd cyber-maze-runner
   ```

2. **Install dependencies:**
   ```bash
   pip install pygame
   ```

3. **Launch the game:**
   ```bash
   python main.py
   ```

---

## Building Standalone Executable

To compile a portable, single-file Windows executable with PyInstaller:
```powershell
python build_game.py
```
This automatically executes the full pre-build test validation suite, then packages Python, Pygame, the SQLite database, and all assets into `dist/CyberMazeRunner.exe`.

---

## Testing & Verification

Run the full automated test suite:
```powershell
python -m unittest discover -s tests -p "test_*.py"
```
Or run individual test modules:
```powershell
python tests/test_display_scaler.py
python tests/test_input_manager.py
python tests/test_audio_volume.py
python tests/test_pure_game.py
python tests/test_modes.py
python tests/test_full_system.py
```

---

## License

MIT License. Free for educational, personal, and commercial usage.

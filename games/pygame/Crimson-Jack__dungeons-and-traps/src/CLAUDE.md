# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Strict Rules

**Never:**
- Modify any file in `data/` (images, sounds, tilesets, maps) unless explicitly asked.
- Add, remove, or upgrade a dependency in `requirements.txt` without stating the reason in your response.
- Install packages into the global pip — always use the project's virtual environment.
- Create documentation files (`.md`) or architecture diagrams unless explicitly asked.
- Add new Python modules outside the `src/` directory.

**Always:**
- Run `venv\Scripts\python.exe -m pytest tests/` (PowerShell) only when the user explicitly asks for it — never automatically after a change or as a default step before reporting a task complete. If the user does ask and tests fail, fix them first.
- Use full, descriptive names for all identifiers — no abbreviations or single-letter variables (`enemy_type` not `et`, `center_x` not `cx`).
- Note any new constant added to `settings.py` or `src/events.py` explicitly in your response.
- Use Pygame custom events (defined in `Events`) for cross-system communication — never call across system boundaries directly.
- Place new test files in `tests/` mirroring the path of the module under test.

## Change Workflow

For every change to production code — including one-liners, simple bug fixes, and follow-up corrections requested after a prior change:
1. **Describe first** — state the plan and list every file that will be touched.
2. **Wait for confirmation** — do not edit production code until the plan is approved. Confirmation means an explicit approval in the current conversation turn — a prior standing instruction does not substitute, and approval of an earlier change does not carry over to a later one.
3. **Implement** — make the change and report results. Only run `venv\Scripts\python.exe -m pytest tests/` (PowerShell) if the user explicitly asks for it.

There is no exception for changes that look small or obvious — always describe and wait for approval first.

## Stop and Ask

Halt and request human input when:
- Requirements for a new feature or behavior are ambiguous.
- A new Pygame event type is needed and its name or scope is unclear.
- `pytest tests/` fails after a change and the fix is non-obvious.
- A change affects more than one rendering layer or `ObstacleMap` in a non-obvious way.
- A change modifies `GameManager` state shared across `Game`, `Level`, and sprites.
- A new class or module has been added and there is no corresponding test file in `tests/`.
- The virtual environment is not activated, `pytest` cannot be found, or `pygame-ce` fails to import.

## Running the Game

```bash
python main.py
```

Requires Python 3.11.x.

**Option 1 — launcher scripts (recommended).** Automatically create the venv if missing, install dependencies, and start the game:

```bash
start.bat        # Windows
./start.sh       # Linux / macOS
```

**Option 2 — manual.** Activate the venv first, then install dependencies and run:

```bash
# Windows
venv\Scripts\activate
pip install -r requirements.txt
python main.py

# Linux / macOS
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

Dependencies: `pygame-ce==2.5.6`, `PyTMX==3.32`, `pytest`

Run tests with (PowerShell):

```powershell
venv\Scripts\python.exe -m pytest tests/
```

## Architecture Overview

**dungeons-and-traps** is a top-down 2D maze game. The main entry point is `main.py`, which instantiates `src/game.py:Game` and calls `game.run()`.

### Core Objects and Their Roles

- **`settings.py:Settings`** — single class of static constants: screen dimensions, FPS, colors, and rendered tile size (`TILE_SIZE`). Use `GameHelper.multiply_by_tile_size_ratio()` when hardcoding speed or geometry values. Touch this when adding new global settings. The source spritesheet tile size (`SOURCE_TILE_SIZE`) is asset-derived, not a tunable setting — it lives on `SpriteHelper` (`src/sprite_helper.py`) instead.

- **`src/events.py:Events`** — single class of all custom Pygame event type IDs. Touch this when adding a new cross-system event.

- **`src/game_manager.py:GameManager`** — central shared state object passed everywhere. Holds: current game status (`GameStatus` enum), the current level (`level_index` into the level catalog, `current_level_details`), player energy/lives/score/movement, collected items (diamonds, keys), weapons and their ammunition, lighting status, boss state, and the statistics of every played level (`current_level_stats` for the current one; the list persists until game over). All fields are private; other classes read them through read-only properties of the same name and change them only through `GameManager` methods (e.g. `collect_diamond()`, `show_boss()`, `record_enemy_spawn()`, `award_enemy_kill()`). Also owns `SoundManager`. Raises Pygame custom events to trigger cross-system reactions (e.g. `COLLECT_DIAMOND_EVENT` triggers dashboard refresh).

- **`src/level_catalog.py:LEVELS`** — the ordered tuple of `LevelDetails`: the campaign levels in play order, followed by the test maps. `GameManager` reads it directly (`current_level_details`, `validate_secret_code()`).

- **`src/game.py:Game`** — the main game loop. Creates the window, `GameManager`, `ScreenManager`, `KeyboardController` and `CustomEventController`, then each frame passes key events to `KeyboardController`, every event to `CustomEventController`, and draws the current screen through `ScreenManager`.

- **`src/screen_manager.py:ScreenManager`** — what is currently on screen. Owns the three UI surfaces (header, dashboard, game area), the current `Level`, `Header`, `Dashboard`, and the studio page, first page, dialogs and summary panel. Draws the current screen each frame (`run_current_screen()`), loads/disposes pages and dialogs, refreshes panels, and rebuilds the level. Never calls `Game` — controllers always read `screen_manager.level` at call time, because the level object is replaced on restart and level change.

- **`src/custom_event_controller.py:CustomEventController`** — reactions to custom game events posted by sprites and timers. Maps each `Events` type to a handler (`custom_event_handlers`) that calls `Level` methods (through `screen_manager.level`), refreshes panels, shows end-of-level/game dialogs, and schedules follow-up events with `pygame.time.set_timer`. Uses only `GameManager` and `ScreenManager`.

- **`src/keyboard_controller.py:KeyboardController`** — keyboard input via a state-machine driven by `game_manager.game_status` (`keyboard_handlers`: one key down handler per status). Owns the secret code text and the movement keys pressed while the game is running, and runs gameplay transitions (level intro, pause resume, game reset). Uses only `GameManager` and `ScreenManager`; ends the game from the pause menu by posting `GAME_OVER_SUMMARY_EVENT`, never by calling `CustomEventController`.

- **`src/level.py:Level`** — loads a `.tmx` map file and builds the world from it through `LevelSpriteBuilder`. Owns `LevelSpriteGroups` (private `_level_sprite_groups`) and the `Camera` (private `_camera`). Runs the game loop's update/draw cycle each frame. All its fields are private; other classes use only its methods.

- **`src/level_sprite_builder.py:LevelSpriteBuilder`** — builds the world of a level from a TMX map in its constructor: sprites from the tile and object layers, `Player`, `CheckPoint`, `ExitPoint` and the boss point position. Receives the `ObstacleMap` created by `Level` in its constructor. `Level` only reads the results from its read-only properties (`player`, `check_point`, `exit_point`, `boss_point_position`); all builder fields and methods are private. Used only while `Level` is constructed; sprites created during play (eggs, monsters, the boss) stay in `Level`.

- **`src/level_sprite_groups.py:LevelSpriteGroups`** — the sprite groups of a level: five layered `CameraGroup`s (drawn back-to-front for depth) and multiple functional `pygame.sprite.Group`s used for collision detection.

### Rendering Layers (drawn in order)

| Layer | Class | Contents |
|---|---|---|
| `bottom_background_layer` | `CameraGroup` | Ground tiles, exit point, check point |
| `bottom_sprites_layer` | `CameraGroup` | Collectables, fire flames, teleports |
| `middle_sprites_layer` | `CameraGroupWithYSort` | Player, walls, stones — Y-sorted for 3D effect |
| `top_sprites_layer` | `CameraGroup` | Most enemies |
| `the_highest_sprites_layer` | `CameraGroup` | Boss (Octopus, 3×3 tiles) |

`CameraGroupWithYSort` sorts sprites by `rect.centery` before drawing, which creates the pseudo-3D depth illusion. The camera offset is computed once per frame by `Camera` (`src/camera.py`): `Level.run()` calls `camera.follow()` with the player center and the tilt effect shake after the sprites have been updated, then passes `camera.offset` to `CameraGroup.custom_draw()` of every layer, to the particle effects, the darkness effect and the debug overlay. The camera groups only draw their visible sprites with the given offset.

In debug mode (F1/F2 on, F3 off; available when `Settings.DEBUG_MODE_AVAILABLE` is `True`) `DebugOverlay` (`src/utilities/debug_overlay.py`) draws sprite frames, enemy paths and the player tile on top of all layers.

### Event-Driven Communication

Sprites communicate back to the game loop via Pygame custom events defined in `Events`. For example:
- Collecting all diamonds posts `EXIT_POINT_IS_OPEN_EVENT` or `CREATE_BOSS_OCTOPUS_EVENT` (depending on `LevelDetails.exit_point_enabled`).
- Enemy death posts `ADD_TOMBSTONE_EVENT` with a position dict.
- Level completion triggers a chain: `START_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT` → (1s delay) → `FINISH_TELEPORT_PLAYER_TO_NEXT_LEVEL_EVENT` → `NEXT_LEVEL_EVENT`.

`CustomEventController.handle_custom_events()` is the single handler for all of these.

### Map / Level System

Levels are defined in `src/level_catalog.py:LEVELS` as `LevelDetails` objects with a `.tmx` filename, a flag for whether an exit point opens on diamond collection (`exit_point_enabled`), and an optional secret code for level-select. `GameManager.current_level_details` returns the details of the level being played; `GameManager.validate_secret_code()` (static) returns the index of the level with a given secret code. Maps live in `data/tmx/`, tilesets in `data/tsx/`.

`LevelSpriteBuilder` (in its constructor) iterates named TMX layers. Tile layers (`ground`, `obstacle`, `moving-obstacle`, etc.) and object layers (`spider-enemy`, `ghost-enemy`, etc.) are handled separately. Enemy behavior parameters (speed, motion schedule, etc.) are read from TMX object custom properties via `TmxHelper`.

### Sprite Hierarchy

- Enemies that use pathfinding extend `PathfindingEnemy` (marker interface) — `Level.inform_about_player_tile_position()` calls `set_player_tile_position()` on them each time the player moves to a new tile.
- Enemies that need to refresh their collision map extend `ObstacleMapObserver`.
- `DamageableEnemy` (abstract) handles HP and damage logic.

### Obstacle Map

`ObstacleMap` (`src/obstacle_map.py`) is a 2D grid that merges all blocking layers (walls, moving obstacles, removable walls, doors). `Level` creates it with `ObstacleMapFactory.create(tmx_data)` (`src/obstacle_map_factory.py`) and passes it to `LevelSpriteBuilder`. Enemies with pathfinding (BFS / Greedy Best-First Search in `src/search_path_algorithms/`) use this map. When stones are pushed or walls demolished, `REFRESH_OBSTACLE_MAP_EVENT` triggers `Level.refresh_obstacle_map()`.

### Sound

`SoundManager` (`src/sound_manager.py`) is a Singleton. It loads all `.ogg` files from `sound/sfx/set_01/` keyed by `SoundEffect` enum values on startup. Call `sound_manager.play_sfx(SoundEffect.XYZ)` to play a sound.

### Kill Statistics

`LevelStats` (`src/level_stats.py`) tracks per-level statistics: enemy kills (count, killed, score per `EnemyType`), diamonds, keys, and bonus. `GameManager.current_level_stats` always refers to the current level's stats; `GameManager.get_aggregate_collectable_stats()` and `get_aggregate_kill_stats()` sum all played levels for the summary. Spawns and kills are recorded through `GameManager.record_enemy_spawn()` and `award_enemy_kill()` (score and kill together). The boss (Octopus) has no `EnemyType`: killing it only adds score and does not count towards the statistics. When all enemies are defeated, a bonus is awarded at level completion.


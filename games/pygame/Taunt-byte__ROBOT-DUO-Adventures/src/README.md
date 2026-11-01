# ROBOT DUO: ADVENTURES

A cooperative 2D puzzle-platformer for one player controlling **two robots at once**, inspired by the
gameplay of classic "fire & water" co-op games, with its own characters, art direction and levels.
Built with **Python 3.10+** and **Pygame 2**.

| | ROBO-X (red) | ROBO-B (blue) |
|---|---|---|
| Survives | lava | water |
| Dies in | water | lava |
| Both die in | spikes, electric barriers, pits | |

Both robots can walk, jump, collect crystals, press switches and ride platforms. Each has its **own exit door**,
and a level is only complete when **both** robots stand in their doors and the level's crystal requirement is met.

## Run

```bash
pip install -r requirements.txt
python main.py
```

Works on Windows, Linux and macOS. Progress and settings are stored in `~/.robot_duo/save.json`.

## Controls

| Action | ROBO-X | ROBO-B |
|---|---|---|
| Move | `A` / `D` | `←` / `→` |
| Jump | `W` | `↑` |

| Key | Function |
|---|---|
| `TAB` | switch the focused robot (camera + arrow indicator) |
| `1` / `2` | focus ROBO-X / ROBO-B |
| `R` | restart level |
| `ESC` | pause |
| `ENTER` | confirm in menus |
| `F11` | toggle fullscreen |

Switching focus never moves, removes or resets the other robot; both sets of keys work simultaneously.
In *Settings* you can pick **Alternado** (single-control) mode, where only the focused robot moves.

## Game elements

- **Crystals** - shared collectibles; some levels require a minimum number to open the exit doors.
- **Buttons** - active while a robot stands on them (gold-notch buttons *latch* and stay on). Coloured lamps on
  doors/barriers show which button controls them, and the HUD shows every button's state.
- **Doors** slide open while powered and never close on a robot.
- **Bridges** extend over chasms while powered.
- **Moving platforms** patrol (ping-pong) or act as elevators driven by a button; riders are carried.
- **Crumbling platforms** break shortly after being stood on and return a few seconds later.
- **Electric barriers** kill both robots unless a button switches them off.
- **Hazards**: lava, water, spikes, bottomless pits.

## Levels

| # | Name | Focus |
|---|---|---|
| 1 | First Contact | controls, lava/water, first crystals |
| 2 | The Split Bridge | hold-a-button relays, doors, bridge, different heights |
| 3 | The Forgotten Laboratory | electric barriers, moving platforms, elevator, latching switches |
| 4 | Crystal Caverns | suspended + crumbling platforms, distant switch, alternate routes (lava lake for ROBO-X) |
| 5 | The Core Factory | every mechanic combined, final platform climb |

Score = crystals x 150 + time bonus (+1000 for all crystals). Rank S/A/B/C depends on crystals and the level's par time.

## Project structure

```
main.py                 entry point
src/
  settings.py           all constants (physics, colours, paths)
  collision.py          Box + sub-stepped swept collision (anti-tunnelling)
  physics.py            KinematicBody: gravity, accel, variable jump, coyote time, jump buffer
  player.py             Player (robot rules: immunities, death, animation state)
  level.py              level parsing, mechanisms update, hazards, exits, win rule
  puzzle.py             Button + Actuator (trigger logic)
  platforms.py          Door, Bridge, MovingPlatform, FadingPlatform
  hazards.py            pools, spikes, ElectricBarrier
  collectibles.py       Crystal
  level_manager.py      level discovery, ranks/score, SaveData
  camera.py             smooth, clamped scrolling camera + shake
  animation.py          procedural robot art + animation sets (spritesheet-ready)
  background.py         procedural parallax themes
  render.py             LevelRenderer (tiles, pools, mechanisms, lighting)
  particles.py          particles + ambient motes
  audio.py              sound/music manager (files or built-in synth fallback)
  ui.py                 fonts, panels, glow, HUD
  menus.py              main menu, level select, controls, settings, completion screen
  play.py               gameplay scene
  game.py               window, main loop, scene switching
data/levels/            level_01.json ... level_05.json
tests/                  headless unit tests + level reachability lint
```

Game logic modules (`collision`, `physics`, `player`, `level`, `puzzle`, `platforms`, `hazards`, ...) never import
pygame, so they are unit-tested headless and rendering is fully separated from simulation.
Physics uses a fixed cap on `dt` (1/30 s) and sub-stepped axis-separated collision.

## Adding levels

Drop a `level_NN.json` into `data/levels/`; it appears automatically. Format:

```json
{
  "name": "My Level", "subtitle": "text", "theme": "factory|abandoned|lab|cave|core|space",
  "par_time": 90, "required_crystals": 3,
  "map": ["####...", "..."],
  "entities": [ {"type": "button", "id": "a", "x": 5, "y": 13, "latch": false},
                {"type": "door", "x": 10, "y": 11, "w": 1, "h": 3, "triggers": ["a"], "mode": "any"} ]
}
```

Map characters: `#` solid, `.` empty, `L` lava, `W` water, `^` spikes, `*` crystal, `r`/`u` spawn of ROBO-X/ROBO-B,
`x`/`b` exit door of ROBO-X/ROBO-B (marks the door's bottom cell). Maps are 16 rows tall (40 px tiles).
Entity types: `button`, `door`, `bridge` (`w`), `mover` (`w`, `dx`, `dy`, `speed`, optional `triggers`), `fading`
(`w`, `delay`, `respawn`), `barrier`, `sign` (`text`). Coordinates are grid cells; `triggers` lists button ids.

## Assets

The game needs **no asset files**: robots, tiles and backgrounds are drawn procedurally and sounds are synthesised.
To use your own:

- **Sprites**: `assets/sprites/robo_x/<state>_<n>.png` and `robo_b/` (states: `idle walk jump fall land death victory`;
  e.g. `walk_0.png`, `walk_1.png`...). Square images, any size (scaled to 64 px).
- **Sounds**: `assets/sounds/<name>.wav|ogg|mp3` with names `jump land crystal switch door death victory menu_move menu_select`.
- **Music**: `assets/music/menu.ogg` and `assets/music/game.ogg` (looped).
- **Font**: any `.ttf` in `assets/fonts/`.

If audio hardware is unavailable the game simply runs silently.

## Tests

```bash
python -m unittest discover -s tests -t .      # physics, mechanisms, hazards, win rules, level data
python -m tests.level_lint                      # reachability lint for level designers
```

The lint builds a graph of standing spots using the real jump physics and reports unreachable exits, crystals
and buttons per robot (respecting which hazards each robot survives).

## Roadmap ideas

Lasers, pushable boxes, more themes (space station), level editor, gamepad support, local 2-player mode.

## License

MIT - the code and procedurally generated art are original; no assets from other games are used.

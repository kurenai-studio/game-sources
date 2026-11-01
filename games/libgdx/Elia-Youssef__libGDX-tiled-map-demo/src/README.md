# Tiled Map Demo

Tiled Map Demo is a libGDX cave-exploration example built around a layered TMX map. Move an animated
character through a 2048x2048 tile world while collision, depth layering, and a clamped follow camera
keep the scene coherent.

## Features

- 128x128 orthogonal Tiled map using 16-pixel tiles
- Background, hidden collision, and foreground decoration layers
- Fifteen-frame animated player sprite
- Four-directional movement and facing
- Normalized diagonal speed and axis-separated collision
- Camera follow constrained to the map edges
- Foreground-over-player rendering for visual depth
- Self-contained desktop JAR with all map assets bundled

## Controls

| Input | Action |
| --- | --- |
| `W` | Move north |
| `S` | Move south |
| `A` | Move west |
| `D` | Move east |
| `Esc` | Exit |

## Requirements

- JDK 17 or newer
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.1

## Build and run

On Windows:

```powershell
.\gradlew.bat clean :lwjgl3:jar
.\gradlew.bat lwjgl3:run
```

On macOS or Linux:

```bash
./gradlew clean :lwjgl3:jar
./gradlew lwjgl3:run
```

The demo opens in a fixed 800x480 window. The runnable JAR is written to
`lwjgl3/build/libs/TiledMapDemo.jar`.

## Map and collision

The background layer fills the entire cave with floor and wall tiles. A hidden collision layer is
the single source of truth for solid cells, while a sparse foreground layer draws selected rocks,
crystals, and decoration over the player. Movement resolves one axis at a time so the character can
slide naturally along walls without entering solid tiles.

## Project structure

```text
assets/    TMX map, cave tileset, and player sprite sheet
core/      Map loading, player movement, collision, rendering, and camera logic
lwjgl3/    Desktop launcher and executable-JAR packaging
```

`Player` and `TileCollision` isolate movement and collision rules from presentation. `GameScreen`
loads and renders the layered map, samples input, animates the sprite, and follows the player.

## Assets

The repository contains `map.tmx`, `cave_tileset.png`, and `player_move_spritesheet.png`, all required
by the runnable demo.

## License

This project is available under the [MIT License](LICENSE).

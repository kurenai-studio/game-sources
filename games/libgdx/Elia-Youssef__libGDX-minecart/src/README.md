# Mine Cart

Mine Cart is a railway-routing arcade game built with libGDX. Direct incoming carts through a
three-way junction, match each color-coded destination, and avoid collisions while the railway
steadily becomes faster.

## Features

- Three destination tracks connected through one switchable junction
- Color-coded carts and matching caves
- Progressive cart speed and spawn-rate difficulty
- Maximum active-cart cap and AABB collision detection
- Correct-delivery scoring with complete win, disaster, and replay states
- GL-free simulation separated from rendering and input
- Procedurally drawn railway, carts, caves, HUD, and overlays

## Controls

| Input | Route |
| --- | --- |
| `W` or Up | Upper track |
| `Space` | Middle track |
| `S` or Down | Lower track |
| Mouse | Click **START**, **RETRY**, or **PLAY AGAIN** |

Each cart shows the color of its required cave. A correct delivery awards 25 gold; sending a cart to
the wrong cave or allowing two carts to collide ends the run. Reach 50 gold to win.

## Requirements

- JDK 21
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.1

## Build and run

On Windows:

```powershell
.\gradlew.bat clean build
.\gradlew.bat lwjgl3:run
```

On macOS or Linux:

```bash
./gradlew clean build
./gradlew lwjgl3:run
```

The game opens in a fixed 1280x720 desktop window.

## Project structure

```text
core/      Railway simulation, screens, cart model, rendering, and input
lwjgl3/    Desktop launcher
```

`MineCartWorld` owns routing, spawning, difficulty, delivery, collision, scoring, and end-state
logic. `GameplayScreen` handles keyboard selection, restart clicks, and presentation.

## Assets

Mine Cart is asset-free. All graphics and text are generated at runtime with libGDX primitives and
the built-in font.

## License

This project is available under the [MIT License](LICENSE).

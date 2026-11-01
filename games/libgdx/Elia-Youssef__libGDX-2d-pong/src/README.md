# Primitive Pong

Primitive Pong is a complete two-player Pong game built with libGDX. It combines responsive paddle
controls, deterministic ball physics, progressive rally speed, scoring, and a first-to-seven match.

## Features

- Local two-player paddle controls
- Direction-aware paddle collision and angle-based rebounds
- Ball speed that increases during a rally up to a safe cap
- First player to seven points wins
- Frozen game-over state with a complete restart path
- GL-free gameplay model separated from rendering and input
- Asset-free procedural graphics

## Controls

| Player | Input | Action |
| --- | --- | --- |
| Player 1 | `W` / `S` | Move the left paddle |
| Player 2 | Up / Down | Move the right paddle |
| Either | `R` | Restart after game over |

## Requirements

- JDK 17 or newer recommended for the Gradle build; the source and bytecode target Java 8
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.0

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

The game opens in a fixed 800x600 window titled `Primitive Pong`.

## Gameplay

The ball serves from the center at a constant initial speed and accelerates by five percent after
each paddle hit, up to the configured maximum. Contact position controls the vertical rebound angle.
A point is awarded when the ball leaves the left or right edge; the match ends when either player
reaches seven.

## Project structure

```text
core/      Ball, paddle, match simulation, rendering, and input
lwjgl3/    Desktop launcher
```

`PongWorld` owns all movement, collision, scoring, serving, and match-state rules without depending
on OpenGL. `PongGame` is the thin input and rendering layer.

## Assets

Primitive Pong is asset-free. The play field, dashed center line, paddles, ball, scores, and overlay
are drawn with libGDX primitives and the built-in font.

## License

This project is available under the [MIT License](LICENSE).

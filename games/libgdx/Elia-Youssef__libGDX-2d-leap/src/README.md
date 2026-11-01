# Leap

Leap is a minimalist side-scrolling platformer built with libGDX. Cross ten handcrafted platform
sections, survive the gaps, and reach the goal at the far end of a 3200-pixel level.

## Features

- Ten-platform side-scrolling course with a fixed horizontal HUD
- Deterministic movement, gravity, jumping, landing, and fall resets
- Horizontally scrolling camera clamped to the level bounds
- Title, gameplay, win, and replay flow
- Pure gameplay simulation with headless JUnit tests
- Entirely procedural presentation using primitive shapes and the built-in font

## Controls

| Input | Action |
| --- | --- |
| `A` / `D` or Left / Right | Move |
| `Space` or Up | Jump |
| Mouse | Click **START** or **PLAY AGAIN** |

Falling below the play field returns the player to the starting platform. Movement freezes after
reaching the yellow goal until **PLAY AGAIN** is selected.

## Requirements

- JDK 21
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.1

## Build, test, and run

On Windows:

```powershell
.\gradlew.bat clean build
.\gradlew.bat core:test
.\gradlew.bat lwjgl3:run
```

On macOS or Linux:

```bash
./gradlew clean build
./gradlew core:test
./gradlew lwjgl3:run
```

The game opens in a fixed 800x600 desktop window. The included tests cover level geometry, movement,
jumping, collision, camera clamping, resets, and an automated route through all ten platforms.

## Project structure

```text
core/      Level data, pure simulation, screens, rendering, and tests
lwjgl3/    Desktop launcher
```

`World` contains the testable simulation and owns the player, level, camera position, reset behavior,
and win state. `GameScreen` samples input and renders the scrolling play field and fixed HUD in
separate passes.

## Assets

Leap is asset-free. Every visual is generated with `ShapeRenderer` primitives and libGDX's built-in
`BitmapFont`; no external images, fonts, or audio are loaded at runtime.

## License

This project is available under the [MIT License](LICENSE).

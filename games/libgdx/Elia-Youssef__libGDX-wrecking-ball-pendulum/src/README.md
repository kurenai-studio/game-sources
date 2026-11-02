# Wrecking Ball Pendulum

Wrecking Ball Pendulum is a Box2D physics demo built with libGDX. Move a crane boom to build momentum,
release the suspended wrecking ball, and knock the target block completely out of the play area.

## Features

- Kinematic crane boom with constrained horizontal movement
- Dynamic wrecking ball attached by a rigid Box2D distance joint
- Dynamic target block with physical collision response
- Fixed-timestep simulation for stable pendulum behavior
- Ball release that preserves the current swing velocity
- Win detection, delayed full reset, and failed-attempt recovery
- Headless JUnit tests covering geometry, fixtures, joints, state transitions, and collisions
- Entirely code-generated visuals

## Controls

| Input | Action |
| --- | --- |
| Left / Right | Move the boom while the rope is attached |
| `Space` | Release the wrecking ball |

Move the boom back and forth to generate a useful swing, then release at the right moment. A win is
registered when the target block's complete bounds leave the screen.

## Requirements

- JDK 17 or newer recommended for the Gradle build; the source and bytecode target Java 8
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.0 and Box2D

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

The application opens in a fixed 900x500 desktop window.

## Simulation design

`WreckingBallWorld` owns every Box2D body, fixture, joint, timer, and reset rule without requiring an
OpenGL context. The world runs at a fixed 60 Hz step. `WreckingBallPendulumApp` polls input and draws
the current floor, crane, rope, ball, and target state.

## Project structure

```text
core/      Box2D simulation, rendering shell, and headless tests
lwjgl3/    Desktop launcher and Box2D native dependencies
```

## Assets

Wrecking Ball Pendulum is asset-free. Every visible element is drawn with libGDX primitives; no
images, fonts, or audio are loaded at runtime.

## License

This project is available under the [MIT License](LICENSE).

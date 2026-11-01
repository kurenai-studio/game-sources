# Running Wheel

Running Wheel is a side-scrolling Box2D driving game built with libGDX. Apply ground-only torque to
a physics-driven wheel, carry speed across procedurally generated terrain, clear the gaps, and reach
the finish flag.

## Features

- Dynamic circular wheel driven by Box2D torque
- Contact-based grounding that prevents mid-air acceleration
- Randomized, traversable 6000-pixel course
- Chain ground, rectangular platforms, ramps, kickers, drops, and gaps
- Horizontally scrolling camera clamped to both world edges
- Live timer and speed HUD
- Complete win and loss states with frozen simulation
- Entirely code-generated visuals

## Controls

| Input | Action |
| --- | --- |
| Right Arrow | Drive right while grounded |
| Left Arrow | Drive left while grounded |
| `Esc` | Exit |

Carry enough speed into each gap to land on the next section. Reaching the finish flag wins; falling
below the course loses.

## Requirements

- JDK 17 or newer recommended for the Gradle build; the source and bytecode target Java 8
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.1 and Box2D

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

The game opens in a fixed 800x600 desktop window. A new terrain seed is generated on each launch.

## Simulation design

`GameWorld` owns the Box2D world, fixed-timestep update, terrain bodies, wheel contacts, timer, camera
target, and end-state rules. `RunningWheelApp` polls the controls and renders the terrain, wheel,
finish marker, and screen-space HUD.

## Project structure

```text
core/      Box2D world, terrain generation, rendering, and input
lwjgl3/    Desktop launcher and Box2D native dependencies
```

## Assets

Running Wheel is asset-free. All terrain, physics objects, markers, and interface elements are drawn
with libGDX primitives and the built-in font.

## License

This project is available under the [MIT License](LICENSE).

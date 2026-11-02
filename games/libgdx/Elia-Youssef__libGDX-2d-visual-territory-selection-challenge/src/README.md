# Territory Challenge

Territory Challenge is a timed visual-estimation game built with libGDX. Compete against three CPU
players across four rounds by identifying the largest colored territory inside a partitioned shape.

## Features

- Four timed spatial-reasoning rounds
- Convex and concave polygon hit detection, including boundary clicks
- Shoelace-formula area calculations for authoritative answers
- Three CPU opponents with independent selections
- Per-round scoring, cumulative rankings, ties, and final winner resolution
- Pure game-state and geometry model with headless JUnit tests
- Runnable desktop JAR with the four supplied territory images bundled

## Controls

| Input | Action |
| --- | --- |
| `S` | Start the game |
| Left mouse click | Select a territory during the selection phase |
| `N` | Continue after a round result |

Each round begins with a hidden three-second countdown, followed by a three-second selection phase.
The correct territory and percentage are then revealed before the leaderboard appears.

## Requirements

- JDK 17 or newer recommended for the Gradle build; the source and bytecode target Java 8
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.0

## Build, test, and run

On Windows:

```powershell
.\gradlew.bat clean :core:test :lwjgl3:jar
.\gradlew.bat lwjgl3:run
```

On macOS or Linux:

```bash
./gradlew clean :core:test :lwjgl3:jar
./gradlew lwjgl3:run
```

The game opens in a fixed 1100x900 window. The runnable JAR is written to
`lwjgl3/build/libs/TerritoryChallenge.jar`.

## Geometry and scoring

The game calculates each polygon's area directly from its vertices rather than relying on image
labels. Clicks are transformed into territory coordinates and tested against the polygon edges and
interior. Every player who chooses the largest territory earns one point; all competitors sharing
the highest final score are declared winners.

## Project structure

```text
assets/    Four territory images used during the rounds
core/      Geometry, state machine, scoring, rendering, input, and tests
lwjgl3/    Desktop launcher and executable-JAR packaging
```

`GameLogic` contains the complete round flow, geometry, CPU choices, and score calculations without
requiring an OpenGL context. `GameScreen` handles presentation and user input.

## License

This project is available under the [MIT License](LICENSE).

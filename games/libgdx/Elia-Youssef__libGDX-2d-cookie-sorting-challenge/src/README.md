# Cookie Sorting Challenge

Cookie Sorting Challenge is a fast-paced libGDX desktop game about sorting light and dark cookies
before a one-minute timer expires. Drag cookies from the center plate into four corner plates; the
first accepted cookie assigns each plate's type for the rest of the round.

## Features

- Forty-cookie sorting round with light and dark cookie types
- Four initially unassigned corner plates with a guaranteed two-light/two-dark assignment split
- Rejected mismatched drops and cancelled-drag handling
- Win and loss states driven by the cookie count and countdown timer
- Gameplay analytics covering placements, movement time, drag distance, idle time, and cancellations
- Timestamped metrics logs written when a round ends
- Pure simulation model with headless JUnit coverage
- Self-contained desktop JAR with bundled libGDX dependencies and native libraries

## Controls

| Input | Action |
| --- | --- |
| Left mouse press on a cookie | Pick up one cookie |
| Move mouse while held | Drag the selected cookie |
| Release over a corner plate | Attempt to place the cookie |
| Release elsewhere | Cancel the drag and return the cookie |

The pointer changes to a hand while hovering over a cookie and to a small cookie image while dragging.

## Requirements

- JDK 17 or newer to run the Gradle build; the source and bytecode target Java 8
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.0

## Build, test, and run

From the repository root on Windows:

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

Build the runnable desktop JAR with:

```bash
./gradlew lwjgl3:jar
```

The packaged application is written to
`lwjgl3/build/libs/cookie-sorting-challenge.jar`.

## Metrics

Each completed round creates a local file named with the pattern
`dd-mm-yyyy-hh-mm-ss-metrics.log`. The report includes successful and failed placements, drag
cancellations, average movement time, total drag distance, idle time, and corner-plate usage.

## Project structure

```text
assets/    Plate and cookie artwork used at runtime
core/      Simulation, rendering, input, analytics, and headless tests
lwjgl3/    Desktop launcher and executable-JAR packaging
```

`CookieSortWorld` owns the game rules without requiring an OpenGL context. `CookieSortGame` handles
rendering, mouse input, cursor changes, and writing the final analytics report.

## Assets

The repository includes the three gameplay images required by the project: `cookie_plate.png`,
`l_cookie.png`, and `d_cookie.png`. No other external runtime artwork, fonts, or audio is required.

## License

This project is available under the [MIT License](LICENSE).

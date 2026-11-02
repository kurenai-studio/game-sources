# Monster Café Madness

Monster Café Madness is a colorful order-matching game built with libGDX. Read each monster's order,
serve the matching dish, keep customer happiness above zero, and score 100 points to complete the
café shift.

## Features

- Four-screen flow: main menu, gameplay, victory, and game over
- Three monster types and three food choices
- Randomized customers and orders
- Score and happiness systems with immediate feedback
- Reliable retry, play-again, and main-menu transitions
- Pure session model with headless JUnit tests
- Twelve bundled gameplay and interface images

## Controls

The game is mouse-driven:

| Action | Input |
| --- | --- |
| Start a shift | Click **PLAY** on the main menu |
| Serve an order | Click the burger, cupcake, or potion |
| Restart | Click **RETRY** or **PLAY AGAIN** |
| Return to the menu | Click **MAIN MENU** |

A correct order awards 10 points and presents a new customer. A wrong dish removes 20 percent
happiness and keeps the current order active. Reach 100 points to win; reaching zero happiness loses.

## Requirements

- JDK 17 or newer
- Windows, macOS, or Linux with desktop OpenGL support
- Internet access on the first build so Gradle can download libGDX 1.14.0

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

Build the runnable desktop JAR with:

```bash
./gradlew lwjgl3:jar
```

The packaged application is written to `lwjgl3/build/libs/monster-cafe-madness.jar`.

## Project structure

```text
assets/    Background, character, food, and interface artwork
core/      Session rules, screens, assets, rendering, input, and tests
lwjgl3/    Desktop launcher and executable-JAR packaging
```

`CafeSession` contains scoring, happiness, order generation, and terminal-state rules without an
OpenGL dependency. The four screen classes own presentation and navigation.

## Assets

The repository ships the twelve supplied runtime PNGs under `assets/`. Reference mockups are not
required at runtime and are not included in the standalone project.

## License

This project is available under the [MIT License](LICENSE).

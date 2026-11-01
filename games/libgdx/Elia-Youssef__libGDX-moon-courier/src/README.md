# Moon Courier

A small top-down lunar-delivery arcade prototype built with libGDX. Control a courier spacecraft on
the moon surface, collect one cargo crate, dodge the rocks and craters, and land on the delivery pad
before your fuel runs out.

The prototype has exactly four screens: **Main Menu**, **Gameplay**, **Victory**, and **Game Over**.

## Environment

- **Java 17** (source/target 17). Builds on a newer JDK via `--release 17`.
- **libGDX 1.14.2**, LWJGL3 desktop backend.
- **Gradle** via the bundled wrapper (`gradlew` / `gradlew.bat`) - no separate install needed.
- Asset-free: every visual is drawn at runtime from shapes and the built-in font. No external art,
  audio, or font files are used or shipped.

## Prerequisites

- A 64-bit **JDK 17** with `JAVA_HOME` set to that installation.
- No separate Gradle install. The repository includes Gradle Wrapper 8.10.2.

Confirm the active JDK before building:

```text
java -version
```

The build also accepts a newer JDK because Java compilation uses `--release 17`; all produced class
files remain Java 17 compatible.

## Build, test, and run

Run these commands from this `project` directory.

Windows PowerShell or Command Prompt:

```bat
gradlew.bat clean build
gradlew.bat core:test
gradlew.bat lwjgl3:run
```

Linux or macOS:

```sh
./gradlew clean build
./gradlew core:test
./gradlew lwjgl3:run
```

The game opens a resizable 1280x720 window on the Main Menu. `clean build` compiles both modules,
runs the headless tests, and creates the runnable distributions:

- `lwjgl3/build/distributions/MoonCourier.zip`
- `lwjgl3/build/distributions/MoonCourier.tar`

After extracting a distribution, launch `bin/MoonCourier.bat` on Windows or `bin/MoonCourier` on
Linux/macOS. Build output is reproducible and can be deleted safely with `gradlew.bat clean` (or
`./gradlew clean`).

## Controls

| Input | Action |
| ----- | ------ |
| `W` / `Up` | Move up |
| `S` / `Down` | Move down |
| `A` / `Left` | Move left |
| `D` / `Right` | Move right |
| `Enter` / `Space` / mouse | Start / confirm menu options |
| `Esc` | Exit (menu) / return to Main Menu (gameplay, endings) |

## How to play

1. From the Main Menu, choose **Start Mission**.
2. Fly the spacecraft into the **cargo crate** to collect it (the HUD cargo status updates).
3. Carry the cargo to the highlighted **delivery pad** (the "H" landing pad).
4. Fuel starts at 100% and drains continuously; hitting a rock or crater costs extra fuel.
5. Reach the pad with the cargo before fuel hits zero to **win** (Victory Scene). If fuel runs out
   first, the mission **fails** (Game Over Scene). Both endings let you restart or return to the menu.

## Project layout

- `core/` - platform-independent game code. `MissionWorld` is the GL-free simulation (movement, fuel,
  cargo, collisions, win/lose) and is unit-tested headlessly; the four `*Screen` classes plus
  `MoonCourierGame` are the render/input layer.
- `lwjgl3/` - the desktop launcher (`Lwjgl3Launcher`).

## License

This project is available under the [MIT License](LICENSE).

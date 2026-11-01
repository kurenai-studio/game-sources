# Gladiator Arena

Gladiator Arena is a top-down combat game built with libGDX. Survive increasingly dangerous enemy
waves, fire projectiles toward the cursor, and earn enough points to become arena champion before
your health reaches zero.

## Features

- Circular combat arena with boundary-constrained movement
- Direct enemy pursuit and contact damage
- Mouse-aimed projectile combat
- Escalating enemy waves and movement speed
- Score, health, wave, victory, defeat, and restart states
- GL-free simulation separated from rendering and input
- Entirely code-generated visuals

## Controls

| Input | Action |
| --- | --- |
| `WASD` or Arrow keys | Move |
| Left mouse click | Fire toward the cursor |
| Mouse | Click **START**, **RETRY**, or **PLAY AGAIN** |

Projectiles deal 25 damage, defeated enemies award 10 points, and contact with an enemy costs health.
Reach 500 points to win.

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
core/      Arena simulation, screens, entities, rendering, and input
lwjgl3/    Desktop launcher
```

`ArenaWorld` owns player movement, wave spawning, projectiles, enemy behavior, collisions, scoring,
and end-state rules. `GameplayScreen` translates input and renders the current state.

## Assets

Gladiator Arena is asset-free. The arena, combatants, projectiles, HUD, and overlays are drawn with
libGDX primitives and the built-in font.

## License

This project is available under the [MIT License](LICENSE).

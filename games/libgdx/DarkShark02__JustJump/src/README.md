# JustJump

A small 2D side-scrolling platformer made with [libGDX](https://libgdx.com/) in Java.

Run through the level, jump over spikes, dodge (or stomp) bees, grab hearts and stars, and reach the end of the level to move on to the next one.

> ⚠️ **Hobby project disclaimer**
>
> JustJump is a personal project I made for fun and to learn libGDX. It is **not** a finished or polished game:
> expect bugs, rough edges, unbalanced levels and code that could be cleaner.
> Feel free to open an issue if you find something broken, but please keep in mind that fixes may be slow (or may never come).

## Requirements

- **JDK 17 or newer** (needed to run Gradle; the game itself targets Java 8+).
  You can get one from [Adoptium](https://adoptium.net/).
- An internet connection the first time you build, so Gradle can download its dependencies.

You do **not** need to install Gradle: the project includes the Gradle wrapper (`gradlew` / `gradlew.bat`).

## How to run the game

1. Clone the repository:

   ```bash
   git clone https://github.com/DarkShark02/JustJump.git
   cd JustJump
   ```

2. Start the game:

   - **Windows**

     ```bat
     gradlew.bat lwjgl3:run
     ```

   - **Linux / macOS**

     ```bash
     ./gradlew lwjgl3:run
     ```

The first run can take a few minutes while dependencies are downloaded. After that, a 1600×900 window titled *JustJump* should open.

### Building a runnable JAR

If you want a single file you can launch without Gradle:

```bash
./gradlew lwjgl3:jar        # or gradlew.bat lwjgl3:jar on Windows
```

The JAR will be created in `lwjgl3/build/libs/` and can be started with:

```bash
java -jar lwjgl3/build/libs/JustJump-1.0.0.jar
```

## Controls

| Key        | Action                                            |
|------------|---------------------------------------------------|
| ← / →      | Move left / right                                 |
| ↑          | Jump                                              |
| ↓          | Duck (also changes how high springs launch you)   |
| R          | Restart from the first level after a game over    |

## Gameplay

- **Hearts** restore health; your health is shown in the top-left corner.
- **Stars** give you a temporary speed boost.
- **Spikes** and **bees** hurt you.
- **Snow** slows you down (unless a star is active).
- **Springs** bounce you high into the air.
- Reach the end of the level to load the next one.

Levels are defined as JSON files in [`assets/`](assets/) (`level1.json`, `level2.json`), so you can tweak them or make your own.

## Project structure

- `core/` – game logic shared by all platforms.
- `lwjgl3/` – desktop launcher (LWJGL3).
- `assets/` – textures and level files.

## Credits

- Built with [libGDX](https://libgdx.com/), project generated with [gdx-liftoff](https://github.com/libgdx/gdx-liftoff).

## License

The source code is released under the [MIT License](LICENSE).

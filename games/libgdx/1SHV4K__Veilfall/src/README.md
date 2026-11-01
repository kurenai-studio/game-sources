# Veilfall

A stylized wave-based action RPG built with Java and libGDX.

A [libGDX](https://libgdx.com/) project generated with [gdx-liftoff](https://github.com/libgdx/gdx-liftoff).

Choose a character and one of that character's weapons in the lobby, select an arena, then clear its waves and defeat its final-wave boss. The prototype currently includes Warden, Veil Archer, and Ash Mage; three arenas; character-specific abilities; weapon stats; boss attack warnings; and local SQLite saves. Player/enemy silhouettes and some weapons use imported CC0 meshes; class-specific weapons and combat effects use generated low-poly models. Arenas use open ground with scattered biome vegetation, rocks, and pools.

## Controls

- `W`, `A`, `S`, `D`: move
- Right-click (including trackpad secondary-click): move to the ground point
- Move the mouse: aim/facing direction
- Left-click: basic attack
- `Q`, `E`, `R`: character abilities
- `Space`: dodge
- Mouse wheel: zoom
- `P`: switch between orthographic and perspective projection
- Lobby Settings: rebind movement, abilities, and dodge; toggle fullscreen or mute combat sounds

## Progression and arenas

Completed and failed runs are saved to the local SQLite profile with the arena, character, weapon, waves reached, defeats, bosses, and duration. Runs award XP and update level, wins, losses, defeat totals, and personal best wave. Match History displays the latest 30 runs.

The current arena roster is Mistwood, Ashen Reach, and Sunken Chapel. Each arena has a distinct wave composition and its configured boss in the final wave. Arena Select previews the mob roster for each wave; the HUD names the mob types currently active. The playfield is an open 60×60 natural arena with no prefabricated rooms or walls.

## Included free assets

- Kenney Mini Dungeon fighter and weapon models: `assets/models/kenney-mini-dungeon/` (CC0, license included)
- Kenney RPG Audio and Impact Sounds combat cues: `assets/audio/combat/` (CC0, license included)
- Sources and licenses: [ASSET_SOURCES.md](ASSET_SOURCES.md)

## Platforms

- `core`: Main module with the application logic shared by all platforms.
- `lwjgl3`: Primary desktop platform using LWJGL3; was called 'desktop' in older docs.

## Gradle

This project uses [Gradle](https://gradle.org/) to manage dependencies.
The Gradle wrapper was included, so you can run Gradle tasks using `gradlew.bat` or `./gradlew` commands.
Useful Gradle tasks and flags:

- `--continue`: when using this flag, errors will not stop the tasks from running.
- `--daemon`: thanks to this flag, Gradle daemon will be used to run chosen tasks.
- `--offline`: when using this flag, cached dependency archives will be used.
- `--refresh-dependencies`: this flag forces validation of all dependencies. Useful for snapshot versions.
- `build`: builds sources and archives of every project.
- `cleanEclipse`: removes Eclipse project data.
- `cleanIdea`: removes IntelliJ project data.
- `clean`: removes `build` folders, which store compiled classes and built archives.
- `eclipse`: generates Eclipse project data.
- `idea`: generates IntelliJ project data.
- `lwjgl3:jar`: builds application's runnable jar, which can be found at `lwjgl3/build/libs`.
- `lwjgl3:run`: starts the application.
- `test`: runs unit tests (if any).

Note that most tasks that are not specific to a single project can be run with `name:` prefix, where the `name` should be replaced with the ID of a specific project.
For example, `core:clean` removes `build` folder only from the `core` project.

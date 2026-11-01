# 2D Shadow Clash

A compact libGDX 1.14.0 desktop fighting game. The code is split into a GL-free combat model and a small
render/input layer so game rules stay easy to inspect and test.

## Run it

On Windows:

```powershell
.\gradlew.bat lwjgl3:run
```

Build and launch the runnable JAR:

```powershell
.\gradlew.bat lwjgl3:jar
java -jar .\lwjgl3\build\libs\ShadowClash.jar
```

## Controls

- Left/Right: walk; hold to run; double-tap away from the opponent to back-dash
- Up: jump
- Down: crouch
- J, K, L: light attacks
- U, I, O: heavy attacks
- P, semicolon, apostrophe: special attacks, available below 75 HP
- M or comma: block; hold Down as well to crouch-block
- R: restart the match

## Code map

- `ClashWorld`: match phases, time stepping, combat resolution, projectiles, KO flow, and separation
- `Fighter`: movement/action state machine, physics, facing, reactions, and collision volumes
- `Move`: the nine named move definitions and their exact damage, timing, height, and reaction data
- `AIController`: deterministic CPU decisions and reactive defense
- `Assets`: sprite-region loading and animation construction
- `MatchScreen`: keyboard input, presentation, HUD, and the optional capture harness
- `ClashWorldTest`: headless rule and edge-case coverage

## Verify it

```powershell
.\gradlew.bat clean core:test lwjgl3:jar
```

The optional QA capture run launches the actual JAR, scripts both match outcomes, and writes nine PNGs:

```powershell
java -Dclash.capture=true -Dclash.captureDir=captures -jar .\lwjgl3\build\libs\ShadowClash.jar
```

## License

This project is available under the [MIT License](LICENSE).

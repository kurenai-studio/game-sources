# STEPS

Two parts: **A** is what I did, in order, to build this project without Unreal installed. **B** is what you do to build and play it.

---

## Part A: steps taken

1. **Checked the machine.** No Unreal Engine, no Visual Studio or MSVC, no g++, no CMake, no .NET. Only Python and pip. So the engine, the editor and Unreal Build Tool were all out of reach.
2. **Found a way to compile C++ anyway.** `pip install ziglang` (into a scratch folder) ships a clang-based C++ compiler as `zig c++`. Plain C++17 can be compiled and run locally with it. Unreal code cannot, because there are no Unreal headers.
3. **Decided the architecture around that limit.**
   - All game rules go in plain C++17 with no Unreal includes (`Source/CoinRun/Rules`), so they can be tested for real.
   - The Unreal layer (`Source/CoinRun/Game`) stays thin: read keys, move actors, draw the HUD.
   - No binary assets (a `.uasset` or `.umap` cannot be hand-written), so the game uses the engine's built-in basic shapes, the engine's empty `/Engine/Maps/Entry` map, and builds everything else at runtime.
4. **Designed the game ("Coin Run").** A small arcade loop with enough rules to test: coins with a combo multiplier and a time bonus, drifters that steer toward you, a dash with a cooldown and i-frames, waves that scale difficulty, health, a time limit, a saved best score.
5. **Wrote the rules** (`Vec2`, `Rng`, `Tuning`, `Dash`, `RunState`, `Motion`, `Spawner`, `HighScore`): no exceptions, no RTTI, no Unreal names, trailing-underscore members so nothing shadows (Unreal treats shadowing as a warning or error).
6. **Wrote 76 tests** with a small dependency-free runner (Google Test and Catch2 need packages I did not want to depend on) and ran them with `zig c++ -std=c++17 -Wall -Wextra -Wshadow`: all pass, no warnings in project files. Includes a whole-run simulation that mirrors the Unreal tick loop: a player who never moves is defeated in under 30 s, a coin-chasing bot scores, drifters never leave the arena, and the same seed gives the same run.
7. **Mutation-checked the tests.** A script copies the sources, applies one deliberate break (28 in total: combo cap, invulnerability, dash i-frames, off-by-one caps, steering direction, drifters faster than the player, overflow handling, RNG state, ...), rebuilds, and requires the tests to fail. It reports "pattern missed" if a break did not apply and "build error" if it did not compile, so nothing passes silently. All 28 were caught on the first run.
8. **Renamed `Core` to `Rules`.** Unreal has its own `Core` module and include root; a folder called `Core` could collide with it.
9. **Wrote the Unreal project files:** `CoinRun.uproject` (engine 5.5), the game and editor `.Target.cs`, `CoinRun.Build.cs` (adds the module folder to the include path so `#include "Rules/Foo.h"` works), the module `.cpp`, and `Config/DefaultEngine.ini` (default map, default game mode) plus `DefaultGame.ini`.
10. **Wrote the gameplay classes:** `ACoinRunGameMode` (picks pawn and HUD, spawns the director), `ACoinRunPawn` (sphere mesh and fixed top-down camera, no logic), `ACoinRunDirector` (reads keys, runs the rules each tick, spawns and moves coin and drifter actors, builds floor, walls and light), `ACoinRunHUD` (text HUD, pause and game-over screens).
11. **Reviewed my own Unreal code and fixed two things:** `TCHAR_TO_UTF8` returns a temporary, so the stored score string is now converted inside one expression instead of through a pointer that would dangle; and the `.uproject` no longer restricts target platforms to Windows.
12. **Type-checked the Unreal layer against stand-ins.** I wrote a small header that fakes the slice of the Unreal API the code uses (`AActor`, `UStaticMeshComponent`, `APlayerController`, `AHUD`, `TArray`, `FString`, ...), then compiled all 11 `.cpp` files with `-Wall -Wextra -Wshadow`. All pass. A negative control (a deliberately misspelled method) fails as it should. **This only shows my code is self-consistent. The stand-ins are from memory, so a wrong signature in both places would not be noticed.**
13. **Added CI and a reference pipeline.** `ci.yml` builds and runs the rules tests with g++ and clang++ using CMake (warnings are errors). `build-unreal.yml` is a manual reference pipeline for packaging with Epic's container image; it needs an Epic-linked account and I have not run it. I checked that the GitHub Action tags used exist.
14. **Pushed to GitHub** (both accounts) and checked CI: the rules-tests job passed with both g++ and clang++ on the first run. That run covers `Rules` only, not the Unreal classes.

Problems hit along the way: `zig c++` failed when I passed `-Werror` (it applied it to its own bundled C++ library, so I filter diagnostics to project files instead); `-fsyntax-only` is not usable with it (compile to an object file instead); Git Bash mangles compiler flags that start with `/` (used PowerShell); the folder rename needed a second pass over includes, scripts and comments.

---

## Part B: steps for you to build and play it

### What you need
- Windows 10 or 11 (the steps below are for Windows; Linux and macOS use the same project files but different IDE steps).
- **Epic Games Launcher** and **Unreal Engine 5.5** (Launcher → Unreal Engine → Library → add version 5.5). This is a large download.
- **Visual Studio 2022** with the **Game development with C++** workload, which includes the Windows SDK and the MSVC toolchain.
- About 20 GB free for the engine's intermediate files plus the project's build output.

### Build and run
1. Clone the repo: `git clone https://github.com/Sup3rMar10/unreal-coin-run.git` (or the Supp3r-Man copy) and open the folder.
2. Right-click `CoinRun.uproject` → **Generate Visual Studio project files**. If Windows shows no such entry, run the launcher once first so the Unreal file association exists. If you have a different engine version, right-click → **Switch Unreal Engine version**, or edit `EngineAssociation` and the `Unreal5_5` and `V5` settings in the two `.Target.cs` files.
3. Open `CoinRun.sln` in Visual Studio. Set the configuration to **Development Editor** and the platform to **Win64**. Set `CoinRun` as the startup project. Build with **Ctrl+B**. The first build compiles the game module (a few minutes).
4. Press **F5** (or open `CoinRun.uproject`). The editor opens on the engine's empty `Entry` map. Press **Play** (Alt+P). The project's game mode builds the arena and starts the game.
5. Controls: W/A/S/D or arrows to move, Space to dash, P to pause, R or Space to restart after game over.

### Make a standalone build
- In the editor: **Platforms → Windows → Package Project**, pick an output folder. Or from a command prompt:
  `"<UE install>\Engine\Build\BatchFiles\RunUAT.bat" BuildCookRun -project="<path>\CoinRun.uproject" -platform=Win64 -clientconfig=Development -build -cook -stage -pak -archive -archivedirectory="<out>"`.

### Run the rules tests without Unreal
```
cmake -S Tests/rules -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
```
Expect `76 passed, 0 failed`.

### If it does not build or run
The Unreal layer has never met a real compiler, so expect to fix something. Likely suspects, most likely first:
1. **Target files:** `BuildSettingsVersion.V5` and `EngineIncludeOrderVersion.Unreal5_5` only exist in recent engines. On an older engine, use `V2` and the matching `Unreal5_x` value.
2. **A wrong include or signature** somewhere in `Source/CoinRun/Game`. Unreal's error message names the file and line; the fix is usually a one-line include or a renamed function.
3. **Engine content paths:** `/Engine/BasicShapes/Sphere.Sphere`, `/Engine/BasicShapes/Cube.Cube`, `/Engine/BasicShapes/BasicShapeMaterial.BasicShapeMaterial`. If shapes are missing, check these in the Content Browser (enable *Show Engine Content*).
4. **Shapes show up grey instead of coloured:** the dynamic material sets a parameter named `Color`; if the basic-shape material uses another parameter name, change it in `CoinRunPawn.cpp` and `CoinRunDirector.cpp`.
5. **Black screen:** the map has no lighting, and the director spawns one directional light. Check the output log, or raise `SetIntensity` in `CoinRunDirector.cpp`. Auto exposure is turned off in `DefaultEngine.ini`, which may make a dark scene look darker.
6. **The game mode is not used:** a map's World Settings can override the project default. Check Project Settings → Maps & Modes and the map's World Settings → Game Mode Override.
7. **Camera angle or distance:** `CoinRunPawn.cpp` (pitch `-65`, arm length `2400`). The arena is 3000 cm wide.
8. **Keys do not respond:** click the game window first so it has input focus.

If you send me the first build error or the editor's output log, I can fix it from there.

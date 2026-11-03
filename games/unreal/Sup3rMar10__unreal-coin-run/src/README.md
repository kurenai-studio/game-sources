# unreal-coin-run

![ci](https://github.com/Sup3rMar10/unreal-coin-run/actions/workflows/ci.yml/badge.svg)

A small top-down arcade game for **Unreal Engine 5.5**, written entirely in C++ with no content assets: steer a glowing sphere around a square arena, grab gold coins before time runs out, dodge red drifters that home in on you, and dash through them when they get close.

> **What is verified, and what is not.** I wrote this on a machine with **no Unreal Engine installed**, so **the project has never been opened, compiled or played in Unreal**. What *was* checked:
> - The game rules (scoring, combo, health, waves, dash, spawning, steering, collision maths) live in plain C++17 under `Source/CoinRun/Rules` with no Unreal headers, and **76 tests pass** on them (locally with clang from the `ziglang` pip package; in CI with g++ and clang++, warnings as errors). I broke the rules on purpose 28 ways and the tests failed every time.
> - The Unreal-facing classes in `Source/CoinRun/Game` were compiled (all 11 `.cpp` files, `-Wall -Wextra -Wshadow`) against **hand-written stand-ins** for the Unreal API. That catches typos, type errors and scope mistakes in my code. It does **not** check that I used the real Unreal API correctly: the stand-ins are my own memory of it.
> - Not checked at all: that the project compiles under Unreal Build Tool, the engine content paths (`/Engine/BasicShapes/...`, `/Engine/Maps/Entry`), the material parameter name `"Color"`, the `.Target.cs` settings for 5.5, the spawned light, the camera, the HUD, and how the game looks or feels. If the first build fails, those are the places to look; `STEPS.md` lists the likely suspects.

## Play it

Full instructions are in [`STEPS.md`](STEPS.md) (Part B). Short version, on Windows with Unreal Engine 5.5 and Visual Studio 2022 (C++ game development workload) installed:

1. Right-click `CoinRun.uproject` → **Generate Visual Studio project files**.
2. Open `CoinRun.sln`, choose **Development Editor / Win64**, build.
3. Open `CoinRun.uproject` and press **Play**. There is no map to set up: the project's game mode builds the floor, walls, light, player, coins and drifters at start-up.

| Key | Action |
|---|---|
| W A S D / arrow keys | Move (W is up the screen) |
| Space | Dash (short burst, passes through drifters, 1.2 s cooldown) |
| P / Esc | Pause |
| R / Space / Enter | Restart after game over |

**Rules.** You start with 45 seconds and 3 health. A coin is worth 10 points times a combo multiplier (1 to 4, one step per coin collected within 3 seconds of the previous) and adds 1.5 seconds (capped at 60). Every 8 coins is a wave: bonus points, and more and faster drifters (always slower than you, so a moving player can get away). A drifter touch costs one health, resets the combo and gives 1.5 s of invulnerability; a dash ignores hits. The run ends at zero time ("TIME UP") or zero health ("CAUGHT"). The best score is saved in the game's user settings ini.

## Layout

```
CoinRun.uproject                  project file (engine association 5.5)
Config/                           DefaultEngine.ini (default map + game mode), DefaultGame.ini
Source/CoinRun.Target.cs          game target;  CoinRunEditor.Target.cs: editor target
Source/CoinRun/CoinRun.Build.cs   module rules (adds the module dir to the include path)
Source/CoinRun/Rules/             engine-free rules: RunState, Dash, Motion, Spawner, Tuning, HighScore, Rng, Vec2
Source/CoinRun/Game/              Unreal layer: CoinRunGameMode, CoinRunPawn, CoinRunDirector, CoinRunHUD
Tests/rules/                      console test runner + CMake project for Rules (no Unreal needed)
.github/workflows/                ci.yml (builds and runs the rules tests), build-unreal.yml (reference, never run)
STEPS.md                          what I did, in order, and how to build and play it
```

Design choices worth knowing:
- **Rules separate from engine.** The Unreal layer only reads keys, moves actors and asks `Rules` what happened. That is what makes the part that matters testable without the engine. The folder is called `Rules`, not `Core`, to stay clear of Unreal's own `Core` module.
- **No binary assets.** Shapes are the engine's built-in basic shapes (sphere, cube) tinted through the basic-shape material; text is drawn with the default font. Nothing binary is committed, which is also why nothing here could be authored without the editor.
- **No map.** The project uses the empty `/Engine/Maps/Entry` and the game mode builds the scene at runtime.
- **Collision by distance checks**, not Unreal physics: circles only, deterministic, and the same function the tests exercise.
- **Passive pawn.** `ACoinRunDirector` owns the game state and moves the pawn; the pawn is only a mesh and a camera.
- **Own RNG** (xorshift) so spawn sequences are identical on every platform and the spawn tests are stable.
- **Input by polling** (`IsInputKeyDown`), so no input-mapping assets or Enhanced Input setup are needed.

## Run the rules tests (no Unreal needed)

```
cmake -S Tests/rules -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
```

It prints `76 passed, 0 failed`. CI runs the same steps with g++ and clang++.

## Build and package

- **In the editor:** File → Package Project → Windows.
- **Command line (RunUAT):** `RunUAT BuildCookRun -project=<path>\CoinRun.uproject -platform=Win64 -clientconfig=Development -build -cook -stage -pak -archive -archivedirectory=<out>`.
- **GitHub:** this repo is the source. `build-unreal.yml` is a manual reference pipeline that needs Epic's container image (a GitHub account linked to an Epic account) and enough disk for it. I have not run it and its image tag and paths are unchecked.

## Known gaps

- Never opened or compiled in Unreal; look, feel and tuning (speeds, spawn rates, camera distance) are guesses.
- No sound, no particles, no touch or gamepad support.
- The scene lighting is a single spawned directional light on an otherwise empty map, so it may look flat or dark.
- Only the sphere and cube shapes are used, so drifters and coins differ only by colour and size.
- The module is compiled with default Unreal warning settings; I have not seen what Unreal's compiler thinks of it.

## License

MIT

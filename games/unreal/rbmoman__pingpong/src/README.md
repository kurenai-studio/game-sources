# PingPong

A retro 1980s-style arcade Pong game built with **Unreal Engine 5.7** and **Visual C++**.

![Gameplay](https://img.shields.io/badge/Platform-Windows-blue) ![Engine](https://img.shields.io/badge/Unreal_Engine-5.7-black) ![License](https://img.shields.io/badge/License-MIT-green)

## About

Human vs AI Pong with an authentic phosphor-monitor aesthetic — the look and feel of the earliest arcade computers. No menus, no scoring, no distractions. The game starts immediately and runs until you quit.

## Features

- Black background with white paddles and a yellow ball
- CRT scanline overlay and phosphor glow effect
- Letterboxed 16:9 field with screen-edge vignette
- AI opponent that tracks the ball (beatable)
- Continuous play — ball resets to center on each point
- All rendering via 2D HUD canvas draw calls (no 3D meshes)

## Controls

| Key | Action |
|-----|--------|
| W / Up arrow | Move paddle up |
| S / Down arrow | Move paddle down |
| ESC | Quit |

## Requirements

- Windows 10/11 x64
- [Unreal Engine 5.7](https://www.unrealengine.com)
- Visual Studio 2022 with C++ game development workload

## Building from Source

1. Right-click `PingPong.uproject` → **Generate Visual Studio project files**
2. Open `PingPong.sln` in Visual Studio 2022
3. Build target: **Development Editor / Win64**
4. Open the project in UE Editor
5. Create an Empty Level, set **Game Mode Override** to `PingPongGameMode`, save as `/Game/Maps/PingPongMap`
6. Set the default map in **Project Settings → Maps & Modes**
7. Hit **Play** or package via **Platforms → Windows → Package**

## Architecture

| Class | Role |
|-------|------|
| `APingPongGameMode` | Ball physics, wall/paddle collision, AI movement, game loop |
| `APingPongHUD` | All 2D rendering: paddles, ball, glow, scanlines, vignette |
| `APingPongPlayerController` | Input axis capture (W/S, arrows), ESC to quit |

Game state is stored in normalized `[0..1]` coordinates and scaled to screen pixels at render time, maintaining a 16:9 aspect ratio with letterboxing on any resolution.

## License

MIT — free to use, modify, and distribute.

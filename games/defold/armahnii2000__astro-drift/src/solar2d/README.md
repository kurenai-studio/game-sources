# Astro Drift — Solar 2D (Corona SDK)

Drifting-ship demo for [Solar 2D](https://solar2d.com/) (the open-source continuation of the Corona SDK). Pure Lua.

## Run

1. Install the [Solar 2D Simulator](https://solar2d.com/) for Windows/macOS/Linux.
2. Open the simulator and choose **File → Open Project…**, then select this `solar2d/` directory.
3. The simulator runs the project in a 960×540 landscape window.

## Files

- `main.lua` — game loop, input, ship physics, bullets, screen wrap, starfield
- `config.lua` — content scaling (`letterbox`) and target FPS
- `build.settings` — orientation, window mode, title

## Controls

`W`/`↑` thrust · `A`/`D`/`←`/`→` rotate · `Space`/`J` fire · `Esc` quit

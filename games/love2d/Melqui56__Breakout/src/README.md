# Breakout

> A classic brick-breaking arcade game in **Lua**, built with **LÖVE 2D**, modeled around clean object-oriented design.

Breakout is a lightweight, architecture-first implementation of the classic
*Breakout* arcade game. The project models entities, responsibilities and the
game state machine **before** the logic is implemented — the result is a
small, readable, and extensible codebase where every class has a single
responsibility.

It began as the ACA 1 architecture (design + skeleton) and became a fully
playable game in the ACA 2: collisions, states, data-driven levels, special
bricks, power-ups and game feel.

## Table of contents

- [Features](#features)
- [Getting started](#getting-started)
- [Gameplay](#gameplay)
- [Project structure](#project-structure)
- [Documentation](#documentation)
- [Delta from ACA 1](#delta-from-aca-1)
- [Building portable releases](#building-portable-releases)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Object-oriented entities** — one class per file, each with a single
  responsibility. The base model (`Ball`, `Paddle`, `Brick`, `Level`, `Game`,
  `UI`) grew with `StrongBrick` (inheritance + polymorphism) and `PowerUp`.
- **Reusable finite state machine** — a `StateMachine` class with six states
  (title, serve, play, pause, game over, victory) and event-driven transitions,
  instead of scattered boolean flags.
- **AABB collisions** — ball vs. walls, paddle and bricks, with correct axis
  resolution (smallest overlap) and **sub-stepping** to avoid tunneling.
- **Angle bounce on the paddle** — the reflection depends on the impact point.
- **Data-driven levels** — levels are plain Lua tables (`src/levels.lua`); add a
  level by adding a table, no logic changes.
- **Polymorphism in action** — the collision loop never asks what kind of brick
  it hit; each brick answers through its own `onHit()`.
- **Power-ups** — multiball, wide paddle and extra life. The effect is a
  function passed to the power-up, so it does not know what it does.
- **Game feel** — particles, screen shake, tweening (paddle width, hit flash)
  and sound effects.
- **Delta-time driven loop** — input → update → render, frame-rate independent.
- **Cross-platform** — setup and run helpers for Linux, macOS and Windows.

## Getting started

### Prerequisites

- [LÖVE 2D](https://love2d.org/) 11.x (bundles Lua)

### Install LÖVE automatically

| OS | Command |
|---|---|
| Linux (Fedora/RHEL, Debian/Ubuntu, Arch) | `./scripts/setup.sh` |
| macOS | `./scripts/setup.sh` |
| Windows | `powershell -ExecutionPolicy Bypass -File scripts\setup.ps1` |

### Run

| OS | Command |
|---|---|
| Linux / macOS | `./scripts/run.sh` |
| Windows | `powershell -ExecutionPolicy Bypass -File scripts\run.ps1` |
| Any (with LÖVE on PATH) | `love .` |

## Gameplay

- **Controls**
  - `←` / `→` or `A` / `D` — move the paddle
  - `Enter` / `Space` — start and launch the ball
  - `P` — pause / resume
  - `Esc` — pause / back to menu
  - `R` — restart from the game over / victory screen
- **Rules**
  - Clear all bricks to advance to the next level (4 levels).
  - Normal bricks: 10 points · strong bricks: 5 points on the first hit and 20 when destroyed.
  - You start with 3 lives; losing every ball costs one life.
  - Destroyed bricks may drop a power-up: **M** multiball, **W** wide paddle,
    **+** extra life.
  - The ball deflects off the paddle based on the impact point.
  - Win by clearing every level; lose by running out of lives.

## Project structure

```
Breakout/
├── main.lua              # LÖVE callbacks; wires the state machine
├── conf.lua              # LÖVE configuration
├── assets/               # Sound effects (generated .wav)
├── scripts/              # setup / run / build helpers
├── src/
│   ├── config.lua        # Shared game constants
│   ├── ball.lua          # Moving projectile
│   ├── paddle.lua        # Player-controlled platform
│   ├── brick.lua         # Base destructible block
│   ├── strongbrick.lua   # Resistant brick (inherits Brick, overrides onHit)
│   ├── powerup.lua       # Falling power-up (effect as a function)
│   ├── level.lua         # Bricks of a stage and completion
│   ├── levels.lua        # Level data (Lua tables)
│   ├── collision.lua     # AABB detection and resolution
│   ├── statemachine.lua  # Reusable finite state machine
│   ├── scene.lua         # Shared world rendering
│   ├── effects.lua       # Particles, screen shake, tween helpers
│   ├── game.lua          # Shared world state
│   ├── ui.lua            # HUD and messages
│   └── states/           # title, serve, play, pause, gameover, victory
├── data/                 # (reserved for external level data)
└── docs/
    ├── architecture.md   # UML class diagram and responsibilities
    ├── state-machine.md  # States, transitions and edge cases
    ├── game-loop.md      # Main loop pseudocode
    ├── lua-fundamentals.md
    ├── oop-in-lua.md
    └── design-justification.md
```

## Documentation

### Diagrams

| Diagram | Image | PlantUML source |
|---|---|---|
| UML class diagram (ACA 1) | [`docs/uml/class-diagram.png`](docs/uml/class-diagram.png) | [`docs/uml/class-diagram.puml`](docs/uml/class-diagram.puml) |
| UML class diagram (final, ACA 2 delta) | [`docs/uml/class-diagram-final.png`](docs/uml/class-diagram-final.png) | [`docs/uml/class-diagram-final.puml`](docs/uml/class-diagram-final.puml) |
| State machine (FSM) | [`docs/uml/state-machine.png`](docs/uml/state-machine.png) | [`docs/uml/state-machine.puml`](docs/uml/state-machine.puml) |

### Documents

- [Architecture](docs/architecture.md) — UML class diagram, responsibilities and relationships.
- [State machine](docs/state-machine.md) — game flow, transitions and edge cases.
- [Game loop](docs/game-loop.md) — main loop pseudocode.
- [Lua fundamentals](docs/lua-fundamentals.md) — how the Lua runtime works.
- [Object-oriented programming in Lua](docs/oop-in-lua.md) — the metatable class pattern.
- [Design justification](docs/design-justification.md) — rationale for every architectural decision.

## Delta from ACA 1

The ACA 1 deliverable was the architecture and a runnable skeleton. The ACA 2
turns it into a playable game:

| Added in ACA 2 | Why |
|---|---|
| `collision.lua` | AABB detection + axis resolution + angle bounce (the core of the course). |
| `statemachine.lua` + `states/` | The FSM moved out of `Game` into a reusable class; 4 → 6 states (serve, victory). |
| `strongbrick.lua` | Real polymorphism: same `onHit()` signature, different behavior. |
| `powerup.lua` + effects | Data-driven variety and game feel (particles, shake, tween, sound). |
| `levels.lua` | Levels as data instead of hard-coded logic. |

## Building portable releases

Releases are **built and published manually** (no automated CI/CD).

```bash
./scripts/build.sh 0.2.0                # Linux/macOS
powershell -ExecutionPolicy Bypass -File scripts\build.ps1   # Windows
```

Artifacts are written to `dist/`:

- `Breakout.love` — portable package (runs on any OS with LÖVE).
- `Breakout-linux-x86_64.tar.gz` — self-contained Linux bundle.
- `Breakout-win64/Breakout.exe` and `Breakout-win64.zip` — Windows portable.

See [RELEASING.md](RELEASING.md) for the full manual release checklist.

## Contributing

We use a simple branch workflow:

- `main` — protected. Only maintainers push or merge here.
- `dev` — integration branch for the team.
- `feature/*` — short-lived branches created from `dev`; merged via **pull requests**.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

[MIT](LICENSE)

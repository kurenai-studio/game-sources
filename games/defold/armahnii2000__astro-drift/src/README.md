# Astro Drift — Multi-Engine Game Studies

**▶ Play in your browser: [armahnii2000.github.io/astro-drift](https://armahnii2000.github.io/astro-drift/)**

A single drifting-ship Asteroids-style game implemented across **eight game engines and frameworks**, side-by-side, as a comparison study. Each subfolder is a self-contained project with its own README and run instructions.

Three engines ship as live browser builds (Godot, Love 2D, PyGame). The other five are source-of-truth projects you open in their respective editors.

| Folder | Engine / Framework | Language | Status |
|---|---|---|---|
| [`godot/`](godot/) | Godot 4.6 | GDScript | **Full game** — waves, lives, scoring, splitting asteroids |
| [`love2d/`](love2d/) | LÖVE 2D 11.x | Lua | **Runnable demo** — ship, bullets, screen wrap |
| [`solar2d/`](solar2d/) | Solar 2D / Corona SDK | Lua | **Runnable demo** — opens in Solar 2D Simulator |
| [`defold/`](defold/) | Defold 1.8+ | Lua | **Editor-ready project** — collection + game objects + scripts |
| [`pygame/`](pygame/) | PyGame 2.5+ | Python | **Runnable demo** — ship, bullets, starfield |
| [`panda3d/`](panda3d/) | Panda 3D 1.10+ | Python | **Runnable 3D demo** — ship on world plane with lighting |
| [`unity/`](unity/) | Unity 2022.3 LTS | C# | **Source-of-truth scripts** — PlayerController, Bullet, Asteroid, GameManager |
| [`stride/`](stride/) | Stride 4.2 | C# | **Source-of-truth scripts** — PlayerScript, BulletScript |

## The shared concept

A small ship drifts through space with **inertial movement**: thrust accelerates in the facing direction, drag bleeds off velocity, rotation is independent of velocity, and the ship wraps when leaving the screen. The Godot version extends this to a full Asteroids-style game with three asteroid size tiers that split on hit, wave progression, lives, and a score HUD.

Each port keeps the same physics constants (`THRUST=350`, `ROT_SPEED=4`, `DRAG=0.55`, `MAX_SPEED=480` in 2D pixel-units; scaled equivalents in the 3D scenes) so they all *feel* the same when piloted.

## Why a multi-engine repo

Most engines look impressive in isolation — the interesting question is how the *same idea* maps onto different runtimes:

- **Scene tree vs. game-object vs. ECS** — Godot's typed `Node2D` tree, Defold's flat game-object + script model, Stride's entity-component-script triad
- **Render loop ownership** — Love 2D's `love.update`/`love.draw` callbacks, PyGame's explicit `while True:` loop, Panda 3D's `taskMgr.add` cooperative scheduler, Unity's `Update()` dispatch
- **Coordinate systems** — Godot/Love/PyGame Y-down 2D pixels, Solar 2D content-coordinates with letterbox scaling, Panda 3D Z-up right-handed 3D, Unity Y-up 2D-in-3D, Stride Y-up 3D
- **Input** — polled (`Input.is_physical_key_pressed`, `pygame.key.get_pressed`) vs. event-driven (Defold `on_input`, Love 2D `keypressed`) vs. binding maps (Defold `game.input_binding`)
- **Asset pipeline** — Godot's editor-managed `.import` cache, Unity's `.meta` GUIDs, Stride's `.sdpkg` packages, Defold's binary-compiled collections

## Controls (all versions)

| Action | Keys |
|---|---|
| Rotate | `A`/`D` or `←`/`→` |
| Thrust | `W` or `↑` |
| Fire | `Space` or `J` |
| Quit | `Esc` |

## Repository layout

```
astro-drift/
├── README.md              ← you are here
├── godot/                 ← Godot 4 full game
├── love2d/                ← LÖVE 2D demo
├── solar2d/               ← Solar 2D / Corona demo
├── defold/                ← Defold project
├── pygame/                ← PyGame demo
├── panda3d/               ← Panda 3D 3D demo
├── unity/                 ← Unity C# scripts
└── stride/                ← Stride C# scripts
```

## Author

Built as a portfolio piece for evaluating multi-engine game development experience.

## License

This project is licensed under the [MIT License](LICENSE).

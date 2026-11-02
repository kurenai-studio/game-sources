# Astro Drift — Godot 4

The reference implementation: a full Asteroids-style game in Godot 4.6 with GDScript.

## Engine twist — CRT post-process shader

`shaders/crt.gdshader` is a fragment shader stacked on top of the gameplay via a `CanvasLayer + ColorRect` with `material = ShaderMaterial`. It samples `hint_screen_texture` and applies:

- **Phosphor bloom** — 6-tap neighborhood sum, additive
- **Scanlines** — sine-modulated brightness reduction along Y
- **Barrel distortion** — UV remap that bulges the image outward like a curved CRT face
- **Chromatic aberration** — red sampled slightly right, blue slightly left
- **Vignette** — corner darkening using `uv * (1 - uv)`

On by default. Toggle with **`T`**.

## Run

```sh
godot --path .
```

Or open this folder in the Godot editor and press `F5`.

## Controls

| Action | Keys |
|---|---|
| Rotate | `A`/`D` or `←`/`→` |
| Thrust | `W` or `↑` |
| Fire | `Space` or `J` |
| Toggle CRT shader | `T` |
| Restart after Game Over | `R` |

## Project layout

```
godot/
├── project.godot          ← engine config
├── icon.svg
├── scenes/Main.tscn       ← entry scene (Node2D + Main.gd)
├── scripts/
│   ├── Main.gd            ← game manager: waves, lives, score, CRT setup
│   ├── Player.gd          ← ship: input, physics, shooting
│   ├── Bullet.gd          ← projectile + Area2D collision
│   ├── Asteroid.gd        ← drifting asteroid, procedural shape, size tiers
│   └── HUD.gd             ← Label HUD on a CanvasLayer
└── shaders/
    └── crt.gdshader       ← CRT post-process (the twist)
```

# Astro Drift — Love 2D

Full Asteroids game in [LÖVE 2D](https://love2d.org/) 11.x. Pure Lua, no image assets.

## Engine twist — authentic vector-display phosphor

Every shape is drawn three times in the same pass:

1. **Wide outer halo** — additive blend, width 8, alpha 0.12 — the soft "glow"
2. **Narrow inner halo** — additive blend, width 4, alpha 0.25 — the "beam"
3. **Crisp stroke** — normal blend, width ~1.4, alpha 1.0, with per-frame brightness flicker — the "phosphor trace"

The result is the look of a 1979 Atari vector monitor: lines that bloom outward, slightly flickering, with no fill. A fragment shader on a fullscreen offscreen canvas adds scanlines and a vignette before final blit.

## Run

```sh
love .
```

Or drag this `love2d/` folder onto the LÖVE executable.

## Files

- `main.lua` — game loop, input, ship + asteroids + bullets, splitting, screen wrap, phosphor draw routine, CRT shader
- `conf.lua` — window config

## Controls

| Action | Keys |
|---|---|
| Rotate | `A`/`D` or `←`/`→` |
| Thrust | `W` or `↑` |
| Fire | `Space` or `J` |
| Restart after Game Over | `R` |
| Quit | `Esc` |

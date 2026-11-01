# Astro Drift — PyGame

Full Asteroids game in [PyGame](https://www.pygame.org/) 2.5+. Single Python file, pure stdlib + numpy.

## Engine twist — Python-native showcases

This is the one engine where the *language ecosystem* is the differentiator. Two Python-specific features layered on the base game:

### 1. Procedural nebula background (numpy)

`generate_nebula()` builds a 960×540×3 `np.float32` array entirely with numpy:
- A vertical blue gradient
- 7 Gaussian "color cloud" blobs in random positions, sizes, and colors
- A per-pixel noise field thresholded into ~1500 stars

The whole image is blitted to a `pygame.Surface` in one call via `pygame.surfarray.make_surface(...)`. No PNGs, no Photoshop — the backdrop is mathematics.

### 2. AI autopilot (`Tab` to toggle)

`ai_step()` is a deterministic heuristic — readable in 20 lines:

1. Find the **nearest asteroid** by distance.
2. Compute the desired heading toward it.
3. Rotate to align (left or right based on signed angular diff).
4. Thrust forward when aligned and farther than 180 px.
5. Fire when aligned and within 500 px range.
6. Override with **dodge mode** if any asteroid is inside an 80 px danger radius — thrust away from the target axis.

No ML model, no opaque weights. Every decision is visible in the source. Watching the AI play through a wave is a tidy demonstration of why Python-first engines are useful for AI/game-research work.

## Run

```sh
python -m pip install -r requirements.txt
python main.py
```

## Controls

| Action | Keys |
|---|---|
| Rotate | `A`/`D` or `←`/`→` |
| Thrust | `W` or `↑` |
| Fire | `Space` or `J` |
| Toggle AI autopilot | `Tab` |
| Restart after Game Over | `R` |
| Quit | `Esc` |

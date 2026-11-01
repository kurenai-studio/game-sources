# Astro Drift — Panda 3D

3D restatement of the Astro Drift drifting-ship demo, built with [Panda 3D](https://www.panda3d.org/) 1.10+. The 2D arcade idea projected into a 3D scene: a box-mesh ship drifts across the XY plane with screen-wrap at the world bounds, lit by an ambient + directional light pair.

## Run

```sh
python -m pip install -r requirements.txt
python main.py
```

## Files

- `main.py` — `ShowBase` subclass with task loop, lighting, input map, and screen-wrap
- `requirements.txt` — `panda3d>=1.10`

## Controls

`W`/`↑` thrust · `A`/`D`/`←`/`→` rotate · `Esc` quit

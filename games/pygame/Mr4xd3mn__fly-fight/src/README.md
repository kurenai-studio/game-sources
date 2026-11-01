# Fly Fight

A Pygame combat game in which the player fights a fly controlled by the
`flybrain` connectome. The connectome implementation is maintained in
[alextitonis/fly.ai](https://github.com/alextitonis/fly.ai).

## Features

- Continuous HP-based combat with respawns instead of rounds.
- Keyboard movement, mouse firing, pause, restart, and fullscreen support.
- Multiple weapons, including EMP, jammer, and synapse-overload effects.
- Brain-driven fly behavior and neural status display.
- Optional JSONL logs for simulation steps and game events.
- A local web dashboard under `webcatch/`.

## Requirements

- Python 3.11 or newer.
- The `flybrain` package and its connectome data. Install them from
  [alextitonis/fly.ai](https://github.com/alextitonis/fly.ai).
- NVIDIA CUDA/CuPy is supported for GPU simulation.

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

For CUDA:

```powershell
python -m pip install -r requirements-gpu.txt
```

## Run

The bridge launches the desktop game:

```powershell
$env:FLY_DEVICE="cpu"
python .\fly_catch_bridge.py
```

For CUDA:

```powershell
$env:FLY_DEVICE="cuda"
$env:FLY_BRAIN_LOG="brain_logs\session.jsonl"
python .\fly_catch_bridge.py
```

Set `FLY_BRAIN_LOG=off` to disable logging. Runtime logs are not committed.

## Controls

| Input | Action |
|---|---|
| WASD / arrow keys | Move |
| Left mouse button | Fire |
| 1-0 | Select weapon |
| P | Pause/resume |
| R | Restart after game over |
| F11 | Toggle fullscreen |
| Esc | Leave fullscreen, then quit |

## Web dashboard

The web version is a local dashboard:

```powershell
python .\webcatch_server.py
```

Then open `webcatch/index.html` or follow the server's printed address.

## License

MIT. See [LICENSE](LICENSE).

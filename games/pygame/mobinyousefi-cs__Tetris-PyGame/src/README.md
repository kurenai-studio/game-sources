# Tetris (PyGame)

A clean, production‑ready Tetris implementation using PyGame — structured for real-world
Python projects (src/ layout, tests, CI, linting, and packaging).

https://github.com/mobinyousefi-cs

## Features
- Standard 10×20 Tetris board with 7 tetrominoes and rotation.
- Soft/Hard drop, left/right, rotate, pause, restart.
- Line clear, level & scoring system.
- Hold‑to‑repeat movement with DAS/ARR‑like feel.
- src/ project layout, pytest tests, Ruff + Black via GitHub Actions.

## Controls
- **Left/Right**: Move piece
- **Down**: Soft drop
- **Up**: Rotate clockwise
- **Space**: Hard drop
- **P**: Pause / Resume
- **R**: Restart
- **Esc / Q**: Quit

## Install & Run
```bash
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\\Scripts\\activate
pip install -U pip
pip install -e .
python -m tetris             # or: tetris
```

## Tests
```bash
pytest
```

## License
MIT — see LICENSE.
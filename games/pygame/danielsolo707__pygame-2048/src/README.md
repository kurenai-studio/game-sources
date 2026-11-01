# 2048 — Python / Pygame

Classic **2048** puzzle game built in Python with Pygame.

This project started as a single script and is now a small Python package with pure board logic (unit-tested), a desktop UI, and a [playable web demo](https://danielsolo707.github.io/pygame-2048/) on GitHub Pages.

[![Play demo](https://img.shields.io/badge/GitHub%20Pages-Play%20demo-edc22e?style=for-the-badge)](https://danielsolo707.github.io/pygame-2048/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-blue?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

---

## Play

| Where | How |
|--------|-----|
| **Browser** | [danielsolo707.github.io/pygame-2048](https://danielsolo707.github.io/pygame-2048/) |
| **Desktop** | Run locally with Pygame (below) |

### Controls

| Key | Action |
|-----|--------|
| Arrow keys / WASD | Move tiles |
| `R` | Restart |
| Enter / Space | Continue after you reach 2048 |
| Esc / `Q` | Quit (desktop) |

---

## Run locally

```bash
# clone
git clone https://github.com/danielsolo707/pygame-2048.git
cd pygame-2048

# (optional) virtual environment
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS / Linux:
# source .venv/bin/activate

pip install -r requirements.txt
python main.py
```

Requires **Python 3.9+**.

---

## Project layout

```
pygame-2048/
├── main.py              # entry point
├── game/
│   ├── logic.py         # pure board logic (no Pygame)
│   ├── ui.py            # Pygame window, input, overlays
│   └── constants.py     # sizes, colors, win value
├── tests/
│   └── test_logic.py    # pytest — merges, win/lose, score
├── docs/                # GitHub Pages site + browser demo
│   ├── index.html
│   ├── styles.css
│   └── game.js
├── requirements.txt
└── README.md
```

**Design idea:** keep rules in `logic.py` so they can be tested without opening a window. The UI only draws state and sends moves.

---

## Features

- Classic 4×4 rules (slide, merge once per tile per move, spawn 2/4)
- Score + **best score** saved locally (desktop)
- Win banner at 2048 (keep playing or restart)
- Game over when no moves remain (including full board with no merges)
- Safe tile colors for high values (no crash past 512)
- Browser demo with keyboard, on-screen buttons, and swipe

---

## Tests

```bash
pip install -r requirements.txt
pytest -q
```

CI runs lint + tests on Python 3.9–3.11 (see `.github/workflows/`).

---

## GitHub Pages

The site under `docs/` is served at:

**https://danielsolo707.github.io/pygame-2048/**

Source → repo Settings → Pages → Deploy from branch `main` / folder `/docs` (or use the included workflow if enabled).

---

## What I learned

- Separating **game rules** from **rendering**
- Writing small **unit tests** for merges and end conditions
- Packaging a hobby project so others can clone, run, and play in the browser

---

## License

MIT — see [LICENSE](LICENSE).

Inspired by the original [2048 by Gabriele Cirulli](https://github.com/gabrielecirulli/2048).

---

**Author:** [Daniel Soleimany](https://github.com/danielsolo707)

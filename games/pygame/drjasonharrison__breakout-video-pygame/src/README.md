# 🧱 Breakout

A classic Breakout arcade game built in Python with Pygame.

![Python](https://img.shields.io/badge/Python-3.13-blue) ![Pygame](https://img.shields.io/badge/Pygame-2.0+-green)

## About

Destroy all the bricks by bouncing a ball off your paddle. Features smooth physics, particle effects, and increasing difficulty as the ball speeds up throughout the game.

## Features

- **Angle-based paddle physics** — where the ball hits the paddle determines the bounce angle
- **6 rows of color-coded bricks** with varying point values (1–7 points)
- **Particle effects** on brick destruction and paddle hits
- **Ball trail & glow** visual effects
- **Progressive difficulty** — ball speed increases as bricks are destroyed
- **3 lives** per game
- **Menu, win, and game over screens**

## Requirements

- Python 3.13
- Pygame 2.0+
- macOS 10.15+ (Catalina or later)

## Installation (macOS)

### 1. Install Homebrew

If you don't have Homebrew installed yet:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Tcl/Tk and pyenv

Tcl/Tk is needed if you want full Python GUI support. Install it before building Python:

```bash
brew install tcl-tk pyenv
```

### 3. Install Python 3.13 via pyenv

```bash
pyenv install 3.13.11
pyenv local 3.13.11
```

Verify the installation:

```bash
python --version
# Should output: Python 3.13.x
```

> **Note:** Pygame does not yet support Python 3.14+. If you're on a newer Python version, use pyenv to install 3.13.

### 4. Install pipenv and create a virtual environment

```bash
pip install pipenv
pipenv --python $(pyenv which python)
```

### 5. Install Pygame

```bash
pipenv install pygame
```

### 6. Run the game

```bash
pipenv run python breakout.py
```

## Quick Start (if you already have Python 3.13)

```bash
pip install pipenv
pipenv --python 3.13
pipenv install pygame
pipenv run python breakout.py
```

## How to Play

### Controls

| Key | Action |
|---|---|
| ← → or A / D | Move paddle |
| Space | Launch ball / Start game |
| R | Restart |
| Q | Quit |

## Scoring

| Brick Row | Color | Points |
|---|---|---|
| 1–2 | Red / Orange | 7 |
| 3–4 | Yellow / Green | 5 |
| 5 | Blue | 3 |
| 6 | Purple | 1 |

## Troubleshooting

### `No module named '_tkinter'`

Install Tcl/Tk before building Python:

```bash
brew install tcl-tk
pyenv uninstall 3.13.11
pyenv install 3.13.11
```

### `PyWeakref_GetObject` build error

This means your Python version is too new for the Pygame release. Downgrade to Python 3.13:

```bash
pyenv install 3.13.11
pyenv local 3.13.11
```

### Blank/grey window on Catalina

Try running inside a virtual environment (which this setup already does via pipenv).

## Game Settings

Key constants can be tweaked at the top of `breakout.py`:

- `PADDLE_WIDTH` / `PADDLE_SPEED` — paddle size and responsiveness
- `BALL_SPEED_INITIAL` / `BALL_SPEED_MAX` — ball speed range
- `BRICK_ROWS` / `BRICK_COLS` — grid dimensions

## License

Free to use and modify. Have fun!

## Creation

- Macos Sequoia 15.7.3
- Claude and Opus 4.6
- 2026-02-13
- prompt:

  I want to make a video game, written in python, to play the game breakout

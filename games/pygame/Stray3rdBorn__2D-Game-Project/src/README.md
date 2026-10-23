# Arena Survival

[![CI](https://github.com/Stray3rdBorn/2D-Game-Project/actions/workflows/ci.yml/badge.svg)](https://github.com/Stray3rdBorn/2D-Game-Project/actions/workflows/ci.yml)

A 2D top down arena shooter built with Python and Pygame. Survive 10 waves of enemies that chase you across a single screen. Shoot them down, clear every wave to win, and beat your high score.

<!-- Add a screenshot or GIF here: ![Gameplay](docs/gameplay.png) -->

## Gameplay

You control a blue circle in the middle of the arena. Enemies spawn just outside the screen edges and walk straight at you. Clear all 10 waves to reach the win screen. If your HP reaches zero first, the run is over.

**Enemies**

| Enemy | Color | HP | Size | Speed | Points |
|---|---|---|---|---|---|
| Grunt | Red | 1 | Small | Full wave speed | 10 |
| Tank | Purple | 3 | Large | 60% of wave speed | 30 |

Tanks do not appear in wave 1. Each wave adds 10 percentage points to the chance that a spawn is a tank, up to a cap of 60% from wave 7 onward.

**Player**

- 5 HP at the start of a run.
- Touching an enemy removes that enemy and costs 1 HP. You are then immune for 1 second, and the player blinks while immune.
- Fires 10 shots per second with fast bullets.
- Moves faster than any enemy, so running away always works.

**Waves and scoring**

- Wave `n` spawns `5 + 5n` enemies, one every 0.6 seconds, from random points just outside the four screen edges.
- Enemy speed is `70 + 12n` pixels per second, capped at 220.
- Each kill gives its enemy's points: 10 for a grunt, 30 for a tank.
- Clearing wave `n` gives a bonus of `50 * n` points, followed by a 3 second break before the next wave.
- Clearing wave 10 ends the game with a win. Dying on the same frame as the final kill counts as a loss.
- The win screen shows your score, the HP you have left, and your high score.
- Your best score is saved locally in `highscore.json` when a run ends, whether you win or lose.

| Wave | Enemies | Enemy speed | Tank chance |
|---|---|---|---|
| 1 | 10 | 82 | 0% |
| 2 | 15 | 94 | 10% |
| 3 | 20 | 106 | 20% |
| 4 | 25 | 118 | 30% |
| 5 | 30 | 130 | 40% |
| 6 | 35 | 142 | 50% |
| 7 | 40 | 154 | 60% |
| 8 | 45 | 166 | 60% |
| 9 | 50 | 178 | 60% |
| 10 | 55 | 190 | 60% |

## Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` or arrow keys |
| Aim | Mouse |
| Shoot | Hold left mouse button |
| Start or restart | `Space` |
| Quit | `Esc` or close the window |

## Run locally

Requires Python 3.12 or newer.

```bash
git clone <repository url>
cd <repository folder>

python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS and Linux

pip install -r requirements.txt
python client/main.py
```

## Tests

The tests use pytest and run Pygame without a window, so they work on any machine, including servers.

```bash
pip install pytest
pytest
```

They cover circle collision, screen bounds, equal speed on diagonals, hit immunity, bullets leaving the screen, enemy chasing, tank spawning rules, wave growth, tanks taking multiple hits, high score saving and recovery from a corrupted save file, and a 10 second headless run of the whole game.

## Continuous integration

A GitHub Actions workflow in `.github/workflows/ci.yml` runs on every push and pull request to `main`. It tests on Python 3.12 and 3.13 and does the following:

1. Installs the dependencies.
2. Fails the build on syntax errors and undefined names (flake8).
3. Prints a style report that does not fail the build.
4. Runs the test suite.

## How it works

The whole game is one loop that runs 60 times per second: read input, update the game state, draw the frame, repeat.

- **Game loop.** Update and draw are separate steps. State changes happen as numbers inside Python objects, and the screen is repainted from those numbers every frame.
- **Delta time.** All movement is multiplied by the seconds since the last frame, so speed stays the same on slow and fast machines. The value is capped at 0.05 seconds to avoid large jumps after a freeze.
- **State machine.** The game is always in exactly one state: `menu`, `playing`, `victory`, or `game_over`. Each frame runs only the code for the current state.
- **Vector movement.** Movement is direction times speed times delta time. Directions are normalized so diagonal movement is not faster.
- **Circle collision.** Every object is a circle, and two objects collide when the distance between their centers is smaller than the sum of their radii.
- **Data driven enemies.** One `Enemy` class holds HP, radius, color, speed, and points. A tank is the same class created with different values, chosen by a weighted random roll when it spawns.

## Project structure

```
client/
    main.py              # The game: settings, Player, Bullet, Enemy, Game loop
tests/
    test_game.py         # pytest suite, runs headless
.github/
    workflows/
        ci.yml           # GitHub Actions workflow
requirements.txt         # Python dependencies
README.md
```

## Tech stack

Python, Pygame, pytest, flake8, GitHub Actions

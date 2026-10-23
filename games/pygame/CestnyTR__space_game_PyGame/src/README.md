# Space Shooter — Pygame

A classic 2D space-shooter game built with [Pygame](https://www.pygame.org/).
The player pilots a mission ship, dodges and destroys waves of enemy ships, and
fires lasers with collision detection driven by pixel masks.

## Features

- Player-controlled mission ship with movement and shooting.
- Multiple enemy ship types (red / green / blue), each with their own lasers.
- Pixel-perfect collision detection via `pygame.mask` overlap.
- Wave-based enemy spawning, cooldown timers, and a scrolling space background.

## Layout

```
PyGame/
├── main.py          # game loop, Ship/Laser classes, collision logic
└── assets/          # sprites: ships, lasers, background
```

## Usage

```bash
python main.py
```

Game window is `750x600`. Use the keyboard to move and shoot.

## Requirements

- Python 3.x
- `pygame` (`pip install pygame`)

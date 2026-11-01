# Pong Game

A simple 2D Pong game built with Python and Pygame Community Edition.

This project follows the Model-View-Controller architecture and basic object-oriented design principles:
- Model: game state and ball/paddle logic
- View: rendering with Pygame
- Controller: input handling and main game loop

## Features
- 1-player mode against a CPU opponent
- 2-player local mode on one keyboard
- Score tracking
- Win condition at 7 points
- Start menu and restart flow

## Requirements
- Python 3.9+
- pygame

## Install
```bash
python -m pip install -r requirements.txt
```

## Run
```bash
python pong_game.py
```

## Controls
1-player mode:
- Left paddle: W / S
- Right paddle: CPU controlled

2-player mode:
- Left paddle: W / S
- Right paddle: Up / Down

Extra:
- Esc: Quit or return to menu
- 1 / 2: Choose mode

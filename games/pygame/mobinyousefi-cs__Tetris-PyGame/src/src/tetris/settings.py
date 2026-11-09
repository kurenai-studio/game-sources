#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: settings.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Game-wide constants and configuration.

===========================================================================
"""
from __future__ import annotations

# Board
COLS = 10
ROWS = 20
VISIBLE_ROWS = 20
CELL = 32  # pixels per cell
MARGIN = 2  # cell gap for grid aesthetic

# Window size
SIDE = 6 * CELL  # right panel width
WIDTH = COLS * CELL + SIDE
HEIGHT = VISIBLE_ROWS * CELL
TITLE = "Tetris — Mobin Yousefi"
FPS = 60

# Gameplay
LOCK_DELAY_MS = 500
INITIAL_GRAVITY_MS = 800  # level 1 drop
LEVELUP_LINES = 10

# Scoring
SCORES = {1: 100, 2: 300, 3: 500, 4: 800}
SOFT_DROP_POINT = 1
HARD_DROP_POINT = 2

# Colors (R, G, B)
BLACK = (16, 16, 24)
WHITE = (240, 240, 240)
GRID = (32, 34, 48)
GHOST = (160, 160, 160)

# Piece colors
COLORS = {
    "I": (0, 190, 255),
    "J": (0, 102, 204),
    "L": (255, 140, 0),
    "O": (240, 200, 0),
    "S": (48, 190, 50),
    "T": (160, 80, 200),
    "Z": (220, 60, 60),
}
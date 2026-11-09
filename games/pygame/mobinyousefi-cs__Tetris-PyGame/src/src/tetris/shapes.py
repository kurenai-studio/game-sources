#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: shapes.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Tetromino shape definitions and rotation helpers.

===========================================================================
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple

Grid = List[List[int]]

# Base shapes as 4x4 matrices (0/1)
BASE: dict[str, Grid] = {
    "I": [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "J": [
        [1, 0, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "L": [
        [0, 0, 1, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "O": [
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "S": [
        [0, 1, 1, 0],
        [1, 1, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "T": [
        [0, 1, 0, 0],
        [1, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
    "Z": [
        [1, 1, 0, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ],
}


def rotate(grid: Grid) -> Grid:
    """Rotate a 4x4 grid clockwise."""
    return [list(row) for row in zip(*grid[::-1])]


def rotations(name: str) -> Tuple[Grid, Grid, Grid, Grid]:
    g0 = BASE[name]
    g1 = rotate(g0)
    g2 = rotate(g1)
    g3 = rotate(g2)
    return g0, g1, g2, g3
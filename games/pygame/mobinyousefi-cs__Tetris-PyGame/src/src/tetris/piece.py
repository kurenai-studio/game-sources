#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: piece.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Tetromino piece class with movement & rotation.

===========================================================================
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Tuple

import pygame as pg

from . import settings as S
from . import shapes


@dataclass
class Piece:
    name: str
    x: int
    y: int
    rot: int = 0

    def grid(self) -> list[list[int]]:
        return shapes.rotations(self.name)[self.rot % 4]

    def cells(self):
        g = self.grid()
        for r in range(4):
            for c in range(4):
                if g[r][c]:
                    yield self.x + c, self.y + r

    def moved(self, dx: int = 0, dy: int = 0, drot: int = 0) -> "Piece":
        return Piece(self.name, self.x + dx, self.y + dy, (self.rot + drot) % 4)
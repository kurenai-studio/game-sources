#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: board.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Board state, collision, line clearing, scoring, and rendering helpers.

===========================================================================
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional
import random
import pygame as pg

from . import settings as S
from .piece import Piece


Grid = List[List[Optional[str]]]


def empty_grid() -> Grid:
    return [[None for _ in range(S.COLS)] for _ in range(S.ROWS)]


BAG_ORDER = ["I", "J", "L", "O", "S", "T", "Z"]


def next_bag() -> list[str]:
    b = BAG_ORDER.copy()
    random.shuffle(b)
    return b


@dataclass
class Board:
    grid: Grid = field(default_factory=empty_grid)
    current: Piece | None = None
    queue: list[str] = field(default_factory=list)
    score: int = 0
    lines: int = 0
    level: int = 1
    over: bool = False

    def refill_queue(self) -> None:
        while len(self.queue) < 7:
            self.queue.extend(next_bag())

    def spawn(self) -> None:
        self.refill_queue()
        name = self.queue.pop(0)
        self.current = Piece(name=name, x=3, y=0, rot=0)
        if not self.valid(self.current):
            self.over = True

    def gravity_ms(self) -> int:
        # speed up with level, clamp
        return max(50, int(S.INITIAL_GRAVITY_MS * (0.85 ** (self.level - 1))))

    def valid(self, p: Piece) -> bool:
        for x, y in p.cells():
            if x < 0 or x >= S.COLS or y >= S.ROWS:
                return False
            if y >= 0 and self.grid[y][x] is not None:
                return False
        return True

    def lock_piece(self) -> None:
        assert self.current is not None
        for x, y in self.current.cells():
            if 0 <= y < S.ROWS:
                self.grid[y][x] = self.current.name
        cleared = self.clear_lines()
        if cleared:
            self.lines += cleared
            self.score += S.SCORES.get(cleared, 0)
            if self.lines // S.LEVELUP_LINES + 1 > self.level:
                self.level += 1
        self.spawn()

    def clear_lines(self) -> int:
        keep = [row for row in self.grid if any(cell is None for cell in row)]
        cleared = S.ROWS - len(keep)
        while len(keep) < S.ROWS:
            keep.insert(0, [None] * S.COLS)
        self.grid = keep
        return cleared

    def move(self, dx: int = 0, dy: int = 0) -> bool:
        if not self.current:
            return False
        np = self.current.moved(dx, dy)
        if self.valid(np):
            self.current = np
            if dy > 0:
                self.score += S.SOFT_DROP_POINT
            return True
        return False

    def hard_drop(self) -> None:
        if not self.current:
            return
        dist = 0
        while self.move(0, 1):
            dist += 1
        self.score += dist * S.HARD_DROP_POINT
        self.lock_piece()

    def rotate(self) -> None:
        if not self.current:
            return
        np = self.current.moved(drot=1)
        # naive kicks: try small offsets
        kicks = [(0, 0), (-1, 0), (1, 0), (0, -1)]
        for dx, dy in kicks:
            test = np.moved(dx, dy)
            if self.valid(test):
                self.current = test
                return

    def ghost_y(self) -> int:
        if not self.current:
            return 0
        p = self.current
        y = p.y
        while True:
            test = p.moved(0, y - p.y + 1)
            if not self.valid(test):
                break
            y += 1
        return y

    def draw(self, surf: pg.Surface) -> None:
        surf.fill(S.BLACK)
        # grid
        for r in range(S.ROWS):
            for c in range(S.COLS):
                x = c * S.CELL
                y = r * S.CELL
                pg.draw.rect(
                    surf,
                    S.GRID,
                    (x + 1, y + 1, S.CELL - 2, S.CELL - 2),
                    border_radius=6,
                )
        # placed blocks
        for r in range(S.ROWS):
            for c in range(S.COLS):
                name = self.grid[r][c]
                if name:
                    self._draw_cell(surf, c, r, name)
        # ghost
        if self.current:
            gy = self.ghost_y()
            for x, _y in self.current.cells():
                if 0 <= _y < S.ROWS:
                    pg.draw.rect(
                        surf,
                        S.GHOST,
                        (x * S.CELL + 4, gy * S.CELL + 4, S.CELL - 8, S.CELL - 8),
                        width=2,
                        border_radius=6,
                    )
        # current
        if self.current:
            for x, y in self.current.cells():
                if 0 <= y < S.ROWS:
                    self._draw_cell(surf, x, y, self.current.name)

    def _draw_cell(self, surf: pg.Surface, c: int, r: int, name: str) -> None:
        import pygame as pg
        color = S.COLORS.get(name, S.WHITE)
        rect = pg.Rect(c * S.CELL + S.MARGIN, r * S.CELL + S.MARGIN, S.CELL - 2 * S.MARGIN, S.CELL - 2 * S.MARGIN)
        pg.draw.rect(surf, color, rect, border_radius=6)
        # inner shine
        inner = rect.inflate(-8, -8)
        pg.draw.rect(surf, (255, 255, 255, 32), inner, width=2, border_radius=6)
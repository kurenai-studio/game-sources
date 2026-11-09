#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: test_board.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Board logic tests (line clearing, valid moves).

===========================================================================
"""
from __future__ import annotations

from tetris.board import Board
from tetris import settings as S
from tetris.piece import Piece


def test_line_clear_single():
    b = Board()
    # fill bottom row
    for c in range(S.COLS):
        b.grid[S.ROWS - 1][c] = "I"
    cleared = b.clear_lines()
    assert cleared == 1
    assert all(cell is None for cell in b.grid[0])


def test_valid_and_move():
    b = Board()
    b.current = Piece("I", x=3, y=0)
    assert b.valid(b.current)
    assert b.move(1, 0)  # move right
    assert b.move(0, 1)  # move down
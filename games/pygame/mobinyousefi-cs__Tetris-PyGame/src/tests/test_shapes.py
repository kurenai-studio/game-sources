#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: test_shapes.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Shape rotation sanity checks.

===========================================================================
"""
from __future__ import annotations

from tetris import shapes


def test_rotate_cycle():
    for name in shapes.BASE:
        g0, g1, g2, g3 = shapes.rotations(name)
        # rotating 4 times returns to original
        g4 = shapes.rotate(g3)
        assert g4 == g0
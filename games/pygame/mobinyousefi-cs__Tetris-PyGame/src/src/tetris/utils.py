#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: utils.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Utility helpers: timers, rectangles, etc.

===========================================================================
"""
from __future__ import annotations

import pygame as pg


class RepeatKey:
    """Implements a simple key repeat (DAS/ARR-like) behavior."""

    def __init__(self, delay_ms: int = 150, interval_ms: int = 30) -> None:
        self.delay = delay_ms
        self.interval = interval_ms
        self._state: dict[int, tuple[bool, int, int]] = {}

    def update(self, key: int, is_down: bool, now_ms: int) -> bool:
        held, start, last = self._state.get(key, (False, 0, 0))
        if is_down:
            if not held:
                self._state[key] = (True, now_ms, now_ms)
                return True  # initial press
            # still held
            if now_ms - start >= self.delay and now_ms - last >= self.interval:
                self._state[key] = (True, start, now_ms)
                return True
            return False
        # released
        if held:
            self._state[key] = (False, 0, 0)
        return False
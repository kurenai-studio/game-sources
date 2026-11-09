#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: main.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Entry point.

Usage:
    python -m tetris
    # or installed script: tetris

===========================================================================
"""
from __future__ import annotations

from .game import Game


def main() -> None:
    Game().run()


if __name__ == "__main__":
    main()
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: assets.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Lightweight assets management (fonts, text rendering).

===========================================================================
"""
from __future__ import annotations

import pygame as pg
from . import settings as S


def init_fonts() -> dict[str, pg.font.Font]:
    pg.font.init()
    return {
        "lg": pg.font.SysFont("consolas", 28, bold=True),
        "md": pg.font.SysFont("consolas", 20, bold=False),
        "sm": pg.font.SysFont("consolas", 16, bold=False),
    }


def draw_text(surface: pg.Surface, text: str, pos: tuple[int, int], size: str = "md") -> None:
    fonts = init_fonts()
    font = fonts.get(size, fonts["md"])  # recreate small cache each call; cheap
    img = font.render(text, True, S.WHITE)
    surface.blit(img, pos)
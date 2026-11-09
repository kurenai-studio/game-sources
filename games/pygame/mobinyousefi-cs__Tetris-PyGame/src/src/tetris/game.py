#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===========================================================================
Project: Tetris (PyGame)
File: game.py
Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)
Created: 2025-10-26
Updated: 2025-10-26
License: MIT License (see LICENSE file for details)
===========================================================================

Main game object (loop, input, UI panels).

===========================================================================
"""
from __future__ import annotations

import pygame as pg

from . import settings as S
from .assets import draw_text
from .board import Board
from .utils import RepeatKey

DROP_EVENT = pg.USEREVENT + 1


class Game:
    def __init__(self) -> None:
        pg.init()
        self.screen = pg.display.set_mode((S.WIDTH, S.HEIGHT))
        pg.display.set_caption(S.TITLE)
        self.clock = pg.time.Clock()
        self.board = Board()
        self.board.spawn()
        self.hud = pg.Surface((S.SIDE, S.HEIGHT))
        self.playfield = pg.Surface((S.COLS * S.CELL, S.HEIGHT))
        pg.time.set_timer(DROP_EVENT, self.board.gravity_ms())
        self.paused = False
        self.repeater = RepeatKey()

    def reset(self) -> None:
        self.board = Board()
        self.board.spawn()
        pg.time.set_timer(DROP_EVENT, self.board.gravity_ms())
        self.paused = False

    def run(self) -> None:
        while True:
            now = pg.time.get_ticks()
            for e in pg.event.get():
                if e.type == pg.QUIT:
                    return
                if e.type == pg.KEYDOWN and e.key in (pg.K_ESCAPE, pg.K_q):
                    return
                if e.type == pg.KEYDOWN and e.key == pg.K_p:
                    self.paused = not self.paused
                if e.type == pg.KEYDOWN and e.key == pg.K_r:
                    self.reset()
                if self.board.over:
                    continue
                if self.paused:
                    continue
                if e.type == pg.KEYDOWN:
                    if e.key == pg.K_UP:
                        self.board.rotate()
                    if e.key == pg.K_SPACE:
                        self.board.hard_drop()
                if e.type == DROP_EVENT:
                    if not self.board.move(0, 1):
                        # lock when can't move down
                        self.board.lock_piece()
                        pg.time.set_timer(DROP_EVENT, self.board.gravity_ms())

            # continuous inputs
            keys = pg.key.get_pressed()
            if not self.board.over and not self.paused:
                if self.repeater.update(pg.K_LEFT, keys[pg.K_LEFT], now):
                    self.board.move(-1, 0)
                if self.repeater.update(pg.K_RIGHT, keys[pg.K_RIGHT], now):
                    self.board.move(1, 0)
                if keys[pg.K_DOWN]:
                    self.board.move(0, 1)

            # draw
            self.board.draw(self.playfield)
            self.draw_hud()
            self.screen.blit(self.playfield, (0, 0))
            self.screen.blit(self.hud, (S.COLS * S.CELL, 0))
            pg.display.flip()
            self.clock.tick(S.FPS)

    def draw_hud(self) -> None:
        self.hud.fill((24, 24, 36))
        draw_text(self.hud, "TETRIS", (24, 20), size="lg")
        draw_text(self.hud, f"Score: {self.board.score}", (24, 80))
        draw_text(self.hud, f"Lines: {self.board.lines}", (24, 110))
        draw_text(self.hud, f"Level: {self.board.level}", (24, 140))

        y = 200
        draw_text(self.hud, "Next:", (24, y))
        y += 30
        # preview first 3
        import pygame as pg
        from . import settings as S

        preview = pg.Surface((S.SIDE - 48, 160), pg.SRCALPHA)
        preview.fill((0, 0, 0, 0))
        px = 20
        py = 10
        for i, name in enumerate(self.board.queue[:3]):
            color = S.COLORS.get(name)
            for r in range(2):
                for c in range(3):
                    pg.draw.rect(
                        preview,
                        (32, 32, 48),
                        (px + c * 16, py + r * 16 + i * 50, 14, 14),
                        border_radius=4,
                    )
            # simple blocks representation
            pg.draw.rect(preview, color, (px + 16, py + i * 50, 14, 14), border_radius=4)
            pg.draw.rect(preview, color, (px + 32, py + i * 50, 14, 14), border_radius=4)
            pg.draw.rect(preview, color, (px + 48, py + i * 50, 14, 14), border_radius=4)
            if name != "O":
                pg.draw.rect(preview, color, (px + 32, py + 16 + i * 50, 14, 14), border_radius=4)
            else:
                pg.draw.rect(preview, color, (px + 32, py + 16 + i * 50, 14, 14), border_radius=4)
        self.hud.blit(preview, (24, y))

        y = S.HEIGHT - 180
        draw_text(self.hud, "Controls", (24, y))
        y += 24
        for line in [
            "←/→ Move",
            "↓ Soft drop",
            "↑ Rotate",
            "Space Hard drop",
            "P Pause, R Restart",
        ]:
            draw_text(self.hud, line, (24, y), size="sm")
            y += 18

        if self.board.over:
            overlay = pg.Surface((self.hud.get_width(), 60), pg.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            self.hud.blit(overlay, (0, 60))
            draw_text(self.hud, "Game Over", (24, 70), size="lg")
            draw_text(self.hud, "Press R to Restart", (24, 104))
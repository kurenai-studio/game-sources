"""Pygame rendering and input loop for 2048."""

from __future__ import annotations

import json
from pathlib import Path

import pygame

from . import constants as C
from .logic import Board, Direction

BEST_SCORE_PATH = Path(__file__).resolve().parent.parent / ".best_score.json"

KEY_TO_DIRECTION = {
    pygame.K_LEFT: Direction.LEFT,
    pygame.K_a: Direction.LEFT,
    pygame.K_RIGHT: Direction.RIGHT,
    pygame.K_d: Direction.RIGHT,
    pygame.K_UP: Direction.UP,
    pygame.K_w: Direction.UP,
    pygame.K_DOWN: Direction.DOWN,
    pygame.K_s: Direction.DOWN,
}


def load_best_score() -> int:
    try:
        data = json.loads(BEST_SCORE_PATH.read_text(encoding="utf-8"))
        return int(data.get("best", 0))
    except (OSError, ValueError, json.JSONDecodeError, TypeError):
        return 0


def save_best_score(score: int) -> None:
    try:
        BEST_SCORE_PATH.write_text(
            json.dumps({"best": score}), encoding="utf-8"
        )
    except OSError:
        pass


def tile_color(value: int) -> tuple[int, int, int]:
    if value == 0:
        return C.TILE_COLORS[0]
    return C.TILE_COLORS.get(value, C.TILE_COLOR_FALLBACK)


def tile_text_color(value: int) -> tuple[int, int, int]:
    if value >= C.LIGHT_TEXT_FROM:
        return C.FONT_LIGHT
    return C.FONT_DARK


def cell_rect(row: int, col: int) -> pygame.Rect:
    board_top = C.HEADER_HEIGHT
    cell = (C.BOARD_SIZE - 2 * C.GRID_PADDING - (C.COLS - 1) * C.CELL_GAP) // C.COLS
    x = C.GRID_PADDING + col * (cell + C.CELL_GAP)
    y = board_top + C.GRID_PADDING + row * (cell + C.CELL_GAP)
    return pygame.Rect(x, y, cell, cell)


class GameApp:
    """Desktop 2048 application."""

    def __init__(self) -> None:
        pygame.init()
        pygame.display.set_caption("2048 — Python / Pygame")
        self.window = pygame.display.set_mode((C.WIDTH, C.HEIGHT))
        self.clock = pygame.time.Clock()
        self.font_xl = pygame.font.SysFont("clear sans,arial", 48, bold=True)
        self.font_lg = pygame.font.SysFont("clear sans,arial", 36, bold=True)
        self.font_md = pygame.font.SysFont("clear sans,arial", 22, bold=True)
        self.font_sm = pygame.font.SysFont("clear sans,arial", 16, bold=True)
        self.board = Board(rows=C.ROWS, cols=C.COLS, win_value=C.WIN_VALUE)
        self.best = load_best_score()
        self.show_win_banner = False
        self.running = True

    def run(self) -> None:
        while self.running:
            self.clock.tick(C.FPS)
            self._handle_events()
            self._draw()
        pygame.quit()

    def _handle_events(self) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.running = False
            elif event.type == pygame.KEYDOWN:
                self._on_key(event.key)

    def _on_key(self, key: int) -> None:
        if key in (pygame.K_ESCAPE, pygame.K_q):
            self.running = False
            return
        if key == pygame.K_r:
            self._restart()
            return

        if self.board.is_game_over():
            return

        # Win overlay: Enter continues, R restarts (handled above)
        if self.show_win_banner and not self.board.continued_after_win:
            if key in (pygame.K_RETURN, pygame.K_SPACE):
                self.board.continue_after_win()
                self.show_win_banner = False
            return

        direction = KEY_TO_DIRECTION.get(key)
        if direction is None:
            return

        result = self.board.move(direction)
        if not result.moved:
            return

        if self.board.score > self.best:
            self.best = self.board.score
            save_best_score(self.best)

        if self.board.won and not self.board.continued_after_win:
            self.show_win_banner = True

    def _restart(self) -> None:
        self.board.reset()
        self.show_win_banner = False

    def _draw(self) -> None:
        self.window.fill(C.BACKGROUND_COLOR)
        self._draw_header()
        self._draw_board()
        if self.show_win_banner and not self.board.continued_after_win:
            self._draw_overlay("You win!", "Enter to continue · R to restart")
        elif self.board.is_game_over():
            self._draw_overlay("Game over", "Press R to try again")
        pygame.display.flip()

    def _draw_header(self) -> None:
        title = self.font_xl.render("2048", True, C.FONT_DARK)
        self.window.blit(title, (C.GRID_PADDING, 18))

        self._draw_score_box("SCORE", self.board.score, C.WIDTH - 210, 16)
        self._draw_score_box("BEST", self.best, C.WIDTH - 105, 16)

        hint = self.font_sm.render(
            "Arrows / WASD to move · R restart · Esc quit",
            True,
            C.FONT_DARK,
        )
        self.window.blit(hint, (C.GRID_PADDING, C.HEADER_HEIGHT - 28))

    def _draw_score_box(self, label: str, value: int, x: int, y: int) -> None:
        box = pygame.Rect(x, y, 90, 55)
        pygame.draw.rect(self.window, C.SCORE_BOX_COLOR, box, border_radius=6)
        label_s = self.font_sm.render(label, True, C.FONT_LIGHT)
        value_s = self.font_md.render(str(value), True, C.WHITE)
        self.window.blit(
            label_s, (box.centerx - label_s.get_width() // 2, box.y + 6)
        )
        self.window.blit(
            value_s, (box.centerx - value_s.get_width() // 2, box.y + 24)
        )

    def _draw_board(self) -> None:
        board_rect = pygame.Rect(0, C.HEADER_HEIGHT, C.BOARD_SIZE, C.BOARD_SIZE)
        pygame.draw.rect(self.window, C.BOARD_COLOR, board_rect, border_radius=8)

        for r, c, value in self.board.cells():
            rect = cell_rect(r, c)
            pygame.draw.rect(
                self.window, tile_color(value), rect, border_radius=6
            )
            if value == 0:
                continue
            text = self._value_font(value).render(
                str(value), True, tile_text_color(value)
            )
            self.window.blit(
                text,
                (
                    rect.centerx - text.get_width() // 2,
                    rect.centery - text.get_height() // 2,
                ),
            )

    def _value_font(self, value: int) -> pygame.font.Font:
        if value >= 1024:
            return self.font_md
        if value >= 128:
            return self.font_lg
        return self.font_xl

    def _draw_overlay(self, title: str, subtitle: str) -> None:
        veil = pygame.Surface((C.WIDTH, C.HEIGHT), pygame.SRCALPHA)
        veil.fill((238, 228, 218, 180))
        self.window.blit(veil, (0, 0))

        t = self.font_xl.render(title, True, C.FONT_DARK)
        s = self.font_md.render(subtitle, True, C.FONT_DARK)
        self.window.blit(
            t, (C.WIDTH // 2 - t.get_width() // 2, C.HEIGHT // 2 - 40)
        )
        self.window.blit(
            s, (C.WIDTH // 2 - s.get_width() // 2, C.HEIGHT // 2 + 20)
        )

"""The Scene base class and drawing helpers shared by menu screens."""

from __future__ import annotations

from functools import lru_cache
from typing import TYPE_CHECKING

import pygame

from app import config
from app.render.shapes import draw_panel
from app.render.text import draw_spaced, draw_text
from app.theme.palette import PALETTE

if TYPE_CHECKING:                       # scenes call back into the Game; only needed for type hints
    from app.core.game import Game


class Scene:
    """One screen. Subclasses override what they need; the defaults do nothing.

    ``music`` picks the soundtrack: "menu" (calm), "run" (follows danger) or
    "ducked" (the run's music, quieter: pause and game over).
    """

    music = "menu"

    def __init__(self, game: Game) -> None:
        self.game = game

    def handle_event(self, event: pygame.event.Event) -> None:
        pass

    def update(self, dt: float) -> None:
        pass

    def draw(self, surface: pygame.Surface) -> None:
        pass

    def on_focus_lost(self) -> None:
        """The window lost focus (alt-tab, click outside). Play pauses here."""


@lru_cache(maxsize=8)
def _dim_layer(alpha: int) -> pygame.Surface:
    layer = pygame.Surface((config.SCREEN_WIDTH, config.SCREEN_HEIGHT))
    layer.set_alpha(alpha)                  # black by default; only the alpha varies
    return layer


def dim(surface: pygame.Surface, alpha: int) -> None:
    """Darken the whole screen, so a menu card stands out from the game behind it."""
    surface.blit(_dim_layer(max(0, min(255, alpha))), (0, 0))


def card_rect(width: int, height: int, offset_y: int = 0) -> pygame.Rect:
    rect = pygame.Rect(0, 0, width, height)
    rect.center = (config.SCREEN_WIDTH // 2, config.SCREEN_HEIGHT // 2 + offset_y)
    return rect


def draw_card(surface: pygame.Surface, rect: pygame.Rect) -> None:
    draw_panel(surface, rect, "card")


def draw_stat_tile(surface: pygame.Surface, rect: pygame.Rect, label: str, value: str, color,
                   value_style: str = "cooldown", note: str | None = None) -> None:
    """A small sunken box: a caption at the top, a big value under it, and an optional note at the bottom."""
    draw_panel(surface, rect, "slot")
    draw_spaced(surface, label, "label", PALETTE.text_faint, 2, topleft=(rect.x + 12, rect.y + 10))
    draw_text(surface, value, value_style, color, shadow=True, topleft=(rect.x + 12, rect.y + 28))
    if note:
        draw_text(surface, note, "tiny", PALETTE.text_faint, bottomleft=(rect.x + 12, rect.bottom - 9))


def ease_out(t: float) -> float:
    """0..1 -> 0..1, fast at first and gentle at the end (for slide-ins)."""
    t = max(0.0, min(1.0, t))
    return 1 - (1 - t) ** 3

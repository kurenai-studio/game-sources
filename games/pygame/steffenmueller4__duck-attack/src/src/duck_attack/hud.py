"""Text rendering and the in-round display (score and timer)."""

import math

import pygame

from duck_attack import settings

Color = tuple[int, int, int]


def render_text(font: pygame.font.Font, text: str, color: Color = settings.TEXT_COLOR):
    """Render ``text`` with a drop shadow, which keeps it readable on any background."""
    fg = font.render(text, True, color)
    shadow = font.render(text, True, settings.TEXT_SHADOW_COLOR)
    surface = pygame.Surface((fg.get_width() + 3, fg.get_height() + 3), pygame.SRCALPHA)
    surface.blit(shadow, (3, 3))
    surface.blit(fg, (0, 0))
    return surface


class Label:
    """A piece of text that is only re-rendered when its content or color changes."""

    def __init__(self, size: int) -> None:
        self.font = pygame.font.Font(None, size)
        self._key: tuple[str, Color] | None = None
        self._surface: pygame.Surface | None = None

    def draw(self, screen: pygame.Surface, text: str, color: Color = settings.TEXT_COLOR, **pos):
        """Draw at a position given as rect keyword, e.g. ``topleft=(10, 10)``."""
        if (text, color) != self._key:
            self._key = (text, color)
            self._surface = render_text(self.font, text, color)
        screen.blit(self._surface, self._surface.get_rect(**pos))


class Hud:
    """Score in the top-right corner, remaining time in the top-left corner."""

    def __init__(self) -> None:
        self.score_label = Label(settings.HUD_FONT_SIZE)
        self.time_label = Label(settings.HUD_FONT_SIZE)

    def draw(self, screen: pygame.Surface, score: int, time_left: float) -> None:
        margin = settings.HUD_MARGIN
        self.score_label.draw(
            screen, f"Score: {score}", topright=(screen.get_width() - margin, margin)
        )
        seconds = math.ceil(time_left)
        color = settings.WARNING_COLOR if seconds <= settings.TIME_WARNING else settings.TEXT_COLOR
        self.time_label.draw(screen, f"Time: {seconds}", color, topleft=(margin, margin))

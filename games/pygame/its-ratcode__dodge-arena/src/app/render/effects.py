"""Short-lived visual effects."""

import pygame
from pygame.math import Vector2

from app import config
from app.render.shapes import draw_alpha_circle
from app.render.text import get_font
from app.theme.accessibility import wobble
from app.theme.palette import PALETTE
from app.util.mathx import lerp_color


class Effect:
    """Base class: something drawn for ``duration`` seconds, then removed."""

    def __init__(self, duration: float) -> None:
        self.duration = duration
        self.age = 0.0

    @property
    def progress(self) -> float:
        """0 when created -> 1 when finished."""
        return min(1.0, self.age / self.duration)

    @property
    def alive(self) -> bool:
        return self.age < self.duration

    def update(self, dt: float) -> None:
        self.age += dt

    def draw(self, surface: pygame.Surface) -> None:
        pass


class ClickMarker(Effect):
    """A shrinking ring with four inward ticks where the player clicked to move."""

    def __init__(self, pos) -> None:
        super().__init__(config.CLICK_MARKER_DURATION)
        self.pos = Vector2(pos)

    def draw(self, surface: pygame.Surface) -> None:
        t = self.progress
        radius = 3 + config.CLICK_MARKER_RADIUS * (1 - t)
        draw_alpha_circle(surface, PALETTE.marker, self.pos, radius, alpha=255 * (1 - t), width=2)
        tick_color = lerp_color(PALETTE.marker, PALETTE.arena_center, t)
        for angle in (45, 135, 225, 315):
            d = Vector2(1, 0).rotate(angle)
            pygame.draw.line(surface, tick_color, self.pos + d * (radius + 6), self.pos + d * (radius + 1), 2)


class Burst(Effect):
    """An expanding, fading ring: feedback for a blocked hit or a bolt hitting a wall."""

    def __init__(self, pos, color, scale: float = 1.0) -> None:
        super().__init__(config.BURST_DURATION)
        self.pos = Vector2(pos)
        self.color = color
        self.scale = scale

    def draw(self, surface: pygame.Surface) -> None:
        t = self.progress
        radius = (10 + 34 * t) * self.scale
        draw_alpha_circle(surface, self.color, self.pos, radius, alpha=230 * (1 - t), width=3)


class FloatingText(Effect):
    """A short word or number that rises and fades: "+1", "BLOCKED", "CLOSE!".

    ``color_name`` is a palette field, read at draw time. With reduced motion
    it fades in place instead of rising.
    """

    def __init__(self, pos, text: str, color_name: str) -> None:
        super().__init__(config.FLOATING_TEXT_DURATION)
        self.pos = Vector2(pos)
        self.text = text
        self.color_name = color_name
        self.images: tuple[pygame.Surface, pygame.Surface] | None = None    # rendered once, on first draw

    def draw(self, surface: pygame.Surface) -> None:
        t = self.progress
        if self.images is None:
            font = get_font("float")
            self.images = (font.render(self.text, True, getattr(PALETTE, self.color_name)),
                           font.render(self.text, True, PALETTE.key_shadow))
        image, shade = self.images
        rise = wobble(38 * (1 - (1 - t) ** 3))
        rect = image.get_rect(center=(round(self.pos.x), round(self.pos.y - rise)))
        alpha = int(255 * (1 - t ** 2))
        shade.set_alpha(alpha // 2)
        image.set_alpha(alpha)
        surface.blit(shade, rect.move(0, 2))
        surface.blit(image, rect)


class Toast:
    """A short message at the top of the screen ("Second Wind is ready").
    It slides in, stays ``TOAST_DURATION`` seconds and fades out."""

    def __init__(self, text: str, color_name: str, icon: str | None = None) -> None:
        self.text = text
        self.color_name = color_name
        self.icon = icon
        self.age = 0.0

    @property
    def alive(self) -> bool:
        return self.age < config.TOAST_DURATION

    def update(self, dt: float) -> None:
        self.age += dt

    @property
    def alpha(self) -> int:
        fade_in = self.age / 0.2
        fade_out = (config.TOAST_DURATION - self.age) / 0.45
        return int(255 * max(0.0, min(1.0, fade_in, fade_out)))

    @property
    def slide(self) -> float:
        """px above its place while sliding in (0 once settled)."""
        return wobble(-12 * (1 - min(1.0, self.age / 0.25)) ** 3)


class NovaWave(Effect):
    """Nova: a shockwave ring racing out from the player across the whole arena."""

    def __init__(self, pos) -> None:
        super().__init__(config.NOVA_EFFECT_DURATION)
        self.pos = Vector2(pos)

    def draw(self, surface: pygame.Surface) -> None:
        t = self.progress
        reach = max(config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
        draw_alpha_circle(surface, PALETTE.nova, self.pos, 30 + reach * t, alpha=30 * (1 - t) ** 2)
        draw_alpha_circle(surface, PALETTE.nova, self.pos, 30 + reach * t, alpha=255 * (1 - t),
                          width=max(1, int(8 * (1 - t))))


class BlinkTrail(Effect):
    """A Blink: a ring bursting out where you left, one closing in where you landed,
    and a fading streak between them."""

    def __init__(self, start, end) -> None:
        super().__init__(config.BLINK_EFFECT_DURATION)
        self.start = Vector2(start)
        self.end = Vector2(end)

    def draw(self, surface: pygame.Surface) -> None:
        t = self.progress
        alpha = 255 * (1 - t)
        pygame.draw.line(surface, lerp_color(PALETTE.blink, PALETTE.arena_center, t),
                         self.start, self.end, max(1, int(6 * (1 - t))))
        draw_alpha_circle(surface, PALETTE.blink, self.start, config.PLAYER_RADIUS + 30 * t, alpha, width=3)
        draw_alpha_circle(surface, PALETTE.blink, self.end, config.PLAYER_RADIUS + 4 + 22 * (1 - t), alpha,
                          width=2)

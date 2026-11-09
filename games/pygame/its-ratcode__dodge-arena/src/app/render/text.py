"""Text rendering with cached fonts, plus keycaps (a key binding drawn as a key)
and styled text: letter-spaced labels, gradient fills and soft glows."""

from functools import lru_cache

import pygame

from app.theme.palette import PALETTE
from app.theme.styles import RADIUS_SM
from app.theme.typography import TEXT_STYLES, TextStyle
from app.util.mathx import Color, lerp_color

_fonts: dict[TextStyle, pygame.font.Font] = {}


def get_font(style: str) -> pygame.font.Font:
    """The font for a text style role from ``TEXT_STYLES`` (cached)."""
    spec = TEXT_STYLES[style]
    if spec not in _fonts:
        _fonts[spec] = pygame.font.SysFont(spec.font, spec.size, bold=spec.bold)
    return _fonts[spec]


def text_size(text: str, style: str) -> tuple[int, int]:
    return get_font(style).size(text)


def line_height(style: str) -> int:
    return get_font(style).get_linesize()


def wrap_text(text: str, style: str, width: int) -> list[str]:
    """Split ``text`` into lines no wider than ``width`` px, breaking between words.
    A single word longer than the width gets a line of its own."""
    font = get_font(style)
    lines: list[str] = []
    line = ""
    for word in text.split():
        trial = f"{line} {word}" if line else word
        if font.size(trial)[0] <= width or not line:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def draw_text(surface: pygame.Surface, text: str, style: str, color: Color,
              shadow: bool = False, **anchor) -> pygame.Rect:
    """Draw text positioned by any pygame.Rect anchor, e.g. ``center=(x, y)``.

    ``shadow`` adds a dark copy 1 px below, which keeps text readable over busy
    backgrounds such as lasers.
    """
    font = get_font(style)
    image = font.render(text, True, color)
    rect = image.get_rect(**anchor)
    if shadow:
        surface.blit(font.render(text, True, PALETTE.key_shadow), rect.move(1, 2))
    surface.blit(image, rect)
    return rect


# --- Styled text (each image is built once and cached) ---------------------------------------
@lru_cache(maxsize=128)
def render_spaced(text: str, style: str, color: Color, spacing: int) -> pygame.Surface:
    """``text`` with ``spacing`` px of extra room between letters, for small captions and the logo."""
    font = get_font(style)
    glyphs = [font.render(ch, True, color) for ch in text]
    width = sum(g.get_width() for g in glyphs) + spacing * max(0, len(glyphs) - 1)
    image = pygame.Surface((max(1, width), font.get_height()), pygame.SRCALPHA)
    x = 0
    for glyph in glyphs:
        image.blit(glyph, (x, 0))
        x += glyph.get_width() + spacing
    return image


def draw_spaced(surface: pygame.Surface, text: str, style: str, color: Color, spacing: int = 2,
                **anchor) -> pygame.Rect:
    """Letter-spaced text positioned like ``draw_text``, e.g. the "PROFILE" caption."""
    image = render_spaced(text, style, tuple(color), spacing)
    rect = image.get_rect(**anchor)
    surface.blit(image, rect)
    return rect


@lru_cache(maxsize=16)
def render_gradient(text: str, style: str, top: Color, bottom: Color) -> pygame.Surface:
    """Text filled with a vertical gradient from ``top`` to ``bottom`` (the logo)."""
    image = get_font(style).render(text, True, (255, 255, 255))
    w, h = image.get_size()
    gradient = pygame.Surface((w, h), pygame.SRCALPHA)
    for y in range(h):
        pygame.draw.line(gradient, (*lerp_color(top, bottom, y / max(1, h - 1)), 255), (0, y), (w, y))
    image.blit(gradient, (0, 0), special_flags=pygame.BLEND_RGBA_MULT)
    return image


@lru_cache(maxsize=16)
def render_glow(text: str, style: str, color: Color, pad: int = 28) -> pygame.Surface:
    """A soft blurred copy of ``text`` to draw behind it. Shrinking and growing it again is a cheap blur."""
    base = get_font(style).render(text, True, color)
    canvas = pygame.Surface((base.get_width() + pad * 2, base.get_height() + pad * 2), pygame.SRCALPHA)
    canvas.blit(base, (pad, pad))
    small = pygame.transform.smoothscale(canvas, (max(1, canvas.get_width() // 6), max(1, canvas.get_height() // 6)))
    return pygame.transform.smoothscale(small, canvas.get_size())


def draw_glowing_text(surface: pygame.Surface, text: str, style: str, color: Color, **anchor) -> pygame.Rect:
    """A headline with a soft glow of its own color behind it (GAME OVER)."""
    rect = pygame.Rect((0, 0), get_font(style).size(text))
    for name, value in anchor.items():
        setattr(rect, name, value)
    glow = render_glow(text, style, tuple(color))
    surface.blit(glow, glow.get_rect(center=rect.center))
    return draw_text(surface, text, style, color, shadow=True, center=rect.center)


def draw_keycap(surface: pygame.Surface, label: str, **anchor) -> pygame.Rect:
    """A small raised key showing a binding, e.g. [Q]."""
    rect = pygame.Rect(0, 0, keycap_width(label), 20)
    for name, value in anchor.items():
        setattr(rect, name, value)
    pygame.draw.rect(surface, PALETTE.key_shadow, rect.move(0, 2), border_radius=RADIUS_SM)
    pygame.draw.rect(surface, PALETTE.key_face, rect, border_radius=RADIUS_SM)
    pygame.draw.rect(surface, lerp_color(PALETTE.key_face, PALETTE.text, 0.2), rect, 1, border_radius=RADIUS_SM)
    draw_text(surface, label, "key", PALETTE.text, center=rect.center)
    return rect


def ellipsize(text: str, style: str, width: int) -> str:
    """``text`` if it fits in ``width`` px, otherwise cut short with "..." so it does."""
    font = get_font(style)
    if font.size(text)[0] <= width:
        return text
    while text and font.size(text + "...")[0] > width:
        text = text[:-1]
    return text.rstrip() + "..."


HintRow = list[tuple[list[str], str]]          # [(["Q", "W", "E"], "Abilities"), (["ESC"], "Back")]


def keycap_width(label: str) -> int:
    return max(22, text_size(label, "key")[0] + 12)


def hint_row_width(items: HintRow) -> int:
    width = 0
    for keys, label in items:
        width += sum(keycap_width(k) + 4 for k in keys) + 2 + text_size(label, "small")[0] + 18
    return width - 18


def draw_hint_row(surface: pygame.Surface, items: HintRow, x: int, y: int, align: str = "left") -> None:
    """A row of keycaps with labels, e.g. [Q][W][E] Abilities   [ESC] Back.
    ``y`` is the top of the keycaps; ``align`` is "left", "center" or "right" around ``x``."""
    if align == "center":
        x -= hint_row_width(items) // 2
    elif align == "right":
        x -= hint_row_width(items)
    for keys, label in items:
        for key in keys:
            x = draw_keycap(surface, key, topleft=(x, y)).right + 4
        x = draw_text(surface, label, "small", PALETTE.text_dim, shadow=True, midleft=(x + 2, y + 10)).right + 18

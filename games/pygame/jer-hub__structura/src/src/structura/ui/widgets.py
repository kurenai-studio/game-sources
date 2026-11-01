from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable

import pygame

from . import theme


@dataclass
class Button:
    label: str
    rect: pygame.Rect
    on_click: Callable[[], None]
    enabled: bool = True
    selected: bool = False
    accent: tuple = theme.IDLE
    size: int = 20
    hover: bool = False
    pressed: bool = False

    def draw(self, surf):
        saved = self.rect
        if self.enabled and self.pressed:
            self.rect = saved.inflate(-6, -4)
        elif self.enabled and self.hover:
            self.rect = saved.move(0, -2)
        self._draw(surf)
        self.rect = saved

    def _draw(self, surf):
        if not self.enabled:
            bg = theme.PANEL
        elif self.selected:
            bg = self.accent
        else:
            bg = tuple(min(255, c + 25) for c in theme.PANEL_EDGE) if self.hover else theme.PANEL_EDGE
        pygame.draw.rect(surf, bg, self.rect, border_radius=8)
        pygame.draw.rect(surf, self.accent if self.enabled else theme.DISABLED, self.rect, 2, border_radius=8)
        colour = theme.TEXT if self.enabled else theme.DISABLED
        f = theme.font(self.size)
        img = f.render(self.label, True, colour)
        surf.blit(img, img.get_rect(center=self.rect.center))

    def handle(self, event) -> bool:
        if event.type == pygame.MOUSEMOTION:
            self.hover = self.rect.collidepoint(event.pos)
            if not self.hover:
                self.pressed = False
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.pressed = self.rect.collidepoint(event.pos)
        if event.type == pygame.MOUSEBUTTONUP:
            self.pressed = False
        if event.type == pygame.MOUSEBUTTONUP and event.button == 1 and self.enabled \
                and self.rect.collidepoint(event.pos):
            self.on_click()
            return True
        return False


@dataclass
class TextField:
    label: str
    rect: pygame.Rect
    text: str = ""
    focused: bool = False
    max_len: int = 40

    def draw(self, surf):
        theme.draw_text(surf, self.label, (self.rect.x, self.rect.y - 26), 18, theme.MUTED)
        pygame.draw.rect(surf, theme.PANEL, self.rect, border_radius=6)
        pygame.draw.rect(surf, theme.SELECT if self.focused else theme.PANEL_EDGE, self.rect, 2, border_radius=6)
        shown = self.text + ("|" if self.focused else "")
        theme.draw_text(surf, shown, (self.rect.x + 10, self.rect.y + 8), 22)

    def handle(self, event) -> bool:
        if event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            self.focused = self.rect.collidepoint(event.pos)
            return self.focused
        if not self.focused:
            return False
        if event.type == pygame.TEXTINPUT:
            self.text = (self.text + event.text)[: self.max_len]
            return True
        if event.type == pygame.KEYDOWN and event.key == pygame.K_BACKSPACE:
            self.text = self.text[:-1]
            return True
        return False


@dataclass
class Row:
    """Lays buttons out left to right."""

    x: int
    y: int
    h: int = 44
    gap: int = 10
    items: list = field(default_factory=list)

    def add(self, label, on_click, width=None, **kw) -> Button:
        w = width or max(110, theme.font(kw.get("size", 20)).size(label)[0] + 36)
        b = Button(label, pygame.Rect(self.x, self.y, w, self.h), on_click, **kw)
        self.x += w + self.gap
        self.items.append(b)
        return b

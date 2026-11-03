"""Small reusable UI components."""

from __future__ import annotations

from dataclasses import dataclass

import pygame

from game.config import CYAN, INK, MUTED, PANEL


def draw_text(
    surface: pygame.Surface,
    text: str,
    font: pygame.font.Font,
    color: tuple[int, int, int] = INK,
    *,
    center: tuple[int, int] | None = None,
    topleft: tuple[int, int] | None = None,
) -> pygame.Rect:
    rendered = font.render(text, True, color)
    rect = rendered.get_rect()
    if center is not None:
        rect.center = center
    elif topleft is not None:
        rect.topleft = topleft
    surface.blit(rendered, rect)
    return rect


def draw_panel(surface: pygame.Surface, rect: pygame.Rect, alpha: int = 226) -> None:
    panel = pygame.Surface(rect.size, pygame.SRCALPHA)
    pygame.draw.rect(panel, (*PANEL, alpha), panel.get_rect(), border_radius=18)
    pygame.draw.rect(panel, (*CYAN, 96), panel.get_rect(), width=2, border_radius=18)
    surface.blit(panel, rect)


@dataclass(slots=True)
class Button:
    label: str
    rect: pygame.Rect
    action: str
    enabled: bool = True

    def draw(
        self,
        surface: pygame.Surface,
        font: pygame.font.Font,
        mouse_position: tuple[int, int],
        selected: bool = False,
    ) -> None:
        hovered = self.enabled and self.rect.collidepoint(mouse_position)
        active = hovered or selected
        fill = (30, 73, 112) if active else (22, 43, 76)
        border = CYAN if active else (65, 96, 126)
        text_color = INK if self.enabled else MUTED
        pygame.draw.rect(surface, fill, self.rect, border_radius=12)
        pygame.draw.rect(surface, border, self.rect, width=2, border_radius=12)
        draw_text(surface, self.label, font, text_color, center=self.rect.center)

    def accepts(self, event: pygame.event.Event) -> bool:
        return (
            self.enabled
            and event.type == pygame.MOUSEBUTTONDOWN
            and event.button == 1
            and self.rect.collidepoint(event.pos)
        )

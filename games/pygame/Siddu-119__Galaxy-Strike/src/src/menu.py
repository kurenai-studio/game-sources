"""Reusable animated menu buttons."""

import math

import pygame

from settings import CYAN, MUTED, WHITE


class Button:
    def __init__(self, label, action, width=290, height=48):
        self.label = label
        self.action = action
        self.width, self.height = width, height
        self.rect = pygame.Rect(0, 0, width, height)
        self.hover = 0.0
        self.press = 0.0

    def update(self, dt, mouse_pos):
        target = 1.0 if self.rect.collidepoint(mouse_pos) else 0.0
        self.hover += (target - self.hover) * min(1.0, dt * 12)
        self.press = max(0.0, self.press - dt * 8)

    def draw(self, surface, font, center, time):
        self.rect.center = center
        amount = self.hover
        fill = (int(15 + 13 * amount), int(26 + 28 * amount), int(53 + 35 * amount))
        outline = tuple(int(MUTED[i] + (CYAN[i] - MUTED[i]) * amount) for i in range(3))
        rect = self.rect.inflate(int(amount * 12 - self.press * 8),
                                 int(-self.press * 4))
        pygame.draw.rect(surface, fill, rect, border_radius=11)
        pygame.draw.rect(surface, outline, rect, 1 if amount < 0.4 else 2, border_radius=11)
        label = font.render(self.label, True, WHITE if amount > 0.2 else MUTED)
        surface.blit(label, label.get_rect(center=rect.center))
        if amount > 0.1:
            dot_x = rect.left + 18 + int(math.sin(time * 4) * 3)
            pygame.draw.circle(surface, CYAN, (dot_x, rect.centery), 3)

    def clicked(self, position):
        clicked = self.rect.collidepoint(position)
        if clicked:
            self.press = 1.0
        return clicked

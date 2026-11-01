"""Every Achievement, earned ones lit and the rest dimmed. Worked out from results
each time the screen opens, so new Zones add their own without anything stored."""
from __future__ import annotations

import pygame

from ...persistence.achievements import evaluate
from .. import theme
from ..app import SIZE, Scene
from ..widgets import Button

CARD_W, CARD_H, GAP = 560, 58, 10
TOP = 120
BOTTOM = SIZE[1] - 72 - GAP          # above the Back button


class AchievementsScene(Scene):
    def __init__(self, app):
        super().__init__(app)
        self.achievements = evaluate(app.zones, app.results())
        self.buttons = [Button("Back", pygame.Rect(40, SIZE[1] - 72, 140, 44), app.open_map)]

    def card(self, i: int) -> pygame.Rect:
        rows = (len(self.achievements) + 1) // 2
        pitch = min(CARD_H + GAP, (BOTTOM - TOP + GAP) // rows)
        col, row = divmod(i, rows)
        return pygame.Rect(40 + col * (CARD_W + 80), TOP + row * pitch, CARD_W, pitch - GAP)

    def draw(self, surf):
        theme.draw_text(surf, "Achievements", (40, 30), 40, bold=True)
        got = sum(a.earned for a in self.achievements)
        theme.draw_text(surf, f"{got} of {len(self.achievements)} earned", (40, 80), 18, theme.MUTED)
        for i, a in enumerate(self.achievements):
            r = self.card(i)
            edge = theme.GOOD if a.earned else theme.PANEL_EDGE
            theme.panel(surf, r, edge=edge)
            theme.star(surf, (r.x + 30, r.centery), 30, theme.STAR if a.earned else theme.DISABLED)
            theme.draw_text(surf, a.title, (r.x + 58, r.y + 7), 20, theme.TEXT if a.earned else theme.MUTED,
                            bold=a.earned)
            theme.draw_text(surf, a.detail, (r.x + 58, r.y + 32), 15, theme.MUTED)
        super().draw(surf)

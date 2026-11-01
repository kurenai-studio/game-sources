"""Draws a stack as a tower (bottom to top) with the top marked, beside an
Output row of popped values in the order they came out.

Stack-specific motion:
  * a pushed block drops onto the tower from above;
  * a popped block lifts off the top and flies to the end of the Output row;
  * undoing a pop takes the value back off the Output row.

There is nothing to click on the board: Moves come from the Push and Pop buttons.
"""
from __future__ import annotations

import pygame

from .. import theme
from .base import Motion
from .output_row import OUTPUT_W, OutputRowRenderer

GAP = 8           # between blocks in the tower


class StackRenderer(OutputRowRenderer):
    # ---- layout -------------------------------------------------------------
    def elements(self):
        return list(self.model.items)

    def _floor(self) -> float:
        return self.rect.bottom - 30

    def _tower_x(self) -> float:
        return self.rect.x + self.rect.w * 0.28

    def element_size(self) -> int:
        n = len(self.model.items)
        room = self._floor() - (self.rect.y + 70)
        return int(max(32, min(64, room / max(n, 1) - GAP)))

    def layout(self):
        w = self.element_size()
        x = self._tower_x() - w / 2
        return {eid: (x, self._floor() - (i + 1) * (w + GAP)) for i, eid in enumerate(self.element_ids())}

    def output_origin(self):
        return self.rect.x + self.rect.w * 0.5, self.rect.centery - OUTPUT_W / 2

    # ---- motion -------------------------------------------------------------
    def arrive(self, eid, target):
        self.pos[eid] = [target[0], self.rect.y - 10, 1.0]
        self.motions[eid] = Motion((target[0], self.rect.y - 10), target)

    def flight_arc(self):
        return -1.4 * self.element_size()

    # ---- drawing --------------------------------------------------------------
    def draw_under(self, surf, hint_slot, pulse, offset):
        ox, oy = offset
        w = self.element_size()
        tx = self._tower_x()
        pygame.draw.line(surf, theme.PANEL_EDGE, (tx - w + ox, self._floor() + 4 + oy),
                         (tx + w + ox, self._floor() + 4 + oy), 3)

        ids = self.element_ids()
        if ids:
            x, y, _ = self.pos[ids[-1]]
            tip = (x - 10 + ox, y + w / 2 + oy)
            theme.draw_text(surf, "top", (tip[0] - 42, tip[1] - 11), 18, theme.ACTIVE)
            pygame.draw.polygon(surf, theme.ACTIVE, [tip, (tip[0] - 10, tip[1] - 6), (tip[0] - 10, tip[1] + 6)])
        else:
            theme.draw_text(surf, "(empty)", (tx + ox, self._floor() - 30 + oy), 17, theme.MUTED, center=True)

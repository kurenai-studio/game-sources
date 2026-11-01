"""Draws a queue as a canal: values wait in a horizontal line, front on the left
behind the gate and back on the right, above an Output row of dequeued values
in the order they came out.

Queue-specific motion:
  * an enqueued value slides in along the canal and joins at the back;
  * a dequeued value leaves the front for the end of the Output row, and the
    rest move up (straight along the line, from the renderer base);
  * undoing a dequeue takes the value back off the Output row to the front.

There is nothing to click on the board: Moves come from the Enqueue and Dequeue buttons.
"""
from __future__ import annotations

import pygame

from .. import theme
from ..fx import mix
from .base import Motion
from .output_row import OUTPUT_W, OutputRowRenderer

GAP = 10          # between values in the line
FRONT_W = 100     # room left of the line for the gate and the "front" label
BACK_W = 110      # room right of the line for the "back" label and incoming values
WATER = mix(theme.PANEL, theme.SELECT, 0.08)
BANK = mix(theme.PANEL_EDGE, theme.SELECT, 0.3)


class QueueRenderer(OutputRowRenderer):
    # ---- layout -------------------------------------------------------------
    def elements(self):
        return list(self.model.items)

    def _front_x(self) -> float:
        return self.rect.x + FRONT_W

    def _line_y(self) -> float:
        """The centre line of the canal."""
        return self.rect.y + self.rect.h * 0.42

    def element_size(self) -> int:
        n = len(self.model.items)
        room = self.rect.w - FRONT_W - BACK_W
        return int(max(36, min(64, (room - GAP * (n - 1)) / max(n, 1))))

    def layout(self):
        w = self.element_size()
        y = self._line_y() - w / 2
        return {eid: (self._front_x() + i * (w + GAP), y) for i, eid in enumerate(self.element_ids())}

    def output_origin(self):
        return self._front_x(), self.rect.bottom - 30 - OUTPUT_W

    def _canal(self) -> pygame.Rect:
        w = self.element_size()
        left = self._front_x() - 14
        return pygame.Rect(int(left), int(self._line_y() - w / 2 - 12), int(self.rect.right - 24 - left), w + 24)

    # ---- motion -------------------------------------------------------------
    def arrive(self, eid, target):
        start = (self._canal().right - self.element_size() - 6, target[1])
        self.pos[eid] = [*start, 1.0]
        self.motions[eid] = Motion(start, target)

    # ---- drawing --------------------------------------------------------------
    def draw_under(self, surf, hint_slot, pulse, offset):
        ox, oy = offset
        w = self.element_size()
        canal = self._canal().move(ox, oy)
        pygame.draw.rect(surf, WATER, canal, border_radius=12)
        pygame.draw.line(surf, BANK, canal.topleft, (canal.right - 12, canal.top), 2)
        pygame.draw.line(surf, BANK, canal.bottomleft, (canal.right - 12, canal.bottom), 2)
        gate = pygame.Rect(canal.x - 6, canal.y - 6, 6, canal.h + 12)          # the front gate
        pygame.draw.rect(surf, theme.ACTIVE, gate, border_radius=3)

        cy = self._line_y() + oy
        ids = self.element_ids()
        if ids:
            tip = (gate.x - 8, cy)
            theme.draw_text(surf, "front", (tip[0] - 58, cy - 11), 18, theme.ACTIVE)
            pygame.draw.polygon(surf, theme.ACTIVE, [tip, (tip[0] - 10, tip[1] - 6), (tip[0] - 10, tip[1] + 6)])
            bx, _, _ = self.pos[ids[-1]]
            tip = (bx + w + 8 + ox, cy)
            pygame.draw.polygon(surf, theme.MUTED, [tip, (tip[0] + 10, tip[1] - 6), (tip[0] + 10, tip[1] + 6)])
            theme.draw_text(surf, "back", (tip[0] + 14, cy - 11), 18, theme.MUTED)
        else:
            theme.draw_text(surf, "(empty)", (canal.centerx, cy - 11), 17, theme.MUTED, center=True)

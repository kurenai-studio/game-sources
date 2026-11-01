"""Draws an array as a row of cells with indexes, plus insertion gaps.

Array-specific motion: cells that trade places travel on opposite arcs (one
over, one under); cells that all move the same way (a shift) slide straight.
Pop-in, fade-out and the other shared effects come from the renderer base.
"""
from __future__ import annotations

import pygame

from ...models import Move
from .. import theme
from ..fx import mix
from .base import Renderer, Target

GAP = 26


class ArrayRenderer(Renderer):
    # ---- layout -------------------------------------------------------------
    def elements(self):
        return list(self.model.items)

    def element_size(self) -> int:
        n = len(self.model.items)
        return int(max(40, min(84, (self.rect.w - 40 - GAP * (n + 1)) / max(n, 1))))

    def layout(self):
        ids = self.element_ids()
        n, w = len(ids), self.element_size()
        total = n * w + (n - 1) * GAP
        x0 = self.rect.centerx - total / 2
        y = self.rect.centery - w / 2
        return {eid: (x0 + i * (w + GAP), y) for i, eid in enumerate(ids)}

    def slot_targets(self):
        if not self.allows("insert"):
            return []
        layout, ids, w = self.layout(), self.element_ids(), self.element_size()
        if ids:
            xs = [layout[eid][0] - GAP for eid in ids] + [layout[ids[-1]][0] + w]
            y = layout[ids[0]][1]
        else:
            xs, y = [self.rect.centerx - GAP / 2], self.rect.centery - 30
        return [Target("slot", i, pygame.Rect(int(x + 2), int(y - 12), GAP - 4, w + 24))
                for i, x in enumerate(xs)]

    def slot_move(self, key, value):
        return Move.of("insert", key, value)

    def slot_for(self, move):
        return move.args[0] if move.op == "insert" else None

    # ---- motion -------------------------------------------------------------
    def arcs(self, moving):
        rightward = any(t[0] > c[0] for c, t in moving.values())
        leftward = any(t[0] < c[0] for c, t in moving.values())
        if not (rightward and leftward):
            return {}
        w = self.element_size()
        return {eid: -0.95 * w if t[0] > c[0] else 0.95 * w for eid, (c, t) in moving.items()}

    # ---- drawing --------------------------------------------------------------
    def draw_under(self, surf, hint_slot, pulse, offset):
        ox, oy = offset
        for t in self.targets():
            if t.kind == "slot":
                colour = mix(theme.GOOD, theme.ACTIVE, pulse) if t.key == hint_slot else theme.GOOD
                r = t.rect.move(ox, oy)
                pygame.draw.rect(surf, colour, r, 2, border_radius=6)
                pygame.draw.line(surf, colour, (r.centerx, r.y + 8), (r.centerx, r.bottom - 8), 2)
            elif t.kind == "node":
                theme.draw_text(surf, str(t.key), (t.rect.centerx + ox, t.rect.bottom + 8 + oy), 16,
                                theme.MUTED, center=True)

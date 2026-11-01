"""The Output row shared by structures that hand removed values out in order
(the stack and the queue): each removed value flies to the end of the row, the
row reads left to right in removal order, and Undo sends values back.

Subclasses say where the row starts (`output_origin`), how a new element arrives
(`arrive`, used in place of the base's `enter`, which here also handles values
Undo brings back) and how far a value bows on its way out (`flight_arc`). The
row is drawn over the board, so values in flight pass over the structure. There
is nothing to click on these boards: Moves come from buttons.
"""
from __future__ import annotations

from typing import NamedTuple

import pygame

from .. import theme
from ..fx import mix
from .base import Motion, Renderer

OUTPUT_W = 52     # Output row box size
OUTPUT_GAP = 10


class Flyer(NamedTuple):
    """A removed value on its way to the Output row."""

    index: int            # its place in the Output
    value: object
    motion: Motion


class OutputRowRenderer(Renderer):
    def __init__(self, rect):
        super().__init__(rect)
        self.flyers: dict[int, Flyer] = {}           # removed element id -> its flight to the Output
        self._output_count = 0                       # Output values already shown or in flight
        self._returning: list[int] = []              # during a sync: Output places Undo takes values back from

    # ---- what subclasses describe -------------------------------------------
    def output_origin(self) -> tuple[float, float]:
        """Top-left of the first Output box."""
        raise NotImplementedError

    def arrive(self, eid: int, target: tuple[float, float]) -> None:
        """Animate a newly added element in."""
        super().enter(eid, target)

    def flight_arc(self) -> float:
        return 0.0

    # ---- layout -------------------------------------------------------------
    def output_slot(self, index: int) -> pygame.Rect:
        """The box of the `index`th Output value; the row reads left to right."""
        x, y = self.output_origin()
        return pygame.Rect(int(x + index * (OUTPUT_W + OUTPUT_GAP)), int(y), OUTPUT_W, OUTPUT_W)

    def targets(self):
        return []

    def output(self) -> list[tuple[object, pygame.Rect]]:
        """Landed Output values with their boxes, in removal order."""
        flying = {f.index for f in self.flyers.values()}
        return [(v, self.output_slot(i)) for i, v in enumerate(self.model.out) if i not in flying]

    # ---- motion -------------------------------------------------------------
    def sync(self, model):
        if self.model is None:
            self._output_count = len(model.out)
        if len(model.out) < self._output_count:         # Undo took values back off the Output
            self._returning = list(range(len(model.out), self._output_count))
            self._output_count = len(model.out)
            self.flyers = {eid: f for eid, f in self.flyers.items() if f.index < self._output_count}
        super().sync(model)
        self._returning = []

    def enter(self, eid, target):
        if not self._returning:
            self.arrive(eid, target)
            return
        w = self.element_size()
        slot = self.output_slot(self._returning.pop())
        start = (slot.centerx - w / 2, slot.centery - w / 2)
        self.pos[eid] = [*start, 1.0]
        self.motions[eid] = Motion(start, target)

    def leave(self, eid, x, y, value):
        if len(self.model.out) <= self._output_count:   # not handed out (e.g. a Disruption): just fade
            super().leave(eid, x, y, value)
            return
        w = self.element_size()
        slot = self.output_slot(self._output_count)
        end = (slot.centerx - w / 2, slot.centery - w / 2)
        self.flyers[eid] = Flyer(self._output_count, value, Motion((x, y), end, arc=self.flight_arc()))
        self._output_count += 1

    def leaving(self):
        return super().leaving() | set(self.flyers)

    def update(self, dt):
        super().update(dt)
        for eid, f in list(self.flyers.items()):
            f.motion.tween.update(dt * self.speed)
            if f.motion.tween.done:
                del self.flyers[eid]

    # ---- drawing --------------------------------------------------------------
    def draw(self, surf, highlights=None, selected=(), hinted=(), hint_slot=None, offset=(0, 0)):
        super().draw(surf, highlights, selected, hinted, hint_slot, offset)
        if self.model is not None:
            self._draw_output(surf, offset)

    def _draw_output(self, surf, offset) -> None:
        """The "Output" label, landed values, and values still in flight."""
        ox, oy = offset
        w = self.element_size()
        first = self.output_slot(0)
        theme.draw_text(surf, "Output", (first.x + ox, first.y - 30 + oy), 18, theme.MUTED)
        f = theme.font(22, bold=True)
        for value, box in self.output():
            _block(surf, box.move(ox, oy), value, mix(theme.IDLE, theme.BG, 0.35), f)
        for flyer in self.flyers.values():
            x, y = flyer.motion.at()
            _block(surf, pygame.Rect(int(x + ox), int(y + oy), w, w), flyer.value, theme.BAD, f)


def _block(surf, rect, value, fill, font) -> None:
    pygame.draw.rect(surf, fill, rect, border_radius=10)
    img = font.render(str(value), True, theme.TEXT)
    surf.blit(img, img.get_rect(center=rect.center))

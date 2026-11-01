"""Draws a singly linked list: a head pointer, nodes in a row joined by arrows,
and null at the end. The row is only for reading; the arrows are the structure.

Each node is drawn in two parts, a value box and a next field; its pointer arrow
leaves from a dot in the next field. Pointers that are variables (head, cur) are
labelled boxes too, so every arrow starts from something that holds it.

Linked-list-specific motion:
  * arrows follow the nodes as they move, so inserts and deletes re-route them;
  * while a removed node fades, the arrow that now skips it bows over it;
  * a "cur" marker glides to whichever node the current walk Step is on.

Slots are keyed HEAD (insert at the head) and i (insert after position i). Each
is a "+" badge hanging below the arrow it would split, so the arrows stay visible.
Arrows run from HEAD or a node, to a node or None (null).
"""
from __future__ import annotations

import math

import pygame

from ...models import Move
from .. import theme
from ..anim import approach
from ..fx import mix
from .base import BADGE_R, Renderer, Target, draw_badge

HEAD = "head"     # the head pointer: an arrow's start, and the insert-at-head slot key
FIELD = 0.36      # next field width, as a fraction of the value box
HEAD_BOX = 30     # the head pointer's box
HEAD_W = 44       # room for the head box
NULL_SIZE = (52, 28)
NULL_W = 56       # room for the null box
MIN_GAP, MAX_GAP = 28, 60      # arrow length between nodes
BADGE_DROP = 28   # how far below the row a badge hangs
ARROW = mix(theme.MUTED, theme.TEXT, 0.35)


class LinkedListRenderer(Renderer):
    def __init__(self, rect):
        super().__init__(rect)
        self.cursor: int | None = None               # element id the "cur" marker is on
        self.cursor_x = 0.0

    # ---- layout -------------------------------------------------------------
    def elements(self):
        return list(self.model.nodes)

    def _track_width(self) -> float:
        return self.rect.w - 24 - HEAD_W - NULL_W

    def element_size(self) -> int:
        """Value box side: as big as fits with arrows about 0.6 of a node long."""
        n = len(self.model.nodes)
        return int(max(44, min(76, self._track_width() / (n * (1 + FIELD) + 0.6 * (n + 1)))))

    def gap(self) -> float:
        """Arrow length: whatever the nodes leave, so long lists still fit the board."""
        n, w = len(self.model.nodes), self.element_size()
        return max(MIN_GAP, min(MAX_GAP, (self._track_width() - n * _node_w(w)) / (n + 1)))

    def _unit(self) -> float:
        """A node's full width at rest."""
        return _node_w(self.element_size())

    def _head_x(self) -> float:
        """Where the head pointer's arrow starts: the head box's right edge."""
        n, g = len(self.model.nodes), self.gap()
        return self.rect.centerx - (HEAD_W + (n + 1) * g + n * self._unit() + NULL_W) / 2 + HEAD_W

    def layout(self):
        w, g, unit = self.element_size(), self.gap(), self._unit()
        x0 = self._head_x() + g
        y = self.rect.centery - w / 2
        return {eid: (x0 + i * (unit + g), y) for i, eid in enumerate(self.element_ids())}

    def body(self, rect):
        return pygame.Rect(rect.x, rect.y, round(_node_w(rect.w)), rect.h)

    def head_box(self) -> pygame.Rect:
        r = pygame.Rect(0, 0, HEAD_BOX, HEAD_BOX)
        r.midright = (int(self._head_x()), self.rect.centery)
        return r

    def null_box(self) -> pygame.Rect:
        ids = self.element_ids()
        left = self.next_field(ids[-1]).right + self.gap() if ids else self._head_x() + self.gap()
        r = pygame.Rect(0, 0, *NULL_SIZE)
        r.midleft = (int(left), self.rect.centery)
        return r

    def _value_box(self, eid: int) -> pygame.Rect:
        """Where a node's value box is right now: it scales about its centre and travels."""
        w = self.element_size()
        x, y, s = self.pos[eid]
        r = pygame.Rect(0, 0, max(1, round(w * s)), max(1, round(w * s)))
        r.center = (round(x + w / 2), round(y + w / 2))
        return r

    def next_field(self, eid: int) -> pygame.Rect:
        """Where a node's next field is right now, just right of its value box."""
        box = self._value_box(eid)
        return pygame.Rect(box.right, box.y, max(1, _field_w(box.w)), box.h)

    def arrow_start(self, end) -> tuple[float, float]:
        """The dot an arrow leaves from: the head box, or a node's next field."""
        r = self.head_box() if end == HEAD else self.next_field(end)
        return r.center

    # ---- slots ------------------------------------------------------------------
    def _slot_lefts(self) -> list[tuple[object, float]]:
        """(slot key, x where its gap starts) for every slot the Puzzle's ops allow."""
        out = []
        if self.allows("insert_head"):
            out.append((HEAD, self._head_x()))
        if self.allows("insert_after"):
            layout, unit = self.layout(), self._unit()
            out += [(i, layout[eid][0] + unit) for i, eid in enumerate(self.element_ids())]
        return out

    def badge_center(self, key) -> tuple[float, float]:
        g = self.gap()
        x = dict(self._slot_lefts())[key] + g / 2
        return x, self.rect.centery + self.element_size() / 2 + BADGE_DROP

    def slot_targets(self):
        """The whole gap is clickable, from just above the arrow down past the badge."""
        g = self.gap()
        top = self.rect.centery - 14
        out = []
        for key, left in self._slot_lefts():
            bottom = self.badge_center(key)[1] + BADGE_R + 6
            out.append(Target("slot", key, pygame.Rect(int(left + 2), int(top), int(g - 4), int(bottom - top))))
        return out

    def slot_move(self, key, value):
        return Move.of("insert_head", value) if key == HEAD else Move.of("insert_after", key, value)

    def slot_for(self, move):
        if move.op == "insert_head":
            return HEAD
        return move.args[0] if move.op == "insert_after" else None

    # ---- arrows ---------------------------------------------------------------
    def arrows(self) -> list[tuple]:
        """(from, to, bowed) for every pointer: `from` is an element id or HEAD,
        `to` is an element id or None (null). A bowed arrow skips a fading node."""
        chain = [HEAD, *self.element_ids(), None]
        ghost_xs = [g[0] for g in self.ghosts.values()]

        def x_of(end):
            if end == HEAD:
                return self._head_x()
            return math.inf if end is None else self.pos[end][0]

        return [(a, b, any(x_of(a) < gx < x_of(b) for gx in ghost_xs)) for a, b in zip(chain, chain[1:])]

    def _arrow_end(self, end) -> tuple[float, float]:
        if end is None:
            return self.null_box().midleft
        return self._value_box(end).midleft

    # ---- the cur marker -------------------------------------------------------
    def on_step(self, step):
        eid = step.ids[0] if step is not None and step.kind == "walk" and step.ids else None
        if eid not in self.pos:
            eid = None
        if eid is not None and self.cursor is None:
            self.cursor_x = self._head_x()           # a fresh walk starts at the head
        self.cursor = eid

    def update(self, dt):
        super().update(dt)
        if self.cursor is not None:
            target = self.pos[self.cursor][0] + self.element_size() / 2
            self.cursor_x = approach(self.cursor_x, target, dt * self.speed)

    # ---- drawing --------------------------------------------------------------
    def draw_under(self, surf, hint_slot, pulse, offset):
        ox, oy = offset
        w = self.element_size()

        # Insert badges hang below the arrow they would split, on a dotted stem.
        if self.show_slots:
            for key, _ in self._slot_lefts():
                hinted = key == hint_slot
                colour = mix(theme.GOOD, theme.ACTIVE, pulse) if hinted else theme.GOOD
                bx, by = self.badge_center(key)
                c = (int(bx + ox), int(by + oy))
                for y in range(int(self.rect.centery + 6 + oy), int(c[1] - BADGE_R), 6):
                    pygame.draw.line(surf, colour, (c[0], y), (c[0], y + 2), 2)
                draw_badge(surf, c, colour, hinted)

        for a, b, bowed in self.arrows():
            x1, y1 = self.arrow_start(a)
            x2, y2 = self._arrow_end(b)
            _arrow(surf, (x1 + ox, y1 + oy), (x2 + ox, y2 + oy), bow=w * 1.1 if bowed else 0.0)

        # head: a pointer variable, labelled, holding the first arrow.
        hb = self.head_box().move(ox, oy)
        pygame.draw.rect(surf, theme.PANEL, hb, border_radius=6)
        pygame.draw.rect(surf, theme.ACTIVE, hb, 2, border_radius=6)
        pygame.draw.line(surf, ARROW, hb.center, hb.midright, 2)
        pygame.draw.circle(surf, theme.ACTIVE, hb.center, 4)
        theme.draw_text(surf, "head", (hb.centerx, hb.y - 24), 17, theme.ACTIVE, bold=True, center=True)

        nb = self.null_box().move(ox, oy)
        pygame.draw.rect(surf, theme.MUTED, nb, 2, border_radius=nb.h // 2)
        theme.draw_text(surf, "null", (nb.centerx, nb.y + 3), 16, theme.MUTED, center=True)

        if self.cursor is not None:
            top = self.rect.centery - w / 2 - 44 + oy
            label = theme.font(16, bold=True).render("cur", True, theme.BG)
            pill = label.get_rect(center=(int(self.cursor_x + ox), int(top + 10))).inflate(14, 4)
            pygame.draw.rect(surf, theme.ACTIVE, pill, border_radius=pill.h // 2)
            surf.blit(label, label.get_rect(center=pill.center))
            tip = (self.cursor_x + ox, top + 36)
            pygame.draw.line(surf, theme.ACTIVE, (tip[0], pill.bottom), (tip[0], tip[1] - 6), 2)
            pygame.draw.polygon(surf, theme.ACTIVE, [(tip[0] - 6, tip[1] - 8), (tip[0] + 6, tip[1] - 8), tip])

    def draw_attachment(self, surf, eid, rect, fill):
        """The next field: joined to the value box, a shade darker, with the pointer's dot."""
        if rect.w < 4:
            return
        radius = 10
        field = pygame.Rect(rect.right - radius, rect.y, _field_w(rect.w) + radius, rect.h)
        pygame.draw.rect(surf, mix(fill, theme.BG, 0.4), field,
                         border_top_right_radius=radius, border_bottom_right_radius=radius)
        pygame.draw.line(surf, mix(fill, theme.BG, 0.65), (rect.right, rect.y + 3), (rect.right, rect.bottom - 4), 2)
        dot = ((rect.right + field.right) // 2, rect.centery)
        pygame.draw.line(surf, ARROW, dot, (field.right, dot[1]), 2)
        pygame.draw.circle(surf, theme.TEXT, dot, max(2, rect.w // 16))


def _field_w(box_w: float) -> int:
    """A next field's width, for a value box `box_w` wide."""
    return round(box_w * FIELD)


def _node_w(box_w: float) -> float:
    """A whole node's width (value box plus next field), for a value box `box_w` wide."""
    return box_w * (1 + FIELD)


def _arrow(surf, start, end, bow: float = 0.0) -> None:
    """A pointer arrow, straight or bowed upward by `bow` pixels."""
    if bow:
        mid = ((start[0] + end[0]) / 2, (start[1] + end[1]) / 2 - 2 * bow)
        pts = [(_bezier(start[0], mid[0], end[0], t / 16), _bezier(start[1], mid[1], end[1], t / 16))
               for t in range(17)]
    else:
        pts = [start, end]
    (x1, y1), (x2, y2) = pts[-2], pts[-1]
    ang = math.atan2(y2 - y1, x2 - x1)
    back = (x2 - 9 * math.cos(ang), y2 - 9 * math.sin(ang))
    pygame.draw.lines(surf, ARROW, False, [*pts[:-1], back], 2)
    pygame.draw.polygon(surf, ARROW, [
        (x2, y2),
        (x2 - 11 * math.cos(ang - 0.42), y2 - 11 * math.sin(ang - 0.42)),
        (x2 - 11 * math.cos(ang + 0.42), y2 - 11 * math.sin(ang + 0.42)),
    ])


def _bezier(a: float, m: float, b: float, t: float) -> float:
    return (1 - t) ** 2 * a + 2 * (1 - t) * t * m + t ** 2 * b

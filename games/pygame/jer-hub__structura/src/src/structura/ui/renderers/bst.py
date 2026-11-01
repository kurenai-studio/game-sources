"""Draws a binary search tree: a node's in-order position sets its x, its depth
sets its y, and edges join parents to children.

Every empty child position is a slot. A tree of n nodes has n + 1 of them, one
in each gap between in-order neighbours, so columns alternate gap, node, gap
and nothing overlaps. Each slot is a "+" badge one level below its parent.

Slots are keyed (parent value, side); the empty tree's root slot is (None, "").
Nodes are keyed by value.

Tree-specific motion, once a scene's StepPlayer drives the renderer:
  * a new node stays hidden while its insert compares down the path, and grows
    in when the "place" Step plays;
  * after a delete the old tree stays on the board, so the comparison path and
    the successor light up on it, until the Step that removes the node plays;
  * nodes that change level (a rotation) swing sideways along arcs.
Either change shows at once when no Steps are playing. The renderer draws a
copy of the model taken at sync, so it can keep showing the old tree.
"""
from __future__ import annotations

import pygame

from ...models import Move
from .. import theme
from ..fx import Tween, mix
from .base import BADGE_R, Renderer, Target, draw_badge

ROOT = (None, "")    # the empty tree's slot
MARGIN_X, MARGIN_Y = 12, 20
MAX_UNIT = 60        # widest column, so small trees don't sprawl
MAX_LEVEL = 86       # tallest level
EDGE = mix(theme.MUTED, theme.TEXT, 0.35)
REMOVING = {"remove_leaf", "splice", "replace"}    # Steps that take a node off the tree


class BSTRenderer(Renderer):
    def __init__(self, rect):
        super().__init__(rect)
        self.waiting: set[int] = set()             # new nodes not yet placed by their Step
        self.later = None                          # the tree after a delete, until its removing Step
        self.stepped = False                       # a scene's StepPlayer drives this renderer
        self._told = False                         # on_step was called since the last update
        self._step = None

    # ---- layout -------------------------------------------------------------
    def elements(self):
        return [(nid, self.model.nodes[nid].value) for nid in self.model.inorder_ids()]

    def keys(self):
        return [value for _, value in self.elements()]

    def _depths(self) -> dict[int, int]:
        out, stack = {}, [(self.model.root, 0)] if self.model.root is not None else []
        while stack:
            nid, d = stack.pop()
            out[nid] = d
            n = self.model.nodes[nid]
            stack += [(c, d + 1) for c in (n.left, n.right) if c is not None]
        return out

    def _unit(self) -> float:
        """Column width; columns alternate gap and node."""
        return min(MAX_UNIT, (self.rect.w - 2 * MARGIN_X) / (2 * len(self.model.nodes) + 1))

    def _level(self) -> float:
        levels = max(self._depths().values(), default=-1) + 2    # node levels plus the slot row
        return min(MAX_LEVEL, (self.rect.h - 2 * MARGIN_Y) / levels)

    def _x(self, column: int) -> float:
        n = len(self.model.nodes)
        return self.rect.centerx + (column - n) * self._unit()

    def _y(self, depth: int) -> float:
        return self.rect.y + MARGIN_Y + (depth + 0.5) * self._level()

    def element_size(self) -> int:
        return int(max(28, min(56, self._unit() * 1.3, self._level() * 0.65)))

    def layout(self):
        w, depths = self.element_size(), self._depths()
        return {eid: (self._x(2 * i + 1) - w / 2, self._y(depths[eid]) - w / 2)
                for i, eid in enumerate(self.element_ids())}

    # ---- slots ------------------------------------------------------------------
    def _slots(self) -> list[tuple[tuple, tuple[float, float]]]:
        """(slot key, badge centre) for each gap, left to right."""
        if not self.allows("insert"):
            return []
        depths = self._depths()
        out = []
        for gap, key in enumerate(self.model.empty_slots()):
            parent = None if key == ROOT else self.model.find(key[0])
            if parent in self.waiting:
                continue
            depth = 0 if parent is None else depths[parent] + 1
            out.append((key, (self._x(2 * gap), self._y(depth))))
        return out

    def slot_targets(self):
        side = int(max(28, self._unit()))
        out = []
        for key, (x, y) in self._slots():
            r = pygame.Rect(0, 0, side, side)
            r.center = (int(x), int(y))
            out.append(Target("slot", key, r))
        return out

    def slot_move(self, key, value):
        parent, side = key
        return Move.of("insert", value, parent, side)

    def slot_for(self, move):
        return (move.args[1], move.args[2]) if move.op == "insert" else None

    # ---- edges --------------------------------------------------------------------
    def edges(self) -> list[tuple[int, int]]:
        """(parent id, child id) for every link between showing nodes."""
        out = []
        for nid, n in self.model.nodes.items():
            if nid in self.waiting:
                continue
            for child in (n.left, n.right):
                if child is not None and child not in self.waiting:
                    out.append((nid, child))
        return out

    def _centre(self, eid: int) -> tuple[float, float]:
        w = self.element_size()
        x, y, _ = self.pos[eid]
        return x + w / 2, y + w / 2

    # ---- motion -------------------------------------------------------------------
    def arcs(self, moving):
        """In a rotation, nodes going up and nodes going down swing sideways, away from
        each other, like a wheel turning; a rotation keeps every column, so a straight
        path would only slide. A delete only lifts nodes, so it moves them straight."""
        risers = [c[0] for c, t in moving.values() if t[1] < c[1] - 0.5]
        fallers = [c[0] for c, t in moving.values() if t[1] > c[1] + 0.5]
        if not (risers and fallers):
            return {}
        centre = (sum(risers) / len(risers) + sum(fallers) / len(fallers)) / 2
        swing = 0.9 * self.element_size()
        return {eid: (swing if c[0] >= centre else -swing, 0.0)
                for eid, (c, t) in moving.items() if abs(t[1] - c[1]) > 0.5}

    def enter(self, eid, target):
        self.pos[eid] = [target[0], target[1], 0.0]
        self.waiting.add(eid)

    def leave(self, eid, x, y, value):
        if eid not in self.waiting:                # a node never shown has nothing to fade
            super().leave(eid, x, y, value)

    def sync(self, model):
        tree = model.copy()
        if self.stepped and self.model is not None and set(self.model.nodes) - set(tree.nodes):
            self.later = tree
            return
        self.later = None
        self._show(tree)

    def _show(self, tree):
        first = self.model is None
        super().sync(tree)
        self.waiting &= set(self.pos)
        if first:                                  # no Step will place the starting tree
            self._place(set(self.waiting))

    def on_step(self, step):
        self.stepped = self._told = True
        self._step = step

    def update(self, dt):
        step = self._step if self._told else None
        if self.later is not None and (step is None or step.kind in REMOVING):
            later, self.later = self.later, None
            self._show(later)
        if step is None:
            placed = set(self.waiting)
        else:
            placed = self.waiting & set(step.ids) if step.kind == "place" else set()
        self._place(placed)
        self._told = False
        super().update(dt)

    def _place(self, eids) -> None:
        for eid in eids:
            self.waiting.discard(eid)
            self.spawns[eid] = Tween(0.4)

    # ---- drawing ----------------------------------------------------------------
    def draw_under(self, surf, hint_slot, pulse, offset):
        ox, oy = offset
        for parent, child in self.edges():
            (x1, y1), (x2, y2) = self._centre(parent), self._centre(child)
            pygame.draw.line(surf, EDGE, (x1 + ox, y1 + oy), (x2 + ox, y2 + oy), 3)

        if not self.show_slots:
            return
        for key, (bx, by) in self._slots():
            hinted = key == hint_slot
            colour = mix(theme.GOOD, theme.ACTIVE, pulse) if hinted else theme.GOOD
            c = (int(bx + ox), int(by + oy))
            if key != ROOT:
                px, py = self._centre(self.model.find(key[0]))
                _dotted(surf, colour, (px + ox, py + oy), c)
            draw_badge(surf, c, colour, hinted)


def _dotted(surf, colour, start, end, dash: int = 3, space: int = 5) -> None:
    """A dotted line from start that stops at the edge of the badge at end."""
    (x1, y1), (x2, y2) = start, end
    length = max(1.0, ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5)
    stop = length - BADGE_R
    t = 0.0
    while t < stop:
        a, b = t / length, min(t + dash, stop) / length
        pygame.draw.line(surf, colour, (x1 + (x2 - x1) * a, y1 + (y2 - y1) * a),
                         (x1 + (x2 - x1) * b, y1 + (y2 - y1) * b), 2)
        t += dash + space

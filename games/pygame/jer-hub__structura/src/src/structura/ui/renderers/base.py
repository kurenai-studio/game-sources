"""The renderer contract and the visual effects every structure shares.

A renderer draws one data structure model. Subclasses describe only their
layout (where each element sits, what can be clicked) and any motion peculiar
to their structure; the base supplies the rest:

  * new elements grow in with a little overshoot, removed ones shrink and fade
    (subclasses may override `enter` and `leave` to move them somewhere instead);
  * elements that change place travel there (straight unless the subclass arcs them);
  * shake, the left-to-right celebration wave, highlights, selection and hints.

Elements are identified by model element id (`eid`); the player-facing `key`
of an element (what clicks, selection and `center_of` use) is its position in
reading order unless a subclass says otherwise.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

import pygame

from ...models import Move, Step
from .. import theme
from ..fx import Shake, Tween, ease_in_out_sine, ease_out_back, lerp, mix

TRAVEL = 0.45     # seconds for an element to reach its new place
BADGE_R = 12      # insert badge radius


def draw_badge(surf, centre, colour, hinted: bool) -> None:
    """The "+" badge that marks an insert slot; a hinted one is drawn larger."""
    r = BADGE_R + 3 * hinted
    pygame.draw.circle(surf, mix(theme.PANEL, colour, 0.18), centre, r)
    pygame.draw.circle(surf, colour, centre, r, 2)
    pygame.draw.line(surf, colour, (centre[0] - 5, centre[1]), (centre[0] + 5, centre[1]), 2)
    pygame.draw.line(surf, colour, (centre[0], centre[1] - 5), (centre[0], centre[1] + 5), 2)


@dataclass
class Target:
    """Something the player can click: a `node` (an element) or a `slot` (an empty place)."""

    kind: str
    key: object
    rect: pygame.Rect


Arc = float | tuple[float, float]


class Motion:
    """Travel from start to end, bowed off the straight line at mid-flight: `arc`
    pixels downward, or by an (x, y) offset to bow sideways."""

    def __init__(self, start, end, arc: Arc = 0.0):
        self.start, self.end = start, end
        self.bow = (0.0, arc) if isinstance(arc, (int, float)) else arc
        self.tween = Tween(TRAVEL)

    def at(self):
        t = ease_in_out_sine(self.tween.progress)
        lift = math.sin(math.pi * t)
        x = lerp(self.start[0], self.end[0], t) + self.bow[0] * lift
        y = lerp(self.start[1], self.end[1], t) + self.bow[1] * lift
        return x, y


class Renderer:
    def __init__(self, rect: pygame.Rect):
        self.rect = rect
        self.model = None
        self.pos: dict[int, list[float]] = {}        # element id -> [x, y, scale] (top-left)
        self.motions: dict[int, Motion] = {}
        self.spawns: dict[int, Tween] = {}
        self.ghosts: dict[int, tuple] = {}           # id -> (x, y, value, Tween)
        self.shakes: dict[int, Shake] = {}
        self.cheer: dict[int, Tween] = {}
        self.clock = 0.0
        self.show_slots = False
        self.last_values: dict[int, object] = {}     # as of the last sync; models change in place
        self.ops: set[str] | None = None             # the Puzzle's ops; None allows all (Lessons)
        self.speed = 1.0                             # the Profile's animation speed; scales element motion only

    # ---- what subclasses describe -------------------------------------------
    def elements(self) -> list[tuple[int, object]]:
        """(element id, value) pairs in reading order."""
        raise NotImplementedError

    def element_size(self) -> int:
        """Side of an element's square box, in pixels."""
        raise NotImplementedError

    def layout(self) -> dict[int, tuple[float, float]]:
        """Resting top-left corner of every element."""
        raise NotImplementedError

    def slot_targets(self) -> list[Target]:
        """Slot targets, asked for only while `show_slots` is on."""
        return []

    def slot_move(self, key, value) -> Move:
        """The Move made by clicking slot `key` with `value` from the Tray."""
        raise NotImplementedError

    def slot_for(self, move: Move):
        """The slot whose click makes `move`, or None if it isn't made by a slot."""
        return None

    def allows(self, op: str) -> bool:
        return self.ops is None or op in self.ops

    def on_step(self, step: Step | None) -> None:
        """Called every frame with the Step being played, for markers that follow it."""

    def arcs(self, moving: dict[int, tuple]) -> dict[int, Arc]:
        """How each moving element bows off a straight path (see Motion); straight by default."""
        return {}

    def draw_under(self, surf, hint_slot, pulse: float, offset) -> None:
        """Structure furniture drawn beneath the elements (slots, labels, arrows)."""

    def body(self, rect: pygame.Rect) -> pygame.Rect:
        """An element's whole drawn shape, given its value box; outlines and clicks use it."""
        return rect

    def draw_attachment(self, surf, eid: int, rect: pygame.Rect, fill) -> None:
        """Extra parts of an element drawn right after its value box (e.g. a next field)."""

    def enter(self, eid: int, target: tuple[float, float]) -> None:
        """Animate a new element in. By default it grows in place."""
        self.pos[eid] = [target[0], target[1], 0.0]
        self.spawns[eid] = Tween(0.4)

    def leave(self, eid: int, x: float, y: float, value) -> None:
        """Animate a removed element out. By default it shrinks and fades as a ghost."""
        self.ghosts[eid] = (x, y, value, Tween(0.35))

    # ---- keys -----------------------------------------------------------------
    def element_ids(self) -> list[int]:
        return [eid for eid, _ in self.elements()]

    def keys(self) -> list:
        """The player-facing key of each element, parallel to `element_ids`."""
        return list(range(len(self.elements())))

    def eid_of(self, key) -> int | None:
        return dict(zip(self.keys(), self.element_ids())).get(key)

    # ---- syncing with the model -------------------------------------------------
    def sync(self, model) -> None:
        self.model = model
        layout = self.layout()
        moving = {}
        for eid, target in layout.items():
            if eid not in self.pos:
                self.enter(eid, target)
                continue
            current = (self.pos[eid][0], self.pos[eid][1])
            heading = self.motions[eid].end if eid in self.motions else current
            if abs(heading[0] - target[0]) > 0.5 or abs(heading[1] - target[1]) > 0.5:
                moving[eid] = (current, target)
        arcs = self.arcs(moving)
        for eid, (current, target) in moving.items():
            self.motions[eid] = Motion(current, target, arcs.get(eid, 0.0))
        for eid in list(self.pos):
            if eid not in layout:
                x, y, _ = self.pos.pop(eid)
                self.motions.pop(eid, None)
                self.spawns.pop(eid, None)
                self.leave(eid, x, y, self.last_values.get(eid, ""))
        self.last_values = dict(self.elements())

    def update(self, dt: float) -> None:
        if self.model is None:
            return
        self.clock += dt
        move_dt = dt * self.speed
        for eid, m in list(self.motions.items()):
            m.tween.update(move_dt)
            self.pos[eid][0], self.pos[eid][1] = m.at()
            if m.tween.done:
                del self.motions[eid]
        for eid, t in list(self.spawns.items()):
            t.update(move_dt)
            self.pos[eid][2] = max(0.0, ease_out_back(t.progress))
            if t.done:
                self.pos[eid][2] = 1.0
                del self.spawns[eid]
        for eid, g in list(self.ghosts.items()):
            g[3].update(move_dt)
            if g[3].done:
                del self.ghosts[eid]
        for eid, s in list(self.shakes.items()):
            s.update(dt)
            if not s.active:
                del self.shakes[eid]
        for t in self.cheer.values():
            t.update(move_dt)

    # ---- effects --------------------------------------------------------------
    def shake(self, keys) -> None:
        for key in keys:
            eid = self.eid_of(key)
            if eid is not None:
                self.shakes[eid] = Shake(0.45, amplitude=9)

    def celebrate(self) -> None:
        for i, eid in enumerate(self.element_ids()):
            self.cheer[eid] = Tween(0.3, delay=i * 0.08)

    def celebration(self, eid: int) -> float:
        return self.cheer[eid].progress if eid in self.cheer else 0.0

    def at_rest(self, eid: int) -> bool:
        """In place, full size and not moving."""
        return eid not in self.motions and eid not in self.spawns and self.pos[eid][2] == 1.0

    def leaving(self) -> set[int]:
        """Ids of removed elements still animating out."""
        return set(self.ghosts)

    def scale(self, eid: int) -> float:
        return self.pos[eid][2]

    def draw_offset(self, eid: int) -> tuple[int, int]:
        s = self.shakes.get(eid)
        return s.offset() if s else (0, 0)

    # ---- hit testing ------------------------------------------------------------
    def targets(self) -> list[Target]:
        if self.model is None:
            return []
        layout, w = self.layout(), self.element_size()
        out = [Target("node", key, self.body(pygame.Rect(int(layout[eid][0]), int(layout[eid][1]), w, w)))
               for key, eid in zip(self.keys(), self.element_ids())]
        if self.show_slots:
            out += self.slot_targets()
        return out

    def center_of(self, key, offset=(0, 0)) -> tuple[int, int]:
        w = self.element_size()
        x, y, _ = self.pos[self.eid_of(key)]
        return int(x + w / 2 + offset[0]), int(y + w / 2 + offset[1])

    # ---- drawing ------------------------------------------------------------------
    def draw(self, surf, highlights=None, selected=(), hinted=(), hint_slot=None, offset=(0, 0)) -> None:
        if self.model is None:
            return
        highlights = highlights or {}
        w = self.element_size()
        f = theme.font(int(w * 0.42), bold=True)
        pulse = 0.5 + 0.5 * math.sin(self.clock * 6)
        ox, oy = offset

        self.draw_under(surf, hint_slot, pulse, offset)

        for x, y, value, tw in self.ghosts.values():
            s = 1 - tw.progress
            rect = pygame.Rect(0, 0, w * s, w * s)
            rect.center = (x + w / 2 + ox, y + w / 2 + oy + 20 * tw.progress)
            pygame.draw.rect(surf, mix(theme.BG, theme.BAD, s), rect, border_radius=10)

        # Elements in flight draw last so they stay visible over their neighbours.
        items = list(zip(self.keys(), self.elements()))
        items.sort(key=lambda item: item[1][0] in self.motions)
        for key, (eid, value) in items:
            x, y, s = self.pos[eid]
            if s <= 0:
                continue
            dx, dy = self.draw_offset(eid)
            colour = highlights.get(eid)
            grow = 1 + (0.08 * pulse if colour else 0)
            size = w * s * grow
            rect = pygame.Rect(0, 0, size, size)
            rect.center = (x + w / 2 + dx + ox, y + w / 2 + dy + oy)
            fill = mix(colour or theme.IDLE, theme.GOOD, self.celebration(eid))
            whole = self.body(rect)
            if colour:
                glow = pygame.Surface((whole.w + 24, whole.h + 24), pygame.SRCALPHA)
                pygame.draw.rect(glow, (*colour, 70), glow.get_rect(), border_radius=18)
                surf.blit(glow, (whole.x - 12, whole.y - 12))
            if eid in self.shakes:
                fill = mix(fill, theme.BAD, 0.7)
            pygame.draw.rect(surf, fill, rect, border_radius=10)
            self.draw_attachment(surf, eid, rect, fill)
            if key in selected:
                pygame.draw.rect(surf, theme.SELECT, whole.inflate(10, 10), 3, border_radius=12)
            if key in hinted:
                pygame.draw.rect(surf, mix(theme.ACTIVE, theme.TEXT, pulse), whole.inflate(16, 16), 3, border_radius=14)
            dark = fill != theme.IDLE
            img = f.render(str(value), True, (15, 18, 30) if dark else theme.TEXT)
            if s < 0.98:
                img = pygame.transform.smoothscale_by(img, max(0.05, s))
            surf.blit(img, img.get_rect(center=rect.center))

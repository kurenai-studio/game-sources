"""Solid mechanisms: doors, bridges, moving platforms and crumbling platforms."""
import math
from . import settings as S
from .collision import Box
from .puzzle import Actuator


class Door(Actuator):
    """A barrier that slides up while powered. Never closes on top of a robot."""

    def __init__(self, col, row, w, h, triggers, mode="any"):
        self.init_actuator(triggers, mode)
        self.full = Box(col * S.TILE, row * S.TILE, w * S.TILE, h * S.TILE)
        self.solid_box = self.full.copy()
        self.open_amount = 0.0
        self.target_open = False

    def update(self, dt, signals, players):
        events = []
        want_open = self.powered(signals)
        if not want_open and self.open_amount > 0 and any(p.alive and p.box.overlaps(self.full) for p in players):
            want_open = True                      # do not crush anybody
        if want_open != self.target_open:
            self.target_open = want_open
            events.append("door_open" if want_open else "door_close")
        step = S.DOOR_SPEED * dt
        self.open_amount = min(1.0, self.open_amount + step) if want_open else max(0.0, self.open_amount - step)
        # panel retracts upward: top edge stays, height shrinks
        self.solid_box.h = self.full.h * (1.0 - self.open_amount)
        return events

    def solids(self):
        return [self.solid_box] if self.solid_box.h > 1.0 else []


class Bridge(Actuator):
    """A horizontal energy bridge that extends from its left end while powered."""

    def __init__(self, col, row, w, triggers, mode="any"):
        self.init_actuator(triggers, mode)
        self.origin_x = col * S.TILE
        self.full_w = w * S.TILE
        self.box = Box(self.origin_x, row * S.TILE, 0.0, S.BRIDGE_THICKNESS)
        self.extension = 0.0
        self.target_out = False

    def update(self, dt, signals, players):
        events = []
        want_out = self.powered(signals)
        if want_out != self.target_out:
            self.target_out = want_out
            events.append("door_open" if want_out else "door_close")
        step = S.BRIDGE_SPEED * dt / self.full_w
        self.extension = min(1.0, self.extension + step) if want_out else max(0.0, self.extension - step)
        self.box.w = self.full_w * self.extension
        return events

    def solids(self):
        return [self.box] if self.box.w > 2.0 else []


class MovingPlatform(Actuator):
    """Platform travelling between two points.

    * without triggers: continuous ping-pong with a short pause at each end
    * with triggers: glides to the far end while powered and returns when not
    """

    def __init__(self, col, row, w, dx, dy, speed=90.0, triggers=(), mode="any", pause=0.7):
        self.init_actuator(triggers, mode)
        self.start = (col * S.TILE, row * S.TILE)
        self.end = ((col + dx) * S.TILE, (row + dy) * S.TILE)
        self.length = max(1.0, math.hypot(self.end[0] - self.start[0], self.end[1] - self.start[1]))
        self.speed = speed
        self.pause = pause
        self.t = 0.0          # 0 = start, 1 = end
        self.direction = 1
        self.wait = 0.0
        self.box = Box(self.start[0], self.start[1], w * S.TILE, S.MOVER_THICKNESS)
        self.delta = (0.0, 0.0)

    def update(self, dt, signals):
        old = (self.box.x, self.box.y)
        dt_t = self.speed * dt / self.length
        if self.triggers:
            target = 1.0 if self.powered(signals) else 0.0
            if self.t < target:
                self.t = min(target, self.t + dt_t)
            elif self.t > target:
                self.t = max(target, self.t - dt_t)
        else:
            if self.wait > 0:
                self.wait -= dt
            else:
                self.t += self.direction * dt_t
                if self.t >= 1.0:
                    self.t, self.direction, self.wait = 1.0, -1, self.pause
                elif self.t <= 0.0:
                    self.t, self.direction, self.wait = 0.0, 1, self.pause
        self.box.x = self.start[0] + (self.end[0] - self.start[0]) * self.t
        self.box.y = self.start[1] + (self.end[1] - self.start[1]) * self.t
        self.delta = (self.box.x - old[0], self.box.y - old[1])

    def solids(self):
        return [self.box]


class FadingPlatform:
    """Solid until stepped on; crumbles after `delay` seconds, returns after `respawn` seconds."""
    SOLID, CRUMBLING, GONE = "solid", "crumbling", "gone"

    def __init__(self, col, row, w, delay=0.7, respawn=2.8):
        self.box = Box(col * S.TILE, row * S.TILE, w * S.TILE, S.FADING_THICKNESS)
        self.delay = delay
        self.respawn = respawn
        self.state = self.SOLID
        self.timer = 0.0

    def update(self, dt, players):
        events = []
        if self.state == self.SOLID:
            if any(p.alive and p.ground_solid is self.box for p in players):
                self.state = self.CRUMBLING
                self.timer = 0.0
        elif self.state == self.CRUMBLING:
            self.timer += dt
            if self.timer >= self.delay:
                self.state = self.GONE
                self.timer = 0.0
                events.append("door_close")
        else:
            self.timer += dt
            if self.timer >= self.respawn and not any(p.alive and p.box.overlaps(self.box) for p in players):
                self.state = self.SOLID
                self.timer = 0.0
        return events

    @property
    def progress(self):
        """0..1 crumbling progress (for rendering)."""
        return min(1.0, self.timer / self.delay) if self.state == self.CRUMBLING else 0.0

    def solids(self):
        return [] if self.state == self.GONE else [self.box]

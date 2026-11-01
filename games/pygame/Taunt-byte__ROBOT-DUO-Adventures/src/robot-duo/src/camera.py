"""Smooth horizontal-scrolling camera clamped to the map. No pygame."""
import math
import random


class Camera:
    def __init__(self, view_w, view_h, world_w, world_h):
        self.view_w, self.view_h = view_w, view_h
        self.world_w, self.world_h = world_w, world_h
        self.x = 0.0
        self.y = 0.0
        self.shake_time = 0.0
        self.shake_amount = 0.0
        self._rng = random.Random(7)

    def _target(self, box):
        tx = box.centerx - self.view_w / 2.0
        ty = box.centery - self.view_h / 2.0
        return self._clamp(tx, ty)

    def _clamp(self, x, y):
        max_x = max(0.0, self.world_w - self.view_w)
        x = min(max(x, 0.0), max_x)
        if self.world_h <= self.view_h:
            y = -(self.view_h - self.world_h) / 2.0       # small maps are centred vertically
        else:
            y = min(max(y, 0.0), self.world_h - self.view_h)
        return x, y

    def snap(self, box):
        self.x, self.y = self._target(box)

    def update(self, box, dt):
        tx, ty = self._target(box)
        k = 1.0 - math.exp(-6.0 * dt)         # frame-rate independent easing
        self.x += (tx - self.x) * k
        self.y += (ty - self.y) * k
        self.x, self.y = self._clamp(self.x, self.y)
        self.shake_time = max(0.0, self.shake_time - dt)

    def shake(self, amount=6.0, duration=0.35):
        self.shake_amount, self.shake_time = amount, duration

    @property
    def offset(self):
        """Integer pixel offset to subtract from world coordinates when drawing."""
        ox, oy = self.x, self.y
        if self.shake_time > 0:
            f = self.shake_time * self.shake_amount
            ox += self._rng.uniform(-f, f)
            oy += self._rng.uniform(-f, f)
        return int(round(ox)), int(round(oy))

"""Plays model Steps one beat at a time, for highlights and Code Mirror."""
from __future__ import annotations

from collections import deque

from ..models import Step
from . import theme

BEAT = 0.55  # seconds per Step at 1x speed


class StepPlayer:
    def __init__(self, speed: float = 1.0):
        self.queue: deque[Step] = deque()
        self.current: Step | None = None
        self.timer = 0.0
        self.speed = speed

    def play(self, steps) -> None:
        self.queue.extend(steps)
        if self.current is None:
            self._advance()

    def clear(self) -> None:
        self.queue.clear()
        self._advance()

    def _advance(self) -> None:
        self.current = self.queue.popleft() if self.queue else None
        self.timer = BEAT / self.speed if self.current else 0.0

    def update(self, dt: float) -> None:
        while self.current is not None and dt > 0:
            used = min(dt, self.timer)
            self.timer -= used
            dt -= used
            if self.timer <= 0:
                self._advance()

    @property
    def busy(self) -> bool:
        return self.current is not None

    def highlights(self) -> dict[int, tuple]:
        if self.current is None:
            return {}
        colour = theme.STEP_COLOURS.get(self.current.kind, theme.ACTIVE)
        return {i: colour for i in self.current.ids}


def approach(cur: float, target: float, dt: float, rate: float = 12.0) -> float:
    """Exponential ease toward target; frame-rate independent enough for UI."""
    k = min(1.0, rate * dt)
    return cur + (target - cur) * k

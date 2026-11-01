"""Watching the Reference Solution play itself on the board after a Puzzle is finished.

It is the Puzzle scene with the player's hands off: the same board, effects,
Code Mirror and Disruption announcements, but Moves come from the Reference
Solution, one per beat at the Profile's animation speed. Nothing is recorded,
and leaving returns to the same Results screen rather than a new one, which
would record another attempt.
"""
from __future__ import annotations

from ...puzzles.session import reference_moves
from .. import theme
from ..anim import BEAT
from ..app import SIZE
from ..widgets import Row
from .puzzle import PuzzleScene


class ReplayScene(PuzzleScene):
    watching = True

    def __init__(self, app, zone, puzzle, results):
        self.results = results
        self.queue = list(reference_moves(puzzle))
        super().__init__(app, zone, puzzle)
        self.wait = self._beat()
        self._say("Watching the Reference Solution.")

    def _beat(self) -> float:
        return BEAT / self.player.speed

    def _sync(self):
        s = self.session
        self.renderer.show_slots = False
        self.renderer.sync(s.model)
        self.buttons = self._answer_buttons() if self.answering else []
        label, accent = ("Back to Results", theme.GOOD) if s.done else ("Leave Replay", theme.IDLE)
        self.buttons.append(Row(SIZE[0] - 220, SIZE[1] - 70).add(
            label, lambda: self.app.go(self.results), width=190, accent=accent))

    def on_event(self, event):
        pass

    def update(self, dt):
        # The next Move waits for the last one's Steps, so each can be followed.
        if self.queue and not self.player.busy:
            self.wait -= dt
            if self.wait <= 0:
                self.wait = self._beat()
                self._attempt(self.queue.pop(0))
        super().update(dt)

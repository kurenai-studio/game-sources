"""After a Puzzle: Stars, how the attempt compared with the Reference Solution, what next."""
from __future__ import annotations

import pygame

from ...puzzles.session import reference_count
from .. import theme
from ..app import SIZE, Scene
from ..fx import Effects, Tween, ease_out_back
from ..widgets import Row


class ResultsScene(Scene):
    def __init__(self, app, zone, puzzle, session):
        super().__init__(app)
        self.zone, self.puzzle, self.session = zone, puzzle, session
        self.stars = session.stars()
        self.reference = reference_count(puzzle)
        self.fx = Effects()
        self.reveal = [Tween(0.35, delay=0.3 + i * 0.35) for i in range(self.stars)]
        self._landed = [False] * self.stars
        self.best = app.store.record(app.profile.id, puzzle.id, self.stars, session.moves,
                                     session.glitches, session.hints_used)
        idx = zone.puzzles.index(puzzle)
        nxt = zone.puzzles[idx + 1] if idx + 1 < len(zone.puzzles) else None
        row = Row(SIZE[0] // 2 - 330, 560, h=50)
        self.buttons = [
            row.add("Retry", lambda: app.open_puzzle(zone, puzzle), width=200),
            row.add("Back to Zone", lambda: app.open_zone(zone), width=200),
        ]
        if nxt:
            self.buttons.append(row.add("Next Puzzle", lambda: app.open_puzzle(zone, nxt), width=200,
                                        accent=theme.GOOD))
        self.buttons.append(Row(SIZE[0] // 2 - 160, 625).add("Watch Reference Solution", self._watch, width=320))

    def _watch(self):
        from .replay import ReplayScene
        self.app.go(ReplayScene(self.app, self.zone, self.puzzle, results=self))

    STAR_SIZE = 64
    STAR_Y = 230

    def _star_x(self, i: int) -> float:
        return SIZE[0] // 2 + (i - 1) * self.STAR_SIZE * 1.2

    def stars_revealed(self) -> int:
        return sum(1 for t in self.reveal if t.progress >= 0.5)

    def update(self, dt):
        for i, t in enumerate(self.reveal):
            t.update(dt)
            if t.done and not self._landed[i]:
                self._landed[i] = True
                self.fx.particles.burst((self._star_x(i), self.STAR_Y), 18, [theme.STAR, theme.TEXT], speed=260)
        self.fx.update(dt)

    def _advice(self) -> str:
        s = self.session
        if self.stars == 3:
            return "Perfect: you matched the Reference Solution."
        tips = []
        if s.moves + s.glitches > self.reference:
            tips.append(f"The Reference Solution takes {self.reference} Moves. Glitches count against you too.")
        if s.hints_used:
            tips.append("Try it again without Hints for more Stars.")
        return " ".join(tips)

    def draw(self, surf):
        cx = SIZE[0] // 2
        s = self.session
        theme.draw_text(surf, "Repaired!", (cx, 70), 48, theme.GOOD, bold=True, center=True)
        theme.draw_text(surf, self.puzzle.title, (cx, 140), 24, theme.MUTED, center=True)
        for i in range(3):
            centre = (self._star_x(i), self.STAR_Y)
            theme.star(surf, centre, self.STAR_SIZE, theme.DISABLED)
            if i < self.stars:
                theme.star(surf, centre, self.STAR_SIZE * max(0.0, ease_out_back(self.reveal[i].progress)), theme.STAR)
        rows = [("Your Moves", s.moves), ("Reference Solution", self.reference),
                ("Glitches", s.glitches), ("Hints used", s.hints_used)]
        y = 310
        for label, value in rows:
            theme.draw_text(surf, label, (cx - 200, y), 22, theme.MUTED)
            theme.draw_text(surf, str(value), (cx + 160, y), 22)
            y += 36
        theme.draw_text(surf, self._advice(), (cx, y + 14), 19, theme.ACTIVE, width=760, center=True)
        if self.best.stars > self.stars:
            theme.draw_text(surf, f"Your best is still {self.best.stars} Stars.", (cx, y + 70), 17,
                            theme.MUTED, center=True)
        super().draw(surf)
        self.fx.draw(surf)

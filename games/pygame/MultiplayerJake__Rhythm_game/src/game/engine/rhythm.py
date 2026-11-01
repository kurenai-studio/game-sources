"""RhythmEngine: timing judgment, scoring, combo and boost.

The engine is pure logic - it never draws. It reads the song position
from an injected ``clock`` (milliseconds), which keeps it fully
unit-testable without audio.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Optional

from .note import HOLDING, HIT, MISSED, PENDING, RELEASED, Note

PERFECT_MS = 45
GREAT_MS = 90
GOOD_MS = 140

POINTS = {"perfect": 100, "great": 75, "good": 50, "miss": 0}
HOLD_PTS_PER_SEC = 100.0
BOOST_NOTE_CHARGE = 20.0
BOOST_MIN_CHARGE = 10.0
BOOST_DRAIN_PER_SEC = 20.0
BOOST_MAX = 100.0
SUSTAIN_MIN_MS = 0.0  # holds are recorded with an end > time


@dataclass
class Judgment:
    rating: str      # "perfect" | "great" | "good" | "miss"
    lane: int
    offset: Optional[float]  # ms, None for auto-miss


class RhythmEngine:
    def __init__(self, notes, clock: Callable[[], float]):
        self.clock = clock
        self.notes: list[Note] = sorted(
            (Note.from_dict(n) if isinstance(n, dict) else Note(**n) for n in notes),
            key=lambda n: (n.time, n.lane),
        )
        self.score = 0.0
        self.combo = 0
        self.max_combo = 0
        self.counts = {"perfect": 0, "great": 0, "good": 0, "miss": 0}
        self.boost_charge = 0.0
        self.boost_active = False
        self.finished = False

        self._lane_down = [False, False, False, False]
        self._hold_note: list[Optional[Note]] = [None, None, None, None]
        self.judgments: list[Judgment] = []  # consumed by the scene

    # -------------------------------------------------------------- input
    def press_lane(self, lane: int) -> Optional[Judgment]:
        """Register a key press in ``lane``; returns the judgment, if any."""
        if not 0 <= lane < 4:
            return None
        self._lane_down[lane] = True
        if self._hold_note[lane] is not None:
            return None

        pos = self.clock()
        best = None
        best_off = None
        for note in self.notes:
            if note.status is not PENDING or note.lane != lane:
                continue
            off = pos - note.time
            if abs(off) <= GOOD_MS:
                if best is None or abs(off) < abs(best_off):
                    best, best_off = note, off
            elif note.time > pos + GOOD_MS:
                break
        if best is None:
            return None

        rating = self._rate(abs(best_off))
        self._award(rating)
        if best.boost and rating != "miss":
            self.boost_charge = min(BOOST_MAX, self.boost_charge + BOOST_NOTE_CHARGE)

        if best.is_sustain:
            best.status = HOLDING
            self._hold_note[lane] = best
        else:
            best.status = HIT

        judgment = Judgment(rating=rating, lane=lane, offset=best_off)
        self.judgments.append(judgment)
        return judgment

    def release_lane(self, lane: int) -> None:
        self._lane_down[lane] = False
        note = self._hold_note[lane]
        if note is not None:
            note.status = RELEASED
            self._hold_note[lane] = None

    def press_boost(self) -> bool:
        """Activate boost if there is enough charge. Returns True if activated."""
        if not self.boost_active and self.boost_charge >= BOOST_MIN_CHARGE:
            self.boost_active = True
            return True
        return False

    # ------------------------------------------------------------- update
    def update(self, dt: float) -> None:
        pos = self.clock()

        # auto-miss notes that blew past the hit line
        for note in self.notes:
            if note.time > pos + GOOD_MS:
                break
            if note.status is PENDING and pos - note.time > GOOD_MS:
                note.status = MISSED
                self._award("miss")
                self.judgments.append(Judgment("miss", note.lane, None))

        # sustain accrual
        for lane, note in enumerate(self._hold_note):
            if note is None:
                continue
            if not self._lane_down[lane]:
                self._hold_note[lane] = None
                continue
            if pos > note.end + GOOD_MS:
                note.status = HIT
                self._hold_note[lane] = None
                continue
            if pos >= note.time - GOOD_MS:
                self.score += HOLD_PTS_PER_SEC * max(dt, 0.0) * self.multiplier

        # boost drain
        if self.boost_active:
            self.boost_charge -= BOOST_DRAIN_PER_SEC * max(dt, 0.0)
            if self.boost_charge <= 0:
                self.boost_charge = 0.0
                self.boost_active = False

        if not self.finished and self.notes:
            last = self.notes[-1]
            tail = (last.end if last.end is not None else last.time) + GOOD_MS
            if pos > tail and not self._pending_left():
                self.finished = True

    def _pending_left(self) -> bool:
        return any(n.status in (PENDING, HOLDING) for n in self.notes)

    # ------------------------------------------------------------ helpers
    @property
    def multiplier(self) -> float:
        return 2.0 if self.boost_active else 1.0

    @property
    def lane_states(self) -> list:
        return list(self._lane_down)

    @staticmethod
    def _rate(abs_offset: float) -> str:
        if abs_offset <= PERFECT_MS:
            return "perfect"
        if abs_offset <= GREAT_MS:
            return "great"
        if abs_offset <= GOOD_MS:
            return "good"
        return "miss"

    def _award(self, rating: str) -> None:
        self.counts[rating] += 1
        if rating == "miss":
            self.combo = 0
            return
        self.score += POINTS[rating] * self.multiplier
        self.combo += 1
        self.max_combo = max(self.max_combo, self.combo)

    def pop_judgments(self) -> list:
        out, self.judgments = self.judgments, []
        return out

    @property
    def score_display(self) -> int:
        return int(round(self.score))

    def summary(self) -> dict:
        return {
            "score": self.score_display,
            "max_combo": self.max_combo,
            "perfect": self.counts["perfect"],
            "great": self.counts["great"],
            "good": self.counts["good"],
            "miss": self.counts["miss"],
        }

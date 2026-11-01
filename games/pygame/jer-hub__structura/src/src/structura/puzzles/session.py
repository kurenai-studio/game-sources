"""PuzzleSession: the rules of play for one attempt at one Puzzle.

No pygame here. The UI turns clicks into Moves and calls `try_move`; tests
and the content checker drive sessions the same way.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from ..models import Move, Step, make
from . import hints
from .goals import TRAY_OPS, Goal, PlayState, make_goal
from .schema import Puzzle


@dataclass
class Outcome:
    ok: bool
    steps: list[Step] = field(default_factory=list)
    glitch: str = ""                  # explanation when not ok
    disruption: str = ""              # narration when a Disruption fired
    disruption_steps: list[Step] = field(default_factory=list)
    done: bool = False


@dataclass
class _Snapshot:
    state: PlayState
    plan: list[Move]
    pos: int
    fired: frozenset


DEAD_END = "Undo: this Puzzle can't be finished from here. Go back to before the Move that made it impossible."


def stars_for(moves: int, glitches: int, hints_used: int, reference: int) -> int:
    efficiency = (moves + glitches) / max(reference, 1)
    if efficiency <= 1.0 and hints_used == 0:
        return 3
    if efficiency <= 1.5 and hints_used <= 1:
        return 2
    return 1


class PuzzleSession:
    def __init__(self, puzzle: Puzzle):
        self.puzzle = puzzle
        self.goal: Goal = make_goal(puzzle)
        self.state = PlayState(make(puzzle.structure, puzzle.initial), list(puzzle.tray))
        self.moves = 0
        self.glitches = 0
        self.hints_used = 0
        self.hint_tier = 0
        self.history: list[_Snapshot] = []
        self.fired: frozenset = frozenset()
        self.plan = self.goal.plan(self.state)
        self.pos = 0
        self.strict = puzzle.strict or self.goal.kind == "visit"

    # ---- queries -------------------------------------------------------
    @property
    def model(self):
        return self.state.model

    @property
    def done(self) -> bool:
        return self.goal.done(self.state)

    @property
    def tray_next(self):
        return self.state.tray[0] if self.state.tray else None

    def expected(self) -> Move | None:
        if self.done:
            return None
        # An empty plan means no Reference Solution exists from here; only a used-up plan is worth redoing.
        if self.plan and self.pos >= len(self.plan):
            self.plan, self.pos = self.goal.plan(self.state), 0
        return self.plan[self.pos] if self.plan else None

    @property
    def dead_end(self) -> bool:
        """True when no Reference Solution exists from here, so only Undo can help."""
        return not self.done and self.expected() is None

    def stars(self) -> int:
        return stars_for(self.moves, self.glitches, self.hints_used, reference_count(self.puzzle))

    # ---- play ----------------------------------------------------------
    def try_move(self, move: Move) -> Outcome:
        if self.done:
            return Outcome(False, glitch="This Puzzle is already finished.", done=True)

        if move.op == "answer":
            if move.args[0] == self.goal.correct:
                self._snapshot()
                self.state.answered = True
                self.moves += 1
                return Outcome(True, done=True)
            self.glitches += 1
            return Outcome(False, glitch=self.goal.wrong_answer(move.args[0]))

        if move.op not in self.puzzle.ops:
            return Outcome(False, glitch=f"'{move.op}' isn't available in this Puzzle.")
        if move.op in TRAY_OPS:
            value = move.args[-1] if move.op != "insert" or len(move.args) == 2 else move.args[0]
            if self.tray_next is None:
                return self._glitch("The Tray is empty.")
            if value != self.tray_next:
                return self._glitch(f"Use the Tray in order: {self.tray_next} comes next.")

        reason = self.model.why_illegal(move)
        if reason:
            return self._glitch(reason)

        expected = self.expected()
        if self.strict and move != expected:
            return self._glitch(self.goal.strict_reason(move, expected))

        self._snapshot()
        steps = self.model.apply(move)
        if move.op in TRAY_OPS:
            self.state.tray.pop(0)
        if move.op == "visit":
            self.state.visited.append(move.args[0])
        self.moves += 1
        if move == expected:
            self.pos += 1
        else:
            self.plan, self.pos = self.goal.plan(self.state), 0

        out = Outcome(True, steps=steps)
        self._fire_disruptions(out)
        out.done = self.done
        return out

    def _glitch(self, reason: str) -> Outcome:
        self.glitches += 1
        return Outcome(False, glitch=reason)

    def _fire_disruptions(self, out: Outcome) -> None:
        progress = len(self.history)
        for i, d in enumerate(self.puzzle.disruptions):
            if i in self.fired or d.after != progress or self.done:
                continue
            self.fired = self.fired | {i}
            for line in d.do:
                for m in self.model.parse(line):
                    out.disruption_steps += self.model.apply(m)
            out.disruption = d.say or "The structure was disrupted!"
            self.plan, self.pos = self.goal.plan(self.state), 0

    def _snapshot(self) -> None:
        self.history.append(_Snapshot(self.state.copy(), list(self.plan), self.pos, self.fired))

    def undo(self) -> bool:
        """Step back one Move. The Move still counts (see CONTEXT.md: Move)."""
        if not self.history:
            return False
        snap = self.history.pop()
        self.state, self.plan, self.pos, self.fired = snap.state, snap.plan, snap.pos, snap.fired
        return True

    def hint(self) -> tuple[int, str, Move | None]:
        """Reveal the next Hint tier. Returns (tier, text, move to highlight).

        In a dead end every tier would say the same thing, so the Hint is free."""
        if self.dead_end:
            return self.hint_tier, DEAD_END, None
        if self.hint_tier < 3:
            self.hint_tier += 1
            self.hints_used += 1
        nxt = self.expected()
        described = hints.describe(nxt, self.model, self.goal.options)
        tier = self.hint_tier
        written = self.puzzle.hints[tier - 1] if tier <= len(self.puzzle.hints) else ""
        if tier < 3 and written:
            text = hints.render(written, next_move=described, value=self.tray_next,
                                target=self.puzzle.goal.get("value"))
            return tier, text, None
        return tier, f"Next: {described}.", nxt


_REFERENCE_CACHE: dict[int, tuple[Puzzle, tuple[Move, ...]]] = {}


def _reference(puzzle: Puzzle) -> tuple[Move, ...]:
    s = PuzzleSession(puzzle)
    moves: list[Move] = []
    for _ in range(1000):
        m = s.expected()
        if m is None:
            break
        out = s.try_move(m)
        if not out.ok:
            raise RuntimeError(f"{puzzle.id}: Reference Move {m} was rejected: {out.glitch}")
        moves.append(m)
    if not s.done:
        raise RuntimeError(f"{puzzle.id}: the Reference Solution does not finish the Puzzle")
    return tuple(moves)


def reference_moves(puzzle: Puzzle) -> tuple[Move, ...]:
    """The full Reference Solution from the starting state, Disruptions included."""
    hit = _REFERENCE_CACHE.get(id(puzzle))
    if hit is None or hit[0] is not puzzle:
        hit = _REFERENCE_CACHE[id(puzzle)] = (puzzle, _reference(puzzle))
    return hit[1]


def reference_count(puzzle: Puzzle) -> int:
    return len(reference_moves(puzzle))

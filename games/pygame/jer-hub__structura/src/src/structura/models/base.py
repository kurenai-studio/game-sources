"""Shared vocabulary for every data structure model.

A model is the single source of truth for its structure (ADR 0001): it decides
whether a Move is legal, explains why when it is not, and reports the Steps an
operation took so the renderer and Code Mirror can replay them.
"""
from __future__ import annotations

import copy
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Hashable, Iterable

# Moves that are about to swap two positions are order-insensitive.
_SYMMETRIC_OPS = {"swap"}


@dataclass(frozen=True)
class Move:
    """One graded player action (see CONTEXT.md)."""

    op: str
    args: tuple = ()

    @staticmethod
    def of(op: str, *args) -> "Move":
        if op in _SYMMETRIC_OPS:
            args = tuple(sorted(args))
        return Move(op, tuple(args))

    def __str__(self) -> str:
        return " ".join([self.op, *map(str, self.args)])


@dataclass(frozen=True)
class Step:
    """One beat of an operation, for animation and Code Mirror line highlighting.

    `kind` names the code line that is executing (e.g. "compare", "go_left").
    `ids` are the element ids to highlight. `text` is a short narration.
    """

    kind: str
    ids: tuple = ()
    text: str = ""


class IllegalMove(Exception):
    """Raised by `apply` when a Move breaks the structure's rules."""


class Model(ABC):
    """Base class for all data structure models."""

    structure: str = ""
    # Ops a player may perform. Internal ops (used by Disruptions) are not listed.
    player_ops: tuple[str, ...] = ()

    def __init__(self) -> None:
        self._next_id = 0

    def _new_id(self) -> int:
        self._next_id += 1
        return self._next_id

    def copy(self):
        return copy.deepcopy(self)

    @abstractmethod
    def key(self) -> Hashable:
        """A hashable snapshot of the logical state, ignoring element ids."""

    @abstractmethod
    def values(self) -> list:
        """The values in the structure's natural reading order."""

    @abstractmethod
    def why_illegal(self, move: Move) -> str | None:
        """None if the move is legal, otherwise a learner-facing explanation."""

    @abstractmethod
    def _apply(self, move: Move) -> list[Step]:
        ...

    def apply(self, move: Move) -> list[Step]:
        reason = self.why_illegal(move)
        if reason is not None:
            raise IllegalMove(reason)
        return self._apply(move)

    @abstractmethod
    def parse(self, text: str) -> list[Move]:
        """Turn script text such as "insert 5" into the textbook Moves for it."""

    def alternatives(self, text: str) -> list[list[Move]]:
        """Every textbook way to carry out a script line; parse() is the first."""
        return [self.parse(text)]

    def needs_replacement(self, key) -> bool:
        """Whether deleting the element at `key` needs the player to pick what takes its place."""
        return False

    def delete_move(self, key, replacement=None) -> Move:
        """The Move that deletes the element at `key`."""
        return Move.of("delete", key)

    def candidate_moves(self, tray_next) -> Iterable[Move]:
        """Every Move worth trying from this state; used by the search solver."""
        return ()

    def run(self, script: Iterable[str]) -> list[Step]:
        """Apply script lines in order, returning all Steps."""
        steps: list[Step] = []
        for line in script:
            for move in self.parse(line):
                steps.extend(self.apply(move))
        return steps


def ints(tokens: list[str]) -> list[int]:
    try:
        return [int(t) for t in tokens]
    except ValueError as exc:
        raise ValueError(f"expected numbers in script, got {tokens!r}") from exc

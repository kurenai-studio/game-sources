"""Pure 2048 board logic — no Pygame dependency (easy to test)."""

from __future__ import annotations

import random
from dataclasses import dataclass
from enum import Enum
from typing import Iterator


class Direction(Enum):
    LEFT = "left"
    RIGHT = "right"
    UP = "up"
    DOWN = "down"


@dataclass(frozen=True)
class MoveResult:
    """Outcome of one swipe."""

    moved: bool
    score_gained: int
    merged_positions: frozenset[tuple[int, int]]


class Board:
    """4×4 2048 board with spawn, slide, merge, win/lose checks."""

    def __init__(
        self,
        rows: int = 4,
        cols: int = 4,
        win_value: int = 2048,
        rng: random.Random | None = None,
    ) -> None:
        self.rows = rows
        self.cols = cols
        self.win_value = win_value
        self.rng = rng or random.Random()
        self.grid: list[list[int]] = [[0] * cols for _ in range(rows)]
        self.score = 0
        self.won = False
        self.continued_after_win = False
        self._spawn_tile()
        self._spawn_tile()

    # --- queries ---------------------------------------------------------

    def empty_cells(self) -> list[tuple[int, int]]:
        return [
            (r, c)
            for r in range(self.rows)
            for c in range(self.cols)
            if self.grid[r][c] == 0
        ]

    def max_tile(self) -> int:
        return max(max(row) for row in self.grid)

    def is_full(self) -> bool:
        return not self.empty_cells()

    def can_move(self) -> bool:
        if self.empty_cells():
            return True
        for r in range(self.rows):
            for c in range(self.cols):
                value = self.grid[r][c]
                if c + 1 < self.cols and self.grid[r][c + 1] == value:
                    return True
                if r + 1 < self.rows and self.grid[r + 1][c] == value:
                    return True
        return False

    def is_game_over(self) -> bool:
        return not self.can_move()

    def has_won(self) -> bool:
        return self.max_tile() >= self.win_value

    def cells(self) -> Iterator[tuple[int, int, int]]:
        for r in range(self.rows):
            for c in range(self.cols):
                yield r, c, self.grid[r][c]

    # --- mutations -------------------------------------------------------

    def reset(self) -> None:
        self.grid = [[0] * self.cols for _ in range(self.rows)]
        self.score = 0
        self.won = False
        self.continued_after_win = False
        self._spawn_tile()
        self._spawn_tile()

    def move(self, direction: Direction) -> MoveResult:
        """Slide/merge in `direction`. Spawns a tile if anything moved."""
        before = [row[:] for row in self.grid]
        score_gained = 0
        merged: set[tuple[int, int]] = set()

        if direction in (Direction.LEFT, Direction.RIGHT):
            for r in range(self.rows):
                line = self.grid[r][:]
                if direction == Direction.RIGHT:
                    line.reverse()
                new_line, gained, line_merges = self._compress_and_merge(line)
                if direction == Direction.RIGHT:
                    new_line.reverse()
                    line_merges = {self.cols - 1 - i for i in line_merges}
                self.grid[r] = new_line
                score_gained += gained
                for c in line_merges:
                    merged.add((r, c))
        else:
            for c in range(self.cols):
                line = [self.grid[r][c] for r in range(self.rows)]
                if direction == Direction.DOWN:
                    line.reverse()
                new_line, gained, line_merges = self._compress_and_merge(line)
                if direction == Direction.DOWN:
                    new_line.reverse()
                    line_merges = {self.rows - 1 - i for i in line_merges}
                for r, value in enumerate(new_line):
                    self.grid[r][c] = value
                score_gained += gained
                for r in line_merges:
                    merged.add((r, c))

        moved = self.grid != before
        if moved:
            self.score += score_gained
            self._spawn_tile()
            if not self.won and self.has_won():
                self.won = True

        return MoveResult(
            moved=moved,
            score_gained=score_gained,
            merged_positions=frozenset(merged),
        )

    def continue_after_win(self) -> None:
        self.continued_after_win = True

    # --- internals -------------------------------------------------------

    def _spawn_tile(self) -> bool:
        empties = self.empty_cells()
        if not empties:
            return False
        r, c = self.rng.choice(empties)
        # 90% a 2, 10% a 4
        self.grid[r][c] = 4 if self.rng.random() < 0.1 else 2
        return True

    @staticmethod
    def _compress_and_merge(line: list[int]) -> tuple[list[int], int, set[int]]:
        """Slide non-zeros left and merge equal neighbors once each."""
        tiles = [v for v in line if v != 0]
        merged_indices: set[int] = set()
        score = 0
        result: list[int] = []
        i = 0
        while i < len(tiles):
            if i + 1 < len(tiles) and tiles[i] == tiles[i + 1]:
                merged = tiles[i] * 2
                result.append(merged)
                merged_indices.add(len(result) - 1)
                score += merged
                i += 2
            else:
                result.append(tiles[i])
                i += 1
        result.extend([0] * (len(line) - len(result)))
        return result, score, merged_indices

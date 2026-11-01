"""Unit tests for pure board logic (no Pygame required)."""

from __future__ import annotations

import random

import pytest

from game.logic import Board, Direction


def test_initial_board_has_two_tiles() -> None:
    board = Board(rng=random.Random(0))
    filled = sum(1 for _, _, v in board.cells() if v != 0)
    assert filled == 2
    assert board.score == 0


def test_move_left_merges_and_scores() -> None:
    board = Board(rng=random.Random(0))
    board.grid = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
    result = board.move(Direction.LEFT)
    assert result.moved
    assert board.grid[0][0] == 4
    assert result.score_gained == 4
    assert board.score == 4


def test_no_move_when_blocked() -> None:
    board = Board(rng=random.Random(0))
    board.grid = [
        [2, 4, 8, 16],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
    # clear spawn side-effects: fill only first row pattern; move left does nothing
    before = [row[:] for row in board.grid]
    result = board.move(Direction.LEFT)
    assert result.moved is False
    assert board.grid == before


def test_double_merge_only_once_per_tile() -> None:
    board = Board(rng=random.Random(0))
    board.grid = [
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
    board.move(Direction.LEFT)
    # After left: [4, 4, 0, 0] then a random spawn somewhere
    assert board.grid[0][0] == 4
    assert board.grid[0][1] == 4


def test_game_over_when_no_moves() -> None:
    board = Board(rng=random.Random(0))
    board.grid = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
    ]
    assert board.is_game_over()
    assert board.can_move() is False


def test_can_move_when_merge_possible_on_full_board() -> None:
    board = Board(rng=random.Random(0))
    board.grid = [
        [2, 2, 4, 8],
        [16, 32, 64, 128],
        [256, 512, 1024, 4],
        [8, 16, 32, 64],
    ]
    assert board.is_full()
    assert board.can_move()
    assert board.is_game_over() is False


def test_win_detection() -> None:
    board = Board(rng=random.Random(0), win_value=16)
    board.grid = [
        [8, 8, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
    ]
    board.move(Direction.LEFT)
    assert board.won
    assert board.has_won()


def test_reset_clears_score() -> None:
    board = Board(rng=random.Random(1))
    board.score = 100
    board.reset()
    assert board.score == 0
    filled = sum(1 for _, _, v in board.cells() if v != 0)
    assert filled == 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

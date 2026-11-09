#!/usr/bin/env python3
"""אותם טסטים כמו Godot, בלי להתקין את המנוע."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from core_py import (  # noqa: E402
    SIZE,
    SCORE_MAX,
    Board,
    Session,
    XorShift,
    clamp_score,
    rotated_cells,
    sanitize_name,
    score_place,
)

failed = 0


def check(name: str, ok: bool, detail: str = "") -> None:
    global failed
    if ok:
        print("PASS", name)
    else:
        failed += 1
        print("FAIL", name, detail)


def test_row() -> None:
    b = Board()
    for x in range(SIZE - 1):
        b.set(x, 0, 1)
    ok = b.can_place("dot", SIZE - 1, 0)
    b.place("dot", SIZE - 1, 0, 2)
    n = b.clear_lines()["count"]
    empty = all(b.get(x, 0) == 0 for x in range(SIZE))
    check("place_and_row_clear", ok and n == 1 and empty, f"n={n}")


def test_col() -> None:
    b = Board()
    for y in range(SIZE - 1):
        b.set(0, y, 1)
    b.place("dot", 0, SIZE - 1, 3)
    check("col_clear", b.clear_lines()["count"] == 1)


def test_overlap() -> None:
    b = Board()
    b.place("o", 0, 0, 1)
    check("reject_overlap", not b.can_place("dot", 0, 0))


def test_score() -> None:
    check(
        "score_formula",
        score_place(4, 0) == 40
        and score_place(1, 2, 1, False) == 410
        and score_place(1, 2, 2, True) == 1060,
    )


def test_over() -> None:
    s = Session()
    s.rng = XorShift(1)
    s.board.cells = [1] * (SIZE * SIZE)
    s.tray = ["dot", "dot", "dot"]
    s._check_over()
    check("game_over_full", s.over)


def test_tray() -> None:
    s = Session()
    s.rng = XorShift(42)
    s.board = Board()
    s.fill_tray()
    check("tray_refill", len(s.tray) == 3 and all(s.tray))


def test_rotate() -> None:
    check("rotate_i2", rotated_cells("i2", 1) == ((0, 0), (0, 1)))
    b = Board()
    check("rotate_place", b.place("i2", 0, 0, 2, 1) == 2 and b.get(0, 1) == 2)


def test_rotate_charges() -> None:
    s = Session()
    s.tray = ["i3", "dot", "o"]
    s.tray_rot = [0, 0, 0]
    s.rotates_left = 2
    s.over = False
    ok1 = s.rotate_piece(0) and s.tray_rot[0] == 1 and s.rotates_left == 1
    ok2 = s.rotate_piece(0) and s.rotates_left == 0
    ok3 = not s.rotate_piece(0)
    check("rotate_charges", ok1 and ok2 and ok3)


def test_race() -> None:
    s = Session(mode="race")
    s.tick(s.time_left + 0.1)
    check("race_timeout", s.over and s.timed_out)
    r = Session(mode="race")
    r.board = Board()
    r.tray = ["dot", None, None]
    r.tray_rot = [0, 0, 0]
    r.over = False
    r.timed_out = False
    r.time_left = 10.0
    before = r.time_left
    check("race_time_bonus", r.try_place(0, 0, 0) and r.time_left > before)


def test_safety() -> None:
    b = Board()
    b.set(-1, 0, 9)
    b.set(0, 99, 9)
    check("board_oob", b.get(-1, 0) == 0 and b.get(0, 0) == 0)
    check("unknown_piece", not b.can_place("nope", 0, 0) and b.place("nope", 0, 0, 1) == 0)
    check("clamp_score", clamp_score(-3) == 0 and clamp_score(SCORE_MAX + 8) == SCORE_MAX)
    check(
        "sanitize_name",
        sanitize_name("  Ada\nLovelace  ") == "Ada Lovelace"
        and sanitize_name("a@b.com") == ""
        and sanitize_name("https://x.test") == ""
        and sanitize_name("www.x.test") == "",
    )
    s = Session(mode="race")
    s.over = False
    s.timed_out = False
    s.time_left = 20.0
    s.tick(-4.0)
    check("tick_ignores_negative", s.time_left == 20.0 and not s.over)


if __name__ == "__main__":
    test_row()
    test_col()
    test_overlap()
    test_score()
    test_over()
    test_tray()
    test_rotate()
    test_rotate_charges()
    test_race()
    test_safety()
    print("BLOOMGRID_PY_TESTS failed=", failed)
    raise SystemExit(1 if failed else 0)

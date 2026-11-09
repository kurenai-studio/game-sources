"""עותק פייתון של הליבה, כדי להריץ טסטים בלי Godot.

אם משנים חוק ב-core/*.gd — לעדכן גם כאן, אחרת שני הרצים יסתרו.
"""
from __future__ import annotations

from dataclasses import dataclass, field

SIZE = 8

SHAPES: dict[str, tuple[tuple[int, int], ...]] = {
    "dot": ((0, 0),),
    "i2": ((0, 0), (1, 0)),
    "i2v": ((0, 0), (0, 1)),
    "i3": ((0, 0), (1, 0), (2, 0)),
    "i3v": ((0, 0), (0, 1), (0, 2)),
    "l3": ((0, 0), (0, 1), (1, 1)),
    "o": ((0, 0), (1, 0), (0, 1), (1, 1)),
    "i4": ((0, 0), (1, 0), (2, 0), (3, 0)),
    "i4v": ((0, 0), (0, 1), (0, 2), (0, 3)),
    "t": ((0, 0), (1, 0), (2, 0), (1, 1)),
    "l4": ((0, 0), (0, 1), (0, 2), (1, 2)),
    "j4": ((1, 0), (1, 1), (1, 2), (0, 2)),
    "s": ((1, 0), (2, 0), (0, 1), (1, 1)),
    "z": ((0, 0), (1, 0), (1, 1), (2, 1)),
    "plus": ((1, 0), (0, 1), (1, 1), (2, 1), (1, 2)),
    "u": ((0, 0), (2, 0), (0, 1), (1, 1), (2, 1)),
    "i5": ((0, 0), (1, 0), (2, 0), (3, 0), (4, 0)),
}

TRAY_KEYS = (
    "dot",
    "i2",
    "i2v",
    "i3",
    "i3v",
    "l3",
    "o",
    "i4",
    "i4v",
    "t",
    "l4",
    "j4",
    "s",
    "z",
    "plus",
    "u",
    "i5",
)


def rotated_cells(key: str, rot: int = 0) -> tuple[tuple[int, int], ...]:
    cells = list(SHAPES[key])
    turns = rot % 4
    out: list[tuple[int, int]] = []
    for x, y in cells:
        for _ in range(turns):
            x, y = -y, x
        out.append((x, y))
    minx = min(p[0] for p in out)
    miny = min(p[1] for p in out)
    return tuple((p[0] - minx, p[1] - miny) for p in out)


def shape_cells(key: str, rot: int = 0) -> tuple[tuple[int, int], ...]:
    return rotated_cells(key, rot)


def shape_size(key: str, rot: int = 0) -> tuple[int, int]:
    cells = rotated_cells(key, rot)
    return max(c[0] for c in cells) + 1, max(c[1] for c in cells) + 1


class XorShift:
    def __init__(self, seed: int) -> None:
        self.s = seed & 0xFFFFFFFF
        if self.s == 0:
            self.s = 0xA341316C

    def next_u32(self) -> int:
        x = self.s
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        self.s = x & 0xFFFFFFFF
        return self.s

    def randrange(self, n: int) -> int:
        return self.next_u32() % n


@dataclass
class Board:
    cells: list[int] = field(default_factory=lambda: [0] * (SIZE * SIZE))

    def idx(self, x: int, y: int) -> int:
        return y * SIZE + x

    def in_bounds(self, x: int, y: int) -> bool:
        return 0 <= x < SIZE and 0 <= y < SIZE

    def get(self, x: int, y: int) -> int:
        if not self.in_bounds(x, y):
            return 0
        return self.cells[self.idx(x, y)]

    def set(self, x: int, y: int, v: int) -> None:
        if not self.in_bounds(x, y):
            return
        self.cells[self.idx(x, y)] = v

    def can_place(self, key: str, ox: int, oy: int, rot: int = 0) -> bool:
        if key not in SHAPES:
            return False
        for dx, dy in rotated_cells(key, rot):
            x, y = ox + dx, oy + dy
            if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
                return False
            if self.get(x, y) != 0:
                return False
        return True

    def place(self, key: str, ox: int, oy: int, color: int, rot: int = 0) -> int:
        if not self.can_place(key, ox, oy, rot):
            return 0
        n = 0
        for dx, dy in rotated_cells(key, rot):
            self.set(ox + dx, oy + dy, color)
            n += 1
        return n

    def _full_rows(self) -> list[int]:
        out = []
        for y in range(SIZE):
            if all(self.get(x, y) for x in range(SIZE)):
                out.append(y)
        return out

    def _full_cols(self) -> list[int]:
        out = []
        for x in range(SIZE):
            if all(self.get(x, y) for y in range(SIZE)):
                out.append(x)
        return out

    def clear_lines(self) -> dict:
        rows, cols = self._full_rows(), self._full_cols()
        if not rows and not cols:
            return {"count": 0, "rows": rows, "cols": cols, "cross": False}
        for y in rows:
            for x in range(SIZE):
                self.set(x, y, 0)
        for x in cols:
            for y in range(SIZE):
                self.set(x, y, 0)
        return {
            "count": len(rows) + len(cols),
            "rows": rows,
            "cols": cols,
            "cross": bool(rows) and bool(cols),
        }

    def fits_anywhere(self, key: str, rot: int = 0) -> bool:
        if key not in SHAPES:
            return False
        w, h = shape_size(key, rot)
        for y in range(SIZE - h + 1):
            for x in range(SIZE - w + 1):
                if self.can_place(key, x, y, rot):
                    return True
        return False


NAME_MAX = 16
SCORE_MAX = 9_999_999


def sanitize_name(raw: str) -> str:
    cleaned = "".join(" " if ord(ch) < 32 or ord(ch) == 127 else ch for ch in raw)
    t = " ".join(cleaned.replace("|", " ").split())
    low = t.lower()
    if "@" in low or "://" in low or "www." in low:
        return ""
    return t[:NAME_MAX].strip()


def clamp_score(n: int) -> int:
    if n < 0:
        return 0
    return min(n, SCORE_MAX)


def score_place(cells: int, lines: int, combo: int = 1, cross: bool = False) -> int:
    base = cells * 10
    if lines <= 0:
        return base
    total = base + 100 * lines * lines * max(combo, 1)
    if cross:
        total += 250
    return total


def race_time_bonus(cells: int, lines: int, combo: int = 1, cross: bool = False) -> float:
    t = 1.6 + 0.05 * cells
    if lines > 0:
        t += 3.2 * lines + 0.45 * max(combo, 1)
    if cross:
        t += 4.0
    return t


@dataclass
class Session:
    board: Board = field(default_factory=Board)
    rng: XorShift = field(default_factory=lambda: XorShift(1))
    tray: list[str | None] = field(default_factory=list)
    tray_rot: list[int] = field(default_factory=lambda: [0, 0, 0])
    score: int = 0
    over: bool = False
    combo: int = 0
    mode: str = "classic"
    rotates_left: int = 2
    time_left: float = 0.0
    timed_out: bool = False

    def __post_init__(self) -> None:
        if self.mode == "race" and self.time_left <= 0:
            self.time_left = 48.0
        if not self.tray:
            self.fill_tray()

    def fill_tray(self) -> None:
        self.tray = [TRAY_KEYS[self.rng.randrange(len(TRAY_KEYS))] for _ in range(3)]
        self.tray_rot = [0, 0, 0]
        self._check_over()

    def remaining(self) -> list[str]:
        return [k for k in self.tray if k]

    def _fits_spins(self, key: str, rot: int, spins: int) -> bool:
        return any(self.board.fits_anywhere(key, (rot + extra) % 4) for extra in range(spins + 1))

    def _check_over(self) -> None:
        if self.mode == "race" and self.time_left <= 0:
            self.over = True
            self.timed_out = True
            return
        left = self.remaining()
        if not left:
            self.fill_tray()
            return
        self.over = True
        for i, key in enumerate(self.tray):
            if not key:
                continue
            rot = self.tray_rot[i] if i < len(self.tray_rot) else 0
            if self._fits_spins(key, rot, self.rotates_left):
                self.over = False
                return

    def rotate_piece(self, tray_i: int) -> bool:
        if self.over or self.rotates_left <= 0 or tray_i < 0 or tray_i >= 3:
            return False
        key = self.tray[tray_i]
        if not key:
            return False
        self.tray_rot[tray_i] = (self.tray_rot[tray_i] + 1) % 4
        self.rotates_left -= 1
        self._check_over()
        return True

    def tick(self, delta: float) -> None:
        if self.over or self.mode != "race" or delta != delta or delta <= 0:
            return
        self.time_left = max(self.time_left - delta, 0.0)
        if self.time_left <= 0:
            self.timed_out = True
            self.over = True

    def try_place(self, tray_i: int, x: int, y: int) -> bool:
        if self.over or tray_i < 0 or tray_i >= 3:
            return False
        key = self.tray[tray_i]
        if not key:
            return False
        rot = self.tray_rot[tray_i] if tray_i < len(self.tray_rot) else 0
        color = 1 + (hash(key) % 6)
        n = self.board.place(key, x, y, color, rot)
        if n == 0:
            return False
        cleared = self.board.clear_lines()
        lines = int(cleared["count"])
        if lines:
            self.combo += 1
        else:
            self.combo = 0
        self.score = clamp_score(self.score + score_place(n, lines, self.combo, bool(cleared["cross"])))
        if self.mode == "race":
            self.time_left = min(90.0, self.time_left + race_time_bonus(n, lines, self.combo, bool(cleared["cross"])))
        self.tray[tray_i] = None
        if not self.remaining():
            self.fill_tray()
        else:
            self._check_over()
        return True

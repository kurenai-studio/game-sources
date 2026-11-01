"""Geometric reachability lint for level designers.

Builds a graph of 'standing spots' (cells where a robot can stand) and connects
them with jump / drop edges computed from the real physics constants. It is a
design-time sanity check, not a solver:
  * doors / electric barriers are assumed to be open (puzzle logic is not solved),
  * bridges are assumed extended, movers/fading platforms count as support along their path,
  * hazards are respected per robot (lava kills blue, water kills red, spikes kill both).
Run:  python -m tests.level_lint
"""
import math
import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from src import settings as S                      # noqa: E402
from src.level import Level                        # noqa: E402
from src.level_manager import LevelManager         # noqa: E402

SAFETY = 0.8      # use 80% of the theoretical horizontal range (players are not frame-perfect)


def _air_time(dr):
    """Seconds until a full jump is `dr` tiles above (dr>0) / below (dr<0) its start, on the way down."""
    h = 40.0 * dr
    disc = S.JUMP_SPEED ** 2 - 2 * S.GRAVITY * h
    if disc < 0:
        return None
    return (S.JUMP_SPEED + math.sqrt(disc)) / S.GRAVITY


def max_dc(dr):
    t = _air_time(dr)
    if t is None or dr > 3:
        return 0
    dist = S.MOVE_SPEED * t * SAFETY
    return int((dist + 22) / S.TILE) + 1


class Graph:
    def __init__(self, level, kind):
        self.lv, self.kind = level, kind
        self.support = set()          # cells that are floors for standing on (tiles + platform paths)
        for r in range(level.rows):
            for c in range(level.cols):
                if level.grid[r][c] == "#":
                    self.support.add((c, r))
        T = S.TILE
        for m in level.movers:
            for i in range(0, 41):
                t = i / 40.0
                x = m.start[0] + (m.end[0] - m.start[0]) * t
                y = m.start[1] + (m.end[1] - m.start[1]) * t
                for c in range(int(x // T), int((x + m.box.w - 1) // T) + 1):
                    self.support.add((c, int(round(y / T))))
        for f in level.fadings:
            for c in range(int(f.box.x // T), int((f.box.right - 1) // T) + 1):
                self.support.add((c, int(f.box.y // T)))
        for b in level.bridges:
            for c in range(int(b.origin_x // T), int((b.origin_x + b.full_w - 1) // T) + 1):
                self.support.add((c, int(b.box.y // T)))
        self.lethal = set()
        for r in range(level.rows):
            for c in range(level.cols):
                ch = level.grid[r][c]
                if ch == "^" or (ch == "L" and kind != "x") or (ch == "W" and kind != "b"):
                    self.lethal.add((c, r))

    def solid_tile(self, c, r):
        return self.lv.is_solid_tile(c, r)

    def is_node(self, c, r):
        if c < 0 or c >= self.lv.cols or r < 1 or r >= self.lv.rows:
            return False
        if self.solid_tile(c, r) or self.solid_tile(c, r - 1):
            return False
        if (c, r) in self.lethal or (c, r - 1) in self.lethal:
            return False
        return (c, r + 1) in self.support

    def neighbours(self, c, r):
        for dc in range(-6, 7):
            if dc == 0:
                continue
            c2 = c + dc
            for r2 in range(r - 3, r + 15):
                if not self.is_node(c2, r2):
                    continue
                dr = r - r2
                if abs(dc) > max_dc(dr):
                    continue
                lo, hi = min(c, c2), max(c, c2)
                top = min(r, r2)
                need = 3 if dr >= 2 else 2
                ok = all(not self.solid_tile(cc, rr)
                         for cc in range(lo, hi + 1) for rr in range(top - need, top))
                if r2 > r:    # dropping: the landing column must be open all the way down
                    ok = ok and all(not self.solid_tile(c2, rr) for rr in range(r - 1, r2 + 1))
                if ok:
                    yield (c2, r2)

    def reach(self, start):
        seen = {start}
        q = deque([start])
        while q:
            n = q.popleft()
            for m in self.neighbours(*n):
                if m not in seen:
                    seen.add(m)
                    q.append(m)
        return seen


def spawn_node(level, kind):
    x, y = level.spawns[kind]
    return (int((x + S.PLAYER_W / 2) // S.TILE), int((y + S.PLAYER_H - 1) // S.TILE))


def can_touch(reach, cell, graph):
    c, r = cell
    for (cn, rn) in reach:
        if abs(cn - c) <= 1 and 0 <= rn - r <= 4:
            return True
    return False


def lint(level):
    """Return a list of human-readable problems (empty = fine)."""
    problems = []
    reach = {}
    graphs = {}
    for kind in ("x", "b"):
        g = Graph(level, kind)
        graphs[kind] = g
        start = spawn_node(level, kind)
        if not g.is_node(*start):
            problems.append("%s: spawn cell %s is not a valid standing spot" % (kind, start))
            reach[kind] = set()
            continue
        reach[kind] = g.reach(start)
        ex = level.exits[kind]
        door_cell = (int(ex.x // S.TILE), int(ex.bottom // S.TILE) - 1)
        if door_cell not in reach[kind]:
            problems.append("%s: exit door %s unreachable" % (kind, door_cell))
    for c in level.crystals:
        cell = (int(c.x // S.TILE), int(c.y // S.TILE))
        if not any(can_touch(reach[k], cell, graphs[k]) for k in ("x", "b")):
            problems.append("crystal %s unreachable by both robots" % (cell,))
    for bid, b in level.buttons.items():
        cell = (b.col, b.row)
        if not any(cell in reach[k] for k in ("x", "b")):
            problems.append("button %s %s unreachable" % (bid, cell))
    return problems


def main():
    lm = LevelManager()
    bad = 0
    for i in range(lm.count):
        lv = lm.load(i)
        ps = lint(lv)
        print("[%d] %-26s %s" % (i + 1, lv.name, "OK" if not ps else ""))
        for p in ps:
            print("     -", p)
        bad += len(ps)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

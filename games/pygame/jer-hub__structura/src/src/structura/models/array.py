from __future__ import annotations

from .base import Model, Move, Step, ints


class ArrayModel(Model):
    structure = "array"
    player_ops = ("swap", "insert", "delete", "visit")

    def __init__(self, values=()):
        super().__init__()
        self.items: list[tuple[int, int]] = [(self._new_id(), v) for v in values]

    def key(self):
        return tuple(self.values())

    def values(self) -> list:
        return [v for _, v in self.items]

    def ids(self) -> list[int]:
        return [i for i, _ in self.items]

    def _in_range(self, i: int, allow_end: bool = False) -> bool:
        return 0 <= i <= len(self.items) if allow_end else 0 <= i < len(self.items)

    def why_illegal(self, move: Move) -> str | None:
        op, a = move.op, move.args
        if op == "swap":
            i, j = a
            if i == j:
                return "Pick two different cells to swap."
            if not (self._in_range(i) and self._in_range(j)):
                return "Both cells must be inside the array."
        elif op == "insert":
            i, _ = a
            if not self._in_range(i, allow_end=True):
                return f"Index {i} is outside the array."
        elif op in ("delete", "visit"):
            if not self._in_range(a[0]):
                return f"Index {a[0]} is outside the array."
        elif op == "reverse":
            i, j = a
            if not (self._in_range(i) and self._in_range(j) and i <= j):
                return "Bad range."
        else:
            return f"Arrays don't support '{op}'."
        return None

    def _apply(self, move: Move) -> list[Step]:
        op, a = move.op, move.args
        ids = self.ids()
        if op == "swap":
            i, j = a
            vi, vj = self.items[i][1], self.items[j][1]
            self.items[i], self.items[j] = self.items[j], self.items[i]
            return [
                Step("compare", (ids[i], ids[j]), f"Compare a[{i}]={vi} with a[{j}]={vj}"),
                Step("swap", (ids[i], ids[j]), f"Swap them: a[{i}]={vj}, a[{j}]={vi}"),
            ]
        if op == "insert":
            i, v = a
            shifted = ids[i:]
            new_id = self._new_id()
            self.items.insert(i, (new_id, v))
            steps = [Step("shift", tuple(shifted), f"Shift {len(shifted)} cell(s) right to make room")] if shifted else []
            return steps + [Step("place", (new_id,), f"Write {v} into a[{i}]")]
        if op == "delete":
            (i,) = a
            gone_id, v = self.items.pop(i)
            shifted = ids[i + 1:]
            steps = [Step("remove", (gone_id,), f"Remove a[{i}]={v}")]
            if shifted:
                steps.append(Step("shift", tuple(shifted), f"Shift {len(shifted)} cell(s) left to close the gap"))
            return steps
        if op == "visit":
            (i,) = a
            return [Step("visit", (ids[i],), f"Check a[{i}] = {self.items[i][1]}")]
        if op == "reverse":
            i, j = a
            self.items[i:j + 1] = reversed(self.items[i:j + 1])
            return [Step("disrupt", tuple(ids[i:j + 1]), f"Cells {i}..{j} were scrambled!")]
        raise AssertionError(op)

    def parse(self, text: str) -> list[Move]:
        op, *rest = text.split()
        return [Move.of(op, *ints(rest))]

    def candidate_moves(self, tray_next):
        n = len(self.items)
        for i in range(n):
            for j in range(i + 1, n):
                yield Move.of("swap", i, j)
        if tray_next is not None:
            for i in range(n + 1):
                yield Move.of("insert", i, tray_next)
        for i in range(n):
            yield Move.of("delete", i)

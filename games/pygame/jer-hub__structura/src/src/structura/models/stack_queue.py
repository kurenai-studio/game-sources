"""Stack (LIFO) and Queue (FIFO).

Both keep an `out` list of removed values in removal order, so Puzzles can ask
for an output sequence ("make the values come out as 3, 2, 1").
"""
from __future__ import annotations

from .base import Model, Move, Step, ints


class _Line(Model):
    add_op = ""
    remove_op = ""

    def __init__(self, values=()):
        super().__init__()
        # Stack: bottom -> top. Queue: front -> back.
        self.items: list[tuple[int, int]] = [(self._new_id(), v) for v in values]
        self.out: list[int] = []

    @property
    def player_ops(self):
        return (self.add_op, self.remove_op)

    def key(self):
        return (tuple(self.values()), tuple(self.out))

    def values(self) -> list:
        return [v for _, v in self.items]

    def why_illegal(self, move: Move) -> str | None:
        if move.op == self.add_op:
            return None if len(move.args) == 1 else f"{self.add_op} takes one value."
        if move.op == self.remove_op:
            return f"The {self.structure} is empty, so there is nothing to {self.remove_op}." if not self.items else None
        return f"A {self.structure} only supports {self.add_op} and {self.remove_op}."

    def parse(self, text: str) -> list[Move]:
        op, *rest = text.split()
        return [Move.of(op, *ints(rest))]

    def candidate_moves(self, tray_next):
        if tray_next is not None:
            yield Move.of(self.add_op, tray_next)
        if self.items:
            yield Move.of(self.remove_op)


class StackModel(_Line):
    structure = "stack"
    add_op, remove_op = "push", "pop"

    def top(self):
        return self.items[-1][1] if self.items else None

    def _apply(self, move: Move) -> list[Step]:
        if move.op == "push":
            (v,) = move.args
            new_id = self._new_id()
            self.items.append((new_id, v))
            return [Step("push", (new_id,), f"Push {v} on top")]
        top_id, v = self.items.pop()
        self.out.append(v)
        steps = [Step("pop", (top_id,), f"Pop {v} off the top")]
        if self.items:
            steps.append(Step("new_top", (self.items[-1][0],), f"{self.items[-1][1]} is the new top"))
        return steps


class QueueModel(_Line):
    structure = "queue"
    add_op, remove_op = "enqueue", "dequeue"

    def front(self):
        return self.items[0][1] if self.items else None

    def _apply(self, move: Move) -> list[Step]:
        if move.op == "enqueue":
            (v,) = move.args
            new_id = self._new_id()
            self.items.append((new_id, v))
            return [Step("enqueue", (new_id,), f"Enqueue {v} at the back")]
        front_id, v = self.items.pop(0)
        self.out.append(v)
        steps = [Step("dequeue", (front_id,), f"Dequeue {v} from the front")]
        if self.items:
            steps.append(Step("new_front", (self.items[0][0],), f"{self.items[0][1]} is the new front"))
        return steps

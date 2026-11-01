"""Singly linked list. Positions are 0-based from the head."""
from __future__ import annotations

from .base import Model, Move, Step, ints


class LinkedListModel(Model):
    structure = "linked_list"
    player_ops = ("insert_head", "insert_after", "delete", "visit")

    def __init__(self, values=()):
        super().__init__()
        self.nodes: list[tuple[int, int]] = [(self._new_id(), v) for v in values]

    def key(self):
        return tuple(self.values())

    def values(self) -> list:
        return [v for _, v in self.nodes]

    def _walk(self, upto: int) -> list[Step]:
        """Steps for following `next` pointers from head to position `upto`."""
        return [
            Step("walk", (nid,), f"cur = {'head' if k == 0 else 'cur.next'} → {v}")
            for k, (nid, v) in enumerate(self.nodes[: upto + 1])
        ]

    def why_illegal(self, move: Move) -> str | None:
        op, a = move.op, move.args
        n = len(self.nodes)
        if op == "insert_head":
            return None
        if op in ("insert_after", "delete", "visit"):
            i = a[0]
            if not 0 <= i < n:
                return f"There is no node at position {i}."
            return None
        return f"Linked lists here support insert_head, insert_after, delete and visit, not '{op}'."

    def _apply(self, move: Move) -> list[Step]:
        op, a = move.op, move.args
        if op == "insert_head":
            (v,) = a
            new_id = self._new_id()
            old_head = self.nodes[0][0] if self.nodes else None
            self.nodes.insert(0, (new_id, v))
            steps = [Step("new_node", (new_id,), f"Create a node holding {v}")]
            if old_head is not None:
                steps.append(Step("link_next", (new_id, old_head), "node.next = head"))
            steps.append(Step("set_head", (new_id,), f"head = node ({v})"))
            return steps
        if op == "insert_after":
            i, v = a
            steps = self._walk(i)
            new_id = self._new_id()
            prev_id = self.nodes[i][0]
            nxt = self.nodes[i + 1][0] if i + 1 < len(self.nodes) else None
            self.nodes.insert(i + 1, (new_id, v))
            steps.append(Step("new_node", (new_id,), f"Create a node holding {v}"))
            steps.append(Step("link_next", (new_id,) + ((nxt,) if nxt else ()), "node.next = cur.next"))
            steps.append(Step("relink", (prev_id, new_id), "cur.next = node"))
            return steps
        if op == "delete":
            (i,) = a
            gone_id, v = self.nodes[i]
            if i == 0:
                self.nodes.pop(0)
                return [Step("unlink_head", (gone_id,), f"head = head.next (drops {v})")]
            steps = self._walk(i - 1)
            prev_id = self.nodes[i - 1][0]
            self.nodes.pop(i)
            steps.append(Step("unlink", (prev_id, gone_id), f"cur.next = cur.next.next (drops {v})"))
            return steps
        if op == "visit":
            (i,) = a
            nid, v = self.nodes[i]
            return [Step("walk", (nid,), f"Visit node {i}: {v}")]
        raise AssertionError(op)

    def parse(self, text: str) -> list[Move]:
        op, *rest = text.split()
        return [Move.of(op, *ints(rest))]

    def candidate_moves(self, tray_next):
        n = len(self.nodes)
        if tray_next is not None:
            yield Move.of("insert_head", tray_next)
            for i in range(n):
                yield Move.of("insert_after", i, tray_next)
        for i in range(n):
            yield Move.of("delete", i)

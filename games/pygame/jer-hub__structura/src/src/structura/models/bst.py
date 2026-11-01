"""Binary search tree with rotations, so it doubles as the AVL model.

Moves name nodes by value (values are unique in a BST), so a Move means the
same thing on any copy of the tree:

    insert(v, parent, side)    place v as `side` ("left"/"right") child of parent;
                               parent None means v becomes the root
    delete(v, replacement)     replacement is None for 0-1 children, otherwise the
                               in-order successor or predecessor that takes v's place
    rotate_left(v) / rotate_right(v)
    visit(v)                   a step in a traversal or search Trace
"""
from __future__ import annotations

from dataclasses import dataclass

from .base import Model, Move, Step, ints


@dataclass
class Node:
    value: int
    left: int | None = None
    right: int | None = None


class BSTModel(Model):
    structure = "bst"
    player_ops = ("insert", "delete", "rotate_left", "rotate_right", "visit")

    def __init__(self, values=()):
        super().__init__()
        self.nodes: dict[int, Node] = {}
        self.root: int | None = None
        for v in values:
            for move in self.parse(f"insert {v}"):
                self.apply(move)

    # ---- queries -------------------------------------------------------
    def key(self):
        def walk(nid):
            if nid is None:
                return None
            n = self.nodes[nid]
            return (n.value, walk(n.left), walk(n.right))

        return walk(self.root)

    def values(self) -> list:
        return [self.nodes[i].value for i in self.inorder_ids()]

    def inorder_ids(self) -> list[int]:
        out: list[int] = []

        def walk(nid):
            if nid is not None:
                walk(self.nodes[nid].left)
                out.append(nid)
                walk(self.nodes[nid].right)

        walk(self.root)
        return out

    def order(self, kind: str) -> list[int]:
        """Values in preorder / inorder / postorder / levelorder."""
        if kind == "inorder":
            return [self.nodes[i].value for i in self.inorder_ids()]
        out: list[int] = []
        if kind == "levelorder":
            queue = [self.root] if self.root is not None else []
            while queue:
                nid = queue.pop(0)
                n = self.nodes[nid]
                out.append(n.value)
                queue += [c for c in (n.left, n.right) if c is not None]
            return out

        def walk(nid):
            if nid is None:
                return
            n = self.nodes[nid]
            if kind == "preorder":
                out.append(n.value)
            walk(n.left)
            walk(n.right)
            if kind == "postorder":
                out.append(n.value)

        walk(self.root)
        return out

    def find(self, value: int) -> int | None:
        nid = self.root
        while nid is not None:
            n = self.nodes[nid]
            if value == n.value:
                return nid
            nid = n.left if value < n.value else n.right
        return None

    def parent_of(self, nid: int) -> int | None:
        for pid, n in self.nodes.items():
            if n.left == nid or n.right == nid:
                return pid
        return None

    def search_path(self, value: int) -> list[int]:
        """Node ids compared while searching for (or inserting) value."""
        path, nid = [], self.root
        while nid is not None:
            path.append(nid)
            n = self.nodes[nid]
            if value == n.value:
                break
            nid = n.left if value < n.value else n.right
        return path

    def height(self, nid: int | None = -1) -> int:
        """Height in edges; an empty tree has height -1."""
        if nid == -1:
            nid = self.root
        if nid is None:
            return -1
        n = self.nodes[nid]
        return 1 + max(self.height(n.left), self.height(n.right))

    def balance(self, nid: int) -> int:
        n = self.nodes[nid]
        return self.height(n.left) - self.height(n.right)

    def unbalanced_ids(self) -> list[int]:
        """Nodes violating the AVL rule, deepest first."""
        out: list[int] = []

        def walk(nid):
            if nid is None:
                return
            walk(self.nodes[nid].left)
            walk(self.nodes[nid].right)
            if abs(self.balance(nid)) > 1:
                out.append(nid)

        walk(self.root)
        return out

    def is_avl(self) -> bool:
        return not self.unbalanced_ids()

    def successor(self, nid: int) -> int:
        cur = self.nodes[nid].right
        while self.nodes[cur].left is not None:
            cur = self.nodes[cur].left
        return cur

    def predecessor(self, nid: int) -> int:
        cur = self.nodes[nid].left
        while self.nodes[cur].right is not None:
            cur = self.nodes[cur].right
        return cur

    def depth_of(self, nid: int) -> int:
        d, cur = 0, nid
        while (cur := self.parent_of(cur)) is not None:
            d += 1
        return d

    def empty_slots(self) -> list[tuple[int | None, str]]:
        """(parent value, side) for every empty child position."""
        if self.root is None:
            return [(None, "")]
        slots = []
        for nid in self.inorder_ids():
            n = self.nodes[nid]
            if n.left is None:
                slots.append((n.value, "left"))
            if n.right is None:
                slots.append((n.value, "right"))
        return slots

    def _canonical_slot(self, v: int) -> tuple[int | None, str]:
        path = self.search_path(v)
        if not path:
            return (None, "")
        last = self.nodes[path[-1]]
        return (last.value, "left" if v < last.value else "right")

    # ---- legality ------------------------------------------------------
    def why_illegal(self, move: Move) -> str | None:
        op, a = move.op, move.args
        if op == "insert":
            v, parent, side = a
            if self.find(v) is not None:
                return f"{v} is already in the tree. A BST holds each value once."
            if (parent, side) == self._canonical_slot(v):
                return None
            return self._explain_wrong_slot(v, parent, side)
        if op in ("delete", "rotate_left", "rotate_right", "visit"):
            nid = self.find(a[0])
            if nid is None:
                return f"{a[0]} is not in the tree."
            n = self.nodes[nid]
            if op == "rotate_left" and n.right is None:
                return f"A left rotation lifts the right child, but {n.value} has no right child."
            if op == "rotate_right" and n.left is None:
                return f"A right rotation lifts the left child, but {n.value} has no left child."
            if op == "delete":
                repl = a[1]
                two = n.left is not None and n.right is not None
                if not two and repl is not None:
                    return f"{n.value} has fewer than two children, so nothing needs to replace it."
                if two:
                    ok = {self.nodes[self.successor(nid)].value, self.nodes[self.predecessor(nid)].value}
                    if repl not in ok:
                        return (f"{n.value} has two children. Replace it with its in-order successor "
                                f"(the smallest value in its right subtree) to keep the BST ordered.")
            return None
        return f"Trees here don't support '{op}'."

    def _explain_wrong_slot(self, v, parent, side) -> str:
        for nid in self.search_path(v):
            x = self.nodes[nid].value
            go = "left" if v < x else "right"
            sign = "<" if v < x else ">"
            if parent == x:
                if side != go:
                    return f"{v} {sign} {x}, so {v} goes to the {go} of {x}."
                return f"{x} already has a {go} child, so keep comparing further down."
            pid = self.find(parent) if parent is not None else None
            if pid is not None and self._in_subtree(pid, self.nodes[nid].left if go == "right" else self.nodes[nid].right):
                return f"{v} {sign} {x}, so {v} belongs in {x}'s {go} subtree."
        if parent is None:
            return "The tree already has a root. Start comparing at the root."
        return f"That spot would break the ordering. Compare {v} with the root first."

    def _in_subtree(self, target: int, sub: int | None) -> bool:
        if sub is None:
            return False
        if sub == target:
            return True
        n = self.nodes[sub]
        return self._in_subtree(target, n.left) or self._in_subtree(target, n.right)

    # ---- mutation ------------------------------------------------------
    def _set_child(self, parent: int | None, old: int, new: int | None) -> None:
        if parent is None:
            self.root = new
        elif self.nodes[parent].left == old:
            self.nodes[parent].left = new
        else:
            self.nodes[parent].right = new

    def _compare_steps(self, path: list[int], v: int) -> list[Step]:
        steps = []
        for nid in path:
            x = self.nodes[nid].value
            if v == x:
                steps.append(Step("found", (nid,), f"{v} == {x}: found it"))
            elif v < x:
                steps.append(Step("go_left", (nid,), f"{v} < {x}: go left"))
            else:
                steps.append(Step("go_right", (nid,), f"{v} > {x}: go right"))
        return steps

    def _apply(self, move: Move) -> list[Step]:
        op, a = move.op, move.args
        if op == "insert":
            v, parent, side = a
            steps = self._compare_steps(self.search_path(v), v)
            new_id = self._new_id()
            self.nodes[new_id] = Node(v)
            if parent is None:
                self.root = new_id
            else:
                setattr(self.nodes[self.find(parent)], side, new_id)
            return steps + [Step("place", (new_id,), f"Empty spot: place {v} here")]

        if op == "visit":
            nid = self.find(a[0])
            return [Step("visit", (nid,), f"Visit {a[0]}")]

        if op in ("rotate_left", "rotate_right"):
            x = self.find(a[0])
            parent = self.parent_of(x)
            xn = self.nodes[x]
            if op == "rotate_left":
                y = xn.right
                xn.right = self.nodes[y].left
                self.nodes[y].left = x
            else:
                y = xn.left
                xn.left = self.nodes[y].right
                self.nodes[y].right = x
            self._set_child(parent, x, y)
            lifted = self.nodes[y].value
            return [Step(op, (x, y), f"Rotate {'left' if op == 'rotate_left' else 'right'} at {a[0]}: {lifted} moves up")]

        if op == "delete":
            v, repl = a
            nid = self.find(v)
            steps = self._compare_steps(self.search_path(v), v)
            n = self.nodes[nid]
            if repl is None:
                child = n.left if n.left is not None else n.right
                self._set_child(self.parent_of(nid), nid, child)
                del self.nodes[nid]
                kind = "remove_leaf" if child is None else "splice"
                text = f"{v} is a leaf: just remove it" if child is None else f"{v} has one child: link its parent to that child"
                return steps + [Step(kind, (nid,), text)]
            rid = self.find(repl)
            which = "successor" if rid == self.successor(nid) else "predecessor"
            steps.append(Step(f"find_{which}", (rid,), f"In-order {which} of {v} is {repl}"))
            r = self.nodes[rid]
            r_child = r.right if which == "successor" else r.left
            self._set_child(self.parent_of(rid), rid, r_child)
            del self.nodes[rid]
            n.value = repl
            steps.append(Step("replace", (nid,), f"Copy {repl} into {v}'s place, then remove the old {repl}"))
            return steps
        raise AssertionError(op)

    # ---- scripts & search ----------------------------------------------
    def parse(self, text: str) -> list[Move]:
        op, *rest = text.split()
        (v,) = ints(rest)
        if op == "insert":
            parent, side = self._canonical_slot(v)
            return [Move.of("insert", v, parent, side)]
        if op == "delete":
            nid = self.find(v)
            n = self.nodes[nid] if nid is not None else None
            repl = None
            if n is not None and n.left is not None and n.right is not None:
                repl = self.nodes[self.successor(nid)].value
            return [Move.of("delete", v, repl)]
        if op == "search":
            return [Move.of("visit", self.nodes[i].value) for i in self.search_path(v)]
        return [Move.of(op, v)]

    def needs_replacement(self, key) -> bool:
        n = self.nodes[self.find(key)]
        return n.left is not None and n.right is not None

    def delete_move(self, key, replacement=None) -> Move:
        return Move.of("delete", key, replacement)

    def alternatives(self, text: str) -> list[list[Move]]:
        moves = self.parse(text)
        if moves[0].op != "delete" or moves[0].args[1] is None:
            return [moves]
        v = moves[0].args[0]
        predecessor = self.nodes[self.predecessor(self.find(v))].value
        return [moves, [Move.of("delete", v, predecessor)]]

    def candidate_moves(self, tray_next):
        if tray_next is not None:
            yield from self.parse(f"insert {tray_next}")
        for nid, n in self.nodes.items():
            if n.right is not None:
                yield Move.of("rotate_left", n.value)
            if n.left is not None:
                yield Move.of("rotate_right", n.value)

    def avl_fix_moves(self, limit: int = 200) -> list[Move]:
        """Textbook rebalancing: fix the deepest AVL violation with a single or
        double rotation, repeat until balanced. Used as the Reference Solution."""
        work = self.copy()
        moves: list[Move] = []
        while (bad := work.unbalanced_ids()) and len(moves) < limit:
            z = bad[0]
            zn = work.nodes[z]
            if work.balance(z) > 1:
                if work.balance(zn.left) < 0:
                    moves.append(Move.of("rotate_left", work.nodes[zn.left].value))
                    work.apply(moves[-1])
                moves.append(Move.of("rotate_right", zn.value))
            else:
                if work.balance(zn.right) > 0:
                    moves.append(Move.of("rotate_right", work.nodes[zn.right].value))
                    work.apply(moves[-1])
                moves.append(Move.of("rotate_left", zn.value))
            work.apply(moves[-1])
        if work.unbalanced_ids():
            raise RuntimeError("AVL fix did not converge")
        return moves

"""Goals: what "finished" means for a Puzzle, and how to get there.

Every goal can produce a plan, which is the Reference Solution from the current
state (ADR 0001). The plan drives Strict Puzzles, the third Hint tier, star
scoring, and the "watch the Reference Solution" replay.
"""
from __future__ import annotations

import random
from collections import deque
from dataclasses import dataclass, field

from ..models import DISPLAY_NAMES, Model, Move, complexity, make
from .schema import ContentError, Puzzle

TRAY_OPS = {"insert", "push", "enqueue", "insert_head", "insert_after"}


@dataclass
class PlayState:
    model: Model
    tray: list
    visited: list = field(default_factory=list)
    answered: bool = False

    def copy(self) -> "PlayState":
        return PlayState(self.model.copy(), list(self.tray), list(self.visited), self.answered)


class Goal:
    """Base class. Subclasses set `kind` and override plan/done."""

    kind = ""
    options: list[str] | None = None   # for answer-style goals
    correct: int | None = None

    def __init__(self, puzzle: Puzzle):
        self.puzzle = puzzle
        self.spec = puzzle.goal

    def plan(self, st: PlayState) -> list[Move]:
        raise NotImplementedError

    def done(self, st: PlayState) -> bool:
        raise NotImplementedError

    def strict_reason(self, move: Move, expected: Move) -> str:
        return "That's a legal Move, but not the one this Puzzle is practising."

    def wrong_answer(self, index: int) -> str:
        return "Not quite."

    def describe(self) -> str:
        """One-line objective for the HUD."""
        return self.puzzle.brief

    def question(self) -> list[str]:
        """Lines to show in place of the board when the Puzzle is answered, not played."""
        return []

    def big_o_table(self):
        """Select Puzzles: (operations, rows) for the Code Mirror, in place of code."""
        return None


# ---------------------------------------------------------------------------
# Search solver for "reach this state" goals
# ---------------------------------------------------------------------------
def bfs(st: PlayState, ops: list[str], is_goal, limit: int = 60_000) -> list[Move] | None:
    """Shortest list of Moves from st to a goal state, using only `ops`."""
    if is_goal(st):
        return []
    seen = {(st.model.key(), len(st.tray))}
    queue = deque([(st, [])])
    while queue and len(seen) < limit:
        cur, path = queue.popleft()
        tray_next = cur.tray[0] if cur.tray else None
        for move in cur.model.candidate_moves(tray_next):
            if move.op not in ops or cur.model.why_illegal(move):
                continue
            nxt = cur.copy()
            nxt.model.apply(move)
            if move.op in TRAY_OPS:
                nxt.tray.pop(0)
            k = (nxt.model.key(), len(nxt.tray))
            if k in seen:
                continue
            seen.add(k)
            if is_goal(nxt):
                return path + [move]
            queue.append((nxt, path + [move]))
    return None


# ---------------------------------------------------------------------------
class SortedGoal(Goal):
    kind = "sorted"
    REASONS = {
        "bubble": "Bubble sort walks left to right, swapping neighbours that are out of order.",
        "selection": "Selection sort swaps the smallest remaining value into the next unsorted position.",
        "insertion": "Insertion sort slides the next value left, one neighbour at a time, past every larger value.",
        None: "That swap doesn't bring the array closer to sorted.",
    }

    def __init__(self, puzzle):
        super().__init__(puzzle)
        self.algorithm = self.spec.get("algorithm")
        if self.algorithm not in self.REASONS:
            raise ContentError(f"{puzzle.id}: unknown algorithm {self.algorithm!r}")

    def plan(self, st):
        a = list(st.model.values())
        moves: list[Move] = []

        def swap(i, j):
            a[i], a[j] = a[j], a[i]
            moves.append(Move.of("swap", i, j))

        n = len(a)
        if self.algorithm == "bubble":
            for end in range(n - 1, 0, -1):
                swapped = False
                for i in range(end):
                    if a[i] > a[i + 1]:
                        swap(i, i + 1)
                        swapped = True
                if not swapped:
                    break
        elif self.algorithm == "selection":
            for i in range(n - 1):
                m = min(range(i, n), key=lambda k: (a[k], k))
                if m != i:
                    swap(i, m)
        elif self.algorithm == "insertion":
            for i in range(1, n):
                j = i
                while j > 0 and a[j - 1] > a[j]:
                    swap(j - 1, j)
                    j -= 1
        else:
            # Fewest swaps: put the right value in each position, closing
            # 2-cycles first so one swap fixes two cells when possible.
            target = sorted(a)
            for i in range(n):
                if a[i] == target[i]:
                    continue
                js = [j for j in range(i + 1, n) if a[j] == target[i]]
                best = next((j for j in js if a[i] == target[j]), js[0])
                swap(i, best)
        return moves

    def done(self, st):
        v = st.model.values()
        return all(v[i] <= v[i + 1] for i in range(len(v) - 1))

    def strict_reason(self, move, expected):
        return self.REASONS[self.algorithm]


class TargetGoal(Goal):
    kind = "target"

    def __init__(self, puzzle):
        super().__init__(puzzle)
        self.state = self.spec.get("state")
        self.output = self.spec.get("output")
        if self.state is None and self.output is None:
            raise ContentError(f"{puzzle.id}: target goal needs `state` or `output`")

    def done(self, st):
        if self.state is not None and list(st.model.values()) != list(self.state):
            return False
        if self.output is not None and list(getattr(st.model, "out", [])) != list(self.output):
            return False
        return True

    def plan(self, st):
        return bfs(st, self.puzzle.ops, self.done) or []


class ScriptGoal(Goal):
    """Finish in the state you'd get by running a script the textbook way."""

    kind = "script"
    ADD_OP = {"bst": "insert", "stack": "push", "queue": "enqueue", "linked_list": "insert_head"}

    def __init__(self, puzzle):
        super().__init__(puzzle)
        self.lines = self.spec.get("script") or [
            f"{self.ADD_OP[puzzle.structure]} {v}" for v in puzzle.tray
        ]
        works = [make(puzzle.structure, puzzle.initial)]
        self.lines_done = {works[0].key(): 0}       # state -> script lines it has carried out
        for k, line in enumerate(self.lines, 1):
            reached = {}
            for work in works:
                for moves in work.alternatives(line):
                    nxt = work.copy()
                    for m in moves:
                        nxt.apply(m)
                    reached.setdefault(nxt.key(), nxt)
            works = list(reached.values())
            for key in reached:
                self.lines_done.setdefault(key, k)
        self.target_keys = {w.key() for w in works}

    def done(self, st):
        return st.model.key() in self.target_keys

    def plan(self, st):
        key = st.model.key()
        if key in self.lines_done:
            k = self.lines_done[key]
            work = st.model.copy()
            moves = []
            for line in self.lines[k:]:
                for m in work.parse(line):
                    moves.append(m)
                    work.apply(m)
            return moves
        return bfs(st, self.puzzle.ops, self.done) or []

    def strict_reason(self, move, expected):
        return "Follow the operations in the order the Puzzle lists them."


class VisitGoal(Goal):
    """Trace goals: the player clicks elements in the order an algorithm visits them."""

    kind = "visit"
    REASONS = {
        "preorder": "Pre-order visits a node first, then its left subtree, then its right subtree.",
        "inorder": "In-order visits the left subtree, then the node, then the right subtree.",
        "postorder": "Post-order visits both subtrees before the node itself.",
        "levelorder": "Level-order visits the tree one level at a time, left to right.",
        "linear": "Linear search checks each position in turn, starting from the front.",
        "binary": "Binary search always checks the middle of the range that could still hold the value.",
        "bst": "Compare with the current node: go left if the value is smaller, right if it is larger.",
        "walk": "You can only reach a node by following next pointers from the head.",
    }

    def __init__(self, puzzle):
        super().__init__(puzzle)
        model = make(puzzle.structure, puzzle.initial)
        s, kind = self.spec, self.spec["kind"]
        if puzzle.structure == "bst":
            if kind == "traverse":
                self.method = s["order"]
                self.sequence = model.order(self.method)
            else:
                self.method = "bst"
                self.sequence = [model.nodes[i].value for i in model.search_path(s["value"])]
        else:
            vals = model.values()
            target = s.get("value")
            if kind == "traverse":
                self.method = "walk" if puzzle.structure == "linked_list" else "linear"
                self.sequence = list(range(len(vals)))
            elif s.get("method", "linear") == "binary":
                self.method = "binary"
                self.sequence, lo, hi = [], 0, len(vals) - 1
                while lo <= hi:
                    mid = (lo + hi) // 2
                    self.sequence.append(mid)
                    if vals[mid] == target:
                        break
                    lo, hi = (mid + 1, hi) if vals[mid] < target else (lo, mid - 1)
            else:
                self.method = "walk" if puzzle.structure == "linked_list" else "linear"
                stop = vals.index(target) if target in vals else len(vals) - 1
                self.sequence = list(range(stop + 1))

    def plan(self, st):
        return [Move.of("visit", x) for x in self.sequence[len(st.visited):]]

    def done(self, st):
        return len(st.visited) >= len(self.sequence)

    def strict_reason(self, move, expected):
        return self.REASONS[self.method]


class BalancedGoal(Goal):
    kind = "balanced"

    def plan(self, st):
        return st.model.avl_fix_moves()

    def done(self, st):
        return st.model.is_avl()


def _fmt(value) -> str:
    if value is None:
        return "(empty)"
    if isinstance(value, (list, tuple)):
        return "[" + ", ".join(map(str, value)) + "]" if value else "(empty)"
    return str(value)


class QuizGoal(Goal):
    """Trace-by-prediction: run a script in your head, pick the result."""

    kind = "quiz"
    ASKS = {
        "top": lambda m: m.top(),
        "front": lambda m: m.front(),
        "state": lambda m: m.values(),
        "output": lambda m: m.out,
        "height": lambda m: m.height(),
        "preorder": lambda m: m.order("preorder"),
        "inorder": lambda m: m.order("inorder"),
        "postorder": lambda m: m.order("postorder"),
        "levelorder": lambda m: m.order("levelorder"),
    }
    SWAP_DISCIPLINE = {"push": "enqueue", "pop": "dequeue", "enqueue": "push", "dequeue": "pop"}

    def __init__(self, puzzle):
        super().__init__(puzzle)
        self.script = self.spec["script"]
        self.ask = self.spec["ask"]
        get = self.ASKS[self.ask]

        def run(structure, lines, ask=None):
            m = make(structure, puzzle.initial)
            m.run(lines)
            return _fmt((self.ASKS[ask] if ask else get)(m))

        answer = run(puzzle.structure, self.script)
        candidates: list[str] = []
        other = {"stack": "queue", "queue": "stack"}.get(puzzle.structure)
        if other:
            swapped = [" ".join([self.SWAP_DISCIPLINE.get(w, w) for w in l.split()][:1] + l.split()[1:])
                       for l in self.script]
            other_ask = {"top": "front", "front": "top"}.get(self.ask, self.ask)
            candidates.append(run(other, swapped, other_ask))
        if self.ask in ("preorder", "inorder", "postorder", "levelorder"):
            candidates += [run(puzzle.structure, self.script, k) for k in
                           ("preorder", "inorder", "postorder", "levelorder") if k != self.ask]
        for i in range(len(self.script)):
            try:
                candidates.append(run(puzzle.structure, self.script[:i] + self.script[i + 1:]))
            except Exception:
                pass
        if answer.startswith("["):
            inner = answer[1:-1].split(", ")
            candidates.append("[" + ", ".join(reversed(inner)) + "]")
        rng = random.Random(puzzle.id)
        distractors = []
        for c in candidates:
            if c != answer and c not in distractors:
                distractors.append(c)
        rng.shuffle(distractors)
        self.options = [answer] + distractors[:3]
        rng.shuffle(self.options)
        self.correct = self.options.index(answer)
        if len(self.options) < 2:
            raise ContentError(f"{puzzle.id}: quiz has no believable wrong answers")

    def plan(self, st):
        return [] if st.answered else [Move.of("answer", self.correct)]

    def done(self, st):
        return st.answered

    def question(self):
        return list(self.script)

    def wrong_answer(self, index):
        return {
            "stack": "Remember LIFO: pop always removes the value pushed most recently.",
            "queue": "Remember FIFO: dequeue always removes the value that has waited longest.",
        }.get(self.puzzle.structure, "Trace the operations again, one at a time, on paper.")


class SelectGoal(Goal):
    """Pick the right structure for a scenario, scored by the complexity table."""

    kind = "select"

    def __init__(self, puzzle):
        super().__init__(puzzle)
        self.scenario = self.spec["scenario"]
        self.choices = self.spec["choices"]
        try:
            answer = complexity.best(self.choices, self.scenario)
        except ValueError as exc:
            raise ContentError(f"{puzzle.id}: {exc}") from exc
        self.options = [DISPLAY_NAMES[c] for c in self.choices]
        self.correct = self.choices.index(answer)

    def plan(self, st):
        return [] if st.answered else [Move.of("answer", self.correct)]

    def done(self, st):
        return st.answered

    def wrong_answer(self, index):
        return complexity.explain(self.choices[index], self.choices[self.correct], self.scenario)

    def big_o_table(self):
        return complexity.table(self.choices, self.scenario)


GOALS = {"sorted": SortedGoal, "target": TargetGoal, "script": ScriptGoal,
         "traverse": VisitGoal, "search": VisitGoal, "balanced": BalancedGoal,
         "quiz": QuizGoal, "select": SelectGoal}


def make_goal(puzzle: Puzzle) -> Goal:
    kind = puzzle.goal.get("kind")
    if kind not in GOALS:
        raise ContentError(f"{puzzle.id}: unknown goal kind {kind!r}")
    return GOALS[kind](puzzle)

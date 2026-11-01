"""Code Mirror snippets in Python and Java (ADR 0002).

Snippet lines end with `@@kind[,kind]` to say which Step kinds they execute.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from .. import bundle

LANGUAGES = ("python", "java")
_EXT = {"python": "py", "java": "java"}

# Which snippet to show for a Move when the Puzzle doesn't name one.
DEFAULT_BY_OP = {
    ("array", "swap"): "swap", ("array", "insert"): "array_insert",
    ("array", "delete"): "array_delete", ("array", "visit"): "linear_search",
    ("stack", "push"): "stack", ("stack", "pop"): "stack",
    ("queue", "enqueue"): "queue", ("queue", "dequeue"): "queue",
    ("linked_list", "insert_head"): "ll_insert_head", ("linked_list", "insert_after"): "ll_insert_after",
    ("linked_list", "delete"): "ll_delete", ("linked_list", "visit"): "ll_traverse",
    ("bst", "insert"): "bst_insert", ("bst", "delete"): "bst_delete", ("bst", "visit"): "bst_search",
    ("bst", "rotate_left"): "bst_rotate", ("bst", "rotate_right"): "bst_rotate",
}


@dataclass(frozen=True)
class Snippet:
    key: str
    language: str
    lines: tuple[str, ...]
    marks: dict  # step kind -> tuple of line indexes

    def lines_for(self, kind: str) -> tuple[int, ...]:
        return self.marks.get(kind, ())


def _dir() -> Path:
    return bundle.locate(bundle.SNIPPETS)


@lru_cache(maxsize=None)
def load(key: str, language: str) -> Snippet | None:
    path = _dir() / f"{key}.{_EXT[language]}.txt"
    if not path.exists():
        return None
    lines, marks = [], {}
    for i, raw in enumerate(path.read_text(encoding="utf-8").splitlines()):
        text, sep, tags = raw.partition("@@")
        if sep:
            for kind in tags.strip().split(","):
                marks.setdefault(kind, ())
                marks[kind] += (i,)
            text = text.rstrip()
        lines.append(text)
    return Snippet(key, language, tuple(lines), marks)


def keys() -> list[str]:
    return sorted({p.name.split(".")[0] for p in _dir().glob("*.txt")})

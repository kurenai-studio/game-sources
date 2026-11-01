"""Hints. Tiers 1-2 are written by people, tier 3 is generated from the
Reference Solution.

Written hints may not contain literal numbers (ADR 0001). They name values
through tokens filled in from the live Reference Solution, so they can't
contradict it:

    {next}    the next Reference Move, described in words
    {value}   the next value in the Tray
    {target}  the value the goal is about (search value, etc.)
"""
from __future__ import annotations

import re
import string

from ..models import Model, Move

TOKENS = {"next", "value", "target"}
_DIGITS = re.compile(r"\d")


def describe(move: Move | None, model: Model | None = None, options: list[str] | None = None) -> str:
    if move is None:
        return "nothing left to do"
    op, a = move.op, move.args
    vals = model.values() if model is not None and model.structure in ("array", "linked_list") else None
    if op == "swap":
        i, j = a
        if vals:
            return f"swap {vals[i]} (index {i}) with {vals[j]} (index {j})"
        return f"swap index {i} with index {j}"
    if op == "insert" and len(a) == 3:
        v, parent, side = a
        return f"place {v} as the root" if parent is None else f"place {v} as the {side} child of {parent}"
    if op == "insert":
        return f"insert {a[1]} at index {a[0]}"
    if op == "delete" and len(a) == 2:
        v, repl = a
        return f"delete {v}" + (f", replacing it with {repl}" if repl is not None else "")
    if op == "delete":
        return f"delete the node at position {a[0]}" if model and model.structure == "linked_list" \
            else f"delete index {a[0]}"
    if op == "visit":
        if vals:
            return f"visit position {a[0]} (value {vals[a[0]]})"
        return f"visit {a[0]}"
    if op == "insert_head":
        return f"insert {a[0]} at the head"
    if op == "insert_after":
        return f"insert {a[1]} after position {a[0]}" + (f" (value {vals[a[0]]})" if vals else "")
    if op in ("rotate_left", "rotate_right"):
        return f"rotate {op.split('_')[1]} at {a[0]}"
    if op == "answer":
        return f"choose \"{options[a[0]]}\"" if options else "choose the right answer"
    return " ".join([op.replace("_", " "), *map(str, a)])


def render(template: str, *, next_move: str, value, target) -> str:
    return template.format_map({"next": next_move, "value": "—" if value is None else value,
                                "target": "—" if target is None else target})


def lint(template: str) -> list[str]:
    """Problems with a written Hint; empty if fine."""
    problems = []
    literal = "".join(text for text, *_ in string.Formatter().parse(template))
    if _DIGITS.search(literal):
        problems.append("contains a literal number; use a token such as {next} or {value}")
    for _, field, _, _ in string.Formatter().parse(template):
        if field is not None and field not in TOKENS:
            problems.append(f"unknown token {{{field}}}")
    return problems

"""Big-O of each operation per structure. This table is how Select Puzzles get
their Reference Solution (ADR 0001): the answer is computed, never typed in.

A scenario weights how often each operation happens. The best structure has the
lowest weighted cost. Ties go to the structure with fewer capabilities, because
the most restrictive structure that still does the job states intent best
(a stack says "LIFO only" where an array says "anything goes").
"""
from __future__ import annotations

OPERATIONS = {
    "access_index": "read the item at a position",
    "search": "find a value",
    "add_front": "add at the front",
    "add_back": "add at the back",
    "remove_front": "remove from the front",
    "remove_back": "remove from the back",
}

# Stack's "back" is its top. Queue adds at the back and removes from the front.
TABLE: dict[str, dict[str, str]] = {
    "array": {"access_index": "O(1)", "search": "O(n)", "add_front": "O(n)", "add_back": "O(1)",
              "remove_front": "O(n)", "remove_back": "O(1)"},
    "linked_list": {"access_index": "O(n)", "search": "O(n)", "add_front": "O(1)", "add_back": "O(1)",
                    "remove_front": "O(1)", "remove_back": "O(n)"},
    "stack": {"add_back": "O(1)", "remove_back": "O(1)"},
    "queue": {"add_back": "O(1)", "remove_front": "O(1)"},
}

# When two choices cost the same, the loser is named by what it allows that the
# winner forbids. Changes to the structure come first: they break LIFO and FIFO.
MISUSES = ("remove_front", "add_front", "remove_back", "add_back", "access_index", "search")

RANK = {"O(1)": 1, "O(log n)": 2, "O(n)": 3, "O(n log n)": 4}


def cost(structure: str, scenario: dict[str, int]) -> float:
    row = TABLE[structure]
    total = 0.0
    for op, weight in scenario.items():
        if weight <= 0:
            continue
        if op not in row:
            return float("inf")
        total += weight * RANK[row[op]]
    return total


def ranking(choices: list[str], scenario: dict[str, int]) -> list[str]:
    return sorted(choices, key=lambda s: (cost(s, scenario), len(TABLE[s])))


def best(choices: list[str], scenario: dict[str, int]) -> str:
    """The single best structure. Raises if the scenario can't separate the top two."""
    ranked = ranking(choices, scenario)
    a, b = ranked[0], ranked[1]
    if (cost(a, scenario), len(TABLE[a])) == (cost(b, scenario), len(TABLE[b])):
        raise ValueError(f"scenario ties {a} and {b}; adjust the weights")
    if cost(a, scenario) == float("inf"):
        raise ValueError("no choice supports every operation in the scenario")
    return a


def with_article(name: str) -> str:
    return f"{'an' if name[0] in 'AEIOU' else 'a'} {name}"


def explain(chosen: str, correct: str, scenario: dict[str, int]) -> str:
    """Why `chosen` loses to `correct`, naming the most damning operation and
    its Big-O on both structures."""
    from . import DISPLAY_NAMES as names

    row_c, row_k = TABLE[chosen], TABLE[correct]
    a, b = with_article(names[chosen]), with_article(names[correct])
    used = [op for op, w in sorted(scenario.items(), key=lambda kv: -kv[1]) if w > 0]
    for op in used:
        if op not in row_c:
            return f"{a[0].upper() + a[1:]} can't {OPERATIONS[op]} at all, but {b} does it in {row_k[op]}."
    for op in used:
        if RANK[row_c[op]] > RANK[row_k[op]]:
            return f"To {OPERATIONS[op]}, {a} takes {row_c[op]} but {b} takes {row_k[op]}."
    op = used[0]
    extra = next(o for o in MISUSES if o in row_c and o not in row_k)
    return (f"To {OPERATIONS[op]}, {a} takes {row_c[op]} and so does {b}. But {a} also lets you "
            f"{OPERATIONS[extra]}, which this job doesn't need, and {b} rules that out.")


def table(choices: list[str], scenario: dict[str, int]) -> tuple[list[str], list[tuple[str, list[str]]]]:
    """The Big-O of each operation the scenario uses, per choice, for the Code
    Mirror during a Select Puzzle. "—" marks an operation a structure lacks."""
    from . import DISPLAY_NAMES as names

    ops = [op for op in OPERATIONS if scenario.get(op, 0) > 0]
    return [OPERATIONS[op] for op in ops], [(names[c], [TABLE[c].get(op, "—") for op in ops]) for c in choices]

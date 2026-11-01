"""Every shipped Zone must load, and every Puzzle in it must be solvable by its
own Reference Solution (ADR 0001)."""
import copy
import random

import pytest

from structura.codemirror import library
from structura.models import complexity, make
from structura.puzzles.goals import TRAY_OPS
from structura.puzzles.hints import lint
from structura.puzzles.schema import ContentError, load_all, load_zone
from structura.puzzles.session import PuzzleSession, reference_moves

ZONES = load_all()
PUZZLES = [p for z in ZONES for p in z.puzzles]


def test_array_plains_is_the_first_zone():
    z1 = ZONES[0]
    assert z1.id == "z1" and z1.structure == "array" and z1.requires == []
    assert z1.lesson is not None and len(z1.lesson.beats) >= 3
    assert 3 <= len(z1.puzzles) <= 4
    assert z1.puzzles[-1].stage == "boss"
    assert {p.type for p in z1.puzzles} >= {"trace", "build", "sort"}


@pytest.mark.parametrize("puzzle", PUZZLES, ids=lambda p: p.id)
def test_reference_solution_finishes(puzzle):
    moves = reference_moves(puzzle)
    assert moves, "a Puzzle that is already solved teaches nothing"


@pytest.mark.parametrize("puzzle", PUZZLES, ids=lambda p: p.id)
def test_disruptions_actually_fire(puzzle):
    if not puzzle.disruptions:
        return
    s = PuzzleSession(puzzle)
    fired = 0
    for m in reference_moves(puzzle):
        fired += bool(s.try_move(m).disruption)
    assert fired == len(puzzle.disruptions), "a Disruption is scheduled after the Puzzle would end"


def legal_moves(s: PuzzleSession):
    for m in s.model.candidate_moves(s.tray_next):
        if m.op in s.puzzle.ops and not s.model.why_illegal(m):
            yield m


@pytest.mark.parametrize("puzzle", [p for p in PUZZLES if p.disruptions], ids=lambda p: p.id)
def test_disruptions_never_make_a_winnable_puzzle_unwinnable(puzzle):
    """Spec story 35. Winnability is measured between the player's Move and the
    Disruption, so the player's own dead ends aren't blamed on the Disruption."""
    for seed in range(40):
        rng = random.Random(seed)
        s = PuzzleSession(puzzle)
        while len(s.fired) < len(puzzle.disruptions) and s.moves < 12:
            moves = list(legal_moves(s))
            if s.done or not moves:
                break
            move = rng.choice(moves)
            calm = copy.deepcopy(s)
            calm.fired = frozenset(range(len(puzzle.disruptions)))
            calm.try_move(move)
            out = s.try_move(move)
            if out.disruption and not calm.dead_end:
                assert not s.dead_end, f"seed {seed}: {out.disruption!r} after {move} left no way to finish"


@pytest.mark.parametrize("puzzle", [p for p in PUZZLES if p.disruptions], ids=lambda p: p.id)
def test_no_shortcut_finishes_before_the_first_disruption(puzzle):
    """A Disruption a quick player never meets teaches nothing. The search stops at
    the first Disruption: going further is too slow for the swap Bosses."""
    s = PuzzleSession(puzzle)
    frontier = [s.state]
    for depth in range(1, min(d.after for d in puzzle.disruptions) + 1):
        seen = {}
        for st in frontier:
            for m in st.model.candidate_moves(st.tray[0] if st.tray else None):
                if m.op not in puzzle.ops or st.model.why_illegal(m):
                    continue
                nxt = st.copy()
                nxt.model.apply(m)
                if m.op in TRAY_OPS:
                    nxt.tray.pop(0)
                assert not s.goal.done(nxt), f"finished in {depth} Moves, before any Disruption"
                seen.setdefault((nxt.model.key(), len(nxt.tray)), nxt)
        frontier = list(seen.values())


def test_linked_marshes_follow_the_array_plains():
    z2 = next(z for z in ZONES if z.id == "z2")
    assert z2.structure == "linked_list" and z2.requires == ["z1"]
    assert z2.puzzles[-1].stage == "boss" and z2.puzzles[-1].disruptions
    assert all(p.code.startswith("ll_") for p in z2.puzzles)


@pytest.mark.parametrize("puzzle", PUZZLES, ids=lambda p: p.id)
def test_written_hints_pass_lint(puzzle):
    assert len(puzzle.hints) == 2
    for h in puzzle.hints:
        assert lint(h) == [], h


@pytest.mark.parametrize("puzzle", PUZZLES, ids=lambda p: p.id)
def test_code_mirror_snippet_exists_in_both_languages(puzzle):
    if puzzle.code:
        for lang in library.LANGUAGES:
            assert library.load(puzzle.code, lang) is not None, (puzzle.code, lang)


@pytest.mark.parametrize("zone", ZONES, ids=lambda z: z.id)
def test_lesson_scripts_run(zone):
    model = make(zone.lesson.structure, zone.lesson.initial)
    for beat in zone.lesson.beats:
        if beat.structure:
            model = make(beat.structure, beat.initial)
        model.run(beat.do)
        if beat.code:
            assert library.load(beat.code, "java") is not None


def test_queue_canals_follow_the_stack_towers():
    z4 = next(z for z in ZONES if z.id == "z4")
    assert z4.name == "The Queue Canals" and z4.structure == "queue" and z4.requires == ["z3"]
    assert z4.puzzles[-1].stage == "boss" and z4.puzzles[-1].disruptions
    assert any(p.goal["kind"] == "quiz" for p in z4.puzzles)


def test_nexus_alpha_follows_the_queue_canals():
    nx = next(z for z in ZONES if z.id == "nexus_alpha")
    assert nx.name == "Nexus Alpha" and nx.is_nexus and nx.requires == ["z4"]
    assert ZONES.index(nx) == ZONES.index(next(z for z in ZONES if z.id == "z4")) + 1
    assert sum(p.type == "select" for p in nx.puzzles) >= 4
    assert any(p.structure == "queue" and p.goal["kind"] == "quiz" for p in nx.puzzles), "mixed-structure quiz"
    boss = nx.puzzles[-1]
    assert boss.stage == "boss" and boss.structure == "array" and len(boss.disruptions) == 2


def test_binary_forest_follows_nexus_alpha():
    z5 = next(z for z in ZONES if z.id == "z5")
    assert z5.name == "The Binary Forest" and z5.structure == "bst" and z5.requires == ["nexus_alpha"]
    assert ZONES.index(z5) == ZONES.index(next(z for z in ZONES if z.id == "nexus_alpha")) + 1
    kinds = {p.goal["kind"] for p in z5.puzzles}
    assert {"script", "search", "traverse", "quiz"} <= kinds

    children = set()                              # spec story 63: all three deletion cases
    for p in (p for p in z5.puzzles if p.goal["kind"] == "script"):
        model = make(p.structure, p.initial)
        for m in reference_moves(p):
            if m.op == "delete":
                n = model.nodes[model.find(m.args[0])]
                children.add((n.left is not None) + (n.right is not None))
            model.apply(m)
    assert children == {0, 1, 2}
    orders = {p.goal.get("order") for p in z5.puzzles if p.goal["kind"] == "traverse"}
    assert orders == {"preorder", "inorder", "postorder"}, "spec story 65"


def test_binary_forest_rotations_and_the_colossus():
    """Spec stories 66-68."""
    z5 = next(z for z in ZONES if z.id == "z5")
    rotations = {p.id: len(reference_moves(p)) for p in z5.puzzles if p.goal["kind"] == "balanced"}
    assert rotations["z5_p7"] == 1 and rotations["z5_p8"] == 2, "a single and a double rotation"
    boss = z5.puzzles[-1]
    assert boss.stage == "boss" and boss.goal["kind"] == "balanced" and boss.disruptions
    assert any(b.do and b.do[0].startswith("rotate") for b in z5.lesson.beats), "the Lesson shows a rotation"


@pytest.mark.parametrize("puzzle", [p for p in PUZZLES if p.goal["kind"] == "select"], ids=lambda p: p.id)
def test_every_select_scenario_has_a_unique_best_answer(puzzle):
    goal = PuzzleSession(puzzle).goal
    ranked = complexity.ranking(puzzle.goal["choices"], puzzle.goal["scenario"])
    assert puzzle.goal["choices"][goal.correct] == ranked[0]
    first, second = ranked[:2]
    key = lambda s: (complexity.cost(s, puzzle.goal["scenario"]), len(complexity.TABLE[s]))
    assert key(first) < key(second)


def test_a_lesson_beat_with_an_unknown_big_o_operation_is_rejected(tmp_path):
    path = tmp_path / "z.toml"
    path.write_text('''[zone]
id = "zx"
name = "X"
order = 1
structure = "array"

[lesson]
initial = []

[[lesson.beat]]
say = "Compare."
big_o = ["teleport"]
''', encoding="utf-8")
    with pytest.raises(ContentError, match="teleport"):
        load_zone(path)

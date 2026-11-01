from structura.models import Move
from structura.puzzles.hints import lint
from structura.puzzles.schema import Disruption, Puzzle
from structura.puzzles.session import PuzzleSession, reference_count, reference_moves, stars_for


def puzzle(**kw) -> Puzzle:
    base = dict(id="t", title="t", type="sort", stage="challenge", structure="array",
                brief="", goal={"kind": "sorted"}, initial=[3, 1, 2], ops=["swap"])
    base.update(kw)
    return Puzzle(**base)


def test_strict_bubble_sort_rejects_non_bubble_swap():
    p = puzzle(goal={"kind": "sorted", "algorithm": "bubble"}, strict=True, initial=[3, 1, 2])
    s = PuzzleSession(p)
    out = s.try_move(Move.of("swap", 0, 2))           # legal, sorts it, but isn't bubble sort
    assert not out.ok and "neighbours" in out.glitch
    assert s.glitches == 1 and s.model.values() == [3, 1, 2]
    assert s.try_move(Move.of("swap", 0, 1)).ok
    out = s.try_move(Move.of("swap", 1, 2))
    assert out.done and s.stars() == 2               # one Glitch over a 2-Move reference = 1.5x


def test_free_sort_reference_is_fewest_swaps_and_stars():
    p = puzzle(initial=[4, 3, 2, 1])
    assert reference_count(p) == 2
    s = PuzzleSession(p)
    for m in [Move.of("swap", 0, 3), Move.of("swap", 1, 2)]:
        s.try_move(m)
    assert s.done and s.stars() == 3


def test_undo_does_not_refund_moves():
    s = PuzzleSession(puzzle(initial=[2, 1, 3]))
    s.try_move(Move.of("swap", 1, 2))
    assert s.undo()
    assert s.moves == 1 and s.model.values() == [2, 1, 3]


def test_bst_build_from_tray_and_wrong_slot_glitch():
    p = puzzle(type="build", structure="bst", initial=[], tray=[8, 3, 10],
               ops=["insert"], goal={"kind": "script"})
    s = PuzzleSession(p)
    assert s.try_move(Move.of("insert", 8, None, "")).ok
    out = s.try_move(Move.of("insert", 3, 8, "right"))
    assert not out.ok and "3 < 8" in out.glitch
    assert s.try_move(Move.of("insert", 3, 8, "left")).ok
    assert s.try_move(Move.of("insert", 10, 8, "right")).done


def test_tray_order_enforced():
    p = puzzle(type="build", structure="stack", initial=[], tray=[1, 2], ops=["push", "pop"],
               goal={"kind": "target", "state": [2, 1]})
    s = PuzzleSession(p)
    assert "1 comes next" in s.try_move(Move.of("push", 2)).glitch


def test_stack_target_solved_by_search():
    p = puzzle(type="build", structure="stack", initial=[], tray=[1, 2, 3], ops=["push", "pop"],
               goal={"kind": "target", "output": [2, 1]})
    assert [str(m) for m in reference_moves(p)] == ["push 1", "push 2", "pop", "pop"]


def test_binary_search_trace():
    p = puzzle(type="trace", initial=[1, 3, 5, 7, 9, 11, 13], ops=["visit"],
               goal={"kind": "search", "value": 11, "method": "binary"})
    assert [m.args[0] for m in reference_moves(p)] == [3, 5]
    s = PuzzleSession(p)
    out = s.try_move(Move.of("visit", 0))
    assert not out.ok and "middle" in out.glitch


def test_disruption_fires_and_reference_still_finishes():
    p = puzzle(initial=[2, 1, 3, 4, 6, 5], ops=["swap"], goal={"kind": "sorted"},
               disruptions=[Disruption(after=1, do=["reverse 2 5"], say="Scrambled!")])
    s = PuzzleSession(p)
    out = s.try_move(Move.of("swap", 0, 1))
    assert out.disruption == "Scrambled!" and s.model.values() == [1, 2, 5, 6, 4, 3]
    assert not s.done
    assert reference_count(p) == 4


def test_quiz_options_include_computed_answer():
    p = puzzle(type="trace", structure="stack", initial=[], ops=[],
               goal={"kind": "quiz", "script": ["push 1", "push 2", "push 3", "pop"], "ask": "top"})
    s = PuzzleSession(p)
    assert s.goal.options[s.goal.correct] == "2"
    assert "3" in s.goal.options or "1" in s.goal.options
    wrong = next(i for i in range(len(s.goal.options)) if i != s.goal.correct)
    assert "LIFO" in s.try_move(Move.of("answer", wrong)).glitch
    assert s.try_move(Move.of("answer", s.goal.correct)).done


def test_hint_tiers():
    p = puzzle(hints=["Find the smallest value.", "Try: {next}."])
    s = PuzzleSession(p)
    assert s.hint()[1] == "Find the smallest value."
    assert s.hint()[1] == "Try: swap 3 (index 0) with 1 (index 1)."
    tier, text, move = s.hint()
    assert tier == 3 and move == Move.of("swap", 0, 1)
    assert s.hints_used == 3


def test_hint_lint():
    assert lint("Replace it with its successor.") == []
    assert lint("Replace 7 with 13.")
    assert lint("Use {nope}.")


def test_stars_formula():
    assert stars_for(4, 0, 0, 4) == 3
    assert stars_for(5, 0, 0, 4) == 2
    assert stars_for(4, 0, 1, 4) == 2
    assert stars_for(9, 0, 0, 4) == 1


# ---- dead ends ------------------------------------------------------------------
def marsh(**kw) -> Puzzle:
    base = dict(type="repair", structure="linked_list", initial=[1, 7, 3], tray=[2],
                ops=["insert_after", "delete"], goal={"kind": "target", "state": [1, 2, 3]},
                hints=["Remove what doesn't belong.", "Next: {next}."])
    base.update(kw)
    return puzzle(**base)


def test_deleting_a_value_the_tray_cannot_replace_is_a_dead_end():
    s = PuzzleSession(marsh())
    assert not s.dead_end
    assert s.try_move(Move.of("delete", 0)).ok        # 1 is gone and the Tray holds only 2
    assert s.dead_end and not s.done
    assert s.expected() is None
    s.undo()
    assert not s.dead_end


def test_finished_puzzle_is_not_a_dead_end():
    s = PuzzleSession(marsh())
    for m in reference_moves(s.puzzle):
        s.try_move(m)
    assert s.done and not s.dead_end


def test_hint_in_a_dead_end_says_undo_instead_of_a_move_and_is_free():
    s = PuzzleSession(marsh())
    s.hint()
    s.hint()
    s.try_move(Move.of("delete", 0))
    tier, text, move = s.hint()                       # would be the third tier
    assert text.startswith("Undo") and move is None
    assert tier == 2 and s.hints_used == 2


def record_searches(s: PuzzleSession) -> list:
    """Each time the session searches for a Reference Solution, append the state searched from."""
    searched = []
    search = s.goal.plan
    def recording(st):
        searched.append(st)
        return search(st)
    s.goal.plan = recording
    return searched


def test_staying_in_a_dead_end_does_not_search_again():
    """The search can take seconds on a big board, so asking again must not repeat it."""
    s = PuzzleSession(marsh())
    s.try_move(Move.of("delete", 0))
    searched = record_searches(s)
    for _ in range(3):
        assert s.dead_end and s.expected() is None
        s.hint()
    assert searched == []
    s.undo()
    assert not s.dead_end and s.expected() is not None


# ---- quiz answers ------------------------------------------------------------------
def test_wrong_answer_is_a_glitch_then_right_answer_finishes():
    p = puzzle(type="trace", structure="stack", initial=[], ops=[],
               goal={"kind": "quiz", "script": ["push 4", "push 9", "pop", "push 2"], "ask": "top"})
    s = PuzzleSession(p)
    options, right = s.goal.options, s.goal.correct
    assert options[right] == "2" and len(options) >= 2
    wrong = next(i for i in range(len(options)) if i != right)
    out = s.try_move(Move.of("answer", wrong))
    assert not out.ok and "LIFO" in out.glitch and not s.done
    out = s.try_move(Move.of("answer", right))
    assert out.ok and out.done
    assert s.glitches == 1 and s.moves == 1 and s.stars() == 1      # (1 + 1) / 1 = 2.0x


# ---- BST deletion with two children ---------------------------------------------------
def heart() -> Puzzle:
    return puzzle(type="build", structure="bst", initial=[8, 3, 10, 1, 6, 4, 7], ops=["delete"],
                  goal={"kind": "script", "script": ["delete 3"]})


def test_two_children_delete_with_the_successor_finishes():
    s = PuzzleSession(heart())
    assert list(reference_moves(heart())) == [Move.of("delete", 3, 4)]
    out = s.try_move(Move.of("delete", 3, 4))
    assert out.done and s.glitches == 0 and s.stars() == 3


def test_two_children_delete_with_the_predecessor_also_finishes():
    s = PuzzleSession(heart())
    out = s.try_move(Move.of("delete", 3, 1))
    assert out.done and s.glitches == 0 and s.stars() == 3


def test_any_other_replacement_is_a_glitch_that_explains_the_successor():
    s = PuzzleSession(heart())
    out = s.try_move(Move.of("delete", 3, 7))
    assert not out.ok and "in-order successor" in out.glitch
    assert s.glitches == 1 and s.model.order("inorder") == [1, 3, 4, 6, 7, 8, 10]

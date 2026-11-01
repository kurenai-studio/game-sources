import pytest

from structura.models import (ArrayModel, BSTModel, IllegalMove, LinkedListModel, Move,
                              QueueModel, StackModel, complexity)


def is_bst(m: BSTModel) -> bool:
    v = m.values()
    return v == sorted(v) and len(set(v)) == len(v)


class TestBST:
    def test_insert_keeps_ordering(self):
        m = BSTModel([5, 3, 7, 1, 4, 6, 8])
        assert is_bst(m)
        assert m.order("preorder") == [5, 3, 1, 4, 7, 6, 8]

    def test_plan_appendix_case_seven_is_a_leaf(self):
        # The draft plan's sample Puzzle claimed 7 had two children. It doesn't.
        m = BSTModel([8, 3, 10, 1, 6, 14, 4, 7, 13])
        (move,) = m.parse("delete 7")
        assert move == Move.of("delete", 7, None)
        steps = m.apply(move)
        assert steps[-1].kind == "remove_leaf"
        assert m.values() == [1, 3, 4, 6, 8, 10, 13, 14]

    def test_delete_two_children_uses_successor(self):
        m = BSTModel([5, 3, 7, 1, 4, 6, 8])
        (move,) = m.parse("delete 5")
        assert move.args == (5, 6)
        m.apply(move)
        assert is_bst(m) and 5 not in m.values()

    def test_delete_two_children_accepts_predecessor(self):
        m = BSTModel([5, 3, 7, 1, 4, 6, 8])
        m.apply(Move.of("delete", 5, 4))
        assert is_bst(m)

    def test_delete_two_children_rejects_random_replacement(self):
        m = BSTModel([5, 3, 7, 1, 4, 6, 8])
        assert "successor" in m.why_illegal(Move.of("delete", 5, 8))

    def test_wrong_insert_slot_is_explained(self):
        m = BSTModel([8, 3, 10])
        reason = m.why_illegal(Move.of("insert", 6, 10, "left"))
        assert reason == "6 < 8, so 6 belongs in 8's left subtree."
        assert m.why_illegal(Move.of("insert", 6, 3, "left")) == "6 > 3, so 6 goes to the right of 3."
        assert m.why_illegal(Move.of("insert", 6, 3, "right")) is None

    def test_rotations_preserve_ordering(self):
        m = BSTModel([1, 2, 3])
        m.apply(Move.of("rotate_left", 1))
        assert m.order("preorder") == [2, 1, 3]
        m.apply(Move.of("rotate_right", 2))
        assert m.order("preorder") == [1, 2, 3]
        with pytest.raises(IllegalMove):
            m.apply(Move.of("rotate_right", 1))

    @pytest.mark.parametrize("values", [
        list(range(1, 8)), list(range(15, 0, -1)), [50, 20, 70, 10, 30, 25, 27, 26],
        [8, 3, 10, 1, 6, 14, 4, 7, 13],
    ])
    def test_avl_fix_balances(self, values):
        m = BSTModel(values)
        for move in m.avl_fix_moves():
            m.apply(move)
        assert m.is_avl() and is_bst(m)


def test_array_swap_insert_delete():
    a = ArrayModel([3, 1, 2])
    a.apply(Move.of("swap", 2, 0))
    assert a.values() == [2, 1, 3]
    a.apply(Move.of("insert", 1, 9))
    assert a.values() == [2, 9, 1, 3]
    a.apply(Move.of("delete", 0))
    assert a.values() == [9, 1, 3]
    assert a.why_illegal(Move.of("delete", 3))


def test_stack_is_lifo_queue_is_fifo():
    s, q = StackModel(), QueueModel()
    s.run(["push 1", "push 2", "push 3", "pop"])
    q.run(["enqueue 1", "enqueue 2", "enqueue 3", "dequeue"])
    assert s.out == [3] and s.top() == 2
    assert q.out == [1] and q.front() == 2
    assert StackModel().why_illegal(Move.of("pop"))


def test_linked_list_ops():
    ll = LinkedListModel([1, 2, 4])
    ll.apply(Move.of("insert_after", 1, 3))
    ll.apply(Move.of("insert_head", 0))
    assert ll.values() == [0, 1, 2, 3, 4]
    steps = ll.apply(Move.of("delete", 2))
    assert [s.kind for s in steps].count("walk") == 2
    assert ll.values() == [0, 1, 3, 4]


def test_complexity_picks_restrictive_structure_on_ties():
    lifo = {"add_back": 5, "remove_back": 5}
    assert complexity.best(["array", "linked_list", "stack", "queue"], lifo) == "stack"
    fifo = {"add_back": 5, "remove_front": 5}
    assert complexity.best(["array", "linked_list", "stack", "queue"], fifo) == "queue"
    lookup = {"access_index": 10, "add_back": 1}
    assert complexity.best(["array", "linked_list"], lookup) == "array"
    assert "O(n)" in complexity.explain("linked_list", "array", lookup)


ALL = ["array", "linked_list", "stack", "queue"]
SCENARIOS = [{"add_back": 10, "remove_back": 10}, {"add_back": 10, "remove_front": 10},
             {"access_index": 10, "add_back": 1}, {"add_front": 10, "remove_front": 5, "search": 1}]


@pytest.mark.parametrize("scenario", SCENARIOS)
def test_every_wrong_choice_names_an_operation_and_both_big_os(scenario):
    """Spec story 55: the explanation is Big-O reasoning, even when the wrong
    choice is just as fast, or can't do the job at all."""
    names = {"array": "Array", "linked_list": "Linked List", "stack": "Stack", "queue": "Queue"}
    right = complexity.best(ALL, scenario)
    for wrong in ALL:
        if wrong == right:
            continue
        text = complexity.explain(wrong, right, scenario)
        assert names[wrong] in text and names[right] in text, text
        op = next(op for op in scenario if complexity.OPERATIONS[op] in text)
        assert complexity.TABLE[right][op] in text, text
        assert "a Array" not in text, text


def test_explanations_use_an_before_array():
    assert "an Array" in complexity.explain("array", "stack", {"add_back": 5, "remove_back": 5})


def test_big_o_rows_cover_the_choices_and_mark_missing_operations():
    scenario = {"add_back": 10, "remove_front": 10}
    head, rows = complexity.table(["array", "queue"], scenario)
    assert head == ["add at the back", "remove from the front"]
    assert rows == [("Array", ["O(1)", "O(n)"]), ("Queue", ["O(1)", "O(1)"])]
    head, rows = complexity.table(["stack"], {"access_index": 1})
    assert rows == [("Stack", ["—"])], "a structure that can't do it at all"


def test_a_just_as_fast_choice_is_told_what_it_lets_you_misuse():
    text = complexity.explain("array", "stack", {"add_back": 10, "remove_back": 10})
    assert "remove from the front" in text, "an Array allows what a Stack forbids"

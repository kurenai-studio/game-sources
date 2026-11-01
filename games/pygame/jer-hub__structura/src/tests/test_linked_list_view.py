"""Linked-list-specific motion: arrows re-route on insert and delete, slots
follow the Puzzle's ops, and a "cur" marker walks the list. Shared effects are
in test_renderer_contract.py."""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame
import pytest

from structura.models import LinkedListModel, Move, Step
from structura.ui.renderers import make_renderer

pygame.init()
VIZ = pygame.Rect(0, 0, 820, 400)


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


def fresh(values=(1, 2, 3)):
    m = LinkedListModel(values)
    r = make_renderer("linked_list", VIZ)
    r.sync(m)
    run(r, 2)
    return m, r


def test_arrows_run_from_head_through_every_node_to_null():
    m, r = fresh()
    a, b, c = r.element_ids()
    assert r.arrows() == [("head", a, False), (a, b, False), (b, c, False), (c, None, False)]


def test_delete_bows_the_arrow_over_the_dropped_node_then_straightens():
    m, r = fresh()
    a, b, c = r.element_ids()
    m.apply(Move.of("delete", 1))
    r.sync(m)
    r.update(0.05)
    assert (a, c, True) in r.arrows(), "the previous node is relinked past the dropped one"
    run(r, 2)
    assert (a, c, False) in r.arrows()


def test_insert_after_reroutes_through_the_new_node():
    m, r = fresh()
    a, b, c = r.element_ids()
    m.apply(Move.of("insert_after", 0, 9))
    r.sync(m)
    new = r.eid_of(1)
    assert {(a, new, False), (new, b, False)} <= set(r.arrows())
    assert (a, b, False) not in r.arrows()


def test_insert_head_moves_the_head_pointer():
    m, r = fresh()
    a = r.eid_of(0)
    m.apply(Move.of("insert_head", 0))
    r.sync(m)
    assert r.arrows()[:2] == [("head", r.eid_of(0), False), (r.eid_of(0), a, False)]


def test_new_node_grows_in_place():
    m, r = fresh()
    m.apply(Move.of("insert_after", 0, 9))
    r.sync(m)
    new = r.eid_of(1)
    assert r.scale(new) < 0.5 and tuple(r.pos[new][:2]) == r.layout()[new]


def test_empty_list_head_points_at_null():
    _, r = fresh(())
    assert r.arrows() == [("head", None, False)]


@pytest.mark.parametrize("ops, slots", [
    ({"insert_head"}, {"head"}),
    ({"insert_after"}, {0, 1, 2}),
    ({"insert_head", "insert_after", "delete"}, {"head", 0, 1, 2}),
])
def test_slots_follow_the_puzzle_ops(ops, slots):
    m, r = fresh()
    r.ops, r.show_slots = ops, True
    assert {t.key for t in r.targets() if t.kind == "slot"} == slots


def test_slots_turn_into_moves_and_back():
    _, r = fresh()
    assert r.slot_move("head", 5) == Move.of("insert_head", 5)
    assert r.slot_move(1, 5) == Move.of("insert_after", 1, 5)
    assert r.slot_for(Move.of("insert_head", 5)) == "head"
    assert r.slot_for(Move.of("insert_after", 2, 5)) == 2
    assert r.slot_for(Move.of("delete", 0)) is None


def test_cur_marker_walks_to_the_node_of_each_walk_step():
    m, r = fresh()
    a, b, _ = r.element_ids()
    r.on_step(Step("walk", (a,)))
    run(r, 0.5)
    assert r.cursor == a and r.cursor_x == pytest.approx(r.center_of(0)[0], abs=1)
    r.on_step(Step("walk", (b,)))
    r.update(1 / 60)
    assert r.center_of(0)[0] < r.cursor_x < r.center_of(1)[0], "the marker glides, it doesn't jump"
    run(r, 0.5)
    assert r.cursor_x == pytest.approx(r.center_of(1)[0], abs=1)
    r.on_step(None)
    assert r.cursor is None


# ---- reading the board: node anatomy, pointers, insert badges ----------------------
def test_each_node_has_a_next_field_that_its_arrow_leaves_from():
    _, r = fresh()
    a, b, _ = r.element_ids()
    x, y, _ = r.pos[a]
    w = r.element_size()
    field = r.next_field(a)
    assert field.left >= x + w - 1, "the next field sits to the right of the value"
    assert field.collidepoint(r.arrow_start(a)), "the pointer arrow starts inside the next field"


def test_clicking_a_nodes_next_field_counts_as_clicking_the_node():
    _, r = fresh()
    a = r.eid_of(0)
    node = next(t.rect for t in r.targets() if t.kind == "node" and t.key == 0)
    assert node.collidepoint(r.next_field(a).center)


def test_insert_badges_sit_below_the_row_so_arrows_stay_visible():
    _, r = fresh()
    r.ops, r.show_slots = {"insert_head", "insert_after"}, True
    w = r.element_size()
    row_bottom = r.rect.centery + w / 2
    for t in r.slot_targets():
        assert r.badge_center(t.key)[1] > row_bottom


def test_slot_and_node_targets_never_overlap():
    _, r = fresh((1, 2, 3, 4, 5, 6, 7))
    r.ops, r.show_slots = {"insert_head", "insert_after", "delete"}, True
    targets = r.targets()
    nodes = [t.rect for t in targets if t.kind == "node"]
    for s in (t.rect for t in targets if t.kind == "slot"):
        assert s.collidelist(nodes) == -1


def test_seven_nodes_stay_readable():
    _, r = fresh((1, 2, 3, 4, 5, 6, 7))
    assert r.element_size() >= 48
    ids = r.element_ids()
    assert r.next_field(ids[-1]).right < r.null_box().left

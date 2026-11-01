"""Tree-specific layout and motion: in-order position sets x, depth sets y,
edges join parents to children, an insert walks its comparison path before
the new node appears. Shared effects are in test_renderer_contract.py."""
import math
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame

from structura.models import BSTModel, Move
from structura.ui.anim import StepPlayer
from structura.ui.renderers import make_renderer

pygame.init()
VIZ = pygame.Rect(0, 0, 820, 400)


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


def fresh(values=(8, 3, 10, 1, 6)):
    m = BSTModel(values)
    r = make_renderer("bst", VIZ)
    r.sync(m)
    run(r, 2)
    return m, r


def test_in_order_sets_x_and_depth_sets_y():
    _, r = fresh()
    xs = [r.center_of(v)[0] for v in [1, 3, 6, 8, 10]]
    assert xs == sorted(xs) and len(set(xs)) == 5
    y = {v: r.center_of(v)[1] for v in [1, 3, 6, 8, 10]}
    assert y[8] < y[3] == y[10] < y[1] == y[6]


def test_edges_join_every_parent_to_its_children():
    m, r = fresh()
    e = {m.nodes[c].value: m.nodes[p].value for p, c in r.edges()}
    assert e == {3: 8, 10: 8, 1: 3, 6: 3}


def test_each_empty_slot_sits_between_its_in_order_neighbours_below_its_parent():
    m, r = fresh()
    r.show_slots = True
    slots = {t.key: t.rect.center for t in r.targets() if t.kind == "slot"}
    assert set(slots) == set(m.empty_slots())
    x6, x8, x10 = r.center_of(6)[0], r.center_of(8)[0], r.center_of(10)[0]
    assert x6 < slots[(6, "right")][0] < x8
    assert x8 < slots[(10, "left")][0] < x10
    assert slots[(10, "left")][1] > r.center_of(10)[1]


def test_an_empty_tree_offers_only_the_root_slot():
    _, r = fresh(())
    r.show_slots = True
    assert [(t.kind, t.key) for t in r.targets()] == [("slot", (None, ""))]
    assert r.slot_move((None, ""), 8) == Move.of("insert", 8, None, "")


def test_slots_follow_the_puzzles_ops():
    _, r = fresh()
    r.show_slots, r.ops = True, {"visit"}
    assert not [t for t in r.targets() if t.kind == "slot"]


def test_slot_move_and_slot_for_agree():
    _, r = fresh()
    move = r.slot_move((10, "left"), 9)
    assert move == Move.of("insert", 9, 10, "left") and r.slot_for(move) == (10, "left")
    assert r.slot_for(Move.of("visit", 8)) is None


def test_an_insert_walks_its_comparison_path_before_the_new_node_appears():
    m, r = fresh()
    player = StepPlayer()
    player.play(m.apply(Move.of("insert", 7, 6, "right")))
    r.sync(m)
    new = r.eid_of(7)
    seen = []
    while player.busy:
        player.update(1 / 60)
        r.on_step(player.current)
        r.update(1 / 60)
        kind = player.current.kind if player.current else None
        seen.append((kind, r.scale(new)))
    compares = [s for k, s in seen if k in ("go_left", "go_right")]
    assert compares and all(s == 0 for s in compares), "hidden while the path is compared"
    assert any(s > 0 for k, s in seen if k == "place")
    run(r, 1)
    assert r.at_rest(new)


def test_the_starting_tree_appears_even_while_steps_play():
    """A Lesson opens its board and starts playing an insert in the same beat."""
    m = BSTModel([8])
    r = make_renderer("bst", VIZ)
    r.sync(m)
    steps = m.apply(Move.of("insert", 3, 8, "left"))
    r.sync(m)
    for _ in range(60):
        r.on_step(steps[0])
        r.update(1 / 60)
    assert r.at_rest(r.eid_of(8)) and r.scale(r.eid_of(3)) == 0


def play_steps(r, steps):
    """Play Steps the way a scene does, recording the keys on the board at each one."""
    player = StepPlayer()
    player.play(steps)
    seen = []
    while player.busy:
        player.update(1 / 60)
        r.on_step(player.current)
        r.update(1 / 60)
        if player.current:
            seen.append((player.current.kind, r.keys()))
    return seen


def stepped(values=(8, 3, 10, 1, 6, 4, 7)):
    """A renderer already being driven by a scene's StepPlayer."""
    m, r = fresh(values)
    r.on_step(None)
    r.update(1 / 60)
    return m, r


def test_a_delete_shows_the_old_tree_until_the_replace_step():
    m, r = stepped()
    steps = m.apply(Move.of("delete", 3, 4))
    r.sync(m)
    seen = play_steps(r, steps)
    before = [keys for kind, keys in seen if kind in ("go_left", "found", "find_successor")]
    assert before and all(keys == [1, 3, 4, 6, 7, 8, 10] for keys in before)
    assert seen[-1] == ("replace", [1, 4, 6, 7, 8, 10])


def test_a_leaf_stays_until_the_step_that_removes_it():
    m, r = stepped()
    steps = m.apply(Move.of("delete", 7, None))
    r.sync(m)
    seen = play_steps(r, steps)
    assert all(7 in keys for kind, keys in seen if kind != "remove_leaf")
    assert seen[-1] == ("remove_leaf", [1, 3, 4, 6, 8, 10])


def test_an_undo_of_a_hidden_insert_leaves_no_ghost():
    m, r = stepped()
    first = m.apply(Move.of("insert", 9, 10, "left"))[0]
    r.sync(m)
    r.on_step(first)
    r.update(1 / 60)
    m.apply(Move.of("delete", 9, None))
    r.sync(m)
    r.on_step(None)
    r.update(1 / 60)
    assert 9 not in r.keys() and not r.leaving()


def test_a_hidden_node_offers_no_slots_until_it_appears():
    m, r = fresh()
    r.show_slots = True
    first = m.apply(Move.of("insert", 7, 6, "right"))[0]
    r.sync(m)
    r.on_step(first)
    r.update(1 / 60)
    slots = {t.key for t in r.targets() if t.kind == "slot"}
    assert (7, "left") not in slots and (7, "right") not in slots


def test_a_rotation_swings_the_nodes_along_arcs():
    m, r = fresh((10, 20, 30))
    start = {v: r.center_of(v) for v in (10, 20, 30)}
    m.apply(Move.of("rotate_left", 10))
    r.sync(m)
    run(r, 0.2)
    for v in (10, 20):
        (x0, y0), (x, y) = start[v], r.center_of(v)
        assert y != y0, f"{v} changes level"
        assert abs(x - x0) > 4, f"{v} bows sideways instead of sliding straight up or down"
    assert (r.center_of(10)[0] - start[10][0]) * (r.center_of(20)[0] - start[20][0]) < 0, \
        "the node going down and the node going up swing apart"
    run(r, 1)
    assert all(r.at_rest(r.eid_of(v)) for v in (10, 20, 30))
    assert r.center_of(20)[1] < r.center_of(10)[1] == r.center_of(30)[1]


def test_an_insert_shifts_nodes_sideways_in_a_straight_line():
    m, r = fresh()
    y = {v: r.center_of(v)[1] for v in (1, 3, 6, 8, 10)}
    m.apply(Move.of("insert", 9, 10, "left"))
    r.sync(m)
    run(r, 0.2)
    assert {v: r.center_of(v)[1] for v in (1, 3, 6, 8, 10)} == y


def test_a_delete_lifts_the_child_branch_in_a_straight_line():
    m, r = fresh((10, 20, 30))
    start = {v: r.center_of(v) for v in (20, 30)}
    m.apply(m.delete_move(10))
    r.sync(m)
    run(r, 0.2)
    mid = {v: r.center_of(v) for v in (20, 30)}
    run(r, 1)
    for v in (20, 30):
        (x0, y0), (x, y), (x1, y1) = start[v], mid[v], r.center_of(v)
        assert y1 < y0, f"{v} rises a level"
        off_line = abs((x - x0) * (y1 - y0) - (y - y0) * (x1 - x0)) / math.hypot(x1 - x0, y1 - y0)
        assert off_line < 2, f"{v} bows off the straight path"


def test_a_hidden_node_has_no_edge_until_it_appears():
    m, r = fresh()
    first, *_, place = m.apply(Move.of("insert", 7, 6, "right"))
    r.sync(m)
    new = r.eid_of(7)
    r.on_step(first)
    r.update(1 / 60)
    assert all(new not in edge for edge in r.edges())
    r.on_step(place)
    r.update(1 / 60)
    assert any(new in edge for edge in r.edges())

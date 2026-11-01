"""The renderer contract: shared visual effects every structure renderer must
honour, run against every registered renderer. Structure-specific motion
(e.g. the array's swap arcs) is tested beside the structure, not here."""
import os
from typing import Callable, NamedTuple

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame
import pytest

from clicks import PROMISED_TARGETS
from structura.models import ArrayModel, BSTModel, LinkedListModel, Move, QueueModel, StackModel
from structura.ui.renderers import RENDERERS, make_renderer

pygame.init()
VIZ = pygame.Rect(0, 0, 800, 400)


class Sample(NamedTuple):
    model: Callable          # builds a model with at least 3 elements
    add: Move                # adds one element
    remove: Move             # removes one element


SAMPLES = {
    "array": Sample(lambda: ArrayModel([1, 2, 3, 4]), Move.of("insert", 1, 9), Move.of("delete", 1)),
    "linked_list": Sample(lambda: LinkedListModel([1, 2, 3, 4]), Move.of("insert_after", 0, 9),
                          Move.of("delete", 1)),
    "stack": Sample(lambda: StackModel([1, 2, 3, 4]), Move.of("push", 9), Move.of("pop")),
    "queue": Sample(lambda: QueueModel([1, 2, 3, 4]), Move.of("enqueue", 9), Move.of("dequeue")),
    "bst": Sample(lambda: BSTModel([8, 3, 10, 1, 6]), Move.of("insert", 9, 10, "left"),
                  Move.of("delete", 1, None)),
}


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


def fresh(structure):
    model = SAMPLES[structure].model()
    r = make_renderer(structure, VIZ)
    r.sync(model)
    run(r, 2)
    return model, r


def test_every_renderer_has_a_sample_and_click_contract():
    assert set(RENDERERS) == set(SAMPLES) == set(PROMISED_TARGETS)


def test_unknown_structure_is_refused():
    with pytest.raises(NotImplementedError):
        make_renderer("hash_map", VIZ)


@pytest.fixture(params=sorted(RENDERERS))
def structure(request):
    return request.param


def test_new_element_animates_in_then_rests(structure):
    model, r = fresh(structure)
    before = set(r.element_ids())
    model.apply(SAMPLES[structure].add)
    r.sync(model)
    (new,) = set(r.element_ids()) - before
    assert not r.at_rest(new)
    run(r, 1)
    assert r.at_rest(new) and r.scale(new) == pytest.approx(1, abs=0.02)


def test_removed_element_animates_out(structure):
    model, r = fresh(structure)
    before = set(r.element_ids())
    model.apply(SAMPLES[structure].remove)
    r.sync(model)
    (gone,) = before - set(r.element_ids())
    assert gone in r.leaving()
    run(r, 1)
    assert gone not in r.leaving()


def test_shake_moves_only_named_elements_and_settles(structure):
    _, r = fresh(structure)
    first, second = r.keys()[:2]
    r.shake([first])
    r.update(0.05)
    assert r.draw_offset(r.eid_of(first)) != (0, 0)
    assert r.draw_offset(r.eid_of(second)) == (0, 0)
    run(r, 1)
    assert r.draw_offset(r.eid_of(first)) == (0, 0)


def test_slow_speed_slows_element_motion_but_not_glitch_shakes(structure):
    model, r = fresh(structure)
    r.speed = 0.5
    before = set(r.element_ids())
    model.apply(SAMPLES[structure].add)
    r.sync(model)
    (new,) = set(r.element_ids()) - before
    first = r.keys()[0]
    r.shake([first])
    run(r, 0.6)
    assert not r.at_rest(new), "at 0.5x the new element is still growing in"
    assert r.draw_offset(r.eid_of(first)) == (0, 0), "a Glitch shake takes the same time at any speed"
    run(r, 0.6)
    assert r.at_rest(new)


def test_celebration_wave_runs_in_reading_order(structure):
    _, r = fresh(structure)
    r.celebrate()
    r.update(0.15)
    ids = r.element_ids()
    assert r.celebration(ids[0]) > r.celebration(ids[-1])
    run(r, 2)
    assert all(r.celebration(eid) == pytest.approx(1) for eid in ids)


def test_center_of_is_inside_the_element(structure):
    _, r = fresh(structure)
    nodes = {t.key: t.rect for t in r.targets() if t.kind == "node"}
    for key, rect in nodes.items():
        assert rect.collidepoint(r.center_of(key))
    key = r.keys()[0]
    assert r.center_of(key, offset=(5, 7)) == tuple(a + b for a, b in zip(r.center_of(key), (5, 7)))


@pytest.mark.parametrize("show_slots", [False, True])
def test_targets_match_the_click_contract(structure, show_slots):
    model, r = fresh(structure)
    r.show_slots = show_slots
    r.sync(model)
    got = {(t.kind, t.key) for t in r.targets()}
    assert got == PROMISED_TARGETS[structure](model, show_slots)


def test_draw_accepts_highlights_selection_hint_and_offset(structure):
    _, r = fresh(structure)
    r.show_slots = True
    surf = pygame.Surface(VIZ.size)
    ids = r.element_ids()
    r.celebrate()
    keys = r.keys()
    r.shake([keys[1]])
    r.update(0.1)
    r.draw(surf, {ids[0]: (255, 200, 0)}, selected=[keys[0]], hinted=[keys[1]], hint_slot=0, offset=(4, -3))
    r.draw(surf)

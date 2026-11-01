"""Stack-specific motion: pushes drop in from above, pops lift off to the Output
row, and undoing a pop takes the value back. Shared effects are in
test_renderer_contract.py."""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame
import pytest

from structura.models import Move, StackModel
from structura.ui.renderers import make_renderer

pygame.init()
VIZ = pygame.Rect(0, 0, 820, 400)


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


def fresh(values=(1, 2, 3)):
    m = StackModel(values)
    r = make_renderer("stack", VIZ)
    r.sync(m)
    run(r, 2)
    return m, r


def test_tower_grows_upward_from_the_bottom():
    _, r = fresh()
    ys = [r.layout()[eid][1] for eid in r.element_ids()]
    assert ys == sorted(ys, reverse=True), "bottom first, top last"


def test_push_drops_in_from_above():
    m, r = fresh()
    m.apply(Move.of("push", 9))
    r.sync(m)
    new = r.element_ids()[-1]
    rest = r.layout()[new]
    assert r.pos[new][1] < rest[1] - 40 and r.scale(new) == 1, "full size, starting above the tower"
    r.update(0.1)
    assert r.pos[new][1] < rest[1]
    run(r, 1)
    assert tuple(r.pos[new][:2]) == pytest.approx(rest)


def test_pop_lifts_off_to_the_output_row():
    m, r = fresh()
    top = r.element_ids()[-1]
    start_y = r.layout()[top][1]
    m.apply(Move.of("pop"))
    r.sync(m)
    assert r.output() == [], "still in flight"
    r.update(0.2)
    assert r.flyers[top].motion.at()[1] < start_y, "it lifts off the top"
    assert r.flyers[top].value == 3, "it carries its value"
    run(r, 1)
    assert [v for v, _ in r.output()] == [3]
    m.apply(Move.of("pop"))
    r.sync(m)
    run(r, 1)
    (v1, rect1), (v2, rect2) = r.output()
    assert (v1, v2) == (3, 2) and rect1.x < rect2.x, "Output reads left to right in removal order"


def test_undoing_a_pop_takes_the_value_back_from_the_output():
    m, r = fresh()
    before = m.copy()
    m.apply(Move.of("pop"))
    r.sync(m)
    run(r, 1)
    r.sync(before)                                 # what Undo hands the renderer
    assert r.output() == [] and len(r.element_ids()) == 3
    run(r, 1)
    assert all(r.at_rest(eid) for eid in r.element_ids())


def test_there_is_nothing_to_click_on_the_board():
    _, r = fresh()
    r.show_slots = True
    assert r.targets() == []


def test_undoing_a_pop_sends_the_value_back_from_its_output_box():
    m, r = fresh()
    before = m.copy()
    top = r.element_ids()[-1]
    m.apply(Move.of("pop"))
    r.sync(m)
    run(r, 1)
    (_, box), = r.output()
    r.sync(before)
    w = r.element_size()
    assert (r.pos[top][0] + w / 2, r.pos[top][1] + w / 2) == pytest.approx(box.center, abs=1)

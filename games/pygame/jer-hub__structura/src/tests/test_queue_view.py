"""Queue-specific motion: the line runs front to back, enqueues slide in at the
back, dequeues leave the front for the Output row and the rest move up, and
undoing a dequeue takes the value back. Shared effects are in
test_renderer_contract.py."""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame
import pytest

from structura.models import Move, QueueModel
from structura.ui.renderers import make_renderer

pygame.init()
VIZ = pygame.Rect(0, 0, 820, 400)


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


def fresh(values=(1, 2, 3)):
    m = QueueModel(values)
    r = make_renderer("queue", VIZ)
    r.sync(m)
    run(r, 2)
    return m, r


def test_the_line_runs_front_to_back_left_to_right_on_one_level():
    _, r = fresh()
    spots = [r.layout()[eid] for eid in r.element_ids()]
    xs, ys = [x for x, _ in spots], {y for _, y in spots}
    assert xs == sorted(xs) and len(ys) == 1


def test_enqueue_slides_in_at_the_back():
    m, r = fresh()
    m.apply(Move.of("enqueue", 9))
    r.sync(m)
    new = r.element_ids()[-1]
    rest = r.layout()[new]
    assert r.pos[new][0] > rest[0] + 40 and r.scale(new) == 1, "full size, starting behind the back"
    assert r.pos[new][1] == pytest.approx(rest[1]), "it slides along the line"
    r.update(0.1)
    assert r.pos[new][0] > rest[0]
    run(r, 1)
    assert tuple(r.pos[new][:2]) == pytest.approx(rest)


def test_dequeue_sends_the_front_to_the_output_row_and_the_rest_move_up():
    m, r = fresh()
    front, second = r.element_ids()[:2]
    front_spot = r.layout()[front]
    m.apply(Move.of("dequeue"))
    r.sync(m)
    assert r.output() == [], "still in flight"
    assert r.flyers[front].value == 1, "it carries its value"
    assert r.layout()[second] == pytest.approx(front_spot), "the next value becomes the front"
    run(r, 1)
    assert [v for v, _ in r.output()] == [1]
    m.apply(Move.of("dequeue"))
    r.sync(m)
    run(r, 1)
    (v1, rect1), (v2, rect2) = r.output()
    assert (v1, v2) == (1, 2) and rect1.x < rect2.x, "Output reads left to right in removal order"


def test_output_row_sits_below_the_line():
    m, r = fresh()
    m.apply(Move.of("dequeue"))
    r.sync(m)
    run(r, 1)
    (_, box), = r.output()
    w = r.element_size()
    line_bottom = r.layout()[r.element_ids()[0]][1] + w
    assert box.top > line_bottom


def test_undoing_a_dequeue_takes_the_value_back_from_the_output():
    m, r = fresh()
    before = m.copy()
    front = r.element_ids()[0]
    m.apply(Move.of("dequeue"))
    r.sync(m)
    run(r, 1)
    (_, box), = r.output()
    r.sync(before)                                 # what Undo hands the renderer
    assert r.output() == [] and len(r.element_ids()) == 3
    w = r.element_size()
    assert (r.pos[front][0] + w / 2, r.pos[front][1] + w / 2) == pytest.approx(box.center, abs=1), \
        "it leaves its Output box, rather than rejoining at the back"
    run(r, 1)
    assert all(r.at_rest(eid) for eid in r.element_ids())


def test_there_is_nothing_to_click_on_the_board():
    _, r = fresh()
    r.show_slots = True
    assert r.targets() == []


def test_draws_empty_and_full():
    surf = pygame.Surface(VIZ.size)
    for values in ((), (1, 2, 3, 4, 5, 6, 7)):
        _, r = fresh(values)
        r.draw(surf)

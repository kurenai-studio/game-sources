"""Animation behaviour. Visual-only: none of this may change game logic or
delay a scene change (the UI flow tests click straight through)."""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import random

import pygame
import pytest

from structura.models import ArrayModel, Move
from structura.ui import fx
from structura.ui.renderers.array import ArrayRenderer

pygame.init()
VIZ = pygame.Rect(0, 0, 800, 400)


def run(thing, seconds, step=1 / 60):
    for _ in range(int(seconds / step)):
        thing.update(step)


# ---- primitives -------------------------------------------------------------
@pytest.mark.parametrize("ease", [fx.ease_out_cubic, fx.ease_out_back, fx.ease_in_out_sine])
def test_easing_endpoints(ease):
    assert ease(0) == pytest.approx(0) and ease(1) == pytest.approx(1)


def test_ease_out_back_overshoots():
    assert max(fx.ease_out_back(t / 100) for t in range(101)) > 1.0


def test_tween_clamps_and_finishes():
    t = fx.Tween(0.5, delay=0.1)
    assert t.progress == 0
    t.update(0.1)
    assert t.progress == 0 and not t.done
    t.update(0.25)
    assert 0.4 < t.progress < 0.6
    t.update(5)
    assert t.progress == 1 and t.done


def test_shake_decays_to_rest():
    s = fx.Shake(0.4, amplitude=10)
    s.update(0.05)
    assert 0 < abs(s.offset()[0]) <= 10
    run(s, 0.5)
    assert s.offset() == (0, 0)


def test_particles_burst_then_vanish():
    p = fx.Particles(random.Random(1))
    p.burst((100, 100), 30, [(255, 0, 0)])
    assert len(p.items) == 30
    run(p, 3)
    assert p.items == []


def test_ripple_grows_then_ends():
    r = fx.Ripple((10, 10), (255, 255, 0), duration=0.5, radius=40)
    r.update(0.25)
    assert 0 < r.current_radius < 40
    r.update(1)
    assert r.done


# ---- array-specific motion (shared effects: test_renderer_contract.py) -------
def settled(r):
    run(r, 2)
    return {eid: tuple(r.pos[eid][:2]) for eid in r.model.ids()}


def test_swap_travels_on_opposite_arcs():
    m = ArrayModel([1, 2, 3, 4])
    r = ArrayRenderer(VIZ)
    r.sync(m)
    rest = settled(r)
    a, b = m.ids()[0], m.ids()[3]
    m.apply(Move.of("swap", 0, 3))
    r.sync(m)
    run(r, 0.2)
    ya, yb = r.pos[a][1], r.pos[b][1]
    base = rest[a][1]
    assert (ya - base) * (yb - base) < 0, "one goes over, one goes under"
    assert abs(ya - base) > 10
    after = settled(r)
    assert after[a] == pytest.approx(rest[b], abs=0.5) and after[b] == pytest.approx(rest[a], abs=0.5)


def test_inserted_cell_pops_in():
    m = ArrayModel([1, 3])
    r = ArrayRenderer(VIZ)
    r.sync(m)
    settled(r)
    m.apply(Move.of("insert", 1, 2))
    r.sync(m)
    new = m.ids()[1]
    assert r.scale(new) < 0.5, "it grows in place rather than flying in"
    assert tuple(r.pos[new][:2]) == r.layout()[new]


def test_shift_slides_straight():
    m = ArrayModel([1, 2, 3])
    r = ArrayRenderer(VIZ)
    r.sync(m)
    rest = settled(r)
    m.apply(Move.of("insert", 0, 0))
    r.sync(m)
    for _ in range(20):
        r.update(1 / 60)
        assert all(r.pos[eid][1] == pytest.approx(rest[eid][1]) for eid in rest), "a shift never leaves the row"
    assert all(r.pos[eid][0] > rest[eid][0] for eid in rest)


# ---- scenes -------------------------------------------------------------------
@pytest.fixture
def app(tmp_path):
    from structura.persistence.store import Store
    from structura.puzzles.schema import load_all
    from structura.ui.app import App

    a = App(Store(tmp_path / "t.db"), load_all(), screen=pygame.display.set_mode((1280, 720)),
            report_dir=tmp_path)
    a.sign_in(a.store.create_profile("Ana", "1", "python"))
    yield a
    a.store.close()


def test_scene_change_is_immediate_with_fade_in(app):
    zone = app.zones[0]
    app.open_zone(zone)
    assert type(app.scene).__name__ == "ZoneScene"
    assert app.fade.alpha > 0
    run(app, 1)
    assert app.fade.alpha == 0
    app.draw()


def test_puzzle_feedback_effects(app):
    from structura.puzzles.session import reference_moves

    zone = app.zones[0]
    bubble = zone.puzzles[2]
    app.open_puzzle(zone, bubble)
    scene = app.scene
    scene.selected = [0, 4]
    scene._swap()                                     # not what bubble sort does: Glitch
    scene.update(0.05)
    assert scene.renderer.draw_offset(scene.session.model.ids()[0]) != (0, 0)

    for m in reference_moves(bubble):
        scene.selected = list(m.args)
        scene._swap()
    assert scene.session.done
    assert scene.fx.particles.items, "finishing a Puzzle bursts confetti"
    app.draw()


def test_visit_ripples(app):
    zone = app.zones[0]
    app.open_puzzle(zone, zone.puzzles[0])
    app.scene._attempt(Move.of("visit", 0))
    assert app.scene.fx.ripples


def test_disruption_shakes_the_board(app):
    from structura.puzzles.session import PuzzleSession, reference_moves

    zone = app.zones[0]
    boss = zone.puzzles[-1]
    app.open_puzzle(zone, boss)
    scene = app.scene
    for m in reference_moves(boss):
        scene._attempt(m)
        if scene.board_shake.active:
            break
    assert scene.board_shake.active


def test_results_stars_pop_in_one_by_one(app):
    from structura.puzzles.session import PuzzleSession, reference_moves
    from structura.ui.scenes.results import ResultsScene

    zone = app.zones[0]
    p = zone.puzzles[0]
    s = PuzzleSession(p)
    for m in reference_moves(p):
        s.try_move(m)
    scene = ResultsScene(app, zone, p, s)
    assert scene.stars == 3 and scene.stars_revealed() == 0
    scene.update(0.6)
    assert 0 < scene.stars_revealed() < 3
    run(scene, 3)
    assert scene.stars_revealed() == 3
    app.go(scene)
    app.draw()

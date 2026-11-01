"""The Zone page: every card fits on screen without overlapping, the cards run
in unlock order down the columns under their Stage headings, long text is
shortened inside its card, and the card to play next is marked."""
import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")

import pygame
import pytest

from structura.persistence.store import Store
from structura.puzzles.schema import load_all
from structura.ui.app import SIZE, App
from structura.ui.scenes.zone import HEADING_H, ZoneScene

ZONES = load_all()


@pytest.fixture
def app(tmp_path):
    pygame.init()
    a = App(Store(tmp_path / "t.db"), ZONES, screen=pygame.display.set_mode(SIZE), report_dir=tmp_path)
    a.sign_in(a.store.create_profile("Ana", "1"))
    yield a
    a.store.close()


@pytest.mark.parametrize("zone", ZONES, ids=lambda z: z.id)
def test_every_card_fits_on_screen_without_overlapping(app, zone):
    scene = ZoneScene(app, zone)
    screen = pygame.Rect((0, 0), SIZE)
    rects = [b.rect for b in scene.buttons]
    for i, r in enumerate(rects):
        assert screen.contains(r), f"{scene.buttons[i].label} is off screen"
        assert r.collidelist(rects[:i] + rects[i + 1:]) == -1, f"{scene.buttons[i].label} overlaps"
    scene.draw(app.screen)


@pytest.mark.parametrize("zone", ZONES, ids=lambda z: z.id)
def test_cards_run_in_unlock_order_down_each_column_then_across(app, zone):
    scene = ZoneScene(app, zone)
    reading = sorted(cards(scene).values(), key=lambda c: (c.rect.x, c.rect.y))
    assert [c.label for c in reading] == ["Lesson"] + [p.title for p in zone.puzzles]


def columns(scene) -> int:
    return len({c.rect.x for c in cards(scene).values()})


def test_a_zone_uses_two_wide_columns_when_its_cards_fit(app):
    scene = ZoneScene(app, ZONES[1])
    assert columns(scene) == 2 and all(c.rect.w == 560 for c in cards(scene).values())


def test_a_zone_too_big_for_two_columns_uses_three(app):
    forest = next(z for z in ZONES if z.id == "z5")
    assert columns(ZoneScene(app, forest)) == 3


@pytest.mark.parametrize("zone", ZONES, ids=lambda z: z.id)
def test_each_stage_heading_sits_above_the_first_card_of_its_stage(app, zone):
    scene = ZoneScene(app, zone)
    for stage, (x, y) in scene.headings:
        first = next(p for p in zone.puzzles if p.stage == stage)
        card = cards(scene)[first.title].rect
        assert (card.x, card.y) == (x, y + HEADING_H)


@pytest.mark.parametrize("played", ["none", "some", "all"])
def test_every_card_draws_inside_its_own_box(app, played):
    """Long titles and unlock hints are shortened rather than run over the next card."""
    forest = next(z for z in ZONES if z.id == "z5")
    done = {"none": 0, "some": 7, "all": len(forest.puzzles)}[played]
    for p in forest.puzzles[:done]:
        app.store.record(app.profile.id, p.id, 2, 4, 0, 0)
    for card in cards(ZoneScene(app, forest)).values():
        surf = pygame.Surface(SIZE, pygame.SRCALPHA)
        card.draw(surf)
        surf.fill((0, 0, 0, 0), card.rect)
        assert surf.get_bounding_rect().w == 0, f"{card.label} spills out of its card"


def test_the_lesson_is_next_before_anything_is_played(app):
    zone = ZONES[1]
    assert ZoneScene(app, zone).next_up is zone.lesson


def test_the_first_unfinished_puzzle_is_next(app):
    zone = ZONES[1]
    app.store.record(app.profile.id, zone.puzzles[0].id, 3, 4, 0, 0)
    assert ZoneScene(app, zone).next_up is zone.puzzles[1]


def test_nothing_is_next_once_the_zone_is_cleared(app):
    zone = ZONES[1]
    for p in zone.puzzles:
        app.store.record(app.profile.id, p.id, 3, 4, 0, 0)
    assert ZoneScene(app, zone).next_up is None


def cards(scene):
    return {b.label: b for b in scene.buttons if b.label != "Zone Map"}


def test_each_puzzle_card_names_its_stage_and_puzzle_type(app):
    zone = ZONES[1]
    scene = ZoneScene(app, zone)
    for p in zone.puzzles:
        assert f"{p.stage.title()} · {p.type.title()}" in cards(scene)[p.title].subtitle


@pytest.mark.parametrize("zone", ZONES, ids=lambda z: z.id)
def test_a_locked_card_shows_the_whole_name_of_the_puzzle_that_unlocks_it(app, zone):
    """Shortening a narrow card may cut its Stage and Type, which the heading shows,
    but never the name of the Puzzle to finish first."""
    scene = cards(ZoneScene(app, zone))
    for before, p in zip(zone.puzzles, zone.puzzles[1:]):
        card = scene[p.title]
        assert not card.enabled and f"Finish {before.title} first" in card.shown_subtitle()


def test_a_next_card_is_found_by_puzzle_not_by_title(app):
    zone = ZONES[1]
    app.store.record(app.profile.id, zone.puzzles[0].id, 3, 4, 0, 0)
    marked = [label for label, card in cards(ZoneScene(app, zone)).items() if card.next_up]
    assert marked == [zone.puzzles[1].title]

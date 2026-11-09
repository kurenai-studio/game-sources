"""Small helpers: time formatting and the rotated-rectangle collisions every hit relies on."""

import pytest
from pygame.math import Vector2

from app.util.geometry import RotatedRect
from app.util.timefmt import fmt_time


@pytest.mark.parametrize("seconds, text", [
    (0, "00:00.0"),
    (9.99, "00:09.9"),          # truncated: never shows time not yet survived
    (65.34, "01:05.3"),
    (600, "10:00.0"),
])
def test_fmt_time(seconds, text):
    assert fmt_time(seconds) == text


def test_rect_touches_a_circle_only_when_they_overlap():
    rect = RotatedRect((0, 0), Vector2(1, 0), length=70, width=20)
    assert rect.collides_circle((0, 15), 6)            # 15 - 10 = 5 px from the edge
    assert not rect.collides_circle((0, 20), 6)        # 10 px away
    assert rect.collides_circle((40, 0), 6)            # just past the end
    assert not rect.collides_circle((45, 0), 6)


def test_rotation_is_taken_into_account():
    rect = RotatedRect((0, 0), Vector2(0, 1), length=70, width=20)     # standing upright
    assert rect.collides_circle((0, 30), 6)
    assert not rect.collides_circle((30, 0), 6)


def test_rect_against_rect():
    a = RotatedRect((0, 0), Vector2(1, 0), 70, 20)
    assert a.collides_rect(RotatedRect((50, 0), Vector2(1, 1), 70, 20))
    assert not a.collides_rect(RotatedRect((60, 0), Vector2(1, 1), 70, 20)), "passes 0.9 px clear of the corner"
    assert not a.collides_rect(RotatedRect((200, 0), Vector2(1, 1), 70, 20))

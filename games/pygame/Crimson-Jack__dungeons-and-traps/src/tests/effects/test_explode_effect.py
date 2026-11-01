import math
from unittest.mock import Mock

import pygame
import pytest

from src.effects.explode_effect import ExplodeEffect
from src.game_helper import GameHelper

COLOR = (255, 210, 0)
# Step of 150 x 150 keeps every ring of the smallest rectangle larger than zero
MAX_SIZE = (1800, 1800)
STEPS = 12
POSITION = (300, 200)
OTHER_POSITION = (500, 400)


@pytest.fixture
def draw_arc(monkeypatch):
    draw_arc = Mock()
    monkeypatch.setattr('src.effects.explode_effect.pygame.draw.arc', draw_arc)
    return draw_arc


@pytest.fixture
def surface():
    return pygame.Surface((1, 1))


@pytest.fixture
def explode_effect(surface):
    return ExplodeEffect(surface, STEPS, COLOR, MAX_SIZE)


def get_drawn_rings(explode_effect, draw_arc):
    draw_arc.reset_mock()
    explode_effect.draw()
    return [pygame.Rect(arc_call.args[2]) for arc_call in draw_arc.call_args_list]


def get_scaled_rings():
    return [(round(GameHelper.multiply_by_tile_size_ratio(inflate_x)),
             round(GameHelper.multiply_by_tile_size_ratio(inflate_y)),
             round(GameHelper.multiply_by_tile_size_ratio(line_width, 1)))
            for inflate_x, inflate_y, line_width in ExplodeEffect.RINGS]


def get_expected_rings(center, size):
    # Odd inflate values shift a ring center by one pixel, so rings are compared with the inflated rectangle
    explosion_rectangle = pygame.Rect((0, 0), size)
    explosion_rectangle.center = center
    return [explosion_rectangle.inflate(inflate_x, inflate_y)
            for inflate_x, inflate_y, line_width in get_scaled_rings()]


class TestDraw:
    def test_new_effect_draws_nothing(self, explode_effect, draw_arc):
        explode_effect.draw()

        draw_arc.assert_not_called()


class TestRun:
    def test_draws_full_circle_rings_with_color_and_line_widths(self, explode_effect, surface, draw_arc):
        explode_effect.run(POSITION)
        explode_effect.draw()

        assert draw_arc.call_count == 6
        for arc_call in draw_arc.call_args_list:
            surface_argument, color_argument, rectangle_argument, start_angle, stop_angle, line_width = arc_call.args
            assert surface_argument is surface
            assert color_argument == COLOR
            assert (start_angle, stop_angle) == (0, 2 * math.pi)
        line_widths = [arc_call.args[5] for arc_call in draw_arc.call_args_list]
        assert line_widths == [line_width for inflate_x, inflate_y, line_width in get_scaled_rings()]

    def test_rings_of_smallest_rectangle_are_centered_at_position(self, explode_effect, draw_arc):
        explode_effect.run(POSITION)

        assert get_drawn_rings(explode_effect, draw_arc) == get_expected_rings(POSITION, (150, 150))

    def test_restarts_from_smallest_rings_at_new_position(self, explode_effect, draw_arc):
        explode_effect.run(POSITION)
        explode_effect.update()
        explode_effect.update()

        explode_effect.run(OTHER_POSITION)

        assert get_drawn_rings(explode_effect, draw_arc) == get_expected_rings(OTHER_POSITION, (150, 150))


class TestUpdate:
    def test_grows_rings_by_one_step_keeping_center(self, explode_effect, draw_arc):
        explode_effect.run(POSITION)

        explode_effect.update()
        first_rings = get_drawn_rings(explode_effect, draw_arc)
        explode_effect.update()
        second_rings = get_drawn_rings(explode_effect, draw_arc)

        assert first_rings == get_expected_rings(POSITION, (300, 300))
        assert second_rings == get_expected_rings(POSITION, (450, 450))

    def test_hides_effect_after_reaching_maximum_size(self, explode_effect, draw_arc):
        explode_effect.run(POSITION)
        # Eleven updates grow the rectangle to the maximum size
        for update_number in range(11):
            explode_effect.update()
        assert get_drawn_rings(explode_effect, draw_arc) == get_expected_rings(POSITION, MAX_SIZE)

        explode_effect.update()
        draw_arc.reset_mock()
        explode_effect.draw()

        draw_arc.assert_not_called()

    def test_does_nothing_before_run(self, explode_effect, draw_arc):
        explode_effect.update()
        explode_effect.draw()

        draw_arc.assert_not_called()

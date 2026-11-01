from unittest.mock import Mock

import pygame
import pytest

from src.effects.blast_effect import BlastEffect

COLOR = (255, 255, 255)
MAX_SIZE = (80, 40)
STEPS = 4
CENTER = (40, 20)


@pytest.fixture
def draw_rect(monkeypatch):
    draw_rect = Mock()
    monkeypatch.setattr('src.effects.blast_effect.pygame.draw.rect', draw_rect)
    return draw_rect


@pytest.fixture
def surface():
    return pygame.Surface(MAX_SIZE)


@pytest.fixture
def blast_effect(surface):
    return BlastEffect(surface, STEPS, COLOR, MAX_SIZE)


def get_drawn_rectangle(blast_effect, draw_rect):
    draw_rect.reset_mock()
    blast_effect.draw()
    surface_argument, color_argument, rectangle_argument = draw_rect.call_args.args
    return pygame.Rect(rectangle_argument)


class TestDraw:
    def test_new_effect_draws_nothing(self, blast_effect, draw_rect):
        blast_effect.draw()

        draw_rect.assert_not_called()


class TestRun:
    def test_draws_smallest_rectangle_in_center_with_color(self, blast_effect, surface, draw_rect):
        blast_effect.run()
        blast_effect.draw()

        draw_rect.assert_called_once_with(surface, COLOR, pygame.Rect(30, 15, 20, 10))

    def test_restarts_from_smallest_rectangle(self, blast_effect, draw_rect):
        blast_effect.run()
        blast_effect.update()
        blast_effect.update()

        blast_effect.run()

        assert get_drawn_rectangle(blast_effect, draw_rect) == pygame.Rect(30, 15, 20, 10)


class TestUpdate:
    def test_grows_rectangle_by_one_step_keeping_center(self, blast_effect, draw_rect):
        blast_effect.run()

        blast_effect.update()
        first_rectangle = get_drawn_rectangle(blast_effect, draw_rect)
        blast_effect.update()
        second_rectangle = get_drawn_rectangle(blast_effect, draw_rect)

        assert first_rectangle.size == (40, 20)
        assert first_rectangle.center == CENTER
        assert second_rectangle.size == (60, 30)
        assert second_rectangle.center == CENTER

    def test_hides_effect_after_reaching_maximum_size(self, blast_effect, draw_rect):
        blast_effect.run()
        # Three updates grow the rectangle to the maximum size
        for update_number in range(3):
            blast_effect.update()
        assert get_drawn_rectangle(blast_effect, draw_rect).size == MAX_SIZE

        blast_effect.update()
        draw_rect.reset_mock()
        blast_effect.draw()

        draw_rect.assert_not_called()

    def test_does_nothing_before_run(self, blast_effect, draw_rect):
        blast_effect.update()
        blast_effect.draw()

        draw_rect.assert_not_called()

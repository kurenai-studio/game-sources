from unittest.mock import Mock

import pygame
import pytest

from src.effects.particle_spark import ParticleSpark

BASE_POSITION = [10, 20]
COLOR = (255, 0, 0)
RATIO = 2.0


@pytest.fixture
def draw_circle(monkeypatch):
    draw_circle = Mock()
    monkeypatch.setattr('src.effects.particle_spark.pygame.draw.circle', draw_circle)
    return draw_circle


def create_spark(monkeypatch, direction_x=1, direction_y=-1):
    directions = iter([direction_x, direction_y])
    monkeypatch.setattr('src.effects.particle_spark.random.randint', lambda start, end: next(directions))
    return ParticleSpark(list(BASE_POSITION), COLOR, RATIO)


def get_drawn_position_and_radius(spark, draw_circle):
    surface = pygame.Surface((1, 1))
    spark.draw(surface)
    surface_argument, color_argument, position_argument, radius_argument = draw_circle.call_args.args
    return list(position_argument), radius_argument


class TestDraw:
    def test_draws_circle_with_color_at_start_position_with_initial_radius(self, monkeypatch, draw_circle):
        spark = create_spark(monkeypatch)
        surface = pygame.Surface((1, 1))

        spark.draw(surface)

        draw_circle.assert_called_once_with(surface, COLOR, BASE_POSITION, int(ParticleSpark.INITIAL_RADIUS * RATIO))


class TestUpdatePosition:
    def test_shifts_start_position_by_map_offset(self, monkeypatch, draw_circle):
        spark = create_spark(monkeypatch)

        spark.update_position(pygame.math.Vector2(5, 7))

        position, radius = get_drawn_position_and_radius(spark, draw_circle)
        assert position == [15, 27]


class TestMove:
    def test_first_move_does_not_shift_spark(self, monkeypatch, draw_circle):
        spark = create_spark(monkeypatch)

        spark.move()

        position, radius = get_drawn_position_and_radius(spark, draw_circle)
        assert position == BASE_POSITION

    def test_each_move_is_longer_in_spark_direction(self, monkeypatch, draw_circle):
        spark = create_spark(monkeypatch, direction_x=1, direction_y=-1)

        for move_number in range(3):
            spark.move()

        # Moves by 0, 1 and 2 steps of the tile size ratio
        position, radius = get_drawn_position_and_radius(spark, draw_circle)
        assert position == [BASE_POSITION[0] + 3 * RATIO, BASE_POSITION[1] - 3 * RATIO]

    def test_shrinks_radius_with_each_move(self, monkeypatch, draw_circle):
        spark = create_spark(monkeypatch)

        # Four moves keep the radius away from a whole number, so rounding errors do not change int(radius)
        for move_number in range(4):
            spark.move()

        expected_radius = (ParticleSpark.INITIAL_RADIUS - 4 * ParticleSpark.RADIUS_REDUCTION_VALUE) * RATIO
        position, radius = get_drawn_position_and_radius(spark, draw_circle)
        assert radius == int(expected_radius)


class TestIsExpired:
    def test_new_spark_is_not_expired(self, monkeypatch):
        spark = create_spark(monkeypatch)

        assert not spark.is_expired()

    def test_not_expired_before_radius_shrinks_to_nothing(self, monkeypatch):
        spark = create_spark(monkeypatch)

        for move_number in range(34):
            spark.move()

        assert not spark.is_expired()

    def test_expired_after_radius_shrinks_to_nothing(self, monkeypatch):
        spark = create_spark(monkeypatch)

        for move_number in range(36):
            spark.move()

        assert spark.is_expired()

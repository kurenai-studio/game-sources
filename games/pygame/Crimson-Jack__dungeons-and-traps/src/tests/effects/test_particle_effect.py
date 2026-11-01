from unittest.mock import Mock

import pygame
import pytest

from src.effects.particle_effect import ParticleEffect

POSITION = (10, 20)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
RATIO = 0.5


def create_spark(is_expired=False):
    spark = Mock()
    spark.is_expired.return_value = is_expired
    return spark


@pytest.fixture
def particle_spark_class(monkeypatch):
    # Each created ParticleSpark is a new mock
    particle_spark_class = Mock(side_effect=lambda *arguments: create_spark())
    monkeypatch.setattr('src.effects.particle_effect.ParticleSpark', particle_spark_class)
    return particle_spark_class


def create_particle_effect_with_sparks(monkeypatch, expired_states, number_of_sparks=None, surface=None):
    sparks = [create_spark(is_expired) for is_expired in expired_states]
    # Each created ParticleSpark is the next prepared mock
    monkeypatch.setattr('src.effects.particle_effect.ParticleSpark', Mock(side_effect=sparks))

    if number_of_sparks is None:
        number_of_sparks = len(sparks)
    particle_effect = ParticleEffect(surface or pygame.Surface((1, 1)), POSITION, [RED], number_of_sparks, RATIO)
    for prepared_spark in sparks:
        particle_effect.add_spark()
    return particle_effect, sparks


class TestAddSpark:
    def test_creates_spark_at_position_with_color_and_ratio(self, particle_spark_class):
        particle_effect = ParticleEffect(pygame.Surface((1, 1)), POSITION, [RED], 1, RATIO)

        particle_effect.add_spark()

        particle_spark_class.assert_called_once_with(list(POSITION), RED, RATIO)

    def test_uses_colors_in_turn_and_wraps_around(self, particle_spark_class):
        particle_effect = ParticleEffect(pygame.Surface((1, 1)), POSITION, [RED, GREEN, BLUE], 4, RATIO)

        for spark_number in range(4):
            particle_effect.add_spark()

        used_colors = [spark_call.args[1] for spark_call in particle_spark_class.call_args_list]
        assert used_colors == [RED, GREEN, BLUE, RED]

    def test_creates_no_more_sparks_than_number_of_sparks(self, particle_spark_class):
        particle_effect = ParticleEffect(pygame.Surface((1, 1)), POSITION, [RED], 2, RATIO)

        for spark_number in range(3):
            particle_effect.add_spark()

        assert particle_spark_class.call_count == 2


class TestUpdate:
    def test_moves_active_sparks_with_map_offset(self, monkeypatch):
        particle_effect, (active_spark,) = create_particle_effect_with_sparks(monkeypatch, [False])
        map_offset = pygame.math.Vector2(5, 7)

        particle_effect.update(map_offset)

        active_spark.update_position.assert_called_once_with(map_offset)
        active_spark.move.assert_called_once()

    def test_removes_expired_sparks(self, monkeypatch):
        particle_effect, (expired_spark, active_spark) = create_particle_effect_with_sparks(monkeypatch,
                                                                                            [True, False])

        particle_effect.update(pygame.math.Vector2(0, 0))
        particle_effect.draw()

        expired_spark.update_position.assert_not_called()
        expired_spark.move.assert_not_called()
        expired_spark.draw.assert_not_called()
        active_spark.draw.assert_called_once()


class TestDraw:
    def test_draws_every_spark_on_surface(self, monkeypatch):
        surface = pygame.Surface((1, 1))
        particle_effect, sparks = create_particle_effect_with_sparks(monkeypatch, [False, False], surface=surface)

        particle_effect.draw()

        for spark in sparks:
            spark.draw.assert_called_once_with(surface)


class TestIsExpired:
    def test_not_expired_until_all_sparks_are_created(self, monkeypatch):
        particle_effect, sparks = create_particle_effect_with_sparks(monkeypatch, [True], number_of_sparks=2)

        assert not particle_effect.is_expired()

    def test_not_expired_while_any_spark_is_active(self, monkeypatch):
        particle_effect, sparks = create_particle_effect_with_sparks(monkeypatch, [True, False])

        assert not particle_effect.is_expired()

    def test_expired_when_all_sparks_are_created_and_expired(self, monkeypatch):
        particle_effect, sparks = create_particle_effect_with_sparks(monkeypatch, [True, True])

        assert particle_effect.is_expired()

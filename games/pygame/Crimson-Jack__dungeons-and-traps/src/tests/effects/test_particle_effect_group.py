from unittest.mock import Mock

import pygame

from src.effects.particle_effect_group import ParticleEffectGroup
from src.game_helper import GameHelper

POSITION = (10, 20)
NUMBER_OF_SPARKS = 12
COLORS = [(255, 0, 0), (0, 0, 255)]


def create_particle_effect(is_expired):
    particle_effect = Mock()
    particle_effect.is_expired.return_value = is_expired
    return particle_effect


def create_group_with_particle_effects(monkeypatch, expired_states):
    particle_effects = [create_particle_effect(is_expired) for is_expired in expired_states]
    # Each created ParticleEffect is the next prepared mock
    particle_effect_class = Mock(side_effect=particle_effects)
    monkeypatch.setattr('src.effects.particle_effect_group.ParticleEffect', particle_effect_class)

    particle_effect_group = ParticleEffectGroup(pygame.Surface((1, 1)))
    for prepared_particle_effect in particle_effects:
        particle_effect_group.add(POSITION, NUMBER_OF_SPARKS, COLORS)
    return particle_effect_group, particle_effects


class TestAdd:
    def test_creates_particle_effect_on_group_surface(self, monkeypatch):
        particle_effect_class = Mock()
        monkeypatch.setattr('src.effects.particle_effect_group.ParticleEffect', particle_effect_class)
        surface = pygame.Surface((1, 1))
        particle_effect_group = ParticleEffectGroup(surface)

        particle_effect_group.add(POSITION, NUMBER_OF_SPARKS, COLORS)

        particle_effect_class.assert_called_once_with(surface, POSITION, COLORS, NUMBER_OF_SPARKS,
                                                      GameHelper.get_tile_size_ratio())


class TestAddSpark:
    def test_adds_spark_to_every_particle_effect(self, monkeypatch):
        particle_effect_group, particle_effects = create_group_with_particle_effects(monkeypatch, [False, True])

        particle_effect_group.add_spark()

        for particle_effect in particle_effects:
            particle_effect.add_spark.assert_called_once()


class TestUpdate:
    def test_updates_only_active_particle_effects_with_map_offset(self, monkeypatch):
        particle_effect_group, (active_particle_effect, expired_particle_effect) = \
            create_group_with_particle_effects(monkeypatch, [False, True])
        map_offset = pygame.math.Vector2(5, 7)

        particle_effect_group.update(map_offset)

        active_particle_effect.update.assert_called_once_with(map_offset)
        expired_particle_effect.update.assert_not_called()


class TestDraw:
    def test_draws_every_particle_effect(self, monkeypatch):
        particle_effect_group, particle_effects = create_group_with_particle_effects(monkeypatch, [False, True])

        particle_effect_group.draw()

        for particle_effect in particle_effects:
            particle_effect.draw.assert_called_once()


class TestRemoveExpired:
    def test_removes_adjacent_expired_particle_effects_in_one_call(self, monkeypatch):
        particle_effect_group, (first_expired, second_expired, active) = \
            create_group_with_particle_effects(monkeypatch, [True, True, False])

        particle_effect_group.remove_expired()
        particle_effect_group.draw()

        first_expired.draw.assert_not_called()
        second_expired.draw.assert_not_called()
        active.draw.assert_called_once()

    def test_keeps_active_particle_effects_in_order(self, monkeypatch):
        particle_effect_group, (first_active, expired, second_active) = \
            create_group_with_particle_effects(monkeypatch, [False, True, False])
        draw_order = []
        first_active.draw.side_effect = lambda: draw_order.append(first_active)
        second_active.draw.side_effect = lambda: draw_order.append(second_active)

        particle_effect_group.remove_expired()
        particle_effect_group.draw()

        assert draw_order == [first_active, second_active]
        expired.draw.assert_not_called()

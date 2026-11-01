import pygame

from src.effects.particle_effect import ParticleEffect
from src.game_helper import GameHelper


class ParticleEffectGroup:
    """Holds the particle effects of a level and updates, draws and removes them together."""

    def __init__(self, game_surface: pygame.Surface) -> None:
        """
        Create an empty group of particle effects.

        :param game_surface: game surface the sparks are drawn on
        """
        self._game_surface = game_surface
        self._particle_effects = []

    def add(self, position: tuple[int, int], number_of_sparks: int, colors: list[tuple[int, int, int]]) -> None:
        """
        Add a new particle effect. Its sparks appear one by one with each add_spark() call.

        :param position: position on the map the sparks start from
        :param number_of_sparks: number of sparks the effect creates in total
        :param colors: colors of the sparks, used in turn
        """
        self._particle_effects.append(
            ParticleEffect(self._game_surface, position, colors, number_of_sparks, GameHelper.get_tile_size_ratio()))

    def add_spark(self) -> None:
        """Add the next spark to every particle effect that has not created all its sparks yet."""
        for particle_effect in self._particle_effects:
            particle_effect.add_spark()

    def update(self, map_offset: pygame.math.Vector2) -> None:
        """
        Move the sparks of the active particle effects.

        :param map_offset: camera offset of the map
        """
        for particle_effect in self._particle_effects:
            if not particle_effect.is_expired():
                particle_effect.update(map_offset)

    def draw(self) -> None:
        """Draw the sparks of all particle effects on the game surface."""
        for particle_effect in self._particle_effects:
            particle_effect.draw()

    def remove_expired(self) -> None:
        """Remove the particle effects that have created all their sparks and whose sparks have all expired."""
        remaining_particle_effects = []
        for particle_effect in self._particle_effects:
            if not particle_effect.is_expired():
                remaining_particle_effects.append(particle_effect)
        self._particle_effects = remaining_particle_effects

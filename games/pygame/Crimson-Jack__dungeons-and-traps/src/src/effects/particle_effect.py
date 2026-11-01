import pygame

from src.effects.particle_spark import ParticleSpark


class ParticleEffect:
    """Sparks flying out of one position, created one by one, with colors used in turn."""

    def __init__(self, game_surface: pygame.Surface, position: tuple[int, int], colors: list[tuple[int, int, int]],
                 number_of_sparks: int, ratio: float) -> None:
        """
        Create a particle effect without sparks; they are added with add_spark().

        :param game_surface: game surface the sparks are drawn on
        :param position: position on the map the sparks start from
        :param colors: colors of the sparks, used in turn
        :param number_of_sparks: number of sparks the effect creates in total
        :param ratio: ratio of the current tile size to the base tile size, used to scale the sparks
        """
        self._game_surface = game_surface
        self._position = position
        self._colors = colors
        self._sparks: list[ParticleSpark] = []
        self._max_number_of_sparks = number_of_sparks
        self._ratio = ratio

    def update(self, map_offset: pygame.math.Vector2) -> None:
        """
        Remove the expired sparks, then move the remaining ones.

        :param map_offset: camera offset of the map
        """
        if self._sparks:
            self._delete_expired_sparks()
            for spark in self._sparks:
                spark.update_position(map_offset)
                spark.move()

    def draw(self) -> None:
        """Draw the sparks on the game surface."""
        if self._sparks:
            for spark in self._sparks:
                spark.draw(self._game_surface)

    def add_spark(self) -> None:
        """Add the next spark, unless the effect has already created all its sparks."""
        if self._max_number_of_sparks > 0:
            spark_position = list(self._position)
            spark = ParticleSpark(spark_position, self._get_next_color(), self._ratio)
            self._sparks.append(spark)
            self._max_number_of_sparks -= 1

    def is_expired(self) -> bool:
        """
        Check whether the effect has created all its sparks and all of them have expired.

        :return: True if the effect has expired
        """
        is_expired = False

        if self._max_number_of_sparks == 0:
            sparks_copy = [spark for spark in self._sparks if not spark.is_expired()]
            if len(sparks_copy) == 0:
                is_expired = True

        return is_expired

    def _delete_expired_sparks(self) -> None:
        sparks_copy = [spark for spark in self._sparks if not spark.is_expired()]
        self._sparks = sparks_copy

    def _get_next_color(self) -> tuple[int, int, int]:
        # Move the color to the end of the list, so colors are used in turn
        next_color = self._colors.pop(0)
        self._colors.append(next_color)
        return next_color

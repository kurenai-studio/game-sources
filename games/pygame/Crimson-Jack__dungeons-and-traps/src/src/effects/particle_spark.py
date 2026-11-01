import random

import pygame


class ParticleSpark:
    """A single spark that flies in a random direction, speeds up and shrinks until it disappears."""

    # Radius of a new spark for the base tile size
    INITIAL_RADIUS = 7
    # Value the radius shrinks by with each move for the base tile size
    RADIUS_REDUCTION_VALUE = 0.2

    def __init__(self, base_position: list[int], color: tuple[int, int, int], ratio: float) -> None:
        """
        Create a spark at the start position with a random direction.

        :param base_position: position on the map the spark starts from
        :param color: color of the spark
        :param ratio: ratio of the current tile size to the base tile size, used to scale the spark
        """
        self._base_position = base_position
        self._color = color
        self._tile_size_ratio = ratio

        self._position: list[float] = list(self._base_position)
        self._radius = self.INITIAL_RADIUS * self._tile_size_ratio
        self._radius_reduction_value = self.RADIUS_REDUCTION_VALUE * self._tile_size_ratio
        self._counter = 0
        self._direction_x = random.randint(-1, 1)
        self._direction_y = random.randint(-1, 1)

    def update_position(self, map_offset: pygame.math.Vector2) -> None:
        """
        Set the position to the start position shifted by the camera offset; the movement is added by move().

        :param map_offset: camera offset of the map
        """
        self._position[0] = self._base_position[0] + map_offset.x
        self._position[1] = self._base_position[1] + map_offset.y

    def move(self) -> None:
        """Move the spark further in its direction and shrink it; each move is longer than the previous one."""
        self._position[0] += self._direction_x * self._counter * self._tile_size_ratio
        self._position[1] += self._direction_y * self._counter * self._tile_size_ratio
        self._radius -= self._radius_reduction_value
        self._counter += 1

    def draw(self, surface: pygame.Surface) -> None:
        """
        Draw the spark as a circle.

        :param surface: surface the spark is drawn on
        """
        pygame.draw.circle(surface, self._color, self._position, int(self._radius))

    def is_expired(self) -> bool:
        """
        Check whether the spark has shrunk to nothing.

        :return: True if the spark has expired
        """
        return self._radius <= 0

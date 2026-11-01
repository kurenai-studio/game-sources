from enum import IntEnum

import pygame


class Direction(IntEnum):
    RIGHT = 1
    LEFT = 2
    DOWN = 3
    UP = 4
    RIGHT_UP = 14
    RIGHT_DOWN = 13
    LEFT_UP = 24
    LEFT_DOWN = 23

    @classmethod
    def from_vector(cls, vector: pygame.Vector2) -> 'Direction':
        """
        Return the direction pointed by a non-zero movement vector.

        Only the signs of the vector components matter, so (2, -3) points the same way as (1, -1).

        :param vector: movement vector, must not be (0, 0)
        :return: direction matching the signs of the vector components
        :raises ValueError: if the vector is (0, 0)
        """
        if vector == (0, 0):
            raise ValueError('Zero vector has no direction')

        direction_by_vector_signs = {
            (1, 0): cls.RIGHT,
            (1, 1): cls.RIGHT_DOWN,
            (0, 1): cls.DOWN,
            (-1, 1): cls.LEFT_DOWN,
            (-1, 0): cls.LEFT,
            (-1, -1): cls.LEFT_UP,
            (0, -1): cls.UP,
            (1, -1): cls.RIGHT_UP,
        }
        sign_x = (vector.x > 0) - (vector.x < 0)
        sign_y = (vector.y > 0) - (vector.y < 0)
        return direction_by_vector_signs[(sign_x, sign_y)]

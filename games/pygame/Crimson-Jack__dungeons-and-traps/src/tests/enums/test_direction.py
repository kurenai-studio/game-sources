import pygame
import pytest

from src.enums.direction import Direction


class TestDirectionFromVector:
    @pytest.mark.parametrize('vector, expected_direction', [
        ((1, 0), Direction.RIGHT),
        ((1, 1), Direction.RIGHT_DOWN),
        ((0, 1), Direction.DOWN),
        ((-1, 1), Direction.LEFT_DOWN),
        ((-1, 0), Direction.LEFT),
        ((-1, -1), Direction.LEFT_UP),
        ((0, -1), Direction.UP),
        ((1, -1), Direction.RIGHT_UP),
    ])
    def test_returns_direction_for_unit_vector(self, vector, expected_direction):
        assert Direction.from_vector(pygame.Vector2(vector)) == expected_direction

    @pytest.mark.parametrize('vector, expected_direction', [
        ((2, -3), Direction.RIGHT_UP),
        ((0, 2), Direction.DOWN),
        ((-0.5, 0), Direction.LEFT),
    ])
    def test_uses_only_signs_of_vector_components(self, vector, expected_direction):
        assert Direction.from_vector(pygame.Vector2(vector)) == expected_direction

    def test_raises_value_error_for_zero_vector(self):
        with pytest.raises(ValueError, match='Zero vector'):
            Direction.from_vector(pygame.Vector2(0, 0))

import pygame

from src.bar import Bar
from src.sprites.moving_obstacle import MovingObstacle


def create_moving_obstacle(rect, bar_position, bar_width, bar_height):
    # Full constructor requires game objects, which are irrelevant for the culling rectangle
    moving_obstacle = object.__new__(MovingObstacle)
    moving_obstacle.rect = rect
    moving_obstacle.power_bar = Bar(position=bar_position, width=bar_width, height=bar_height, bar_colors=None)
    return moving_obstacle


class TestGetCullingRect:
    def test_covers_power_bar_above_obstacle(self):
        moving_obstacle = create_moving_obstacle(pygame.Rect(100, 100, 64, 64), (105, 84), 54, 12)
        assert moving_obstacle.get_culling_rect() == pygame.Rect(100, 84, 64, 80)

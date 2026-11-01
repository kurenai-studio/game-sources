import pygame
import pytest

from settings import Settings
from src.camera import Camera

GAME_SURFACE_SIZE = (100, 80)
# Map of 50 x 50 tiles shown on a game surface of 100 x 80 pixels
MAP_SIZE_IN_TILES = (50, 50)
MAP_SIZE_IN_PIXELS = 50 * Settings.TILE_SIZE
# Offset that keeps the point (1000, 1000) in the center of the game surface
CENTERED_OFFSET = pygame.math.Vector2(50 - 1000, 40 - 1000)


# Initialise and shut down Pygame around every test so that Vector2 behaves correctly.
@pytest.fixture(autouse=True)
def pygame_init():
    pygame.init()
    yield
    pygame.quit()


def create_camera():
    return Camera(GAME_SURFACE_SIZE, MAP_SIZE_IN_TILES)


class TestFollow:
    def test_new_camera_has_no_offset(self):
        assert create_camera().offset == pygame.math.Vector2(0, 0)

    def test_camera_target_is_centered(self):
        camera = create_camera()
        camera.follow((1000, 1000))
        assert camera.offset == CENTERED_OFFSET

    def test_map_is_aligned_to_top_left_near_top_left_edge(self):
        camera = create_camera()
        camera.follow((10, 10))
        assert camera.offset == pygame.math.Vector2(0, 0)

    def test_map_is_aligned_to_bottom_right_near_bottom_right_edge(self):
        camera = create_camera()
        camera.follow((MAP_SIZE_IN_PIXELS - 10, MAP_SIZE_IN_PIXELS - 10))
        assert camera.offset == pygame.math.Vector2(100 - MAP_SIZE_IN_PIXELS, 80 - MAP_SIZE_IN_PIXELS)

    def test_map_smaller_than_game_surface_does_not_scroll(self):
        camera = Camera((Settings.TILE_SIZE * 2, Settings.TILE_SIZE * 2), (1, 1))
        camera.follow((1000, 1000))
        assert camera.offset == pygame.math.Vector2(0, 0)


class TestShake:
    def test_offset_includes_shake(self):
        camera = create_camera()
        camera.follow((1000, 1000), pygame.math.Vector2(3, -2))
        assert camera.offset == CENTERED_OFFSET + pygame.math.Vector2(3, -2)

    def test_shake_lasts_one_frame(self):
        camera = create_camera()
        camera.follow((1000, 1000), pygame.math.Vector2(3, -2))
        camera.follow((1000, 1000))
        assert camera.offset == CENTERED_OFFSET

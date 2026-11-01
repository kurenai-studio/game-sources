from unittest.mock import MagicMock

import pygame
import pytest

from src.camera_group import CameraGroup
from src.sprites.custom_draw_sprite import CustomDrawSprite


# Initialise and shut down Pygame around every test so that Surface, Vector2 and Rect behave correctly.
@pytest.fixture(autouse=True)
def pygame_init():
    pygame.init()
    yield
    pygame.quit()


class RecordingSprite(CustomDrawSprite):
    def __init__(self, groups, rect, drawn_sprites):
        super().__init__(groups)
        self.rect = rect
        self.drawn_sprites = drawn_sprites

    def custom_draw(self, game_surface, offset):
        self.drawn_sprites.append(self)


class WideCullingRectSprite(RecordingSprite):
    def __init__(self, groups, rect, culling_rect, drawn_sprites):
        super().__init__(groups, rect, drawn_sprites)
        self.culling_rect = culling_rect

    def get_culling_rect(self):
        return self.culling_rect


def create_camera_group(game_surface=None):
    return CameraGroup(game_surface or pygame.Surface((100, 80)))


def no_offset():
    return pygame.math.Vector2(0, 0)


class TestCustomDraw:
    def test_sprite_inside_visible_area_is_drawn(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        sprite = RecordingSprite([camera_group], pygame.Rect(10, 10, 20, 20), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == [sprite]

    def test_sprite_outside_visible_area_is_not_drawn(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        RecordingSprite([camera_group], pygame.Rect(500, 500, 20, 20), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == []

    def test_only_visible_sprites_are_drawn(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        visible_sprite = RecordingSprite([camera_group], pygame.Rect(10, 10, 20, 20), drawn_sprites)
        RecordingSprite([camera_group], pygame.Rect(500, 500, 20, 20), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == [visible_sprite]

    def test_sprite_partially_inside_visible_area_is_drawn(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        sprite = RecordingSprite([camera_group], pygame.Rect(90, 70, 20, 20), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == [sprite]

    def test_sprite_touching_visible_area_edge_is_not_drawn(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        RecordingSprite([camera_group], pygame.Rect(100, 0, 20, 20), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == []

    def test_offset_moves_visible_area(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        sprite = RecordingSprite([camera_group], pygame.Rect(500, 500, 20, 20), drawn_sprites)
        camera_group.custom_draw(pygame.math.Vector2(-450, -450))
        assert drawn_sprites == [sprite]

    def test_offset_is_passed_to_custom_draw_sprite(self):
        camera_group = create_camera_group()
        sprite = RecordingSprite([camera_group], pygame.Rect(10, 10, 20, 20), [])
        sprite.custom_draw = MagicMock()
        offset = pygame.math.Vector2(-5, -5)
        camera_group.custom_draw(offset)
        assert sprite.custom_draw.call_args.args[1] == offset

    def test_custom_culling_rect_is_used_for_custom_draw_sprite(self):
        camera_group = create_camera_group()
        drawn_sprites = []
        sprite = WideCullingRectSprite([camera_group], pygame.Rect(10, 200, 20, 20),
                                       pygame.Rect(10, 50, 20, 170), drawn_sprites)
        camera_group.custom_draw(no_offset())
        assert drawn_sprites == [sprite]

    def test_plain_sprite_uses_its_rect(self):
        # Plain sprites are blitted directly on game_surface, so record the blit calls
        game_surface = MagicMock()
        game_surface.get_size.return_value = (100, 80)
        camera_group = create_camera_group(game_surface)
        visible_sprite = pygame.sprite.Sprite(camera_group)
        visible_sprite.image = pygame.Surface((20, 20))
        visible_sprite.rect = pygame.Rect(10, 10, 20, 20)
        hidden_sprite = pygame.sprite.Sprite(camera_group)
        hidden_sprite.image = pygame.Surface((20, 20))
        hidden_sprite.rect = pygame.Rect(500, 500, 20, 20)
        camera_group.custom_draw(no_offset())
        blitted_images = [call.args[0] for call in game_surface.blit.call_args_list]
        assert blitted_images == [visible_sprite.image]

    def test_plain_sprite_is_blitted_with_offset(self):
        game_surface = MagicMock()
        game_surface.get_size.return_value = (100, 80)
        camera_group = create_camera_group(game_surface)
        sprite = pygame.sprite.Sprite(camera_group)
        sprite.image = pygame.Surface((20, 20))
        sprite.rect = pygame.Rect(30, 30, 20, 20)
        camera_group.custom_draw(pygame.math.Vector2(-10, -20))
        assert game_surface.blit.call_args.args[1] == pygame.math.Vector2(20, 10)

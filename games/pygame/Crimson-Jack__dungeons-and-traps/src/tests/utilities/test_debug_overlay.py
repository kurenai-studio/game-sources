from unittest.mock import Mock

import pygame
import pytest

from settings import Settings
from src.sprites.bat_enemy import BatEnemy
from src.sprites.monster_enemy import MonsterEnemy
from src.sprites.player import Player
from src.utilities.debug import Debug
from src.utilities.debug_overlay import DebugOverlay

MAP_OFFSET = pygame.math.Vector2(-10, -20)


# Initialise and shut down Pygame around every test so that Surface, Vector2, Rect and fonts behave correctly.
@pytest.fixture(autouse=True)
def pygame_init():
    pygame.init()
    yield
    pygame.quit()


@pytest.fixture
def draw_rect(monkeypatch):
    draw_rect = Mock()
    monkeypatch.setattr('src.utilities.debug_overlay.pygame.draw.rect', draw_rect)
    return draw_rect


@pytest.fixture
def game_surface():
    return pygame.Surface((100, 80))


@pytest.fixture
def debug_overlay(game_surface):
    return DebugOverlay(game_surface)


def create_layer(sprites):
    return Mock(sprites=Mock(return_value=sprites))


def create_level_sprite_groups(bottom_background_sprites=(), bottom_sprites=(), middle_sprites=(), top_sprites=(),
                               the_highest_sprites=()):
    return Mock(
        bottom_background_layer=create_layer(list(bottom_background_sprites)),
        bottom_sprites_layer=create_layer(list(bottom_sprites)),
        middle_sprites_layer=create_layer(list(middle_sprites)),
        top_sprites_layer=create_layer(list(top_sprites)),
        the_highest_sprites_layer=create_layer(list(the_highest_sprites))
    )


def create_sprite(rect):
    sprite = pygame.sprite.Sprite()
    sprite.rect = rect
    return sprite


def create_enemy(enemy_class, rect, current_position_on_map, path):
    enemy = Mock(spec=enemy_class)
    enemy.rect = rect
    enemy.current_position_on_map = current_position_on_map
    enemy.path = path
    return enemy


def create_player(rect):
    player = Mock(spec=Player)
    player.rect = rect
    player.get_center_point.return_value = rect.center
    return player


def get_tile_rect(tile):
    tile_rect = pygame.Rect(tile[0] * Settings.TILE_SIZE, tile[1] * Settings.TILE_SIZE,
                            Settings.TILE_SIZE, Settings.TILE_SIZE)
    tile_rect.topleft += MAP_OFFSET
    return tile_rect


def get_drawn_rectangles(draw_rect):
    return [(call.args[1], pygame.Rect(call.args[2]), call.args[3]) for call in draw_rect.call_args_list]


class TestDraw:
    def test_draws_nothing_for_empty_level(self, debug_overlay, draw_rect):
        debug_overlay.draw(create_level_sprite_groups(), MAP_OFFSET)
        assert draw_rect.call_count == 0

    def test_draws_on_game_surface(self, debug_overlay, draw_rect, game_surface):
        sprite = create_sprite(pygame.Rect(10, 10, 20, 20))
        debug_overlay.draw(create_level_sprite_groups(bottom_background_sprites=[sprite]), MAP_OFFSET)
        assert draw_rect.call_args.args[0] is game_surface

    @pytest.mark.parametrize('layer_name', ['bottom_background_sprites', 'bottom_sprites', 'top_sprites',
                                            'the_highest_sprites'])
    def test_sprite_frame_has_main_grid_color(self, debug_overlay, draw_rect, layer_name):
        sprite = create_sprite(pygame.Rect(10, 10, 20, 20))
        debug_overlay.draw(create_level_sprite_groups(**{layer_name: [sprite]}), MAP_OFFSET)
        assert get_drawn_rectangles(draw_rect) == [(Debug().main_grid_color, pygame.Rect(0, -10, 20, 20), 1)]

    def test_middle_layer_sprite_frame_has_alternative_grid_color(self, debug_overlay, draw_rect):
        sprite = create_sprite(pygame.Rect(10, 10, 20, 20))
        debug_overlay.draw(create_level_sprite_groups(middle_sprites=[sprite]), MAP_OFFSET)
        assert get_drawn_rectangles(draw_rect) == [(Debug().alternative_grid_color, pygame.Rect(0, -10, 20, 20), 1)]

    def test_enemy_current_tile_and_path_are_drawn(self, debug_overlay, draw_rect):
        enemy_rect = pygame.Rect(Settings.TILE_SIZE, Settings.TILE_SIZE, Settings.TILE_SIZE, Settings.TILE_SIZE)
        enemy = create_enemy(MonsterEnemy, enemy_rect, [1, 1], [(2, 1), (3, 1)])
        debug_overlay.draw(create_level_sprite_groups(top_sprites=[enemy]), MAP_OFFSET)
        path_color = Debug().path_color
        assert get_drawn_rectangles(draw_rect)[1:] == [
            (path_color, get_tile_rect((1, 1)), 6),
            (path_color, get_tile_rect((2, 1)), 2),
            (path_color, get_tile_rect((3, 1)), 2)
        ]

    def test_enemy_without_position_and_path_has_only_frame(self, debug_overlay, draw_rect):
        enemy = create_enemy(BatEnemy, pygame.Rect(10, 10, 20, 20), None, [])
        debug_overlay.draw(create_level_sprite_groups(top_sprites=[enemy]), MAP_OFFSET)
        assert draw_rect.call_count == 1

    def test_player_tile_is_drawn(self, debug_overlay, draw_rect):
        player_rect = pygame.Rect(Settings.TILE_SIZE + 4, Settings.TILE_SIZE * 2 + 4, 20, 20)
        player = create_player(player_rect)
        debug_overlay.draw(create_level_sprite_groups(middle_sprites=[player]), MAP_OFFSET)
        assert get_drawn_rectangles(draw_rect)[1:] == [(Debug().text_color, get_tile_rect((1, 2)), 3)]

    def test_colors_are_read_on_each_draw(self, debug_overlay, draw_rect):
        sprite = create_sprite(pygame.Rect(10, 10, 20, 20))
        Debug().main_grid_color = 255, 0, 0
        debug_overlay.draw(create_level_sprite_groups(bottom_sprites=[sprite]), MAP_OFFSET)
        assert draw_rect.call_args.args[1] == (255, 0, 0)

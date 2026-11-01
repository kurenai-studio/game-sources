import pygame

from settings import Settings
from src.game_helper import GameHelper
from src.level_sprite_groups import LevelSpriteGroups
from src.sprites.bat_enemy import BatEnemy
from src.sprites.monster_enemy import MonsterEnemy
from src.sprites.octopus_enemy import OctopusEnemy
from src.sprites.player import Player
from src.utilities.debug import Debug


class DebugOverlay:
    """Debug drawing on top of a level: sprite frames, enemy paths and the tile of the player."""

    def __init__(self, game_surface: pygame.Surface) -> None:
        """
        Prepare the overlay drawn on the game surface.

        :param game_surface: surface the level is drawn on
        """
        self._game_surface = game_surface

        # Create debugger
        self._debugger = Debug()

    def draw(self, level_sprite_groups: LevelSpriteGroups, map_offset: pygame.math.Vector2) -> None:
        """
        Draw the frame of each sprite of the level, the paths of the enemies and the tile of the player.
        Colors are read from the debugger on each call, because they can be switched during the game.

        :param level_sprite_groups: sprite groups of the level
        :param map_offset: offset that moves map coordinates to game surface coordinates
        """
        layers_with_main_grid = (
            level_sprite_groups.bottom_background_layer,
            level_sprite_groups.bottom_sprites_layer,
            level_sprite_groups.top_sprites_layer,
            level_sprite_groups.the_highest_sprites_layer
        )
        for layer in layers_with_main_grid:
            for sprite in layer.sprites():
                self._draw_sprite_frame(sprite, self._debugger.main_grid_color, map_offset)
                self._draw_enemy_path(sprite, map_offset)

        for sprite in level_sprite_groups.middle_sprites_layer.sprites():
            self._draw_sprite_frame(sprite, self._debugger.alternative_grid_color, map_offset)
            self._draw_player_tile(sprite, map_offset)

    def _draw_sprite_frame(self, sprite: pygame.sprite.Sprite, color: tuple[int, int, int],
                           map_offset: pygame.math.Vector2) -> None:
        # Frame around the rectangle of the sprite
        frame_rect = pygame.rect.Rect(sprite.rect)
        frame_rect.topleft += map_offset
        pygame.draw.rect(self._game_surface, color, frame_rect, 1)

    def _draw_enemy_path(self, sprite: pygame.sprite.Sprite, map_offset: pygame.math.Vector2) -> None:
        # Current tile and path from the enemy to the player for monster, bat or octopus enemy
        if not isinstance(sprite, (MonsterEnemy, OctopusEnemy, BatEnemy)):
            return

        if sprite.current_position_on_map:
            self._draw_tile(sprite.current_position_on_map, self._debugger.path_color, 6, map_offset)
        if sprite.path:
            for path_item in sprite.path:
                self._draw_tile(path_item, self._debugger.path_color, 2, map_offset)

    def _draw_player_tile(self, sprite: pygame.sprite.Sprite, map_offset: pygame.math.Vector2) -> None:
        # Tile where the player is
        if not isinstance(sprite, Player):
            return

        player_tile = GameHelper.get_tile_by_point(sprite.get_center_point())
        self._draw_tile(player_tile, self._debugger.text_color, 3, map_offset)

    def _draw_tile(self, tile: tuple[int, int], color: tuple[int, int, int], border_width: int,
                   map_offset: pygame.math.Vector2) -> None:
        # Frame around the tile at the given map position
        tile_rect = pygame.rect.Rect(tile[0] * Settings.TILE_SIZE, tile[1] * Settings.TILE_SIZE,
                                     Settings.TILE_SIZE, Settings.TILE_SIZE)
        tile_rect.topleft += map_offset
        pygame.draw.rect(self._game_surface, color, tile_rect, border_width)

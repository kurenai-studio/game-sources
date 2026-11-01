import pygame

from src.camera_group import CameraGroup
from src.camera_group_with_y_sort import CameraGroupWithYSort


class LevelSpriteGroups:
    """Owns the sprite groups of a level: five visible layers drawn back to front and the functional groups."""

    def __init__(self, game_surface: pygame.Surface) -> None:
        """
        Create the empty visible and functional groups.

        :param game_surface: surface the visible groups draw on
        """
        # Set up visible groups
        self._bottom_background_layer = CameraGroup(game_surface)
        self._bottom_sprites_layer = CameraGroup(game_surface)
        self._middle_sprites_layer = CameraGroupWithYSort(game_surface)
        self._top_sprites_layer = CameraGroup(game_surface)
        self._the_highest_sprites_layer = CameraGroup(game_surface)

        # Set up functional groups
        self._exit_points = pygame.sprite.Group()
        self._obstacle_sprites = pygame.sprite.Group()
        self._moving_obstacle_sprites = pygame.sprite.Group()
        self._removable_obstacle_sprites = pygame.sprite.Group()
        self._passage_sprites = pygame.sprite.Group()
        self._teleport_sprites = pygame.sprite.Group()
        self._collectable_sprites = pygame.sprite.Group()
        self._enemy_sprites = pygame.sprite.Group()
        self._hostile_force_sprites = pygame.sprite.Group()

    @property
    def bottom_background_layer(self) -> CameraGroup:
        """Visible layer drawn first: ground tiles, exit point and check point."""
        return self._bottom_background_layer

    @property
    def bottom_sprites_layer(self) -> CameraGroup:
        """Visible layer above the background: collectables, fire flames, teleports, tombstones and eggs."""
        return self._bottom_sprites_layer

    @property
    def middle_sprites_layer(self) -> CameraGroupWithYSort:
        """Visible layer sorted by the y position for the depth effect: player, walls, stones and doors."""
        return self._middle_sprites_layer

    @property
    def top_sprites_layer(self) -> CameraGroup:
        """Visible layer above the player: most enemies."""
        return self._top_sprites_layer

    @property
    def the_highest_sprites_layer(self) -> CameraGroup:
        """Visible layer drawn last: the boss."""
        return self._the_highest_sprites_layer

    @property
    def exit_points(self) -> pygame.sprite.Group:
        """Exit points of the level."""
        return self._exit_points

    @property
    def obstacle_sprites(self) -> pygame.sprite.Group:
        """Sprites that block movement: walls, demolished walls and doors."""
        return self._obstacle_sprites

    @property
    def moving_obstacle_sprites(self) -> pygame.sprite.Group:
        """Stones the player can push."""
        return self._moving_obstacle_sprites

    @property
    def removable_obstacle_sprites(self) -> pygame.sprite.Group:
        """Demolished walls removed when all diamonds are collected on a level without an exit point."""
        return self._removable_obstacle_sprites

    @property
    def passage_sprites(self) -> pygame.sprite.Group:
        """Doors opened with keys."""
        return self._passage_sprites

    @property
    def teleport_sprites(self) -> pygame.sprite.Group:
        """Teleports of the level."""
        return self._teleport_sprites

    @property
    def collectable_sprites(self) -> pygame.sprite.Group:
        """Sprites the player collects: diamonds, keys, powerups, lighting spells, eggs and the check point."""
        return self._collectable_sprites

    @property
    def enemy_sprites(self) -> pygame.sprite.Group:
        """Enemies of the level."""
        return self._enemy_sprites

    @property
    def hostile_force_sprites(self) -> pygame.sprite.Group:
        """Sprites that hurt the player but are not enemies, such as fire flames."""
        return self._hostile_force_sprites

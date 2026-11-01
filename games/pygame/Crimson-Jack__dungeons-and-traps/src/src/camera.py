import pygame

from settings import Settings


class Camera:
    """Camera of a level: keeps a target point in the center of the game surface and stops at the map edges."""

    def __init__(self, game_surface_size: tuple[int, int], size_of_map: tuple[int, int]) -> None:
        """
        Prepare the camera for a map of the given size shown on a game surface of the given size.

        :param game_surface_size: size of the game surface in pixels
        :param size_of_map: map size in tiles
        """
        self._game_surface_width, self._game_surface_height = game_surface_size
        self._game_surface_half_width = self._game_surface_width // 2
        self._game_surface_half_height = self._game_surface_height // 2
        self._map_width = Settings.TILE_SIZE * size_of_map[0]
        self._map_height = Settings.TILE_SIZE * size_of_map[1]
        self._map_offset = pygame.math.Vector2()
        self._shake_offset = pygame.math.Vector2()

    @property
    def offset(self) -> pygame.math.Vector2:
        """Offset that moves map coordinates to game surface coordinates in the current frame, with the shake."""
        return self._map_offset + self._shake_offset

    def follow(self, camera_target: tuple[int, int], shake_offset: pygame.math.Vector2 | None = None) -> None:
        """
        Move the camera to the target and set the offset of the current frame.

        :param camera_target: point on the map the camera keeps in the center, e.g. the center of the player
        :param shake_offset: offset added for the current frame only, e.g. the tilt effect; no shake when None
        """
        self._set_map_offset(camera_target)

        # Shake of the current frame only; no shake when None
        self._shake_offset = shake_offset if shake_offset is not None else pygame.math.Vector2()

    def _set_map_offset(self, camera_target: tuple[int, int]) -> None:
        # Offset shifts map coordinates to game_surface coordinates so that the camera target stays centered
        target_x, target_y = camera_target

        # Scroll horizontally only when the map is wider than game_surface
        if self._map_width > self._game_surface_width:
            # Target near the left edge of the map - keep the map aligned to the left
            if target_x < self._game_surface_half_width:
                self._map_offset.x = 0
            # Target near the right edge of the map - keep the map aligned to the right
            elif self._map_width - target_x < self._game_surface_half_width:
                self._map_offset.x = self._game_surface_width - self._map_width
            # Otherwise center the view on the target
            else:
                self._map_offset.x = self._game_surface_half_width - target_x

        # Scroll vertically only when the map is taller than game_surface
        if self._map_height > self._game_surface_height:
            # Target near the top edge of the map - keep the map aligned to the top
            if target_y < self._game_surface_half_height:
                self._map_offset.y = 0
            # Target near the bottom edge of the map - keep the map aligned to the bottom
            elif self._map_height - target_y < self._game_surface_half_height:
                self._map_offset.y = self._game_surface_height - self._map_height
            # Otherwise center the view on the target
            else:
                self._map_offset.y = self._game_surface_half_height - target_y

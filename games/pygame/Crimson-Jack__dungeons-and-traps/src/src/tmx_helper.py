import pygame
import pytmx
from typing import Any

from settings import Settings
from src.game_helper import GameHelper
from src.sprite_costume import SpriteCostume


class TmxHelper:
    @staticmethod
    def get_data_map_by_layer(layer: pytmx.TiledObjectGroup, size_of_map: tuple[int, int], tile_width: int, tile_height: int) -> list[list[int]]:
        """
        Create and return data map based on layer.

        :param layer: group of tiled objects
        :param size_of_map: map size
        :param tile_width: tile width
        :param tile_height: tile height
        :return: data map
        """
        rows = list()
        for row_counter in range(0, size_of_map[1]):
            columns = list()
            for columns_counter in range(0, size_of_map[0]):
                columns.append(0)
            rows.append(columns)

        if layer is not None:
            for item in layer:
                tile_x = int(item.x // tile_width)
                tile_y = int(item.y // tile_height)
                rows[tile_y][tile_x] = 1

        return rows

    @staticmethod
    def get_tile_position(x: float, y: float, width: int, height: int, rotation: int=0) -> tuple[int, int]:
        """
        Get tile position, based on x, y coordinates and rotation.

        :param x: x coordinate
        :param y: y coordinate
        :param width: width
        :param height: height
        :param rotation: rotation
        :return: tile position
        """
        tile_x = int(x // width)
        tile_y = int(y // height)
        x = tile_x * Settings.TILE_SIZE
        y = tile_y * Settings.TILE_SIZE

        # According to the tmx format, rotation causes the object to move clockwise around the point 0, 0, which is the
        # bottom left corner of the tile.
        # Original baseline values do not correspond to visible on the map therefore they need to be corrected.
        if rotation == 90 or rotation == -270:
            y = y + Settings.TILE_SIZE
        elif rotation == 180 or rotation == -180:
            x = x - Settings.TILE_SIZE
            y = y + Settings.TILE_SIZE
        elif rotation == 270 or rotation == -90:
            x = x - Settings.TILE_SIZE

        return x, y

    @staticmethod
    def get_tiled_object_value(name: str, default: Any, tiled_object: pytmx.TiledObject,
                               layer: pytmx.TiledObjectGroup | None) -> Any:
        """
        Get the value from the tiled object.
        If not exists, get the value from the layer (group of tiled objects).
        Otherwise, return the default value.

        :param name: property name
        :param default: default value
        :param tiled_object: tiled object
        :param layer: group of tiled objects
        :return: property value
        """
        value = default

        if tiled_object is not None and tiled_object.properties.get(name) is not None:
            value = tiled_object.properties.get(name)
        elif layer is not None and layer.properties.get(name) is not None:
            value = layer.properties.get(name)

        return value

    @staticmethod
    def convert_to_sprite_costumes(tiled_map: pytmx.TiledMap, tiled_object: pytmx.TiledObject,
                                   size: tuple[float, float] | None = None) -> list[SpriteCostume]:
        """
        Convert each id and duration from the tiled object to a sprite costume object with an image and number of frames.
        Image can be scaled by size argument.
        Return a list of sprite costumes.

        :param tiled_map: tiled map
        :param tiled_object: tiled object
        :param size: image size
        :return: sprite costumes
        """
        sprite_costumes = list()
        tmx_frames = tiled_object.properties.get('frames')

        if tmx_frames is not None:
            for tmx_frame in tmx_frames:
                image = tiled_map.get_tile_image_by_gid(tmx_frame.gid)
                if size is not None:
                    image = pygame.transform.scale(image, size)
                sprite_costumes.append(
                    SpriteCostume(image, GameHelper.calculate_frames(tmx_frame.duration))
                )

        return sprite_costumes

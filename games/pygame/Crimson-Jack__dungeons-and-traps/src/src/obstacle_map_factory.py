import pytmx

from src.obstacle_map import ObstacleMap
from src.tmx_helper import TmxHelper


class ObstacleMapFactory:
    """Creates the obstacle map of a level from the blocking layers of a TMX map."""

    @staticmethod
    def create(tmx_data: pytmx.TiledMap) -> ObstacleMap:
        """
        Combine the visible obstacle, moving obstacle, removable obstacle and door layers into one obstacle map.

        :param tmx_data: loaded TMX map
        :return: obstacle map
        """
        size_of_map = (tmx_data.width, tmx_data.height)
        obstacle_layer_data = None
        moving_obstacle_layer_data = None
        removable_obstacle_layer_data = None
        door_layer_data = None

        for layer in tmx_data.visible_layers:
            if layer.name == 'obstacle':
                obstacle_layer_data = layer.data
            if layer.name == 'moving-obstacle':
                moving_obstacle_layer_data = layer.data
            if layer.name == 'removable-obstacle':
                removable_obstacle_layer_data = layer.data
            if layer.name == 'door':
                door_layer_data = TmxHelper.get_data_map_by_layer(layer, size_of_map,
                                                                   tmx_data.tilewidth, tmx_data.tileheight)

        return ObstacleMap([
            obstacle_layer_data,
            moving_obstacle_layer_data,
            removable_obstacle_layer_data,
            door_layer_data
        ])

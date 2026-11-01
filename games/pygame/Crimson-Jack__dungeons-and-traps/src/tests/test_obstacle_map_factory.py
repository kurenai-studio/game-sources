from unittest.mock import Mock

from src.obstacle_map_factory import ObstacleMapFactory
from src.tmx_helper import TmxHelper


def create_layer(name, data=None):
    layer = Mock(data=data)
    layer.name = name
    return layer


def create_tmx_data(visible_layers, width=2, height=2):
    tmx_data = Mock(width=width, height=height, tilewidth=16, tileheight=16)
    tmx_data.visible_layers = visible_layers
    return tmx_data


class TestObstacleMapFactory:
    def test_merges_obstacle_moving_obstacle_and_removable_obstacle_layers(self):
        tmx_data = create_tmx_data([
            create_layer('ground', [[1, 1], [1, 1]]),
            create_layer('obstacle', [[1, 0], [0, 0]]),
            create_layer('moving-obstacle', [[0, 1], [0, 0]]),
            create_layer('removable-obstacle', [[0, 0], [1, 0]]),
        ])

        obstacle_map = ObstacleMapFactory.create(tmx_data)

        assert obstacle_map.items == [[1, 1], [1, 0]]

    def test_converts_door_layer_with_map_and_tile_size(self, monkeypatch):
        door_layer = create_layer('door')
        get_data_map_by_layer = Mock(return_value=[[0, 0], [0, 1]])
        monkeypatch.setattr(TmxHelper, 'get_data_map_by_layer', get_data_map_by_layer)
        tmx_data = create_tmx_data([create_layer('obstacle', [[1, 0], [0, 0]]), door_layer], width=2, height=2)

        obstacle_map = ObstacleMapFactory.create(tmx_data)

        get_data_map_by_layer.assert_called_once_with(door_layer, (2, 2), 16, 16)
        assert obstacle_map.items == [[1, 0], [0, 1]]

    def test_skips_layers_that_are_not_visible(self):
        # Only visible_layers are combined, so a hidden obstacle layer is absent from the list
        tmx_data = create_tmx_data([create_layer('moving-obstacle', [[0, 0], [0, 1]])])

        obstacle_map = ObstacleMapFactory.create(tmx_data)

        assert obstacle_map.items == [[0, 0], [0, 1]]

    def test_map_without_blocking_layers_is_empty(self):
        tmx_data = create_tmx_data([create_layer('ground', [[1, 1], [1, 1]])])

        obstacle_map = ObstacleMapFactory.create(tmx_data)

        assert obstacle_map.items == []

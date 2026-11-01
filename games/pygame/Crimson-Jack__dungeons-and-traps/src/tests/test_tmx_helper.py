from unittest.mock import MagicMock

from settings import Settings
from src.tmx_helper import TmxHelper


class TestGetDataMapByLayer:
    def test_none_layer_returns_grid_of_zeros(self):
        result = TmxHelper.get_data_map_by_layer(None, (3, 2), 48, 48)
        assert result == [[0, 0, 0], [0, 0, 0]]

    def test_grid_dimensions_match_size_of_map(self):
        result = TmxHelper.get_data_map_by_layer(None, (4, 3), 48, 48)
        assert len(result) == 3
        assert all(len(row) == 4 for row in result)

    def test_layer_object_marks_correct_tile_with_one(self):
        mock_object = MagicMock()
        mock_object.x = 48
        mock_object.y = 96
        mock_layer = [mock_object]
        result = TmxHelper.get_data_map_by_layer(mock_layer, (5, 5), 48, 48)
        assert result[2][1] == 1

    def test_unmarked_tiles_remain_zero(self):
        mock_object = MagicMock()
        mock_object.x = 0
        mock_object.y = 0
        mock_layer = [mock_object]
        result = TmxHelper.get_data_map_by_layer(mock_layer, (3, 3), 48, 48)
        assert result[0][1] == 0
        assert result[1][0] == 0
        assert result[1][1] == 0

    def test_multiple_objects_mark_multiple_tiles(self):
        first_object = MagicMock()
        first_object.x = 0
        first_object.y = 0
        second_object = MagicMock()
        second_object.x = 48
        second_object.y = 48
        mock_layer = [first_object, second_object]
        result = TmxHelper.get_data_map_by_layer(mock_layer, (3, 3), 48, 48)
        assert result[0][0] == 1
        assert result[1][1] == 1


class TestGetTilePosition:
    TILE = Settings.TILE_SIZE

    def test_no_rotation_returns_tile_top_left(self):
        x, y = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE)
        assert (x, y) == (self.TILE * 2, self.TILE * 1)

    def test_rotation_90_shifts_y_by_tile_size(self):
        x, y = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=90)
        assert (x, y) == (self.TILE * 2, self.TILE * 2)

    def test_rotation_minus_270_same_as_90(self):
        result_90 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=90)
        result_minus_270 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=-270)
        assert result_90 == result_minus_270

    def test_rotation_180_shifts_x_left_and_y_down(self):
        x, y = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=180)
        assert (x, y) == (self.TILE * 1, self.TILE * 2)

    def test_rotation_minus_180_same_as_180(self):
        result_180 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=180)
        result_minus_180 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=-180)
        assert result_180 == result_minus_180

    def test_rotation_270_shifts_x_left(self):
        x, y = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=270)
        assert (x, y) == (self.TILE * 1, self.TILE * 1)

    def test_rotation_minus_90_same_as_270(self):
        result_270 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=270)
        result_minus_90 = TmxHelper.get_tile_position(self.TILE * 2, self.TILE * 1, self.TILE, self.TILE, rotation=-90)
        assert result_270 == result_minus_90


class TestGetTiledObjectValue:
    def test_returns_value_from_tiled_object_when_present(self):
        mock_object = MagicMock()
        mock_object.properties.get.return_value = 42
        result = TmxHelper.get_tiled_object_value('speed', 0, mock_object, None)
        assert result == 42

    def test_falls_back_to_layer_when_object_property_missing(self):
        mock_object = MagicMock()
        mock_object.properties.get.return_value = None
        mock_layer = MagicMock()
        mock_layer.properties.get.return_value = 99
        result = TmxHelper.get_tiled_object_value('speed', 0, mock_object, mock_layer)
        assert result == 99

    def test_returns_default_when_both_object_and_layer_missing(self):
        mock_object = MagicMock()
        mock_object.properties.get.return_value = None
        mock_layer = MagicMock()
        mock_layer.properties.get.return_value = None
        result = TmxHelper.get_tiled_object_value('speed', 5, mock_object, mock_layer)
        assert result == 5

    def test_returns_default_when_object_and_layer_are_none(self):
        result = TmxHelper.get_tiled_object_value('speed', 10, None, None)
        assert result == 10

    def test_object_value_takes_priority_over_layer_value(self):
        mock_object = MagicMock()
        mock_object.properties.get.return_value = 7
        mock_layer = MagicMock()
        mock_layer.properties.get.return_value = 99
        result = TmxHelper.get_tiled_object_value('speed', 0, mock_object, mock_layer)
        assert result == 7

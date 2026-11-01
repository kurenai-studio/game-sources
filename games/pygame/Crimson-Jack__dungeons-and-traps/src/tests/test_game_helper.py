import pygame
import pytest

from settings import Settings
from src.game_helper import GameHelper


class TestGetTileSizeRatio:
    def test_returns_tile_size_divided_by_base_tile_size(self):
        expected = Settings.TILE_SIZE / GameHelper.BASE_TILE_SIZE
        assert GameHelper.get_tile_size_ratio() == expected

    def test_returns_float(self):
        assert isinstance(GameHelper.get_tile_size_ratio(), float)


class TestMultiplyByTileSizeRatio:
    def test_multiplies_value_by_ratio(self):
        ratio = Settings.TILE_SIZE / GameHelper.BASE_TILE_SIZE
        assert GameHelper.multiply_by_tile_size_ratio(100.0) == pytest.approx(100.0 * ratio)

    def test_returns_minimum_when_result_is_below_minimum(self):
        result = GameHelper.multiply_by_tile_size_ratio(1.0, minimum=999.0)
        assert result == 999.0

    def test_returns_calculated_value_when_above_minimum(self):
        ratio = Settings.TILE_SIZE / GameHelper.BASE_TILE_SIZE
        result = GameHelper.multiply_by_tile_size_ratio(100.0, minimum=0.1)
        assert result == pytest.approx(100.0 * ratio)

    def test_minimum_none_does_not_affect_result(self):
        ratio = Settings.TILE_SIZE / GameHelper.BASE_TILE_SIZE
        result = GameHelper.multiply_by_tile_size_ratio(50.0, minimum=None)
        assert result == pytest.approx(50.0 * ratio)


class TestCalculateFrames:
    def test_one_second_equals_fps_frames(self):
        assert GameHelper.calculate_frames(1000) == Settings.FPS

    def test_half_second_equals_half_fps_frames(self):
        assert GameHelper.calculate_frames(500) == int(Settings.FPS * 0.5)

    def test_returns_integer(self):
        assert isinstance(GameHelper.calculate_frames(1000), int)

    def test_zero_milliseconds_returns_zero_frames(self):
        assert GameHelper.calculate_frames(0) == 0


class TestConvertStringToTuple:
    def test_converts_comma_separated_string(self):
        assert GameHelper.convert_string_to_tuple('1,2,3') == (1, 2, 3)

    def test_single_value(self):
        assert GameHelper.convert_string_to_tuple('5') == (5,)

    def test_custom_separator(self):
        assert GameHelper.convert_string_to_tuple('1|2|3', separator='|') == (1, 2, 3)

    def test_returns_tuple_of_integers(self):
        result = GameHelper.convert_string_to_tuple('10,20')
        assert isinstance(result, tuple)
        assert all(isinstance(value, int) for value in result)


class TestConvertStringToListOfTuples:
    def test_converts_pipe_separated_pairs(self):
        assert GameHelper.convert_string_to_list_of_tuples('1,2|3,4') == [(1, 2), (3, 4)]

    def test_single_pair(self):
        assert GameHelper.convert_string_to_list_of_tuples('5,6') == [(5, 6)]

    def test_custom_separator(self):
        assert GameHelper.convert_string_to_list_of_tuples('1,2;3,4', separator=';') == [(1, 2), (3, 4)]

    def test_returns_list_of_tuples(self):
        result = GameHelper.convert_string_to_list_of_tuples('1,2|3,4')
        assert isinstance(result, list)
        assert all(isinstance(item, tuple) for item in result)


class TestGetTileByPoint:
    def test_origin_returns_zero_tile(self):
        assert GameHelper.get_tile_by_point((0, 0)) == (0, 0)

    def test_exact_tile_boundary(self):
        assert GameHelper.get_tile_by_point((Settings.TILE_SIZE, Settings.TILE_SIZE)) == (1, 1)

    def test_point_inside_tile(self):
        assert GameHelper.get_tile_by_point((Settings.TILE_SIZE + 1, Settings.TILE_SIZE + 1)) == (1, 1)

    def test_point_at_tile_edge(self):
        assert GameHelper.get_tile_by_point((Settings.TILE_SIZE * 2 - 1, Settings.TILE_SIZE * 3 - 1)) == (1, 2)


class TestGetPointByTile:
    def test_zero_tile_returns_origin(self):
        assert GameHelper.get_point_by_tile((0, 0)) == (0, 0)

    def test_tile_one_one_returns_tile_size(self):
        assert GameHelper.get_point_by_tile((1, 1)) == (Settings.TILE_SIZE, Settings.TILE_SIZE)

    def test_tile_position_is_top_left_corner(self):
        tile_x, tile_y = 3, 5
        expected = (tile_x * Settings.TILE_SIZE, tile_y * Settings.TILE_SIZE)
        assert GameHelper.get_point_by_tile((tile_x, tile_y)) == expected


class TestGetTileCenterPosition:
    def test_zero_tile_center_is_half_tile_size(self):
        half = Settings.TILE_SIZE // 2
        assert GameHelper.get_tile_center_position((0, 0)) == (half, half)

    def test_center_is_offset_by_half_tile(self):
        tile_x, tile_y = 2, 3
        half = Settings.TILE_SIZE // 2
        expected = (tile_x * Settings.TILE_SIZE + half, tile_y * Settings.TILE_SIZE + half)
        assert GameHelper.get_tile_center_position((tile_x, tile_y)) == expected


class TestGetCollidedRectangle:
    def test_partial_overlap_returns_intersection(self):
        rect_one = pygame.Rect(0, 0, 20, 20)
        rect_two = pygame.Rect(10, 10, 20, 20)
        result = GameHelper.get_collided_rectangle(rect_one, rect_two)
        assert result == pygame.Rect(10, 10, 10, 10)

    def test_full_containment_returns_inner_rect(self):
        rect_one = pygame.Rect(0, 0, 40, 40)
        rect_two = pygame.Rect(10, 10, 10, 10)
        result = GameHelper.get_collided_rectangle(rect_one, rect_two)
        assert result == pygame.Rect(10, 10, 10, 10)

    def test_identical_rects_return_same_rect(self):
        rect = pygame.Rect(5, 5, 20, 20)
        result = GameHelper.get_collided_rectangle(rect, rect)
        assert result == rect


class TestCalculateVisibleArea:
    @pytest.fixture(autouse=True)
    def tile_and_header_size(self, monkeypatch):
        monkeypatch.setattr(Settings, 'TILE_SIZE', 10)
        monkeypatch.setattr(Settings, 'HEADER_HEIGHT', 50)

    def test_map_smaller_than_game_surface_is_centered_and_cut(self):
        visible_area_screen_position, visible_area_rect = GameHelper.calculate_visible_area((20, 10), (400, 300))

        # Map is 200 x 100 pixels: margins are (400 - 200) / 2 and (300 - 100) / 2
        assert visible_area_screen_position == [100, 100 + 50]
        assert visible_area_rect == pygame.Rect(0, 0, 200, 100)

    def test_map_larger_than_game_surface_fills_it(self):
        visible_area_screen_position, visible_area_rect = GameHelper.calculate_visible_area((60, 40), (400, 300))

        assert visible_area_screen_position == [0, 50]
        assert visible_area_rect == pygame.Rect(0, 0, 400, 300)

    def test_map_wider_but_lower_is_centered_and_cut_only_vertically(self):
        visible_area_screen_position, visible_area_rect = GameHelper.calculate_visible_area((60, 10), (400, 300))

        assert visible_area_screen_position == [0, 100 + 50]
        assert visible_area_rect == pygame.Rect(0, 0, 400, 100)

    def test_map_of_game_surface_size_is_neither_moved_nor_cut(self):
        visible_area_screen_position, visible_area_rect = GameHelper.calculate_visible_area((40, 30), (400, 300))

        assert visible_area_screen_position == [0, 50]
        assert visible_area_rect == pygame.Rect(0, 0, 400, 300)

import pytest

from src.obstacle_map import ObstacleMap
from src.search_path_algorithms.greedy_best_first_search import GreedyBestFirstSearch


def make_grid(width: int, height: int) -> list[tuple[int, int]]:
    return [(column, row) for column in range(width) for row in range(height)]


def free_tiles_from_layer(layer: list[list[int]]) -> set[tuple[int, int]]:
    tiles = set()
    for row_index, row in enumerate(layer):
        for column_index, value in enumerate(row):
            if value == 0:
                tiles.add((column_index, row_index))
    return tiles


class TestGreedyBestFirstSearchWhenPathExists:
    def test_is_end_reached_is_true(self):
        gbfs = GreedyBestFirstSearch()
        gbfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert gbfs.is_end_reached is True

    def test_returns_non_empty_path(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert len(result) > 0

    def test_path_contains_only_valid_tiles(self):
        gbfs = GreedyBestFirstSearch()
        tiles = make_grid(5, 5)
        tile_set = set(tiles)
        result = gbfs.search(tiles, (0, 0), (4, 4), max_distance=10)
        for tile in result:
            assert tile in tile_set

    def test_path_property_is_same_object_as_return_value(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert result is gbfs.path

    def test_direct_neighbor_path_contains_start_tile(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(5, 5), (0, 0), (1, 0), max_distance=10)
        assert gbfs.is_end_reached is True
        assert (0, 0) in result

    def test_linear_corridor_path_contains_all_intermediate_tiles(self):
        tiles = [(column, 0) for column in range(5)]
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(tiles, (0, 0), (4, 0), max_distance=10)
        assert gbfs.is_end_reached is True
        result_set = set(result)
        assert (0, 0) in result_set
        assert (1, 0) in result_set
        assert (2, 0) in result_set
        assert (3, 0) in result_set
        assert (4, 0) not in result_set  # end tile is not included in the path


class TestGreedyBestFirstSearchWhenNoPathExists:
    def test_is_end_reached_is_false(self):
        gbfs = GreedyBestFirstSearch()
        isolated_tiles = [(0, 0), (0, 1), (10, 10)]
        gbfs.search(isolated_tiles, (0, 0), (10, 10))
        assert gbfs.is_end_reached is False

    def test_returns_empty_list(self):
        gbfs = GreedyBestFirstSearch()
        isolated_tiles = [(0, 0), (0, 1), (10, 10)]
        result = gbfs.search(isolated_tiles, (0, 0), (10, 10))
        assert result == []

    def test_max_distance_blocks_reachable_but_distant_end(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(20, 20), (0, 0), (15, 15), max_distance=5)
        assert gbfs.is_end_reached is False
        assert result == []


class TestGreedyBestFirstSearchWithMaxDistanceNone:
    def test_none_max_distance_reaches_end_beyond_previous_default(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(20, 20), (0, 0), (15, 15), max_distance=None)
        assert gbfs.is_end_reached is True
        assert len(result) > 0

    def test_omitting_max_distance_defaults_to_unlimited(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(20, 20), (0, 0), (15, 15))
        assert gbfs.is_end_reached is True
        assert len(result) > 0


class TestGreedyBestFirstSearchStartEqualsEnd:
    def test_is_end_reached_is_true(self):
        gbfs = GreedyBestFirstSearch()
        gbfs.search(make_grid(5, 5), (2, 2), (2, 2))
        assert gbfs.is_end_reached is True

    def test_returns_empty_path(self):
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(make_grid(5, 5), (2, 2), (2, 2))
        assert result == []


class TestGreedyBestFirstSearchStateReset:
    def test_second_search_clears_path_from_first_search(self):
        gbfs = GreedyBestFirstSearch()
        gbfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert len(gbfs.path) > 0
        gbfs.search(make_grid(5, 5), (0, 0), (99, 99))
        assert gbfs.path == []

    def test_second_search_clears_is_end_reached_from_first_search(self):
        gbfs = GreedyBestFirstSearch()
        gbfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert gbfs.is_end_reached is True
        gbfs.search(make_grid(5, 5), (0, 0), (99, 99))
        assert gbfs.is_end_reached is False


class TestGreedyBestFirstSearchWithObstacleMapRegionCheck:
    def test_different_regions_returns_empty_path_without_searching(self):
        layer = [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = free_tiles_from_layer(layer)
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert result == []
        assert gbfs.is_end_reached is False

    def test_same_region_search_still_finds_path(self):
        layer = [
            [0, 0, 0],
            [0, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = free_tiles_from_layer(layer)
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert gbfs.is_end_reached is True
        assert len(result) > 0

    def test_blocked_start_tile_does_not_skip_search(self):
        layer = [
            [1, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = {(0, 0), (1, 0), (2, 0)}
        gbfs = GreedyBestFirstSearch()
        result = gbfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert gbfs.is_end_reached is True
        assert len(result) > 0

    def test_early_out_clears_stale_state_from_previous_successful_search(self):
        connected_layer = [[0, 0, 0]]
        connected_obstacle_map = ObstacleMap([connected_layer])
        gbfs = GreedyBestFirstSearch()
        gbfs.search(free_tiles_from_layer(connected_layer), (0, 0), (2, 0), max_distance=10,
                    obstacle_map=connected_obstacle_map)
        assert gbfs.is_end_reached is True

        split_layer = [[0, 1, 0]]
        split_obstacle_map = ObstacleMap([split_layer])
        gbfs.search({(0, 0), (2, 0)}, (0, 0), (2, 0), max_distance=10, obstacle_map=split_obstacle_map)
        assert gbfs.is_end_reached is False
        assert gbfs.path == []


class TestGreedyBestFirstSearchHeuristic:
    def test_same_tile_returns_zero(self):
        assert GreedyBestFirstSearch.heuristic((3, 4), (3, 4)) == 0.0

    def test_horizontal_distance(self):
        assert GreedyBestFirstSearch.heuristic((0, 0), (3, 0)) == pytest.approx(3.0)

    def test_vertical_distance(self):
        assert GreedyBestFirstSearch.heuristic((0, 0), (0, 4)) == pytest.approx(4.0)

    def test_diagonal_distance(self):
        assert GreedyBestFirstSearch.heuristic((0, 0), (3, 4)) == pytest.approx(5.0)

    def test_is_symmetric(self):
        assert GreedyBestFirstSearch.heuristic((1, 2), (5, 6)) == pytest.approx(
            GreedyBestFirstSearch.heuristic((5, 6), (1, 2))
        )

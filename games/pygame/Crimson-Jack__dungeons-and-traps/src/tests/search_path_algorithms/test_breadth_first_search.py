from src.obstacle_map import ObstacleMap
from src.search_path_algorithms.breadth_first_search import BreadthFirstSearch


def make_grid(width: int, height: int) -> list[tuple[int, int]]:
    return [(column, row) for column in range(width) for row in range(height)]


def free_tiles_from_layer(layer: list[list[int]]) -> set[tuple[int, int]]:
    tiles = set()
    for row_index, row in enumerate(layer):
        for column_index, value in enumerate(row):
            if value == 0:
                tiles.add((column_index, row_index))
    return tiles


class TestBreadthFirstSearchWhenPathExists:
    def test_is_end_reached_is_true(self):
        bfs = BreadthFirstSearch()
        bfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert bfs.is_end_reached is True

    def test_returns_non_empty_path(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert len(result) > 0

    def test_path_contains_only_valid_tiles(self):
        bfs = BreadthFirstSearch()
        tiles = make_grid(5, 5)
        tile_set = set(tiles)
        result = bfs.search(tiles, (0, 0), (4, 4), max_distance=10)
        for tile in result:
            assert tile in tile_set

    def test_path_property_is_same_object_as_return_value(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert result is bfs.path

    def test_direct_neighbor_path_contains_start_tile(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(5, 5), (0, 0), (1, 0), max_distance=10)
        assert bfs.is_end_reached is True
        assert (0, 0) in result

    def test_linear_corridor_path_contains_all_intermediate_tiles(self):
        # Corridor: (0,0)-(1,0)-(2,0)-(3,0)-(4,0)
        tiles = [(column, 0) for column in range(5)]
        bfs = BreadthFirstSearch()
        result = bfs.search(tiles, (0, 0), (4, 0), max_distance=10)
        assert bfs.is_end_reached is True
        result_set = set(result)
        assert (0, 0) in result_set
        assert (1, 0) in result_set
        assert (2, 0) in result_set
        assert (3, 0) in result_set
        assert (4, 0) not in result_set  # end tile is not included in the path


class TestBreadthFirstSearchWhenNoPathExists:
    def test_is_end_reached_is_false(self):
        bfs = BreadthFirstSearch()
        isolated_tiles = [(0, 0), (0, 1), (10, 10)]
        bfs.search(isolated_tiles, (0, 0), (10, 10))
        assert bfs.is_end_reached is False

    def test_returns_empty_list(self):
        bfs = BreadthFirstSearch()
        isolated_tiles = [(0, 0), (0, 1), (10, 10)]
        result = bfs.search(isolated_tiles, (0, 0), (10, 10))
        assert result == []

    def test_max_distance_blocks_reachable_but_distant_end(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(20, 20), (0, 0), (15, 15), max_distance=5)
        assert bfs.is_end_reached is False
        assert result == []


class TestBreadthFirstSearchWithMaxDistanceNone:
    def test_none_max_distance_reaches_end_beyond_previous_default(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(20, 20), (0, 0), (15, 15), max_distance=None)
        assert bfs.is_end_reached is True
        assert len(result) > 0

    def test_omitting_max_distance_defaults_to_unlimited(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(20, 20), (0, 0), (15, 15))
        assert bfs.is_end_reached is True
        assert len(result) > 0


class TestBreadthFirstSearchStartEqualsEnd:
    def test_is_end_reached_is_true(self):
        bfs = BreadthFirstSearch()
        bfs.search(make_grid(5, 5), (2, 2), (2, 2))
        assert bfs.is_end_reached is True

    def test_returns_empty_path(self):
        bfs = BreadthFirstSearch()
        result = bfs.search(make_grid(5, 5), (2, 2), (2, 2))
        assert result == []


class TestBreadthFirstSearchStateReset:
    def test_second_search_clears_path_from_first_search(self):
        bfs = BreadthFirstSearch()
        bfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert len(bfs.path) > 0
        bfs.search(make_grid(5, 5), (0, 0), (99, 99))
        assert bfs.path == []

    def test_second_search_clears_is_end_reached_from_first_search(self):
        bfs = BreadthFirstSearch()
        bfs.search(make_grid(5, 5), (0, 0), (4, 4), max_distance=10)
        assert bfs.is_end_reached is True
        bfs.search(make_grid(5, 5), (0, 0), (99, 99))
        assert bfs.is_end_reached is False


class TestBreadthFirstSearchWithObstacleMapRegionCheck:
    def test_different_regions_returns_empty_path_without_searching(self):
        layer = [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = free_tiles_from_layer(layer)
        bfs = BreadthFirstSearch()
        result = bfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert result == []
        assert bfs.is_end_reached is False

    def test_same_region_search_still_finds_path(self):
        layer = [
            [0, 0, 0],
            [0, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = free_tiles_from_layer(layer)
        bfs = BreadthFirstSearch()
        result = bfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert bfs.is_end_reached is True
        assert len(result) > 0

    def test_blocked_start_tile_does_not_skip_search(self):
        layer = [
            [1, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        all_tiles = {(0, 0), (1, 0), (2, 0)}
        bfs = BreadthFirstSearch()
        result = bfs.search(all_tiles, (0, 0), (2, 0), max_distance=10, obstacle_map=obstacle_map)
        assert bfs.is_end_reached is True
        assert len(result) > 0

    def test_early_out_clears_stale_state_from_previous_successful_search(self):
        connected_layer = [[0, 0, 0]]
        connected_obstacle_map = ObstacleMap([connected_layer])
        bfs = BreadthFirstSearch()
        bfs.search(free_tiles_from_layer(connected_layer), (0, 0), (2, 0), max_distance=10,
                   obstacle_map=connected_obstacle_map)
        assert bfs.is_end_reached is True

        split_layer = [[0, 1, 0]]
        split_obstacle_map = ObstacleMap([split_layer])
        bfs.search({(0, 0), (2, 0)}, (0, 0), (2, 0), max_distance=10, obstacle_map=split_obstacle_map)
        assert bfs.is_end_reached is False
        assert bfs.path == []

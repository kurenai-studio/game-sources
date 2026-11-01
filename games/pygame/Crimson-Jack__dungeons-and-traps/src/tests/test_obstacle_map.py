from src.obstacle_map import ObstacleMap


def get_region_ids(obstacle_map):
    # Region id grid built with the public get_region_id, in the same (row, column) layout as items
    return [[obstacle_map.get_region_id((column, row)) for column in range(len(row_items))]
            for row, row_items in enumerate(obstacle_map.items)]


class TestObstacleMapWithNoLayers:
    def test_none_argument_produces_empty_items(self):
        obstacle_map = ObstacleMap(None)
        assert obstacle_map.items == []

    def test_empty_list_produces_empty_items(self):
        obstacle_map = ObstacleMap([])
        assert obstacle_map.items == []

    def test_list_of_none_layers_produces_empty_items(self):
        obstacle_map = ObstacleMap([None, None, None])
        assert obstacle_map.items == []


class TestObstacleMapWithSingleLayer:
    def test_items_match_single_layer(self):
        layer = [[0, 1], [1, 0]]
        obstacle_map = ObstacleMap([layer])
        assert obstacle_map.items == [[0, 1], [1, 0]]

    def test_all_zeros_layer_produces_all_zeros(self):
        layer = [[0, 0], [0, 0]]
        obstacle_map = ObstacleMap([layer])
        assert obstacle_map.items == [[0, 0], [0, 0]]

    def test_all_ones_layer_produces_all_ones(self):
        layer = [[1, 1], [1, 1]]
        obstacle_map = ObstacleMap([layer])
        assert obstacle_map.items == [[1, 1], [1, 1]]

    def test_none_layer_mixed_with_valid_layer_is_skipped(self):
        layer = [[1, 0], [0, 1]]
        obstacle_map = ObstacleMap([None, layer])
        assert obstacle_map.items == [[1, 0], [0, 1]]


class TestObstacleMapWithMultipleLayers:
    def test_two_layers_are_merged_with_logical_or(self):
        layer_one = [[1, 0], [0, 0]]
        layer_two = [[0, 0], [0, 1]]
        obstacle_map = ObstacleMap([layer_one, layer_two])
        assert obstacle_map.items == [[1, 0], [0, 1]]

    def test_overlapping_blocked_cells_remain_blocked(self):
        layer_one = [[1, 0], [0, 0]]
        layer_two = [[1, 0], [0, 0]]
        obstacle_map = ObstacleMap([layer_one, layer_two])
        assert obstacle_map.items == [[1, 0], [0, 0]]

    def test_three_layers_merged_correctly(self):
        layer_one = [[1, 0], [0, 0]]
        layer_two = [[0, 1], [0, 0]]
        layer_three = [[0, 0], [1, 0]]
        obstacle_map = ObstacleMap([layer_one, layer_two, layer_three])
        assert obstacle_map.items == [[1, 1], [1, 0]]

    def test_none_layer_between_valid_layers_is_skipped(self):
        layer_one = [[1, 0], [0, 0]]
        layer_two = [[0, 0], [0, 1]]
        obstacle_map = ObstacleMap([layer_one, None, layer_two])
        assert obstacle_map.items == [[1, 0], [0, 1]]


class TestObstacleMapRegionsWithNoLayers:
    def test_none_argument_produces_empty_region_ids(self):
        obstacle_map = ObstacleMap(None)
        assert get_region_ids(obstacle_map) == []

    def test_empty_list_produces_empty_region_ids(self):
        obstacle_map = ObstacleMap([])
        assert get_region_ids(obstacle_map) == []


class TestObstacleMapRegionsWithSingleConnectedRegion:
    def test_all_free_tiles_share_one_region_id(self):
        layer = [[0, 0, 0], [0, 1, 0], [0, 0, 0]]
        obstacle_map = ObstacleMap([layer])
        region_ids = get_region_ids(obstacle_map)

        free_region_ids = set()
        for row_index in range(3):
            for column_index in range(3):
                if layer[row_index][column_index] == 0:
                    free_region_ids.add(region_ids[row_index][column_index])
                else:
                    assert region_ids[row_index][column_index] == ObstacleMap.BLOCKED_REGION_ID

        assert len(free_region_ids) == 1

    def test_l_shaped_open_area_is_one_region(self):
        layer = [
            [0, 1, 1],
            [0, 1, 1],
            [0, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        region_ids = get_region_ids(obstacle_map)

        assert region_ids[0][0] == region_ids[1][0]
        assert region_ids[1][0] == region_ids[2][0]
        assert region_ids[2][0] == region_ids[2][1]
        assert region_ids[2][1] == region_ids[2][2]


class TestObstacleMapRegionsWithDisconnectedRegions:
    def test_wall_splits_grid_into_two_region_ids(self):
        layer = [
            [0, 1, 0],
            [0, 1, 0],
            [0, 1, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        region_ids = get_region_ids(obstacle_map)

        left_region_id = region_ids[0][0]
        right_region_id = region_ids[0][2]
        assert left_region_id != right_region_id
        assert region_ids[1][0] == left_region_id
        assert region_ids[2][0] == left_region_id
        assert region_ids[1][2] == right_region_id
        assert region_ids[2][2] == right_region_id

    def test_diagonal_adjacency_does_not_connect_regions(self):
        layer = [
            [0, 1],
            [1, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        region_ids = get_region_ids(obstacle_map)

        assert region_ids[0][0] != region_ids[1][1]


class TestObstacleMapRegionsWithAllBlockedGrid:
    def test_all_ones_grid_has_no_assigned_regions(self):
        layer = [[1, 1], [1, 1]]
        obstacle_map = ObstacleMap([layer])
        region_ids = get_region_ids(obstacle_map)

        for row in region_ids:
            for value in row:
                assert value == ObstacleMap.BLOCKED_REGION_ID


class TestObstacleMapRegionsAfterRefresh:
    def test_calculate_regions_merges_previously_separate_regions_after_mutation(self):
        layer = [
            [0, 1, 0],
            [0, 1, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        assert get_region_ids(obstacle_map)[0][0] != get_region_ids(obstacle_map)[0][2]

        obstacle_map.items[0][1] = 0
        obstacle_map.calculate_regions()

        assert get_region_ids(obstacle_map)[0][0] == get_region_ids(obstacle_map)[0][2]

    def test_calculate_regions_splits_previously_merged_region_after_mutation(self):
        layer = [
            [0, 0, 0],
            [0, 0, 0],
        ]
        obstacle_map = ObstacleMap([layer])
        assert get_region_ids(obstacle_map)[0][0] == get_region_ids(obstacle_map)[0][2]

        obstacle_map.items[0][1] = 1
        obstacle_map.items[1][1] = 1
        obstacle_map.calculate_regions()

        assert get_region_ids(obstacle_map)[0][0] != get_region_ids(obstacle_map)[0][2]

    def test_calculate_regions_does_not_duplicate_items_rows(self):
        layer = [[0, 0], [0, 0]]
        obstacle_map = ObstacleMap([layer])

        obstacle_map.calculate_regions()
        obstacle_map.calculate_regions()

        assert obstacle_map.items == [[0, 0], [0, 0]]

    def test_calculate_regions_preserves_in_place_mutation_after_recompute(self):
        layer = [[0, 0], [0, 0]]
        obstacle_map = ObstacleMap([layer])

        obstacle_map.items[0][1] = 1
        obstacle_map.calculate_regions()

        assert obstacle_map.items == [[0, 1], [0, 0]]

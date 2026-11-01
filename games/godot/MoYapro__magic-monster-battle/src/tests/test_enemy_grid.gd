extends GutTest


# --- get_cells_for_enemy ---

func test_1x1_occupies_one_cell() -> void:
	var cells := EnemyGrid.get_cells_for_enemy(Vector2i(1, 2), Vector2i(1, 1))
	assert_eq(cells.size(), 1)
	assert_eq(cells[0], Vector2i(1, 2))


func test_2x1_occupies_two_cells_horizontally() -> void:
	var cells := EnemyGrid.get_cells_for_enemy(Vector2i(0, 0), Vector2i(2, 1))
	assert_eq(cells.size(), 2)
	assert_true(Vector2i(0, 0) in cells)
	assert_true(Vector2i(1, 0) in cells)


func test_1x2_occupies_two_cells_vertically() -> void:
	var cells := EnemyGrid.get_cells_for_enemy(Vector2i(1, 1), Vector2i(1, 2))
	assert_eq(cells.size(), 2)
	assert_true(Vector2i(1, 1) in cells)
	assert_true(Vector2i(1, 2) in cells)


func test_2x2_occupies_four_cells() -> void:
	var cells := EnemyGrid.get_cells_for_enemy(Vector2i(0, 0), Vector2i(2, 2))
	assert_eq(cells.size(), 4)


# --- is_within_bounds ---

func test_1x1_at_origin_is_valid() -> void:
	assert_true(EnemyGrid.is_within_bounds(Vector2i(0, 0), Vector2i(1, 1)))


func test_1x1_at_far_corner_is_valid() -> void:
	assert_true(EnemyGrid.is_within_bounds(Vector2i(4, 6), Vector2i(1, 1)))


func test_column_out_of_range_is_invalid() -> void:
	assert_false(EnemyGrid.is_within_bounds(Vector2i(5, 0), Vector2i(1, 1)))


func test_row_out_of_range_is_invalid() -> void:
	assert_false(EnemyGrid.is_within_bounds(Vector2i(0, 7), Vector2i(1, 1)))


func test_wide_enemy_that_extends_beyond_cols_is_invalid() -> void:
	assert_false(EnemyGrid.is_within_bounds(Vector2i(4, 0), Vector2i(2, 1)))


func test_negative_position_is_invalid() -> void:
	assert_false(EnemyGrid.is_within_bounds(Vector2i(-1, 0), Vector2i(1, 1)))


# --- can_place_enemy and place_enemy ---

func test_can_place_on_empty_grid() -> void:
	var grid := EnemyGrid.new()
	assert_true(grid.can_place_enemy(Vector2i(0, 0), Vector2i(1, 1)))
	grid.free()


func test_cannot_place_out_of_bounds() -> void:
	var grid := EnemyGrid.new()
	assert_false(grid.can_place_enemy(Vector2i(5, 0), Vector2i(1, 1)))
	grid.free()


func test_cannot_place_on_occupied_cell() -> void:
	var grid := EnemyGrid.new()
	var enemy := EnemyData.new("e1", "Test", 10, Vector2i(1, 1), Color.RED)
	grid.place_enemy(enemy, Vector2i(1, 1))
	assert_false(grid.can_place_enemy(Vector2i(1, 1), Vector2i(1, 1)))
	grid.free()


func test_wide_enemy_blocks_overlapping_placement() -> void:
	var grid := EnemyGrid.new()
	var ogre := EnemyData.new("ogre", "Ogre", 20, Vector2i(2, 1), Color.RED)
	grid.place_enemy(ogre, Vector2i(0, 0))
	# cell (1,0) is occupied by ogre — a 1x1 enemy should not fit there
	assert_false(grid.can_place_enemy(Vector2i(1, 0), Vector2i(1, 1)))
	grid.free()


func test_place_enemy_returns_true_on_success() -> void:
	var grid := EnemyGrid.new()
	var enemy := EnemyData.new("e1", "Test", 10, Vector2i(1, 1), Color.RED)
	assert_true(grid.place_enemy(enemy, Vector2i(0, 0)))
	grid.free()


func test_place_enemy_returns_false_on_failure() -> void:
	var grid := EnemyGrid.new()
	var e1 := EnemyData.new("e1", "A", 10, Vector2i(1, 1), Color.RED)
	var e2 := EnemyData.new("e2", "B", 10, Vector2i(1, 1), Color.BLUE)
	grid.place_enemy(e1, Vector2i(0, 0))
	assert_false(grid.place_enemy(e2, Vector2i(0, 0)))
	grid.free()


# --- get_enemy_at ---

func test_get_enemy_at_returns_placed_enemy() -> void:
	var grid := EnemyGrid.new()
	var enemy := EnemyData.new("e1", "Test", 10, Vector2i(1, 1), Color.RED)
	grid.place_enemy(enemy, Vector2i(2, 3))
	assert_eq(grid.get_enemy_at(Vector2i(2, 3)), enemy)
	grid.free()


func test_get_enemy_at_empty_cell_returns_null() -> void:
	var grid := EnemyGrid.new()
	assert_null(grid.get_enemy_at(Vector2i(0, 0)))
	grid.free()


# --- remove_enemy ---

func test_remove_frees_occupied_cells() -> void:
	var grid := EnemyGrid.new()
	var enemy := EnemyData.new("e1", "Test", 10, Vector2i(1, 1), Color.RED)
	grid.place_enemy(enemy, Vector2i(1, 1))
	grid.remove_enemy("e1")
	assert_null(grid.get_enemy_at(Vector2i(1, 1)))
	grid.free()


func test_can_place_after_removal() -> void:
	var grid := EnemyGrid.new()
	var enemy := EnemyData.new("e1", "Test", 10, Vector2i(1, 1), Color.RED)
	grid.place_enemy(enemy, Vector2i(1, 1))
	grid.remove_enemy("e1")
	assert_true(grid.can_place_enemy(Vector2i(1, 1), Vector2i(1, 1)))
	grid.free()


# --- get_hit_cells ---

func test_single_cell_pattern_returns_target() -> void:
	var grid := EnemyGrid.new()
	var cells := grid.get_hit_cells(Vector2i(1, 2), [Vector2i(0, 0)])
	assert_eq(cells.size(), 1)
	assert_true(Vector2i(1, 2) in cells)
	grid.free()


func test_multi_cell_pattern_returns_all_in_bounds() -> void:
	var grid := EnemyGrid.new()
	var pattern: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)]
	var cells := grid.get_hit_cells(Vector2i(1, 2), pattern)
	assert_eq(cells.size(), 3)
	assert_true(Vector2i(1, 1) in cells)
	assert_true(Vector2i(1, 2) in cells)
	assert_true(Vector2i(1, 3) in cells)
	grid.free()


func test_pattern_clips_out_of_bounds_cells() -> void:
	var grid := EnemyGrid.new()
	# row 0 — offset (0,-1) goes to row -1 which is out of bounds
	var pattern: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)]
	var cells := grid.get_hit_cells(Vector2i(1, 0), pattern)
	assert_eq(cells.size(), 2)
	assert_false(Vector2i(1, -1) in cells)
	grid.free()


func test_pattern_deduplicates_overlapping_offsets() -> void:
	var grid := EnemyGrid.new()
	var pattern: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	var cells := grid.get_hit_cells(Vector2i(0, 0), pattern)
	assert_eq(cells.size(), 1)
	grid.free()

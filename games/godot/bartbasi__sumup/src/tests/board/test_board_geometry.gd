extends "res://tests/base_test.gd"
## BoardGeometry: the hit test (TH19, GDD D-07, AT-21) and cell centers.

const NO_CELL: Vector2i = Vector2i(-1, -1)
const COLUMNS: int = 5
const ROWS: int = 8
const RADIUS: float = 0.42
## AT-21: a tile pitch of 60 dp, so the hit radius is 25.2 dp.
const PITCH_60: Vector2 = Vector2(60.0, 60.0)
const ORIGIN: Vector2 = Vector2(13.0, 7.0)


func _at(point: Vector2, origin: Vector2 = ORIGIN, pitch: Vector2 = PITCH_60) -> Vector2i:
	return BoardGeometry.cell_at(point, origin, pitch, COLUMNS, ROWS, RADIUS)


func _center(cell: Vector2i, origin: Vector2 = ORIGIN, pitch: Vector2 = PITCH_60) -> Vector2:
	return BoardGeometry.cell_center(cell, origin, pitch)


# AT-21

func test_at_21_hit_radius_examples() -> void:
	var cell: Vector2i = Vector2i(2, 3)
	var center: Vector2 = _center(cell)
	assert_eq(_at(center + Vector2(20.0, 0.0)), cell, "20 dp to the right is over the tile")
	assert_eq(_at(center + Vector2(0.0, -25.0)), cell, "25 dp up is over the tile")
	assert_eq(_at(center + Vector2(-27.0, 0.0)), NO_CELL, "27 dp to the left is over no tile")
	assert_eq(_at(center + Vector2(18.0, 18.0)), NO_CELL, "18 dp right and 18 dp down (25.5 dp) is over no tile")
	assert_eq(_at(center + Vector2(30.0, 30.0)), NO_CELL, "the corner shared by four cells is over none of them")


func test_at_21_diagonal_moves_never_catch_side_tiles() -> void:
	# Every diagonal step between touching cells, sampled finely from center
	# to center, only ever hits the two cells it joins.
	var steps: int = 400
	for column: int in COLUMNS - 1:
		for row: int in ROWS - 1:
			var pairs: Array = [
				[Vector2i(column, row), Vector2i(column + 1, row + 1)],
				[Vector2i(column + 1, row), Vector2i(column, row + 1)],
			]
			for pair: Array in pairs:
				var from: Vector2i = pair[0]
				var to: Vector2i = pair[1]
				for i: int in steps + 1:
					var point: Vector2 = _center(from).lerp(_center(to), float(i) / float(steps))
					var hit: Vector2i = _at(point)
					if hit != from and hit != to and hit != NO_CELL:
						fail("a diagonal from %s to %s caught %s" % [from, to, hit])
						return


func test_at_21_diagonal_hits_both_ends_and_a_dead_zone_between() -> void:
	var from: Vector2i = Vector2i(1, 1)
	var to: Vector2i = Vector2i(2, 2)
	var midpoint: Vector2 = _center(from).lerp(_center(to), 0.5)
	assert_eq(_at(_center(from)), from, "starts over the first tile")
	assert_eq(_at(_center(to)), to, "ends over the second tile")
	assert_eq(_at(midpoint), NO_CELL, "the corner between them is a dead zone")


# The hit circle.

func test_every_center_hits_its_own_cell() -> void:
	for column: int in COLUMNS:
		for row: int in ROWS:
			var cell: Vector2i = Vector2i(column, row)
			assert_eq(_at(_center(cell)), cell, "center of %s" % cell)


func test_the_edge_of_the_circle_counts() -> void:
	var cell: Vector2i = Vector2i(0, 0)
	var radius: float = RADIUS * PITCH_60.x
	assert_eq(_at(_center(cell) + Vector2(radius, 0.0)), cell, "exactly on the radius")
	assert_eq(_at(_center(cell) + Vector2(radius + 0.01, 0.0)), NO_CELL, "just past the radius")


func test_the_radius_uses_the_smaller_pitch() -> void:
	var pitch: Vector2 = Vector2(60.0, 100.0)
	var cell: Vector2i = Vector2i(1, 1)
	var center: Vector2 = _center(cell, ORIGIN, pitch)
	assert_eq(_at(center + Vector2(0.0, 25.0), ORIGIN, pitch), cell, "within 0.42 of the 60 pitch")
	assert_eq(_at(center + Vector2(0.0, 26.0), ORIGIN, pitch), NO_CELL, "not 0.42 of the 100 pitch")


func test_points_off_the_board_hit_nothing() -> void:
	var left: Vector2 = _center(Vector2i(0, 3)) - Vector2(PITCH_60.x, 0.0)
	var below: Vector2 = _center(Vector2i(2, ROWS - 1)) + Vector2(0.0, PITCH_60.y)
	assert_eq(_at(left), NO_CELL, "a cell's width left of column 0")
	assert_eq(_at(below), NO_CELL, "a cell's height below the last row")
	assert_eq(_at(Vector2(-5000.0, -5000.0)), NO_CELL, "far off the board")


func test_a_large_radius_picks_the_nearest_center_even_off_the_grid() -> void:
	# With circles wider than half the pitch, a point just outside the grid
	# still belongs to the nearest edge cell, and between two cells the
	# nearer center wins.
	var radius: float = 0.6
	var cell: Vector2i = Vector2i(0, 4)
	var outside: Vector2 = _center(cell) - Vector2(0.55 * PITCH_60.x, 0.0)
	assert_eq(BoardGeometry.cell_at(outside, ORIGIN, PITCH_60, COLUMNS, ROWS, radius), cell, "just left of column 0")
	var nearer_right: Vector2 = _center(cell) + Vector2(0.55 * PITCH_60.x, 0.0)
	assert_eq(BoardGeometry.cell_at(nearer_right, ORIGIN, PITCH_60, COLUMNS, ROWS, radius), Vector2i(1, 4), "the nearer center wins")


func test_bad_input_hits_nothing() -> void:
	var point: Vector2 = _center(Vector2i(1, 1))
	assert_eq(BoardGeometry.cell_at(point, ORIGIN, Vector2.ZERO, COLUMNS, ROWS, RADIUS), NO_CELL, "zero pitch")
	assert_eq(BoardGeometry.cell_at(point, ORIGIN, Vector2(-60.0, 60.0), COLUMNS, ROWS, RADIUS), NO_CELL, "negative pitch")
	assert_eq(BoardGeometry.cell_at(point, ORIGIN, PITCH_60, 0, ROWS, RADIUS), NO_CELL, "no columns")
	assert_eq(BoardGeometry.cell_at(point, ORIGIN, PITCH_60, COLUMNS, ROWS, 0.0), NO_CELL, "zero radius")
	assert_eq(BoardGeometry.cell_at(Vector2(NAN, 10.0), ORIGIN, PITCH_60, COLUMNS, ROWS, RADIUS), NO_CELL, "NaN point")
	assert_eq(BoardGeometry.cell_at(Vector2(INF, 10.0), ORIGIN, PITCH_60, COLUMNS, ROWS, RADIUS), NO_CELL, "infinite point")


# Centers.

func test_cell_center_is_half_a_pitch_into_the_cell() -> void:
	var pitch: Vector2 = Vector2(60.0, 64.0)
	assert_eq(BoardGeometry.cell_center(Vector2i(0, 0), ORIGIN, pitch), ORIGIN + Vector2(30.0, 32.0), "cell (0, 0)")
	assert_eq(BoardGeometry.cell_center(Vector2i(4, 7), ORIGIN, pitch), ORIGIN + Vector2(270.0, 480.0), "cell (4, 7)")

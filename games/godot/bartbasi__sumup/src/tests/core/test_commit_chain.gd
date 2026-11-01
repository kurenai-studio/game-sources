extends "res://tests/base_test.gd"
## Committing a chain through RunRules (D-09 steps 1 to 7 and the move check),
## small tile clearing (D-38), gravity and spawns (D-11, D-12), records
## (D-16, D-17, D-41), and RunRules.clear_small, settle and update_records on
## their own, as Hammer and Double use them.

const F := preload("res://tests/core/core_fixtures.gd")
const START_WINDOW: PackedInt64Array = [2, 4, 8, 16]

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _commit(state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	var chain: Array[Vector2i] = []
	chain.assign(cells)
	return RunRules.commit_chain(state, records, chain, rng, config)


func _idx(cell: Vector2i) -> int:
	return cell.y * F.COLUMNS + cell.x


## Rebuilds the board after the move from cells_before and the steps the
## result lists, the way the board view animates it. Must equal cells_after.
## Returns an empty board when a tile falls or spawns onto a full cell.
func _replay(result: MoveResult) -> PackedInt64Array:
	var board: PackedInt64Array = result.cells_before.duplicate()
	if result.result_cell != Vector2i(-1, -1):
		board[_idx(result.result_cell)] = result.result_value
	for cell: Vector2i in result.emptied:
		board[_idx(cell)] = 0
	for cell: Vector2i in result.cleared_small:
		board[_idx(cell)] = 0
	for position: int in result.fall_from.size():
		var from_cell: Vector2i = result.fall_from[position]
		var to_cell: Vector2i = result.fall_to[position]
		if board[_idx(to_cell)] != 0:
			return PackedInt64Array()
		board[_idx(to_cell)] = board[_idx(from_cell)]
		board[_idx(from_cell)] = 0
	for position: int in result.spawn_cells.size():
		var cell: Vector2i = result.spawn_cells[position]
		if board[_idx(cell)] != 0:
			return PackedInt64Array()
		board[_idx(cell)] = result.spawn_values[position]
	return board


func _assert_replays(result: MoveResult, label: String) -> void:
	assert_eq(_replay(result), result.cells_after, "%s: the result's steps rebuild cells_after" % label)


## How many tiles of value (a tile value) board (exponents) holds.
func _count(board: PackedInt64Array, value: int) -> int:
	var count: int = 0
	for each: int in board:
		if each == F.e(value):
			count += 1
	return count


func _lowest(board: PackedInt64Array) -> int:
	var low: int = board[0]
	for each: int in board:
		low = mini(low, each)
	return low


# D-09 and the gravity examples

func test_at_17_lifting_commits() -> void:
	var state: RunState = F.state(F.board_p(), 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)], F.seeded(17))
	assert_true(result.accepted, "accepted")
	assert_eq(result.kind, MoveResult.Kind.CHAIN, "kind")
	assert_eq(state.score.to_int(), 16, "score 16")
	assert_eq(result.points.to_int(), 16, "points 16")
	assert_eq(result.result_cell, Vector2i(2, 5), "the result lands on (2,5)")
	assert_eq(F.v(result.result_value), 16, "result 16")
	assert_eq(F.column_of(state.cells, 2).slice(1), PackedInt64Array([2, 8, 2, 8, 2, 16, 32]), "column 2 rows 1 to 7: the 16 fell to (2,6)")
	assert_eq(result.spawn_cells, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)] as Array[Vector2i], "new tiles on (1,0), (2,0) and (3,0)")
	assert_true(F.all_in(result.spawn_values, START_WINDOW), "new tiles from 2, 4, 8, 16")
	assert_eq(F.column_of(state.cells, 1).slice(1), PackedInt64Array([4, 16, 4, 16, 4, 4, 8]), "column 1 fell one row")
	assert_eq(F.column_of(state.cells, 3).slice(1), PackedInt64Array([4, 16, 4, 16, 4, 16, 8]), "column 3 fell one row")
	assert_eq(F.column_of(state.cells, 0), F.column_of(F.board_p(), 0), "column 0 unchanged")
	assert_eq(F.column_of(state.cells, 4), F.column_of(F.board_p(), 4), "column 4 unchanged")
	assert_true(state.has_snapshot(), "an Undo snapshot exists")
	assert_eq(state.snapshot_cells, F.board_p(), "the snapshot is Board P")
	assert_eq(state.snapshot_points.to_int(), 16, "with 16 points")
	assert_eq(result.emptied, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)] as Array[Vector2i], "emptied in drag order")
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_eq(result.fall_from.size(), 18, "six tiles fall in each of three columns")
	assert_eq(result.fall_from[0], Vector2i(1, 5), "falls are listed column by column, lowest tile first")
	assert_eq(result.fall_to[0], Vector2i(1, 6), "one row down")
	assert_true(result.fall_from.has(Vector2i(2, 5)) and result.fall_to.has(Vector2i(2, 6)), "the result tile's fall is listed")
	assert_eq(result.cells_before, F.board_p(), "cells_before")
	assert_eq(result.cells_after, state.cells, "cells_after")
	_assert_replays(result, "AT-17")


func test_at_20_the_path_may_cross_itself() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var chain: Array[Vector2i] = []
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2)]:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
	assert_eq(chain.size(), 4, "all four join")
	assert_eq(F.v(CoreRules.merge_result(F.ev(F.values_of(board, chain)))), 16, "preview 16")
	var state: RunState = F.state(board, 0)
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(20), config)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_int(), 16, "score 16")
	assert_eq(F.v(state.value_at(Vector2i(1, 2))), 16, "the 16 stays on (1,2)")
	_assert_replays(result, "AT-20")


func test_at_25_a_chain_can_use_the_whole_board() -> void:
	var board: PackedInt64Array = F.board_all(2)
	var path: Array[Vector2i] = F.snake_from_top(40)
	var chain: Array[Vector2i] = []
	for cell: Vector2i in path:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
	assert_eq(chain.size(), 40, "the drag joins all 40 tiles")
	assert_eq(chain[39], Vector2i(0, 7), "ending at (0,7)")
	var state: RunState = F.state(board, 0)
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(25), config)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_int(), 80, "score 80")
	assert_eq(F.v(state.value_at(Vector2i(0, 7))), 64, "(0,7) = 64")
	assert_eq(result.spawn_cells.size(), 39, "39 new tiles")
	assert_true(F.all_in(result.spawn_values, START_WINDOW), "from 2, 4, 8, 16")
	assert_true(result.fall_from.is_empty(), "nothing falls: every other cell was emptied")
	_assert_replays(result, "AT-25")


func test_at_26_rounding_examples() -> void:
	var examples: Array[Array] = [
		["M1", [2, 2], 4, 4],
		["M2", [2, 2, 2], 4, 6],
		["M3", [4, 4, 8], 16, 16],
		["M4", [2, 2, 2, 2, 2], 8, 10],
		["M5", [2, 2, 4, 8, 16, 32], 64, 64],
		["M6", [8, 8, 8, 16, 16, 32], 64, 88],
		["M7", [2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 8], 32, 32],
		["M8", [2, 2, 4, 4, 4, 8, 8, 16], 32, 48],
		["M9", [512, 512, 1024, 1024], 2048, 3072],
		["M10", [64, 64, 64, 64], 256, 256],
	]
	for example: Array in examples:
		var label: String = example[0]
		var values: PackedInt64Array = PackedInt64Array(example[1])
		var path: Array[Vector2i] = F.snake_from_bottom(values.size())
		var state: RunState = F.state(F.placed(F.board_d(), path, values), 0)
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), path, F.seeded(26), config)
		assert_true(result.accepted, "%s accepted" % label)
		assert_eq(F.v(result.result_value), example[2], "%s result" % label)
		assert_eq(result.points.to_int(), example[3], "%s points" % label)
		assert_eq(state.score.to_int(), example[3], "%s score" % label)
		assert_true(state.cells.has(F.e(example[2])), "%s result is on the board" % label)
		_assert_replays(result, label)


func test_at_28_large_values_stay_exact() -> void:
	var big: int = 1 << 60
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): big, Vector2i(1, 7): big}), 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(28))
	assert_true(result.accepted, "accepted")
	assert_eq(F.v(state.value_at(Vector2i(1, 7))), 1 << 61, "(1,7) = 2^61 exactly")
	assert_eq(state.score.to_int(), 1 << 61, "score 2^61 exactly")
	assert_eq(result.points.to_int(), 1 << 61, "points 2^61")
	# H is 2^61, so the floor rises to 2^52 and every Board D tile clears (D-38).
	assert_eq(F.v(result.floor_after), 1 << 52, "new floor 2^52")
	assert_eq(result.cleared_small.size(), 38, "all 38 small tiles clear")
	assert_eq(result.spawn_values.size(), 39, "39 refills")
	var window: PackedInt64Array = PackedInt64Array([1 << 52, 1 << 53, 1 << 54, 1 << 55])
	assert_true(F.all_in(result.spawn_values, window), "from 2^52 to 2^55")
	_assert_replays(result, "AT-28")


func test_at_29_gravity_example_g1() -> void:
	var board: PackedInt64Array = F.with_column(F.board_d(), 2, PackedInt64Array([4, 16, 2, 8, 8, 8, 32, 64]))
	var state: RunState = F.state(board, 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5)], F.seeded(29))
	assert_eq(result.points.to_int(), 24, "points 24")
	assert_eq(F.v(result.result_value), 16, "result 16")
	var column: PackedInt64Array = F.column_of(state.cells, 2)
	assert_eq(column.slice(2), PackedInt64Array([4, 16, 2, 16, 32, 64]), "rows 2 to 7")
	assert_true(F.all_in(F.ev(column.slice(0, 2)), START_WINDOW), "rows 0 and 1 are new tiles")
	assert_eq(result.spawn_cells, [Vector2i(2, 0), Vector2i(2, 1)] as Array[Vector2i], "two spawns, top down")
	_assert_replays(result, "G1")


func test_at_30_gravity_example_g2() -> void:
	var board: PackedInt64Array = F.with_column(F.board_d(), 0, PackedInt64Array([2, 4, 8, 16, 32, 8, 4, 4]))
	var state: RunState = F.state(board, 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(0, 6), Vector2i(0, 5)], F.seeded(30))
	assert_eq(result.points.to_int(), 16, "points 16")
	assert_eq(result.result_cell, Vector2i(0, 5), "placed on (0,5)")
	var column: PackedInt64Array = F.column_of(state.cells, 0)
	assert_eq(column.slice(2), PackedInt64Array([2, 4, 8, 16, 32, 16]), "the result tile fell to (0,7)")
	assert_true(F.all_in(F.ev(column.slice(0, 2)), START_WINDOW), "rows 0 and 1 are new tiles")
	assert_eq(result.fall_from[0], Vector2i(0, 5), "the result tile falls first")
	assert_eq(result.fall_to[0], Vector2i(0, 7), "two rows down")
	_assert_replays(result, "G2")


func test_at_31_gravity_example_g3() -> void:
	var board: PackedInt64Array = F.changed(F.board_p(), {Vector2i(1, 6): 2, Vector2i(2, 7): 2, Vector2i(3, 6): 4})
	var state: RunState = F.state(board, 0)
	var rng: RunRandom = F.seeded(31)
	rng.script_spawns(F.ev(PackedInt64Array([8, 16])))
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(1, 6), Vector2i(2, 7), Vector2i(3, 6)], rng)
	assert_eq(result.points.to_int(), 8, "points 8")
	assert_eq(F.v(state.value_at(Vector2i(3, 6))), 8, "(3,6) = 8")
	assert_eq(F.column_of(state.cells, 1).slice(1, 7), F.column_of(board, 1).slice(0, 6), "column 1 rows 0 to 5 moved down one row")
	assert_eq(F.v(state.value_at(Vector2i(1, 7))), F.at(board, Vector2i(1, 7)), "(1,7) stays")
	assert_eq(F.column_of(state.cells, 2).slice(1, 8), F.column_of(board, 2).slice(0, 7), "column 2 rows 0 to 6 moved down one row")
	assert_eq(F.v(state.value_at(Vector2i(1, 0))), 8, "(1,0) = 8, spawned first")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 16, "(2,0) = 16")
	var column_3: PackedInt64Array = F.column_of(board, 3)
	column_3[6] = 8
	assert_eq(F.column_of(state.cells, 3), column_3, "column 3 unchanged apart from (3,6)")
	assert_eq(F.column_of(state.cells, 0), F.column_of(board, 0), "column 0 unchanged")
	assert_eq(F.column_of(state.cells, 4), F.column_of(board, 4), "column 4 unchanged")
	assert_eq(result.spawn_cells, [Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i], "spawn order: (1,0) first, then (2,0)")
	_assert_replays(result, "G3")


func test_at_32_fill_order() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(3, 0): 0, Vector2i(1, 0): 0, Vector2i(1, 1): 0})
	var state: RunState = F.state(board, 0)
	var rng: RunRandom = F.seeded(32)
	rng.script_spawns(F.ev(PackedInt64Array([8, 2, 4])))
	var result: MoveResult = MoveResult.new()
	RunRules.settle(state, result, rng, config)
	assert_eq(F.v(state.value_at(Vector2i(1, 0))), 8, "(1,0) = 8")
	assert_eq(F.v(state.value_at(Vector2i(1, 1))), 2, "(1,1) = 2")
	assert_eq(F.v(state.value_at(Vector2i(3, 0))), 4, "(3,0) = 4")
	assert_eq(result.spawn_cells, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(3, 0)] as Array[Vector2i], "fill order")
	assert_eq(F.vv(result.spawn_values), PackedInt64Array([8, 2, 4]), "values in fill order")
	assert_true(result.fall_from.is_empty(), "the empty cells were already at the top")
	assert_eq(result.cells_after, state.cells, "settle records the settled board")


func test_at_33_records_update_in_the_same_move() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024}), 0)
	var records: Records = F.records(0, 1024)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(33))
	assert_eq(records.best_score.to_int(), 2048, "Best Score 2,048")
	assert_eq(F.v(records.best_tile), 2048, "Best Tile 2048")
	assert_true(result.new_best_score, "the result says Best Score rose")
	assert_true(result.new_best_tile, "the result says Best Tile rose")


# Spawn window timing and small tile clearing

func test_at_36_a_merge_that_raises_h_raises_the_window_at_once() -> void:
	var window: PackedInt64Array = PackedInt64Array([4, 8, 16, 32])
	for seed_value: int in range(1, 201):
		var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024}), 0)
		var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(seed_value))
		var problem: String = ""
		if result.floor_before != F.e(2) or result.floor_after != F.e(4):
			problem = "floor 2^%d to 2^%d" % [result.floor_before, result.floor_after]
		elif result.cleared_small.size() != 12 or result.cleared_values != F.ev(PackedInt64Array([2])):
			problem = "cleared %d tiles %s" % [result.cleared_small.size(), result.cleared_values]
		elif result.spawn_cells.size() != 13:
			problem = "%d refills" % result.spawn_cells.size()
		elif not F.all_in(result.spawn_values, window):
			problem = "new tiles %s" % result.spawn_values
		elif state.cells.has(F.e(2)):
			problem = "a 2 is left"
		elif _replay(result) != result.cells_after:
			problem = "the result does not replay"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_at_39_points_are_the_sum_not_the_result() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(1, 0): 2}), 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], F.seeded(39))
	assert_eq(state.score.to_int(), 6, "score 6")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 4, "(2,0) = 4")
	assert_eq(result.points.to_int(), 6, "points 6")


## The commit half of AT-41. The Hammer half is a boosters test.
func test_at_41_best_score_updates_live_on_commit() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 0): 8}), 9990)
	var records: Records = F.records(10000, 0)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 0), Vector2i(0, 1)], F.seeded(41))
	assert_eq(state.score.to_int(), 10006, "score 10,006")
	assert_eq(records.best_score.to_int(), 10006, "Best Score 10,006 right after the commit")
	assert_true(result.new_best_score, "new Best Score")


## The commit half of AT-43 (updated on 2026-10-13 for D-46). The free Double
## and the Hammer after it are boosters tests.
func test_at_43_best_tile_after_the_commit() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096}), 50000)
	var records: Records = F.records(0, 4096)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(43))
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192")
	assert_eq(state.score.to_int(), 58192, "score 58,192")
	assert_eq(CoreRules.stars(state.run_highest, config), 3, "the 8192 is this run's third star")
	assert_eq(result.free_earned, 1, "so it earns a free booster")
	assert_eq(CoreRules.free_held(state, config), 1, "one free booster is held")


## The chain half of AT-38, from the board right after the Hammer (column 2
## fell one row and (2,0) spawned a 2). The Hammer half is a boosters test.
func test_at_38_chain_raises_the_floor_again_after_a_hammer() -> void:
	var board: PackedInt64Array = F.with_column(F.board_e(), 2, PackedInt64Array([2, 4, 8, 4, 8, 4, 8, 4]))
	board = F.changed(board, {Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = RunState.create(board, F.big(7952), PackedInt64Array(), null, F.e(2048))
	var rng: RunRandom = F.seeded(38)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8])))
	var result: MoveResult = _commit(state, F.records(10000, 2048), [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_eq(state.score.to_int(), 10000, "score 10,000")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 2048, "(4,7) = 2048")
	assert_eq(result.cleared_small, [Vector2i(2, 0)] as Array[Vector2i], "the 2 on (2,0) was cleared")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 8, "(2,0) = 8")
	assert_eq(F.v(state.value_at(Vector2i(4, 0))), 8, "(4,0) = 8")
	assert_false(state.cells.has(F.e(2)), "no 2 is left")
	_assert_replays(result, "AT-38")


func test_at_99_clearing_creates_the_only_valid_move() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(99)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8])))
	var result: MoveResult = _commit(state, records, [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_int(), 12048, "score 12,048: the cleared 2 adds nothing")
	assert_eq(result.points.to_int(), 2048, "points are the chain only")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 2048, "(4,7) = 2048")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "exactly one cleared tile, (0,3)")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2]), "of value 2")
	assert_eq(F.v(result.floor_before), 2, "floor before")
	assert_eq(F.v(result.floor_after), 4, "floor after")
	assert_eq(F.column_of(state.cells, 0), PackedInt64Array([8, 4, 8, 4, 4, 8, 4, 8]), "column 0")
	assert_eq(F.column_of(state.cells, 4), PackedInt64Array([8, 4, 8, 4, 8, 4, 8, 2048]), "column 4")
	assert_eq(F.equal_pairs(state.cells), [Vector2i(0, 3), Vector2i(0, 4)] as Array[Vector2i], "the only valid move is (0,3) with (0,4)")
	assert_true(result.has_valid_move, "no offer opens")
	assert_eq(F.v(records.best_tile), 2048, "Best Tile 2048")
	assert_eq(F.v(state.run_highest), 2048, "run highest tile 2048")
	assert_eq(state.snapshot_cells, board, "the snapshot holds the 2 that cleared")
	_assert_replays(result, "AT-99")


func test_at_100_two_values_clear_at_once() -> void:
	var window: PackedInt64Array = PackedInt64Array([8, 16, 32, 64])
	var chain: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)]
	for seed_value: int in range(1, 201):
		var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024, Vector2i(2, 7): 1024, Vector2i(3, 7): 1024})
		var state: RunState = F.state(board, 0)
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(seed_value), config)
		var problem: String = ""
		if state.score.to_int() != 4096 or F.v(state.value_at(Vector2i(3, 7))) != 4096:
			problem = "score %s, (3,7) = 2^%d" % [state.score.to_decimal(), state.value_at(Vector2i(3, 7))]
		elif result.cleared_small.size() != 20 or result.cleared_values != F.ev(PackedInt64Array([2, 4])):
			problem = "cleared %d tiles %s" % [result.cleared_small.size(), result.cleared_values]
		elif _count(result.cells_before, 2) != 12 or _count(result.cells_before, 4) != 8:
			problem = "the setup should hold twelve 2s and eight 4s"
		elif result.spawn_values.size() != 23 or not F.all_in(result.spawn_values, window):
			problem = "new tiles %s" % result.spawn_values
		elif F.v(_lowest(state.cells)) < 8:
			problem = "a tile below 8 is left"
		elif _replay(result) != result.cells_after:
			problem = "the result does not replay"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


## GDD 11.1: chains 2, 2, 2 then 4, 4, 8 then 8, 8 take the score from 0 to 6, 22 and 38.
func test_score_worked_example() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(1, 0): 2, Vector2i(4, 0): 4})
	var state: RunState = F.state(board, 0)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(11)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8, 2, 2])))
	var first: MoveResult = _commit(state, records, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], rng)
	assert_eq(first.points.to_int(), 6, "2, 2, 2 adds 6")
	assert_eq(state.score.to_int(), 6, "score 6")
	var second: MoveResult = _commit(state, records, [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 1)], rng)
	assert_eq(second.points.to_int(), 16, "4, 4, 8 adds 16")
	assert_eq(state.score.to_int(), 22, "score 22")
	var third: MoveResult = _commit(state, records, [Vector2i(0, 0), Vector2i(1, 0)], rng)
	assert_eq(third.points.to_int(), 16, "8, 8 adds 16")
	assert_eq(state.score.to_int(), 38, "score 38")
	assert_eq(records.best_score.to_int(), 38, "Best Score follows")


# Undo snapshot from commits (the Undo halves are boosters tests)

func test_at_76_commit_stores_the_setup_board_for_undo() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 512, Vector2i(1, 7): 8, Vector2i(2, 7): 16})
	var state: RunState = F.state(board, 1000)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], F.seeded(76))
	assert_true(result.accepted, "8, 8, 16 commits")
	assert_eq(state.score.to_int(), 1032, "score 1,032")
	assert_eq(state.snapshot_cells, board, "the snapshot is the setup board exactly")
	assert_eq(state.snapshot_points.to_int(), 32, "worth 32")


func test_at_79_commit_before_the_undo_refusal() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 2, Vector2i(1, 7): 2, Vector2i(2, 7): 4, Vector2i(3, 7): 8, Vector2i(4, 7): 16, Vector2i(4, 6): 32, Vector2i(3, 6): 32})
	var state: RunState = F.state(board, 30)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(4, 6), Vector2i(3, 6)], F.seeded(79))
	assert_true(result.accepted, "the path commits")
	assert_eq(result.points.to_int(), 96, "worth 96")
	assert_eq(F.v(result.result_value), 64, "makes a 64")
	assert_eq(state.score.to_int(), 126, "score 126")
	assert_eq(F.v(state.highest()), 64, "H = 64")
	assert_eq(state.snapshot_points.to_int(), 96, "the snapshot holds the 96 points")


func test_at_80_commit_snapshot_keeps_the_tiles_it_cleared() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var state: RunState = F.state(board, 20000)
	var records: Records = F.records(0, 1024)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(80))
	assert_eq(state.score.to_int(), 22048, "score 22,048")
	assert_eq(result.cleared_small.size(), 12, "the chain cleared twelve 2s")
	assert_eq(state.snapshot_cells, board, "the snapshot is the setup board, 2s included (D-39)")
	assert_eq(_count(state.snapshot_cells, 2), 12, "twelve 2s in the snapshot")
	assert_eq(F.v(records.best_tile), 2048, "Best Tile 2048")
	assert_eq(records.best_score.to_int(), 22048, "Best Score 22,048")


func test_at_81_commit_before_the_shuffle_and_undo() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 1024, Vector2i(1, 7): 8})
	assert_eq(F.values_of(board, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7)]), PackedInt64Array([8, 8, 8, 16, 8]), "row 7 reads 8, 8, 8, 16, 8")
	var state: RunState = F.state(board, 5000)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)], F.seeded(81))
	assert_eq(result.points.to_int(), 40, "worth 40")
	assert_eq(state.score.to_int(), 5040, "score 5,040")
	assert_eq(state.snapshot_cells, board, "snapshot is the setup board")


func test_commit_replaces_an_older_snapshot() -> void:
	var board: PackedInt64Array = F.board_p()
	var state: RunState = RunState.create(board, F.big(100), F.board_d(), F.big(999))
	_commit(state, Records.new(), [Vector2i(1, 6), Vector2i(2, 6)], F.seeded(1))
	assert_eq(state.snapshot_cells, board, "the new snapshot is the board before this chain")
	assert_eq(state.snapshot_points.to_int(), 4, "with this chain's points")


## The commit and new run rows of AT-108. Double, Hammer and Undo are boosters tests.
func test_at_108_run_highest_after_a_commit_and_a_new_run() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var state: RunState = RunState.create(board, F.big(50000), PackedInt64Array(), null, F.e(1024))
	var records: Records = F.records(0, 8192)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(108))
	assert_eq(state.score.to_int(), 52048, "score 52,048")
	assert_eq(F.v(state.run_highest), 2048, "run highest 2048")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192")
	var fresh: RunState = RunRules.new_run(F.seeded(108), records, config)
	assert_eq(fresh.score.to_int(), 0, "new run score 0")
	assert_eq(fresh.run_highest, fresh.highest(), "run highest is the new board's highest tile")
	assert_true(fresh.run_highest <= F.e(16), "16 at most")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile stays 8192")


# Refusals

func test_a_refused_commit_changes_nothing_at_all() -> void:
	var lists: Array[Array] = [
		[],
		[Vector2i(1, 6)],
		[Vector2i(1, 6), Vector2i(1, 5)],
		[Vector2i(1, 6), Vector2i(3, 6)],
		[Vector2i(1, 6), Vector2i(2, 6), Vector2i(1, 6)],
		[Vector2i(1, 6), Vector2i(2, 6), Vector2i(2, 7)],
		[Vector2i(4, 6), Vector2i(5, 6)],
		[Vector2i(-1, -1), Vector2i(0, 0)],
	]
	for list: Array in lists:
		var state: RunState = RunState.create(F.board_p(), F.big(300), F.board_d(), F.big(40), F.e(64))
		var before: RunState = state.copy()
		var records: Records = F.records(1000, 64)
		var rng: RunRandom = F.seeded(5)
		rng.script_spawns(F.ev(PackedInt64Array([1024])))
		var rng_state: int = rng.get_state()
		var result: MoveResult = _commit(state, records, list, rng)
		assert_false(result.accepted, "%s refused" % [list])
		assert_eq(result.refusal, &"invalid_chain", "%s refusal" % [list])
		assert_true(state.equals(before), "%s: the state equals the copy taken before" % [list])
		assert_eq(records.best_score.to_int(), 1000, "%s: Best Score unchanged" % [list])
		assert_eq(F.v(records.best_tile), 64, "%s: Best Tile unchanged" % [list])
		assert_eq(rng.get_state(), rng_state, "%s: generator unchanged" % [list])
		assert_eq(F.v(rng.next_spawn(F.ev(START_WINDOW), config)), 1024, "%s: scripted spawns not used" % [list])
		assert_eq(result.points.to_int(), 0, "%s: no points" % [list])
		assert_eq(result.cells_after, result.cells_before, "%s: the result shows no change" % [list])
		assert_true(result.spawn_cells.is_empty(), "%s: no spawns" % [list])
		assert_eq(result.stars_earned, 0, "%s: no stars" % [list])
		assert_true(result.notice_values.is_empty(), "%s: no notice values" % [list])


func test_a_board_that_does_not_match_the_config_is_refused() -> void:
	var state: RunState = F.state(F.board_p(), 0)
	var before: RunState = state.copy()
	config.columns = 4
	config.rows = 10
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(1, 6), Vector2i(2, 6)], F.seeded(1))
	assert_false(result.accepted, "refused")
	assert_true(state.equals(before), "nothing changed")


## D-37 (2026-10-21): the 64 bit limit is gone. A 2^62 pair makes 2^63, and
## a score past 2^63 - 1 stays exact.
func test_a_chain_past_64_bits_commits() -> void:
	var state: RunState = F.state(F.changed_exponents(F.board_d(), {Vector2i(0, 7): 62, Vector2i(1, 7): 62}), 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(1))
	assert_true(result.accepted, "a 2^63 sum commits")
	assert_eq(result.result_value, 63, "making 2^63")
	assert_eq(state.score.to_decimal(), "9223372036854775808", "score 2^63 exactly")
	var rich: RunState = F.state(F.board_p(), 9223372036854775807 - 3)
	assert_true(_commit(rich, Records.new(), [Vector2i(1, 6), Vector2i(2, 6)], F.seeded(1)).accepted, "a score that passes 2^63 - 1 commits")
	assert_eq(rich.score.to_decimal(), "9223372036854775808", "2^63 - 4 + 4")
	assert_false(rich.score.fits_int(), "and no longer fits in an int")


# RunRules.clear_small, settle and update_records on their own

## What Double does in CL2 (AT-101), step by step: double the 1024, clear the
## small tiles against the floor from before, then settle.
func test_clear_small_and_settle_on_their_own_cl2() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})
	var state: RunState = F.state(board, 2952)
	var floor_before: int = CoreRules.window_floor(state.highest(), config)
	var doubled: PackedInt64Array = state.cells.duplicate()
	doubled[_idx(Vector2i(2, 0))] = F.e(2048)
	state.cells = doubled
	var result: MoveResult = MoveResult.new()
	RunRules.clear_small(state, floor_before, result, config)
	assert_eq(F.v(result.floor_before), 2, "floor before 2")
	assert_eq(F.v(result.floor_after), 4, "floor after 4")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "the 2 on (0,3) cleared")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2]), "value 2")
	assert_eq(F.v(state.value_at(Vector2i(0, 3))), 0, "(0,3) is empty until settle")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 2048, "the doubled tile never clears")
	var rng: RunRandom = F.seeded(101)
	rng.script_spawns(F.ev(PackedInt64Array([8])))
	RunRules.settle(state, result, rng, config)
	assert_eq(F.v(state.value_at(Vector2i(0, 0))), 8, "(0,0) = 8")
	assert_eq(F.v(state.value_at(Vector2i(0, 3))), 4, "(0,3) = 4")
	assert_eq(F.v(state.value_at(Vector2i(0, 4))), 4, "(0,4) = 4")
	assert_eq(result.fall_from, [Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0)] as Array[Vector2i], "column 0 falls one row")
	assert_true(CoreRules.has_valid_move(state.cells, BigNum.zero(), config), "the board has a valid move")
	assert_eq(state.score.to_int(), 2952, "clearing and settling never touch the score")


## AT-103 style: a tile below the floor stays when the floor does not rise.
func test_clear_small_needs_a_floor_rise() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 2048})
	var state: RunState = F.state(board, 11808)
	var floor_before: int = CoreRules.window_floor(state.highest(), config)
	assert_eq(floor_before, F.e(4), "floor 4 with H 2048")
	var doubled: PackedInt64Array = state.cells.duplicate()
	doubled[_idx(Vector2i(0, 0))] = F.e(8)
	state.cells = doubled
	var after_double: PackedInt64Array = state.cells.duplicate()
	var result: MoveResult = MoveResult.new()
	RunRules.clear_small(state, floor_before, result, config)
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_true(result.cleared_values.is_empty(), "no cleared values")
	assert_eq(F.v(result.floor_after), 4, "floor unchanged")
	assert_eq(state.cells, after_double, "the 2 stays")


func test_clear_small_clears_every_value_below_a_big_jump() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 3): 65536})
	var state: RunState = F.state(board, 0)
	var result: MoveResult = MoveResult.new()
	RunRules.clear_small(state, F.e(2), result, config)
	assert_eq(F.v(result.floor_after), 128, "H 64K gives floor 128")
	assert_eq(result.cleared_small.size(), 39, "every other tile clears")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2, 4, 8, 16]), "distinct values, ascending")
	assert_eq(result.cleared_small[0], Vector2i(0, 0), "index order")
	assert_eq(result.cleared_small[38], Vector2i(4, 7), "index order to the end")


## Board E starts 4, 16 and holds a 2 lower down, so index order is not value order.
func test_cleared_values_are_ascending_whatever_the_board_order() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 5): 2, Vector2i(2, 3): 65536})
	var state: RunState = F.state(board, 0)
	var result: MoveResult = MoveResult.new()
	RunRules.clear_small(state, F.e(2), result, config)
	assert_eq(result.cleared_small.size(), 39, "every tile but the 64K clears")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2, 4, 8, 16, 32]), "distinct values, ascending")


## D-11 and S2: after a Hammer lowers H, the refill comes from the lower window.
func test_settle_after_a_hammer_uses_the_window_after_gravity() -> void:
	var top_left: Array[Vector2i] = [Vector2i(0, 0)]
	for seed_value: int in range(1, 51):
		var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 0, Vector2i(4, 7): 1024})
		var state: RunState = RunState.create(board, F.big(5904), PackedInt64Array(), null, F.e(4096))
		var result: MoveResult = MoveResult.new()
		RunRules.settle(state, result, F.seeded(seed_value), config)
		var problem: String = ""
		if result.spawn_cells != top_left:
			problem = "spawned at %s" % [result.spawn_cells]
		elif not F.all_in(result.spawn_values, START_WINDOW):
			problem = "new tile %s" % result.spawn_values
		elif F.column_of(state.cells, 0).slice(1) != F.column_of(F.board_d(), 0).slice(0, 7):
			problem = "column 0 did not fall one row"
		elif result.fall_from.size() != 7:
			problem = "%d falls" % result.fall_from.size()
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_settle_on_a_full_board_does_nothing() -> void:
	var state: RunState = F.state(F.board_p(), 10)
	var before: RunState = state.copy()
	var rng: RunRandom = F.seeded(3)
	var rng_state: int = rng.get_state()
	var result: MoveResult = MoveResult.new()
	RunRules.settle(state, result, rng, config)
	assert_true(state.equals(before), "the state is unchanged")
	assert_eq(rng.get_state(), rng_state, "no draws")
	assert_true(result.fall_from.is_empty() and result.spawn_cells.is_empty(), "nothing recorded")


func test_settle_keeps_tile_order_in_a_column() -> void:
	var board: PackedInt64Array = F.with_column(F.board_d(), 3, PackedInt64Array([2, 0, 4, 0, 0, 8, 0, 16]))
	var state: RunState = F.state(board, 0)
	var rng: RunRandom = F.seeded(4)
	rng.script_spawns(F.ev(PackedInt64Array([32, 32, 32, 32])))
	var result: MoveResult = MoveResult.new()
	RunRules.settle(state, result, rng, config)
	assert_eq(F.column_of(state.cells, 3), PackedInt64Array([32, 32, 32, 32, 2, 4, 8, 16]), "tiles keep their order, spawns fill the top")
	assert_eq(result.fall_from, [Vector2i(3, 5), Vector2i(3, 2), Vector2i(3, 0)] as Array[Vector2i], "falls listed lowest tile first")
	assert_eq(result.fall_to, [Vector2i(3, 6), Vector2i(3, 5), Vector2i(3, 4)] as Array[Vector2i], "where each lands")


## D-17 and D-41: a spawned tile counts for Best Tile and the run highest tile.
func test_a_spawn_that_becomes_the_highest_tile_counts_for_records() -> void:
	var state: RunState = F.state(F.board_all(2), 0)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(17)
	rng.script_spawns(F.ev(PackedInt64Array([16])))
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(F.v(result.result_value), 4, "the merge makes a 4")
	assert_eq(F.v(state.value_at(Vector2i(0, 0))), 16, "the spawn is a 16")
	assert_eq(F.v(records.best_tile), 16, "Best Tile counts the spawn")
	assert_eq(F.v(state.run_highest), 16, "so does the run highest tile")
	assert_true(result.new_best_tile, "the result says Best Tile rose")


## D-41, T3 and RH4: a lower H never lowers the run highest tile or Best Tile.
func test_update_records_never_lowers_anything() -> void:
	var state: RunState = RunState.create(F.changed(F.board_d(), {Vector2i(0, 0): 4096}), F.big(25424), PackedInt64Array(), null, F.e(16384))
	var records: Records = F.records(60000, 16384)
	var result: MoveResult = MoveResult.new()
	RunRules.update_records(state, records, result)
	assert_eq(F.v(state.run_highest), 16384, "run highest stays")
	assert_eq(F.v(records.best_tile), 16384, "Best Tile stays")
	assert_eq(records.best_score.to_int(), 60000, "Best Score stays")
	assert_false(result.new_best_score, "no new Best Score")
	assert_false(result.new_best_tile, "no new Best Tile")


## RH2 and RH3: the run highest tile follows H up, Best Tile only above its own record.
func test_update_records_raises_run_highest_and_records() -> void:
	var state: RunState = RunState.create(F.changed(F.board_d(), {Vector2i(0, 0): 4096}), F.big(47952), PackedInt64Array(), null, F.e(2048))
	var records: Records = F.records(52048, 8192)
	var result: MoveResult = MoveResult.new()
	RunRules.update_records(state, records, result)
	assert_eq(F.v(state.run_highest), 4096, "run highest rises to H")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192 stays above")
	assert_false(result.new_best_tile, "no new Best Tile")
	state.score = F.big(60000)
	RunRules.update_records(state, records, result)
	assert_true(result.new_best_score, "a new Best Score")
	assert_eq(records.best_score.to_int(), 60000, "Best Score 60,000")


# Repeatability and random play

func test_restoring_state_and_generator_repeats_a_move_exactly() -> void:
	var rng: RunRandom = F.seeded(77)
	var records: Records = Records.new()
	var state: RunState = RunRules.new_run(rng, records, config)
	var saved_state: RunState = state.copy()
	var saved_records: Records = records.copy()
	var saved_rng: int = rng.get_state()
	var pair: Array[Vector2i] = _first_pair(state.cells)
	var first: MoveResult = RunRules.commit_chain(state, records, pair, rng, config)
	var after_first: RunState = state.copy()
	var restored: RunState = saved_state.copy()
	var restored_records: Records = saved_records.copy()
	rng.set_state(saved_rng)
	var second: MoveResult = RunRules.commit_chain(restored, restored_records, pair, rng, config)
	assert_true(first.accepted and second.accepted, "both accepted")
	assert_true(restored.equals(after_first), "the same state after the same move")
	assert_eq(second.spawn_values, first.spawn_values, "the same spawns")
	assert_eq(second.cells_after, first.cells_after, "the same board")


func _first_pair(board: PackedInt64Array) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = F.equal_pairs(board)
	var pair: Array[Vector2i] = [pairs[0], pairs[1]]
	return pair


## The chain part of AT-84 (boosters add the rest): random commits never take
## the score below zero, add exactly their sum, keep the board full of powers
## of two at or above the window floor, and refused lists change nothing.
func test_random_chain_play_keeps_every_invariant() -> void:
	var accepted: int = 0
	var refused: int = 0
	for seed_value: int in range(1, 21):
		var rng: RunRandom = F.seeded(seed_value)
		var records: Records = Records.new()
		var state: RunState = RunRules.new_run(rng, records, config)
		var moves: RandomNumberGenerator = RandomNumberGenerator.new()
		moves.seed = seed_value * 1000
		for action: int in 150:
			var chain: Array[Vector2i] = []
			if moves.randi_range(0, 3) == 0:
				for count: int in moves.randi_range(0, 4):
					chain.append(Vector2i(moves.randi_range(-1, 5), moves.randi_range(-1, 8)))
			else:
				chain = CoreRules.step_chain(state.cells, BigNum.zero(), chain, Vector2i(moves.randi_range(0, 4), moves.randi_range(0, 7)), config)
				var length: int = moves.randi_range(2, 10)
				while chain.size() < length:
					var options: Array[Vector2i] = CoreRules.joinable_cells(state.cells, BigNum.zero(), chain, config)
					if options.is_empty():
						break
					chain.append(options[moves.randi_range(0, options.size() - 1)])
			var before: RunState = state.copy()
			var records_before: Records = records.copy()
			var rng_state: int = rng.get_state()
			var valid: bool = CoreRules.is_valid_chain(state.cells, BigNum.zero(), chain, config)
			var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
			if result.accepted != valid:
				fail("seed %d action %d: accepted %s but valid %s" % [seed_value, action, result.accepted, valid])
				return
			if not result.accepted:
				refused += 1
				if not state.equals(before) or rng.get_state() != rng_state or not records.best_score.equals(records_before.best_score) or records.best_tile != records_before.best_tile:
					fail("seed %d action %d: a refused chain changed something" % [seed_value, action])
					return
				continue
			accepted += 1
			var problem: String = _check_after_commit(before, state, records, result, chain)
			if not problem.is_empty():
				fail("seed %d action %d: %s" % [seed_value, action, problem])
				return
			if not CoreRules.has_valid_move(state.cells, BigNum.zero(), config):
				state = RunRules.new_run(rng, records, config)
	assert_true(accepted > 1000, "plenty of chains were committed (%d)" % accepted)
	assert_true(refused > 300, "plenty of lists were refused (%d)" % refused)


func _check_after_commit(before: RunState, state: RunState, records: Records, result: MoveResult, chain: Array[Vector2i]) -> String:
	var total: int = 0
	for value: int in F.values_of(before.cells, chain):
		total += value
	if not result.points.equals(F.big(total)) or not state.score.equals(before.score.add(F.big(total))):
		return "points %s for a sum of %d" % [result.points.to_decimal(), total]
	var floor_now: int = CoreRules.window_floor(state.highest(), config)
	for value: int in state.cells:
		if value < 1:
			return "a cell holds exponent %d" % value
		if value < floor_now:
			return "a 2^%d is below the floor 2^%d" % [value, floor_now]
	if state.snapshot_cells != before.cells or not state.snapshot_points.equals(F.big(total)):
		return "the snapshot is not the board before the chain"
	if state.run_highest < state.highest() or records.best_tile < state.run_highest or records.best_score.compare(state.score) < 0:
		return "records or run highest fell behind"
	if _replay(result) != result.cells_after or result.cells_after != state.cells:
		return "the result does not replay to the board"
	if result.has_valid_move != CoreRules.has_valid_move(state.cells, BigNum.zero(), config):
		return "has_valid_move is wrong"
	return ""

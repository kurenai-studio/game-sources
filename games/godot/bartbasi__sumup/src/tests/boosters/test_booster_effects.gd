extends "res://tests/base_test.gd"
## Hammer (D-23), Swap (D-24), Shuffle (D-25) and Double (D-26) through
## BoosterRules.apply, with small tile clearing (D-38, D-39), records (D-16,
## D-17, D-41) and the moves the result reports for the view (TH12). Setups
## hold no free booster unless they say so (GDD section 19).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const START_WINDOW: PackedInt64Array = [2, 4, 8, 16]

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _apply(id: StringName, state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return BoosterRules.apply(id, state, records, BF.targets(cells), rng, config)


func _commit(state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return RunRules.commit_chain(state, records, BF.targets(cells), rng, config)


func _idx(cell: Vector2i) -> int:
	return cell.y * F.COLUMNS + cell.x


## Rebuilds the board after the move from cells_before and the steps the
## result lists, the way the board view animates it. Swap and Shuffle list no
## steps. Returns an empty board when a tile lands on a full cell.
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


## Every column of a and b except the listed ones is equal.
func _other_columns_equal(a: PackedInt64Array, b: PackedInt64Array, skip: Array[int]) -> bool:
	for column: int in F.COLUMNS:
		if not skip.has(column) and F.column_of(a, column) != F.column_of(b, column):
			return false
	return true


# Hammer (D-23)

func test_at_67_hammer() -> void:
	var board: PackedInt64Array = F.with_column(F.changed(F.board_d(), {Vector2i(2, 0): 1024}), 3, PackedInt64Array([2, 8, 4, 16, 64, 8, 32, 2]))
	var state: RunState = F.state(board, 3000)
	var rng: RunRandom = F.seeded(67)
	rng.script_spawns(F.ev(PackedInt64Array([4])))
	var result: MoveResult = _apply(BoosterRules.HAMMER, state, Records.new(), [Vector2i(3, 4)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(result.kind, MoveResult.Kind.HAMMER, "kind")
	assert_eq(result.booster_id, BoosterRules.HAMMER, "booster id")
	assert_eq(F.column_of(state.cells, 3), PackedInt64Array([4, 2, 8, 4, 16, 8, 32, 2]), "column 3 (HM1)")
	assert_eq(BF.n(state.score), 1976, "score 1,976")
	assert_eq(BF.n(result.cost), 1024, "cost B = 1,024")
	assert_eq(BF.n(result.points), 0, "boosters add no points")
	assert_true(_other_columns_equal(state.cells, board, [3]), "no other column changed")
	assert_false(state.has_snapshot(), "the Undo snapshot (none) is unchanged")
	assert_eq(result.emptied, [Vector2i(3, 4)] as Array[Vector2i], "the hammered cell")
	assert_eq(result.fall_from, [Vector2i(3, 3), Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0)] as Array[Vector2i], "the tiles above fall, lowest first")
	assert_eq(result.fall_to, [Vector2i(3, 4), Vector2i(3, 3), Vector2i(3, 2), Vector2i(3, 1)] as Array[Vector2i], "one cell each")
	assert_eq(result.spawn_cells, [Vector2i(3, 0)] as Array[Vector2i], "one new tile at the top of the column")
	assert_eq(F.vv(result.spawn_values), PackedInt64Array([4]), "the scripted 4")
	assert_true(result.cleared_small.is_empty(), "Hammer never clears small tiles")
	assert_eq(result.cells_before, board, "cells_before")
	assert_eq(result.cells_after, state.cells, "cells_after")
	_assert_replays(result, "AT-67")


func test_at_37_a_hammer_that_lowers_h_lowers_the_window_at_once() -> void:
	for seed_value: int in range(1, 201):
		var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(4, 7): 1024}), 10000)
		var records: Records = F.records(0, 4096)
		var result: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(0, 7)], F.seeded(seed_value))
		var problem: String = ""
		if not result.accepted or BF.n(state.score) != 5904:
			problem = "score %d" % BF.n(state.score)
		elif result.spawn_cells != ([Vector2i(0, 0)] as Array[Vector2i]) or not START_WINDOW.has(F.v(state.value_at(Vector2i(0, 0)))):
			problem = "new tile %s at %s" % [result.spawn_values, result.spawn_cells]
		elif BF.price(BoosterRules.HAMMER, state, config) != 1024:
			problem = "Hammer costs %d" % BF.price(BoosterRules.HAMMER, state, config)
		elif F.v(records.best_tile) != 4096 or F.v(state.run_highest) != 4096:
			problem = "Best Tile %d, run highest %d" % [F.v(records.best_tile), F.v(state.run_highest)]
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_hm2_hammer_on_the_only_highest_tile() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 3): 4096, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = F.records(0, 4096)
	var rng: RunRandom = F.seeded(2)
	var result: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(2, 3)], rng)
	assert_eq(BF.n(result.cost), 4096, "the cost was read before the effect")
	assert_eq(BF.n(state.score), 5904, "score 5,904")
	assert_eq(F.v(state.highest()), 1024, "H is now 1024")
	assert_true(START_WINDOW.has(result.spawn_values[0]), "the new tile comes from 2, 4, 8, 16 (S2)")
	assert_eq(BF.price(BoosterRules.DOUBLE, state, config), 2048, "prices drop to the 1024 level")
	assert_eq(F.v(records.best_tile), 4096, "Best Tile stays 4096 (T3)")
	_assert_replays(result, "HM2")


func test_hammer_on_the_top_row() -> void:
	var board: PackedInt64Array = BF.board_d1024()
	var state: RunState = F.state(board, 1500)
	var rng: RunRandom = F.seeded(5)
	rng.script_spawns(F.ev(PackedInt64Array([16])))
	var result: MoveResult = _apply(BoosterRules.HAMMER, state, Records.new(), [Vector2i(4, 0)], rng)
	assert_true(result.accepted, "accepted")
	assert_true(result.fall_from.is_empty(), "nothing above it, so nothing falls")
	assert_eq(result.spawn_cells, [Vector2i(4, 0)] as Array[Vector2i], "the new tile fills the same cell")
	assert_eq(state.cells, F.changed(board, {Vector2i(4, 0): 16}), "only that cell changed")
	assert_eq(BF.n(state.score), 476, "charged B = 1,024")
	_assert_replays(result, "top row Hammer")


func test_hammer_on_the_highest_tile_in_the_top_row_lowers_the_window() -> void:
	var state: RunState = F.state(BF.board_d1024(), 5000)
	var result: MoveResult = _apply(BoosterRules.HAMMER, state, Records.new(), [Vector2i(2, 0)], F.seeded(8))
	assert_eq(BF.n(result.cost), 1024, "cost read before the effect")
	assert_eq(F.v(state.highest()), 16, "the 1024 is gone")
	assert_true(START_WINDOW.has(F.v(state.value_at(Vector2i(2, 0)))), "the new tile comes from the window after the Hammer")
	assert_eq(F.v(state.run_highest), 1024, "the run highest tile is not lowered")


# Swap (D-24)

func test_at_68_swap() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 2048, Vector2i(0, 0): 32})
	var state: RunState = F.state(board, 10000)
	var rng: RunRandom = F.seeded(68)
	var rng_before: int = rng.get_state()
	var result: MoveResult = _apply(BoosterRules.SWAP, state, Records.new(), [Vector2i(0, 0), Vector2i(4, 7)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(result.kind, MoveResult.Kind.SWAP, "kind")
	assert_eq(F.v(state.value_at(Vector2i(0, 0))), 8, "(0,0) = 8")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 32, "(4,7) = 32")
	assert_eq(state.cells, F.changed(board, {Vector2i(0, 0): 8, Vector2i(4, 7): 32}), "every other cell unchanged")
	assert_true(result.spawn_cells.is_empty() and result.fall_from.is_empty(), "no gravity, no new tiles")
	assert_eq(result.targets, [Vector2i(0, 0), Vector2i(4, 7)] as Array[Vector2i], "targets hold both cells")
	assert_eq(BF.n(state.score), 7952, "score 7,952 (SW1)")
	assert_eq(BF.n(result.cost), 2048, "cost B")
	assert_eq(rng.get_state(), rng_before, "Swap draws nothing")


func test_at_52_swap_rescues_on_the_rules_model() -> void:
	var board: PackedInt64Array = F.changed(BF.board_d1024(), {Vector2i(0, 0): 32, Vector2i(4, 7): 32})
	var state: RunState = F.state(board, 1500)
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.OFFER, "no move, the offer is open")
	var result: MoveResult = _apply(BoosterRules.SWAP, state, Records.new(), [Vector2i(4, 7), Vector2i(1, 0)], F.seeded(52))
	assert_eq(F.v(state.value_at(Vector2i(1, 0))), 32, "(1,0) = 32")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 4, "(4,7) = 4")
	assert_eq(BF.n(state.score), 476, "score 476")
	assert_true(result.has_valid_move, "the board has a valid move")
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.PLAY, "play goes on")


# Shuffle (D-25)

func test_at_70_shuffle_keeps_the_values_and_leaves_a_move() -> void:
	var board: PackedInt64Array = BF.board_d1024()
	for seed_value: int in range(1, 1001):
		var state: RunState = F.state(board, 5000)
		var result: MoveResult = _apply(BoosterRules.SHUFFLE, state, Records.new(), [], F.seeded(seed_value))
		var problem: String = ""
		if not result.accepted or BF.n(state.score) != 3976:
			problem = "score %d" % BF.n(state.score)
		elif BF.sorted(state.cells) != BF.sorted(board):
			problem = "the values changed"
		elif not CoreRules.has_valid_move(state.cells, state.score, config) or not result.has_valid_move:
			problem = "no valid move"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_sh1_shuffle_cost_and_result() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096})
	var state: RunState = BF.make(board, 20000, F.board_p(), 16)
	var result: MoveResult = _apply(BoosterRules.SHUFFLE, state, Records.new(), [], F.seeded(21))
	assert_eq(result.kind, MoveResult.Kind.SHUFFLE, "kind")
	assert_eq(BF.n(result.cost), 4096, "Shuffle costs 4,096")
	assert_eq(BF.n(state.score), 15904, "score 15,904")
	assert_eq(BF.sorted(state.cells), BF.sorted(board), "same 40 values")
	assert_ne(state.cells, board, "new places")
	assert_true(CoreRules.has_valid_move(state.cells, state.score, config), "at least one valid move")
	assert_eq(result.cells_before, board, "the view animates from cells_before")
	assert_eq(result.cells_after, state.cells, "to cells_after")
	assert_true(result.cleared_small.is_empty() and result.spawn_cells.is_empty(), "no clearing, no spawns")
	assert_eq(state.snapshot_cells, F.board_p(), "the snapshot is untouched")
	assert_eq(BF.n(state.snapshot_points), 16, "and its points")


func test_at_71_shuffle_with_only_one_equal_pair() -> void:
	var board: PackedInt64Array = PackedInt64Array()
	for exponent: int in range(1, 40):
		board.append(exponent)
	board.append(1)
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "the setup has no move: the two 2s are far apart")
	for seed_value: int in range(1, 1001):
		var state: RunState = BF.none_held(F.state(board, 1 << 41))
		var result: MoveResult = _apply(BoosterRules.SHUFFLE, state, Records.new(), [], F.seeded(seed_value))
		var pairs: Array[Vector2i] = F.equal_pairs(state.cells)
		var problem: String = ""
		if not result.accepted or BF.n(state.score) != (1 << 41) - (1 << 39):
			problem = "score %d" % BF.n(state.score)
		elif pairs.size() != 2 or F.v(state.value_at(pairs[0])) != 2:
			problem = "the two 2s do not touch"
		elif BF.sorted(state.cells) != BF.sorted(board):
			problem = "the values changed"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_at_72_shuffle_fallback() -> void:
	var state: RunState = F.state(F.board_d(), 1000)
	var rng: RunRandom = F.seeded(72)
	rng.force_shuffle(F.board_d())
	var result: MoveResult = _apply(BoosterRules.SHUFFLE, state, Records.new(), [], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(rng.shuffle_attempts, 100, "exactly 100 arrangements")
	assert_eq(state.cells, F.changed(F.board_d(), {Vector2i(1, 0): 2, Vector2i(2, 0): 4}), "Board D with (1,0) = 2 and (2,0) = 4 (SH2)")
	assert_true(CoreRules.has_valid_move(state.cells, state.score, config), "it has a valid move")
	assert_eq(BF.n(state.score), 872, "score 872")


func test_shuffle_fallback_with_p_in_the_last_column() -> void:
	# Every value is different except (4,0) and (2,5), which do not touch.
	var board: PackedInt64Array = PackedInt64Array()
	for exponent: int in range(1, 41):
		board.append(exponent)
	var twin: int = board[CoreRules.index_of(Vector2i(4, 0), F.COLUMNS)]
	board[CoreRules.index_of(Vector2i(2, 5), F.COLUMNS)] = twin
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "the forced arrangement has no move")
	var state: RunState = BF.none_held(F.state(board, 1 << 41))
	var rng: RunRandom = F.seeded(1)
	rng.force_shuffle(board)
	_apply(BoosterRules.SHUFFLE, state, Records.new(), [], rng)
	var below: int = board[CoreRules.index_of(Vector2i(4, 1), F.COLUMNS)]
	assert_eq(state.cells, F.changed_exponents(board, {Vector2i(4, 1): twin, Vector2i(2, 5): below}), "Q swaps with the cell below P")
	assert_eq(F.equal_pairs(state.cells), [Vector2i(4, 0), Vector2i(4, 1)] as Array[Vector2i], "P and its twin now touch")


func test_shuffle_attempts_follow_the_config_and_stop_at_a_move() -> void:
	config.shuffle_max_attempts = 5
	var state: RunState = F.state(F.board_d(), 1000)
	var rng: RunRandom = F.seeded(1)
	rng.force_shuffle(F.board_d())
	_apply(BoosterRules.SHUFFLE, state, Records.new(), [], rng)
	assert_eq(rng.shuffle_attempts, 5, "SHUFFLE_MAX_ATTEMPTS override")
	var lucky: RunState = F.state(F.board_d(), 1000)
	rng.force_shuffle(F.board_p())
	_apply(BoosterRules.SHUFFLE, lucky, Records.new(), [], rng)
	assert_eq(rng.shuffle_attempts, 1, "a first arrangement with a move is used as is")
	assert_eq(lucky.cells, F.board_p(), "unchanged by the fallback")


func test_at_73_shuffle_with_no_equal_pair() -> void:
	var board: PackedInt64Array = PackedInt64Array()
	for exponent: int in range(1, 41):
		board.append(exponent)
	var state: RunState = BF.none_held(F.state(board, 1 << 41))
	var rng: RunRandom = F.seeded(73)
	var result: MoveResult = _apply(BoosterRules.SHUFFLE, state, Records.new(), [], rng)
	assert_true(result.accepted, "Shuffle still runs")
	assert_eq(BF.n(state.score), 1 << 40, "score 2^40")
	assert_eq(BF.sorted(state.cells), BF.sorted(board), "the same 40 values")
	assert_ne(state.cells, board, "in new places")
	assert_false(CoreRules.has_valid_move(state.cells, state.score, config), "no valid move")
	assert_eq(rng.shuffle_attempts, 100, "every attempt was tried")
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.OFFER, "the no moves offer opens")


# Double (D-26)

func test_at_74_double_makes_a_pair() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 32})
	var state: RunState = F.state(board, 30000)
	var rng: RunRandom = F.seeded(74)
	var rng_before: int = rng.get_state()
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, Records.new(), [Vector2i(1, 1)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(result.kind, MoveResult.Kind.DOUBLE, "kind")
	assert_eq(F.v(state.value_at(Vector2i(1, 1))), 32, "(1,1) = 32")
	assert_eq(state.cells, F.changed(board, {Vector2i(1, 1): 32}), "nothing else moves")
	assert_eq(BF.n(state.score), 21808, "score 21,808 (DB1)")
	assert_eq(BF.n(result.cost), 8192, "cost 2B")
	assert_eq(result.result_cell, Vector2i(1, 1), "the doubled tile")
	assert_eq(F.v(result.result_value), 32, "its new value")
	assert_true(result.spawn_cells.is_empty() and result.fall_from.is_empty() and result.cleared_small.is_empty(), "no clear, no gravity, no spawn")
	assert_eq(rng.get_state(), rng_before, "nothing was drawn")
	assert_eq(F.equal_pairs(state.cells), [Vector2i(0, 0), Vector2i(1, 1)] as Array[Vector2i], "the valid move is (0,0) with (1,1)")


func test_at_75_double_on_the_highest_tile() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 32})
	var state: RunState = F.state(board, 30000)
	var records: Records = F.records(0, 4096)
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], F.seeded(75))
	assert_eq(F.v(result.result_value), 8192, "the tile becomes 8192")
	assert_eq(BF.n(result.cost), 8192, "the cost was read before the effect")
	assert_eq(BF.n(state.score), 21808, "score 21,808")
	assert_eq(F.v(result.floor_before), 8, "floor before 8")
	assert_eq(F.v(result.floor_after), 16, "floor after 16")
	assert_eq(result.cleared_small.size(), 30, "all 30 tiles of value 2, 4 and 8 clear")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2, 4, 8]), "values 2, 4 and 8")
	assert_eq(F.v(state.value_at(Vector2i(2, 7))), 8192, "the 8192 fell to (2,7)")
	assert_eq(result.spawn_cells.size(), 30, "30 cells refill")
	assert_true(F.all_in(result.spawn_values, PackedInt64Array([16, 32, 64, 128])), "from 16, 32, 64, 128")
	assert_true(BF.lowest(state.cells) >= 16, "no tile below 16 is left (DB2)")
	assert_eq(BF.price(BoosterRules.HAMMER, state, config), 8192, "Hammer now costs 8,192")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192")
	assert_eq(F.v(state.run_highest), 8192, "run highest 8192")
	assert_true(result.new_best_tile, "a new Best Tile")
	assert_eq(result.stars_earned, 1, "the 8192 is this run's third star (D-45)")
	assert_eq(result.free_earned, 1, "so it earns one free booster")
	assert_eq(CoreRules.free_held(state, config), 1, "which is now held (D-46)")
	assert_true(BoosterRules.is_free(state, config), "so every booster reads Free")
	assert_false(result.free_used, "the Double itself was paid")
	_assert_replays(result, "AT-75")


func test_at_101_a_double_clears_small_tiles_and_rescues() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})
	var state: RunState = F.state(board, 5000)
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.OFFER, "the offer is open")
	var rng: RunRandom = F.seeded(101)
	rng.script_spawns(F.ev(PackedInt64Array([8])))
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, Records.new(), [Vector2i(2, 0)], rng)
	assert_eq(BF.n(state.score), 2952, "score 2,952")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 2048, "(2,0) = 2048, on the top row, does not move")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "the 2 on (0,3) was cleared")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2]), "value 2")
	assert_eq(F.column_of(state.cells, 0), PackedInt64Array([8, 4, 8, 4, 4, 8, 4, 8]), "(0,0) = 8, (0,3) and (0,4) are both 4 (CL2)")
	assert_eq(result.spawn_cells, [Vector2i(0, 0)] as Array[Vector2i], "only (0,0) refills")
	assert_true(result.has_valid_move, "the board has a valid move")
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.PLAY, "the offer closes")
	_assert_replays(result, "AT-101")


func test_double_on_the_top_row_without_clearing() -> void:
	var board: PackedInt64Array = BF.board_d1024()
	var state: RunState = F.state(board, 3000)
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, Records.new(), [Vector2i(4, 0)], F.seeded(1))
	assert_eq(state.cells, F.changed(board, {Vector2i(4, 0): 4}), "the 2 on (4,0) became 4 in place")
	assert_eq(BF.n(state.score), 952, "charged 2B = 2,048")
	assert_true(result.cleared_small.is_empty(), "no clear: the floor did not rise")


func test_double_that_does_not_raise_the_floor_never_clears() -> void:
	# H is 2048 with a 1024 below it. Doubling the 1024 ties H: the floor stays.
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 2048, Vector2i(4, 4): 1024})
	var state: RunState = F.state(board, 50000)
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, Records.new(), [Vector2i(4, 4)], F.seeded(1))
	assert_true(result.accepted, "accepted")
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_eq(BF.count(state.cells, 2), 1, "the 2 below the floor stays")
	assert_eq(state.cells, F.changed(board, {Vector2i(4, 4): 2048}), "only the doubled tile changed")


# Score and records with boosters

func test_at_40_boosters_add_no_points() -> void:
	var state: RunState = F.state(BF.board_d1024(), 10000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(40)
	var scores: Array[int] = []
	var steps: Array[Array] = [
		[BoosterRules.HAMMER, [Vector2i(4, 7)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)]],
		[BoosterRules.DOUBLE, [Vector2i(0, 2)]],
		[BoosterRules.SHUFFLE, []],
	]
	for step: Array in steps:
		var result: MoveResult = _apply(step[0], state, records, step[1], rng)
		assert_true(result.accepted, "%s accepted" % step[0])
		assert_eq(BF.n(result.points), 0, "%s adds no points" % step[0])
		scores.append(BF.n(state.score))
	assert_eq(scores, [8976, 7952, 5904, 4880] as Array[int], "score after each step")


func test_at_41_hammer_after_the_commit_keeps_best_score() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 0): 8}), 9990)
	var records: Records = F.records(10000, 0)
	var rng: RunRandom = F.seeded(41)
	_commit(state, records, [Vector2i(0, 0), Vector2i(0, 1)], rng)
	assert_eq(BF.n(state.score), 10006, "score 10,006 after the commit")
	assert_eq(BF.n(records.best_score), 10006, "Best Score 10,006")
	var result: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(3, 3)], rng)
	assert_eq(BF.n(result.cost), 128, "cost 128")
	assert_eq(BF.n(state.score), 9878, "score 9,878")
	assert_eq(BF.n(records.best_score), 10006, "Best Score still 10,006")
	assert_false(result.new_best_score, "no new Best Score")


func test_at_43_best_tile_counts_double_and_is_not_lowered_by_hammer() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096}), 50000)
	var records: Records = F.records(0, 4096)
	var rng: RunRandom = F.seeded(43)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(F.v(records.best_tile), 8192, "after the commit Best Tile 8192")
	assert_eq(BF.n(state.score), 58192, "score 58,192")
	assert_eq(CoreRules.free_held(state, config), 1, "the 8192 is the third star: one free booster held (D-46)")
	var doubled: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [BF.find(state.cells, 8192)], rng)
	assert_true(doubled.accepted, "the Double is accepted")
	assert_true(doubled.free_used, "and uses the free booster")
	assert_eq(BF.n(doubled.cost), 0, "so it charges 0")
	assert_eq(BF.n(state.score), 58192, "score stays 58,192")
	assert_eq(F.v(records.best_tile), 16384, "Best Tile 16384 (T2)")
	assert_eq(CoreRules.free_held(state, config), 0, "no free booster held")
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [BF.find(state.cells, 16384)], rng)
	assert_false(hammered.free_used, "the Hammer is paid")
	assert_eq(BF.n(hammered.cost), 16384, "Hammer costs 16,384")
	assert_eq(BF.n(state.score), 41808, "score 41,808")
	assert_true(F.v(state.highest()) < 16384, "H is below 16384")
	assert_eq(F.v(records.best_tile), 16384, "Best Tile still 16384 (T3)")


func test_at_38_hammer_lowers_the_floor_then_a_chain_raises_it() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(2, 7): 2048, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(38)
	rng.script_spawns(F.ev(PackedInt64Array([2, 8, 8])))
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(2, 7)], rng)
	assert_eq(BF.n(state.score), 7952, "after the Hammer: score 7,952")
	assert_eq(F.v(state.highest()), 1024, "H = 1024")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 2, "(2,0) = 2")
	assert_true(hammered.cleared_small.is_empty(), "nothing was cleared")
	var chain: MoveResult = _commit(state, records, [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_eq(BF.n(state.score), 10000, "after the chain: score 10,000")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 2048, "(4,7) = 2048")
	assert_eq(chain.cleared_small, [Vector2i(2, 0)] as Array[Vector2i], "the 2 on (2,0) was cleared")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 8, "(2,0) = 8")
	assert_eq(F.v(state.value_at(Vector2i(4, 0))), 8, "(4,0) = 8")
	assert_eq(BF.count(state.cells, 2), 0, "no 2 is left (CL4)")


func test_at_103_only_a_raised_floor_clears() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 2048})
	var state: RunState = F.state(board, 20000)
	var rng: RunRandom = F.seeded(103)
	rng.script_spawns(F.ev(PackedInt64Array([4])))
	var steps: Array[Array] = [
		[BoosterRules.HAMMER, [Vector2i(4, 7)], 17952],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)], 15904],
		[BoosterRules.DOUBLE, [Vector2i(0, 0)], 11808],
		[BoosterRules.SHUFFLE, [], 9760],
	]
	for step: Array in steps:
		var result: MoveResult = _apply(step[0], state, Records.new(), step[1], rng)
		assert_true(result.accepted, "%s accepted" % step[0])
		assert_eq(BF.n(state.score), step[2], "score after %s" % step[0])
		assert_eq(BF.count(state.cells, 2), 1, "exactly one 2 after %s" % step[0])
		assert_true(result.cleared_small.is_empty(), "%s reports no cleared tiles" % step[0])


func test_at_108_run_highest_through_double_hammer_and_undo() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var state: RunState = BF.make(board, 50000, PackedInt64Array(), 0, 1024)
	var records: Records = F.records(0, 8192)
	var rng: RunRandom = F.seeded(108)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq([BF.n(state.score), F.v(state.run_highest), F.v(records.best_tile)], [52048, 2048, 8192], "after the commit")
	var doubled: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(1, 7)], rng)
	assert_eq(BF.n(doubled.cost), 4096, "Double costs 4,096")
	assert_eq([BF.n(state.score), F.v(state.run_highest), F.v(records.best_tile)], [47952, 4096, 8192], "after Double (RH3)")
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(1, 7)], rng)
	assert_eq(BF.n(hammered.cost), 4096, "Hammer costs 4,096")
	assert_eq([BF.n(state.score), F.v(state.run_highest), F.v(records.best_tile)], [43856, 4096, 8192], "after Hammer (RH4)")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 64, "Undo costs 64: only tiles up to 64 remain")
	var undone: MoveResult = _apply(BoosterRules.UNDO, state, records, [], rng)
	assert_eq(BF.n(undone.cost), 64, "charged 64")
	assert_eq([BF.n(state.score), F.v(state.run_highest), F.v(records.best_tile)], [41744, 4096, 8192], "after Undo")
	var fresh: RunState = RunRules.new_run(rng, records, config)
	assert_eq(BF.n(fresh.score), 0, "new run score 0")
	assert_true(F.v(fresh.run_highest) <= 16 and fresh.run_highest == fresh.highest(), "the new board's highest tile")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192")


func test_hammer_swap_shuffle_and_double_leave_the_snapshot_alone() -> void:
	var cases: Array[Array] = [
		[BoosterRules.HAMMER, [Vector2i(1, 1)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(4, 7)]],
		[BoosterRules.SHUFFLE, []],
		[BoosterRules.DOUBLE, [Vector2i(2, 0)]],
	]
	for each: Array in cases:
		var state: RunState = BF.make(BF.board_d1024(), 9000, BF.snapshot_board(), 40)
		var result: MoveResult = _apply(each[0], state, Records.new(), each[1], F.seeded(6))
		assert_true(result.accepted, "%s accepted" % each[0])
		assert_eq(state.snapshot_cells, BF.snapshot_board(), "%s keeps the snapshot board" % each[0])
		assert_eq(BF.n(state.snapshot_points), 40, "%s keeps the snapshot points" % each[0])


func test_records_rise_from_a_booster_that_raises_h() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(2, 0): 1024}), 5000)
	var records: Records = F.records(9000, 1024)
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], F.seeded(17))
	assert_eq(F.v(records.best_tile), 2048, "Best Tile follows the Double at once")
	assert_eq(BF.n(records.best_score), 9000, "Best Score is not touched by spending")
	assert_true(result.new_best_tile, "new_best_tile")
	assert_false(result.new_best_score, "new_best_score")

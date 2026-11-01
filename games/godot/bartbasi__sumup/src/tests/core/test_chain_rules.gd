extends "res://tests/base_test.gd"
## Adjacency, joining (D-04), backtracking (D-05), the full chain check (6.1)
## and the joinable highlight (D-40), all through CoreRules. The board builds
## every chain through CoreRules.step_chain, so these cover AT-06 to AT-16,
## AT-105 and AT-106 headless.

const F := preload("res://tests/core/core_fixtures.gd")

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


## Steps the finger through cells from an empty chain, as the board would.
func _drag(board: PackedInt64Array, cells: Array[Vector2i]) -> Array[Vector2i]:
	var chain: Array[Vector2i] = []
	for cell: Vector2i in cells:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
	return chain


## The preview as a tile value: merge_result works on exponents.
func _preview(board: PackedInt64Array, chain: Array[Vector2i]) -> int:
	return F.v(CoreRules.merge_result(F.ev(F.values_of(board, chain))))


# Adjacency and cells

func test_touching_covers_all_eight_directions() -> void:
	var center: Vector2i = Vector2i(2, 3)
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			var other: Vector2i = center + Vector2i(dx, dy)
			if dx == 0 and dy == 0:
				assert_false(CoreRules.touching(center, other), "a cell does not touch itself")
			else:
				assert_true(CoreRules.touching(center, other), "touches %s" % other)
				assert_true(CoreRules.touching(other, center), "both ways %s" % other)


func test_touching_refuses_far_cells_and_row_wrap() -> void:
	assert_false(CoreRules.touching(Vector2i(2, 3), Vector2i(4, 3)), "two columns apart")
	assert_false(CoreRules.touching(Vector2i(2, 3), Vector2i(2, 5)), "two rows apart")
	assert_false(CoreRules.touching(Vector2i(0, 0), Vector2i(2, 2)), "two diagonal steps")
	assert_false(CoreRules.touching(Vector2i(4, 0), Vector2i(0, 1)), "next in index order but on the other edge")
	assert_false(CoreRules.touching(Vector2i(0, 1), Vector2i(4, 0)), "row wrap the other way")


func test_index_and_cell_round_trip() -> void:
	assert_eq(CoreRules.index_of(Vector2i(0, 0), 5), 0, "top left")
	assert_eq(CoreRules.index_of(Vector2i(4, 0), 5), 4, "top right")
	assert_eq(CoreRules.index_of(Vector2i(0, 1), 5), 5, "second row")
	assert_eq(CoreRules.index_of(Vector2i(4, 7), 5), 39, "bottom right")
	for index: int in 40:
		assert_eq(CoreRules.index_of(CoreRules.cell_of(index, 5), 5), index, "round trip %d" % index)
	assert_eq(CoreRules.cell_of(13, 5), Vector2i(3, 2), "cell of 13")


func test_in_bounds_edges_and_corners() -> void:
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(4, 0), Vector2i(0, 7), Vector2i(4, 7), Vector2i(2, 3)]:
		assert_true(CoreRules.in_bounds(cell, config), "in %s" % cell)
	for cell: Vector2i in [Vector2i(-1, 0), Vector2i(5, 0), Vector2i(0, -1), Vector2i(0, 8), Vector2i(-1, -1), Vector2i(5, 8)]:
		assert_false(CoreRules.in_bounds(cell, config), "out %s" % cell)


func test_is_power_of_two() -> void:
	for power: int in 63:
		assert_true(CoreRules.is_power_of_two(1 << power), "2^%d" % power)
	for value: int in [0, -2, 3, 6, 12, 1000, 1023, 1025, 3072]:
		assert_false(CoreRules.is_power_of_two(value), "%d" % value)
	assert_false(CoreRules.is_power_of_two(-9223372036854775807 - 1), "the lowest int")


# Joining, AT-06 to AT-11

func test_at_06_first_two_tiles_must_be_equal() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6)])
	assert_eq(chain, [Vector2i(1, 6)] as Array[Vector2i], "first tile")
	assert_eq(_preview(board, chain), 0, "no preview at 1 tile")
	chain = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(1, 5), config)
	assert_eq(chain, [Vector2i(1, 6)] as Array[Vector2i], "the 4 does not join a single 2")
	assert_eq(_preview(board, chain), 0, "still no preview")
	# Lifting cancels: the rules model refuses a 1 tile chain and changes nothing.
	var state: RunState = F.state(board, 0)
	var before: RunState = state.copy()
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(6)
	var rng_state: int = rng.get_state()
	var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
	assert_false(result.accepted, "lifting on 1 tile is refused")
	assert_true(state.equals(before), "board, score and Undo state unchanged")
	assert_eq(rng.get_state(), rng_state, "the random generator was not used")


func test_at_07_an_equal_second_tile_joins() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6)])
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2]), "chain 2, 2")
	assert_eq(_preview(board, chain), 4, "preview 4")


func test_at_08_a_double_joins_from_the_third_tile_on() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)])
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2, 4]), "chain 2, 2, 4")
	assert_eq(_preview(board, chain), 8, "preview 8")


func test_at_09_more_than_double_does_not_join() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 7)])
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2, 4]), "the 32 does not join")
	assert_eq(_preview(board, chain), 8, "preview 8")


func test_at_10_half_does_not_join_diagonal_does() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)])
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2, 4, 8]), "the diagonal 8 joins")
	assert_eq(_preview(board, chain), 16, "preview 16")
	chain = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(1, 5), config)
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2, 4, 8]), "the 4 (half of 8) does not join")
	assert_eq(_preview(board, chain), 16, "preview unchanged")


func test_at_11_all_eight_directions() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var start: Vector2i = Vector2i(2, 3)
	var targets: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(1, 3), Vector2i(3, 3), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
	for target: Vector2i in targets:
		var chain: Array[Vector2i] = _drag(board, [start, target])
		assert_eq(chain, [start, target] as Array[Vector2i], "joins toward %s" % target)
		assert_eq(_preview(board, chain), 8, "preview 8 toward %s" % target)


# The full check, AT-12 and AT-13

func test_at_12_tiles_that_do_not_touch_are_refused() -> void:
	var lists: Array[Array] = [
		[Vector2i(2, 3), Vector2i(4, 3)],
		[Vector2i(2, 3), Vector2i(2, 5)],
		[Vector2i(0, 0), Vector2i(1, 1), Vector2i(3, 3)],
	]
	for list: Array in lists:
		var chain: Array[Vector2i] = []
		chain.assign(list)
		var state: RunState = F.state(F.board_all(4), 0)
		var before: RunState = state.copy()
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(12), config)
		assert_false(result.accepted, "refused %s" % [chain])
		assert_eq(result.refusal, &"invalid_chain", "refusal %s" % [chain])
		assert_true(state.equals(before), "board and score unchanged %s" % [chain])


func test_at_13_invalid_chain_lists_are_refused() -> void:
	var cases: Array[Array] = [
		[F.board_all(4), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0)]],
		[F.board_all(4), [Vector2i(0, 0)]],
		[F.board_p(), [Vector2i(1, 6), Vector2i(1, 5)]],
		[F.board_p(), [Vector2i(1, 6), Vector2i(2, 6), Vector2i(2, 7)]],
		[F.board_p(), [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(1, 5)]],
	]
	for case: Array in cases:
		var board: PackedInt64Array = case[0]
		var chain: Array[Vector2i] = []
		chain.assign(case[1])
		var state: RunState = RunState.create(board, F.big(100), F.board_e(), F.big(8))
		var before: RunState = state.copy()
		var records: Records = F.records(500, 64)
		var rng: RunRandom = F.seeded(13)
		var rng_state: int = rng.get_state()
		var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
		assert_false(result.accepted, "refused %s" % [chain])
		assert_true(state.equals(before), "state unchanged %s" % [chain])
		assert_eq(records.best_score.to_decimal(), "500", "Best Score unchanged %s" % [chain])
		assert_eq(records.best_tile, F.e(64), "Best Tile unchanged %s" % [chain])
		assert_eq(rng.get_state(), rng_state, "generator unchanged %s" % [chain])
		assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), chain, config), "is_valid_chain agrees %s" % [chain])


func test_is_valid_chain_accepts_the_gdd_examples() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5)]
	assert_true(CoreRules.is_valid_chain(board, BigNum.zero(), chain, config), "2, 2, 4, 8, 16 on Board P")
	var pair: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	assert_true(CoreRules.is_valid_chain(board, BigNum.zero(), pair, config), "a pair")
	var crossing: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2)]
	assert_true(CoreRules.is_valid_chain(F.board_all(4), BigNum.zero(), crossing, config), "a path that crosses itself (D-06)")


func test_is_valid_chain_refuses_bad_shapes() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var empty: Array[Vector2i] = []
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), empty, config), "empty")
	var off_board: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0)]
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), off_board, config), "a cell off the board")
	var no_cell: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, 0)]
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), no_cell, config), "the no cell marker")
	var wrap: Array[Vector2i] = [Vector2i(4, 0), Vector2i(0, 1)]
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), wrap, config), "row wrap")
	var same: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0)]
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), same, config), "the same cell twice in a row")
	var holed: PackedInt64Array = F.changed(board, {Vector2i(1, 0): 0})
	var through_hole: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	assert_false(CoreRules.is_valid_chain(holed, BigNum.zero(), through_hole, config), "an empty cell")
	var short_board: PackedInt64Array = PackedInt64Array([2, 2])
	var pair: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	assert_false(CoreRules.is_valid_chain(short_board, BigNum.zero(), pair, config), "a board of the wrong size")


func test_is_valid_chain_follows_min_chain_length_override() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var pair: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	var three: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	config.min_chain_length = 3
	assert_false(CoreRules.is_valid_chain(board, BigNum.zero(), pair, config), "a pair is too short when 3 are needed")
	assert_true(CoreRules.is_valid_chain(board, BigNum.zero(), three, config), "three tiles pass")


# Backtracking, AT-14 to AT-16

func test_at_14_backtracking_shrinks_the_chain_step_by_step() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = []
	var previews: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5)]:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
		previews.append(_preview(board, chain))
	assert_eq(previews, PackedInt64Array([0, 4, 8, 16, 32]), "previews while building")
	var sizes: PackedInt64Array = PackedInt64Array()
	previews = PackedInt64Array()
	for cell: Vector2i in [Vector2i(2, 5), Vector2i(3, 6), Vector2i(2, 6), Vector2i(1, 6)]:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
		sizes.append(chain.size())
		previews.append(_preview(board, chain))
	assert_eq(sizes, PackedInt64Array([4, 3, 2, 1]), "one tile leaves per backtrack")
	assert_eq(previews, PackedInt64Array([16, 8, 4, 0]), "previews after each backtrack")
	assert_eq(chain, [Vector2i(1, 6)] as Array[Vector2i], "back to the first tile")
	var state: RunState = F.state(board, 0)
	var before: RunState = state.copy()
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(14), config)
	assert_false(result.accepted, "lifting cancels")
	assert_true(state.equals(before), "nothing changes")


func test_at_15_a_backtracked_tile_can_join_again() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5), Vector2i(2, 5)])
	assert_eq(chain.size(), 4, "the 16 left")
	chain = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(3, 5), config)
	assert_eq(F.values_of(board, chain), PackedInt64Array([2, 2, 4, 8, 16]), "the 16 joins again")
	assert_eq(_preview(board, chain), 32, "preview 32")


func test_at_16_other_chain_tiles_are_ignored() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)])
	var moved: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(2, 6), config)
	assert_eq(moved, chain, "no change")
	assert_eq(F.values_of(board, moved), PackedInt64Array([2, 2, 4, 8]), "chain 2, 2, 4, 8")
	assert_eq(_preview(board, moved), 16, "preview 16")
	moved = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(1, 6), config)
	assert_eq(moved, chain, "the first tile is ignored too")


## The core half of AT-90: the preview values while dragging M8 tile by tile
## and backtracking off the 16. Hiding it after the lift is the board's job.
func test_at_90_preview_life_cycle() -> void:
	var path: Array[Vector2i] = F.snake_from_bottom(8)
	var board: PackedInt64Array = F.placed(F.board_d(), path, PackedInt64Array([2, 2, 4, 4, 4, 8, 8, 16]))
	var chain: Array[Vector2i] = []
	var previews: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in path:
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, cell, config)
		previews.append(_preview(board, chain))
	assert_eq(chain.size(), 8, "all eight tiles join")
	assert_eq(previews, PackedInt64Array([0, 4, 8, 8, 16, 16, 32, 32]), "none, 4, 8, 8, 16, 16, 32, 32")
	chain = CoreRules.step_chain(board, BigNum.zero(), chain, path[6], config)
	assert_eq(chain.size(), 7, "backtrack off the 16")
	assert_eq(_preview(board, chain), 32, "32 after the backtrack")


## GDD 6.6, C1 to C9 and the second drag, one finger position at a time.
func test_worked_examples_c1_to_c9() -> void:
	var board: PackedInt64Array = F.board_p()
	var path: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 7), Vector2i(2, 5), Vector2i(1, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 6)]
	var expected_values: Array[PackedInt64Array] = [
		PackedInt64Array([2]),
		PackedInt64Array([2, 2]),
		PackedInt64Array([2, 2, 4]),
		PackedInt64Array([2, 2, 4]),
		PackedInt64Array([2, 2, 4, 8]),
		PackedInt64Array([2, 2, 4, 8]),
		PackedInt64Array([2, 2, 4, 8, 16]),
		PackedInt64Array([2, 2, 4, 8]),
		PackedInt64Array([2, 2, 4, 8]),
	]
	var expected_previews: PackedInt64Array = PackedInt64Array([0, 4, 8, 8, 16, 16, 32, 16, 16])
	var chain: Array[Vector2i] = []
	for step: int in path.size():
		chain = CoreRules.step_chain(board, BigNum.zero(), chain, path[step], config)
		assert_eq(F.values_of(board, chain), expected_values[step], "C%d chain" % (step + 1))
		assert_eq(_preview(board, chain), expected_previews[step], "C%d preview" % (step + 1))
	var second: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(1, 5)])
	assert_eq(second.size(), 1, "second drag: the 4 does not join")


func test_step_chain_starts_on_any_tile_and_ignores_off_board() -> void:
	var board: PackedInt64Array = F.board_p()
	var empty: Array[Vector2i] = []
	assert_eq(CoreRules.step_chain(board, BigNum.zero(), empty, Vector2i(2, 7), config), [Vector2i(2, 7)] as Array[Vector2i], "any tile starts a chain")
	assert_true(CoreRules.step_chain(board, BigNum.zero(), empty, Vector2i(-1, -1), config).is_empty(), "no cell starts nothing")
	assert_true(CoreRules.step_chain(board, BigNum.zero(), empty, Vector2i(5, 0), config).is_empty(), "off the board starts nothing")
	var chain: Array[Vector2i] = [Vector2i(4, 6)]
	assert_eq(CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(5, 6), config), chain, "leaving the board keeps the chain (D-06)")
	assert_eq(CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(-1, -1), config), chain, "no cell keeps the chain")


func test_step_chain_returns_a_new_array() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = [Vector2i(1, 6)]
	var grown: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(2, 6), config)
	assert_eq(chain.size(), 1, "the input chain is not changed by a join")
	var shrunk: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), grown, Vector2i(1, 6), config)
	assert_eq(grown.size(), 2, "the input chain is not changed by a backtrack")
	assert_eq(shrunk.size(), 1, "backtracked")
	var same: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(0, 0), config)
	same.append(Vector2i(4, 4))
	assert_eq(chain.size(), 1, "an unchanged result is still a separate array")


func test_step_chain_on_the_last_tile_changes_nothing() -> void:
	var board: PackedInt64Array = F.board_p()
	var chain: Array[Vector2i] = _drag(board, [Vector2i(1, 6), Vector2i(2, 6)])
	assert_eq(CoreRules.step_chain(board, BigNum.zero(), chain, Vector2i(2, 6), config), chain, "finger still on the last tile")
	var single: Array[Vector2i] = [Vector2i(1, 6)]
	assert_eq(CoreRules.step_chain(board, BigNum.zero(), single, Vector2i(1, 6), config), single, "the first tile never leaves")


func test_chains_along_edges_and_corners() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var corner: Array[Vector2i] = _drag(board, [Vector2i(4, 7), Vector2i(3, 6), Vector2i(4, 6), Vector2i(4, 5)])
	assert_eq(corner.size(), 4, "from the bottom right corner up the right edge")
	var top: Array[Vector2i] = _drag(board, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)])
	assert_eq(top.size(), 5, "along the whole top edge")
	var left: Array[Vector2i] = _drag(board, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
	assert_eq(left.size(), 4, "down the left edge")
	var wrap: Array[Vector2i] = _drag(board, [Vector2i(4, 0), Vector2i(0, 1)])
	assert_eq(wrap.size(), 1, "no join across the row wrap")
	var outside: Array[Vector2i] = _drag(board, [Vector2i(0, 7), Vector2i(-1, 7), Vector2i(0, 8), Vector2i(-1, 8)])
	assert_eq(outside.size(), 1, "cells past the corner never join")
	assert_true(CoreRules.is_valid_chain(board, BigNum.zero(), corner, config), "the corner chain is valid")


func test_can_join_rules() -> void:
	var board: PackedInt64Array = F.board_p()
	var empty: Array[Vector2i] = []
	assert_true(CoreRules.can_join(board, BigNum.zero(), empty, Vector2i(0, 0), config), "an empty chain accepts any tile")
	assert_false(CoreRules.can_join(board, BigNum.zero(), empty, Vector2i(5, 0), config), "but not off the board")
	var single: Array[Vector2i] = [Vector2i(1, 6)]
	assert_true(CoreRules.can_join(board, BigNum.zero(), single, Vector2i(0, 6), config), "equal neighbor")
	assert_false(CoreRules.can_join(board, BigNum.zero(), single, Vector2i(1, 5), config), "a double does not count at 1 tile")
	assert_false(CoreRules.can_join(board, BigNum.zero(), single, Vector2i(1, 6), config), "itself")
	assert_false(CoreRules.can_join(board, BigNum.zero(), single, Vector2i(3, 6), config), "not touching")
	var pair: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	assert_true(CoreRules.can_join(board, BigNum.zero(), pair, Vector2i(3, 6), config), "double after two")
	assert_true(CoreRules.can_join(board, BigNum.zero(), pair, Vector2i(1, 5), config), "double, diagonal")
	assert_false(CoreRules.can_join(board, BigNum.zero(), pair, Vector2i(1, 6), config), "already in the chain")
	assert_false(CoreRules.can_join(board, BigNum.zero(), pair, Vector2i(2, 7), config), "eight times")


# Joinable highlight, AT-105 and AT-106

func test_at_105_joinable_highlight_examples() -> void:
	var board: PackedInt64Array = F.board_p()
	var steps: Array[Array] = [
		["HL1", [Vector2i(1, 6)], [Vector2i(0, 6), Vector2i(2, 6)]],
		["HL2", [Vector2i(1, 6), Vector2i(2, 6)], [Vector2i(1, 5), Vector2i(3, 6)]],
		["HL3", [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)], [Vector2i(2, 5), Vector2i(4, 5), Vector2i(3, 7), Vector2i(4, 7)]],
		["HL4", [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)], [Vector2i(3, 5)]],
		["HL5", [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5)], []],
		["HL6", [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5), Vector2i(2, 5)], [Vector2i(3, 5)]],
		["HL7", [Vector2i(2, 7)], []],
	]
	for step: Array in steps:
		var label: String = step[0]
		var path: Array[Vector2i] = []
		path.assign(step[1])
		var expected: Array[Vector2i] = []
		expected.assign(step[2])
		var chain: Array[Vector2i] = _drag(board, path)
		assert_eq(CoreRules.joinable_cells(board, BigNum.zero(), chain, config), expected, label)


func test_joinable_cells_for_an_empty_chain_is_empty() -> void:
	var empty: Array[Vector2i] = []
	assert_true(CoreRules.joinable_cells(F.board_p(), BigNum.zero(), empty, config).is_empty(), "no highlight before the first tile")


func test_joinable_cells_at_a_corner_stay_on_the_board() -> void:
	var board: PackedInt64Array = F.board_all(4)
	var chain: Array[Vector2i] = [Vector2i(4, 7)]
	var expected: Array[Vector2i] = [Vector2i(3, 6), Vector2i(4, 6), Vector2i(3, 7)]
	assert_eq(CoreRules.joinable_cells(board, BigNum.zero(), chain, config), expected, "only the three neighbors on the board")


## The joining rule of GDD 6.1 written out on its own, without CoreRules.
## Condition 5 (the fit test) always holds for the small tiles of a starting
## board; test_ceiling.gd covers it.
func _oracle_joinable(board: PackedInt64Array, chain: Array[Vector2i]) -> Array[Vector2i]:
	var joinable: Array[Vector2i] = []
	var last: Vector2i = chain[chain.size() - 1]
	var last_value: int = F.at(board, last)
	for row: int in F.ROWS:
		for column: int in F.COLUMNS:
			var cell: Vector2i = Vector2i(column, row)
			if chain.has(cell) or absi(cell.x - last.x) > 1 or absi(cell.y - last.y) > 1:
				continue
			var value: int = F.at(board, cell)
			if value == last_value or (chain.size() >= 2 and value == last_value * 2):
				joinable.append(cell)
	return joinable


func test_at_106_the_highlight_always_matches_joining() -> void:
	var steps_checked: int = 0
	var joins: int = 0
	var backtracks: int = 0
	for seed_value: int in range(1, 101):
		var board: PackedInt64Array = F.seeded(seed_value).start_board_attempt(config)
		var moves: RandomNumberGenerator = RandomNumberGenerator.new()
		moves.seed = seed_value
		var start: Array[Vector2i] = []
		var chain: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), start, Vector2i(moves.randi_range(0, 4), moves.randi_range(0, 7)), config)
		var move_count: int = moves.randi_range(1, 15)
		for move: int in move_count:
			var highlighted: Array[Vector2i] = CoreRules.joinable_cells(board, BigNum.zero(), chain, config)
			assert_eq(highlighted, _oracle_joinable(board, chain), "seed %d move %d: highlight equals the joining rule" % [seed_value, move])
			var previous: Vector2i = chain[chain.size() - 2] if chain.size() >= 2 else Vector2i(-1, -1)
			assert_false(highlighted.has(previous), "seed %d move %d: the previous tile is never highlighted" % [seed_value, move])
			var last: Vector2i = chain[chain.size() - 1]
			var target: Vector2i
			if chain.size() >= 2 and moves.randi_range(0, 3) == 0:
				target = previous
			elif not highlighted.is_empty() and moves.randi_range(0, 1) == 0:
				target = highlighted[moves.randi_range(0, highlighted.size() - 1)]
			else:
				target = last + Vector2i(moves.randi_range(-1, 1), moves.randi_range(-1, 1))
			var stepped: Array[Vector2i] = CoreRules.step_chain(board, BigNum.zero(), chain, target, config)
			if highlighted.has(target):
				var grown: Array[Vector2i] = chain.duplicate()
				grown.append(target)
				assert_eq(stepped, grown, "seed %d move %d: a highlighted tile joins" % [seed_value, move])
				joins += 1
			elif target == previous:
				assert_eq(stepped, chain.slice(0, chain.size() - 1), "seed %d move %d: backtrack" % [seed_value, move])
				backtracks += 1
			else:
				assert_eq(stepped, chain, "seed %d move %d: any other tile changes nothing" % [seed_value, move])
			chain = stepped
			steps_checked += 1
	assert_true(joins > 100, "the random drags joined tiles (%d)" % joins)
	assert_true(backtracks > 20, "the random drags backtracked (%d)" % backtracks)
	assert_true(steps_checked > 500, "enough steps were checked (%d)" % steps_checked)

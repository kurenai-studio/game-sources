extends "res://tests/base_test.gd"
## Undo (GDD 13.7: D-27, D-28, D-29) through BoosterRules, with the Undo
## halves of the acceptance tests whose commit halves are core tests.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const USABLE: BoosterStatus.Usability = BoosterStatus.Usability.USABLE
const CANNOT_AFFORD: BoosterStatus.Usability = BoosterStatus.Usability.CANNOT_AFFORD
const NO_SNAPSHOT: BoosterStatus.Usability = BoosterStatus.Usability.NO_SNAPSHOT

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _apply(id: StringName, state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return BoosterRules.apply(id, state, records, BF.targets(cells), rng, config)


func _commit(state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return RunRules.commit_chain(state, records, BF.targets(cells), rng, config)


func _undo(state: RunState, records: Records, rng: RunRandom) -> MoveResult:
	return BoosterRules.apply(BoosterRules.UNDO, state, records, BF.no_targets(), rng, config)


func _usability(state: RunState) -> BoosterStatus.Usability:
	return BoosterRules.usability(BoosterRules.UNDO, state, config)


## The AT-76 setup: Board D with (2,0) = 512, (1,7) = 8 and (2,7) = 16.
func _at_76_board() -> PackedInt64Array:
	return F.changed(F.board_d(), {Vector2i(2, 0): 512, Vector2i(1, 7): 8, Vector2i(2, 7): 16})


## The first touching pair of equal tiles, in index order, as a two tile chain.
func _first_pair(cells: PackedInt64Array) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = F.equal_pairs(cells)
	return [pairs[0], pairs[1]]


func test_at_17_undo_is_usable_after_the_commit() -> void:
	var state: RunState = F.state(F.board_p(), 1000)
	_commit(state, Records.new(), [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)], F.seeded(17))
	assert_eq(BF.n(state.score), 1016, "score 1,016")
	assert_eq(state.snapshot_cells, F.board_p(), "the snapshot is Board P")
	assert_eq(BF.n(state.snapshot_points), 16, "with 16 points")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 64, "Undo costs 64")
	assert_eq(_usability(state), USABLE, "usable: 1,016 minus 16 is 1,000 (D-28)")


func test_at_76_undo_after_a_chain() -> void:
	var board: PackedInt64Array = _at_76_board()
	var state: RunState = F.state(board, 1000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(76)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
	assert_eq(BF.n(state.score), 1032, "score 1,032 after the commit")
	assert_eq(_usability(state), USABLE, "Undo enabled")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 256, "at cost 256")
	var result: MoveResult = _undo(state, records, rng)
	assert_true(result.accepted, "accepted")
	assert_eq(result.kind, MoveResult.Kind.UNDO, "kind")
	assert_eq(BF.n(result.cost), 256, "charged 256")
	assert_eq(state.cells, board, "the board equals the setup board exactly")
	assert_eq(BF.n(state.score), 744, "score 744 (U1)")
	assert_false(state.has_snapshot(), "the snapshot is cleared")
	assert_eq(BF.n(state.snapshot_points), 0, "and its points")
	assert_eq(_usability(state), NO_SNAPSHOT, "Undo disabled (U3)")
	assert_eq(result.cells_after, board, "the view rearranges to the setup board")
	assert_true(result.cleared_small.is_empty() and result.spawn_cells.is_empty(), "no clear, no spawns")


func test_at_77_undo_after_a_chain_and_a_hammer() -> void:
	var board: PackedInt64Array = _at_76_board()
	var state: RunState = F.state(board, 1000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(77)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(4, 0)], rng)
	assert_eq(BF.n(hammered.cost), 512, "Hammer costs 512")
	assert_eq(BF.n(state.score), 520, "score 520 after the Hammer")
	assert_eq(_usability(state), USABLE, "Undo enabled: 520 minus 32 is 488")
	_undo(state, records, rng)
	assert_eq(state.cells, board, "the board equals the setup board: the hammered tile is back (U2)")
	assert_eq(BF.n(state.score), 232, "score 232")


func test_at_78_undo_is_one_step_and_needs_a_chain() -> void:
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(1)
	var state: RunState = RunRules.new_run(rng, records, config)
	state.score = F.big(1000)
	assert_eq(_usability(state), NO_SNAPSHOT, "disabled at the start: no snapshot (U4)")
	assert_eq(_undo(state, records, rng).refusal, &"no_snapshot", "a forced Undo is refused")
	var first: MoveResult = RunRules.commit_chain(state, records, _first_pair(state.cells), rng, config)
	assert_true(first.accepted, "a two tile chain commits")
	assert_true(state.highest() <= 32, "a two tile chain on a starting board makes at most 32")
	var undone: MoveResult = _undo(state, records, rng)
	assert_true(undone.accepted, "Undo accepted")
	assert_eq(BF.n(undone.cost), 64, "at cost 64")
	assert_eq(BF.n(state.score), 936, "score 936")
	assert_eq(_usability(state), NO_SNAPSHOT, "disabled right after the Undo")
	var second: MoveResult = RunRules.commit_chain(state, records, _first_pair(state.cells), rng, config)
	assert_true(second.accepted, "another chain commits")
	assert_eq(_usability(state), USABLE, "enabled again after the next chain")


func test_at_79_undo_affordability_uses_the_score_without_the_chains_points() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 2, Vector2i(1, 7): 2, Vector2i(2, 7): 4, Vector2i(3, 7): 8, Vector2i(4, 7): 16, Vector2i(4, 6): 32, Vector2i(3, 6): 32})
	var state: RunState = F.state(board, 30)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(79)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(4, 6), Vector2i(3, 6)], rng)
	assert_eq(BF.n(state.score), 126, "score 126")
	assert_eq(F.v(state.highest()), 64, "H = 64")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 64, "Undo cost 64")
	assert_eq(_usability(state), CANNOT_AFFORD, "Undo disabled: 126 minus 96 is 30 (U5)")
	var before: RunState = state.copy()
	var rng_before: int = rng.get_state()
	var result: MoveResult = _undo(state, records, rng)
	assert_false(result.accepted, "the call is refused (Z4)")
	assert_eq(result.refusal, &"cannot_afford", "as unaffordable")
	assert_eq(BF.n(state.score), 126, "the score stays 126, never minus 34")
	assert_true(state.equals(before), "nothing changed")
	assert_eq(rng.get_state(), rng_before, "the generator was not used")


func test_at_80_undo_cost_comes_from_the_current_board_and_records_stay() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var state: RunState = F.state(board, 20000)
	var records: Records = F.records(0, 1024)
	var rng: RunRandom = F.seeded(80)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(BF.n(state.score), 22048, "score 22,048")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 1024, "Undo cost 1,024 from the current board (U6)")
	_undo(state, records, rng)
	assert_eq(state.cells, board, "the board equals the setup board, the twelve 2s included (D-39)")
	assert_eq(BF.count(state.cells, 2), 12, "twelve 2s are back")
	assert_eq(BF.n(state.score), 18976, "score 18,976")
	assert_eq(F.v(records.best_tile), 2048, "Best Tile 2048")
	assert_eq(BF.n(records.best_score), 22048, "Best Score 22,048")
	assert_eq(F.v(state.run_highest), 2048, "run highest 2048 (T4, RH5)")


func test_at_81_undo_after_a_shuffle() -> void:
	var board: PackedInt64Array = BF.snapshot_board()
	var state: RunState = F.state(board, 5000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(81)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)], rng)
	assert_eq(BF.n(state.score), 5040, "after the commit 5,040")
	_apply(BoosterRules.SHUFFLE, state, records, [], rng)
	assert_eq(BF.n(state.score), 4016, "after Shuffle 4,016")
	assert_eq(_usability(state), USABLE, "Undo usable: 4,016 minus 40 is 3,976 (U7)")
	_undo(state, records, rng)
	assert_eq(state.cells, board, "the board equals the setup board, unshuffled")
	assert_eq(BF.n(state.score), 3464, "score 3,464: the Shuffle cost stays spent")


func test_at_82_undo_does_not_rewind_the_random_generator() -> void:
	var state: RunState = F.state(_at_76_board(), 1000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(7)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
	var before: int = rng.get_state()
	var result: MoveResult = _undo(state, records, rng)
	assert_true(result.accepted, "Undo accepted")
	assert_eq(rng.get_state(), before, "the generator state is unchanged")


func test_at_42_undo_does_not_lower_best_score() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 0): 8}), 9990)
	var records: Records = F.records(10000, 0)
	var rng: RunRandom = F.seeded(42)
	_commit(state, records, [Vector2i(0, 0), Vector2i(0, 1)], rng)
	assert_eq(BF.n(state.score), 10006, "score 10,006")
	assert_eq(BF.n(records.best_score), 10006, "Best Score 10,006")
	var result: MoveResult = _undo(state, records, rng)
	assert_eq(BF.n(result.cost), 64, "Undo costs 64")
	assert_eq(BF.n(state.score), 9926, "score 9,926")
	assert_eq(BF.n(records.best_score), 10006, "Best Score stays 10,006")


func test_at_102_undo_brings_cleared_tiles_back() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(99)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8])))
	_commit(state, records, [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_eq(BF.n(state.score), 12048, "the AT-99 state: score 12,048")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 1024, "Undo cost 1,024")
	var result: MoveResult = _undo(state, records, rng)
	assert_eq(state.cells, board, "the board equals the AT-99 setup (CL5)")
	assert_eq(F.v(state.value_at(Vector2i(0, 3))), 2, "the 2 on (0,3) is back")
	assert_eq([F.v(state.value_at(Vector2i(4, 6))), F.v(state.value_at(Vector2i(4, 7)))], [1024, 1024], "both 1024s are back")
	assert_eq(BF.n(state.score), 8976, "score 8,976")
	assert_eq(F.v(records.best_tile), 2048, "Best Tile stays 2048")
	assert_eq(F.v(state.run_highest), 2048, "run highest stays 2048")
	assert_true(result.cleared_small.is_empty(), "Undo never clears")


func test_undo_that_raises_h_never_clears() -> void:
	# The chain made a 2048, then a Hammer took it away. Undo brings back a board
	# whose highest tile is higher than now, with a 2 below its floor.
	var snapshot: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 7): 2048})
	var state: RunState = BF.make(F.board_e(), 9000, snapshot, 16, 2048)
	var records: Records = F.records(9000, 2048)
	var result: MoveResult = _undo(state, records, F.seeded(1))
	assert_true(result.accepted, "accepted")
	assert_eq(BF.n(result.cost), 64, "cost from the current board (H = 32, B = 128)")
	assert_eq(state.cells, snapshot, "the board equals the snapshot exactly")
	assert_eq(BF.count(state.cells, 2), 1, "the 2 stays")
	assert_true(result.cleared_small.is_empty(), "nothing cleared (D-39)")
	assert_eq(BF.n(state.score), 9000 - 16 - 64, "score loses the points and the cost")


func test_undo_after_each_other_booster_keeps_every_cost_spent() -> void:
	var cases: Array[Array] = [
		[BoosterRules.HAMMER, [Vector2i(4, 0)]],
		[BoosterRules.SWAP, [Vector2i(3, 0), Vector2i(4, 0)]],
		[BoosterRules.SHUFFLE, []],
		[BoosterRules.DOUBLE, [Vector2i(2, 0)]],
	]
	for each: Array in cases:
		var id: StringName = each[0]
		var board: PackedInt64Array = _at_76_board()
		var state: RunState = F.state(board, 3000)
		var records: Records = Records.new()
		var rng: RunRandom = F.seeded(12)
		_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
		var booster: MoveResult = _apply(id, state, records, each[1], rng)
		assert_true(booster.accepted, "%s accepted" % id)
		var undo_cost: int = BF.price(BoosterRules.UNDO, state, config)
		var result: MoveResult = _undo(state, records, rng)
		assert_true(result.accepted, "Undo after %s accepted" % id)
		assert_eq(BF.n(result.cost), undo_cost, "Undo after %s charged the price shown" % id)
		assert_eq(state.cells, board, "Undo after %s restores the board before the chain" % id)
		assert_eq(BF.n(state.score), 3000 - BF.n(booster.cost) - undo_cost, "Undo after %s: the booster cost and the Undo cost stay spent" % id)


func test_undo_with_a_double_in_between_uses_the_doubled_price() -> void:
	var board: PackedInt64Array = _at_76_board()
	var state: RunState = F.state(board, 5000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(30)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
	_apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], rng)
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 512, "H is 1024 now, so Undo costs 512")
	var result: MoveResult = _undo(state, records, rng)
	assert_eq(BF.n(result.cost), 512, "the price on the button is the price paid")
	assert_eq(F.v(records.best_tile), 1024, "Best Tile keeps the doubled tile")
	assert_eq(F.v(state.run_highest), 1024, "so does the run highest tile")
	assert_eq(F.v(state.highest()), 512, "the board is back to H = 512")

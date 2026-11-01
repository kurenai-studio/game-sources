extends "res://tests/base_test.gd"
## Stars (GDD 11.5, D-45), notice values (TH12) and free boosters as data
## (13.9, D-46), through CoreRules and RunRules. The booster side (charging 0,
## usability, the offer, the bar) is a boosters test.
##
## A few tests need a Hammer, a Double or an Undo between chains. They do it by
## hand with core pieces, in the order BoosterRules applies them, so the stars
## and notice values that RunRules reports can be checked here. The real
## boosters are tested in tests/boosters.

const F := preload("res://tests/core/core_fixtures.gd")
const BIG: int = 1 << 62

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _commit(state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	var chain: Array[Vector2i] = []
	chain.assign(cells)
	return RunRules.commit_chain(state, records, chain, rng, config)


func _idx(cell: Vector2i) -> int:
	return cell.y * F.COLUMNS + cell.x


func _stars(state: RunState) -> int:
	return CoreRules.stars(state.run_highest, config)


func _held(state: RunState) -> int:
	return CoreRules.free_held(state, config)


## GDD 13.3 by hand: charge, empty the cell, settle, records.
func _hammer_by_hand(state: RunState, records: Records, cell: Vector2i, price: int, rng: RunRandom) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.HAMMER
	state.score = state.score.sub(F.big(price))
	var board: PackedInt64Array = state.cells.duplicate()
	board[_idx(cell)] = 0
	state.cells = board
	RunRules.settle(state, result, rng, config)
	RunRules.update_records(state, records, result, config)
	return result


## GDD 13.6 by hand: charge, double in place, clear small tiles against the
## floor from before, settle only if something cleared, records.
func _double_by_hand(state: RunState, records: Records, cell: Vector2i, price: int, rng: RunRandom) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.DOUBLE
	var floor_before: int = CoreRules.window_floor(state.highest(), config)
	state.score = state.score.sub(F.big(price))
	var board: PackedInt64Array = state.cells.duplicate()
	board[_idx(cell)] = board[_idx(cell)] + 1
	state.cells = board
	RunRules.clear_small(state, floor_before, result, config)
	if not result.cleared_small.is_empty():
		RunRules.settle(state, result, rng, config)
	RunRules.update_records(state, records, result, config)
	return result


## GDD 13.7 by hand: the snapshot board back, the chain's points and the
## charge off the score, the snapshot cleared, records.
func _undo_by_hand(state: RunState, records: Records, price: int) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.UNDO
	state.score = state.score.sub(state.snapshot_points).sub(F.big(price))
	state.cells = state.snapshot_cells.duplicate()
	state.snapshot_cells = PackedInt64Array()
	state.snapshot_points = BigNum.zero()
	RunRules.update_records(state, records, result, config)
	return result


## A board whose highest tile is value: Board D with (2,0) = value, or Board D for 16 or less.
func _board_with_highest(value: int) -> PackedInt64Array:
	if value <= 16:
		return F.board_d()
	return F.changed(F.board_d(), {Vector2i(2, 0): value})


# The star count and free boosters earned (TH3)

func test_at_117_star_count_and_free_boosters_earned() -> void:
	var highest: Array[int] = [16, 1024, 2048, 4096, 8192, 65536, 131072, 1048576, BIG]
	var stars: Array[int] = [0, 0, 1, 2, 3, 6, 7, 10, 52]
	var free: Array[int] = [0, 0, 0, 0, 1, 2, 2, 3, 17]
	for position: int in highest.size():
		var state: RunState = RunState.create(_board_with_highest(highest[position]), null, PackedInt64Array(), null, F.e(highest[position]))
		var label: String = "run highest %d" % highest[position]
		assert_eq(_stars(state), stars[position], "%s: stars" % label)
		assert_eq(CoreRules.free_earned(state.run_highest, config), free[position], "%s: free boosters earned" % label)
		assert_eq(_held(state), free[position], "%s: none used, so all held" % label)
	var bart: RunState = RunState.create(_board_with_highest(131072), null, PackedInt64Array(), null, F.e(131072))
	assert_eq(_stars(bart), 7, "Bart's phone run: 7 stars")
	assert_eq(CoreRules.free_earned(bart.run_highest, config), 2, "and 2 free boosters earned")


## The whole table of GDD 11.5: run highest tile, its window floor, stars, free boosters earned.
func test_star_table_of_gdd_11_5() -> void:
	var rows: Array[Array] = [
		[2, 2, 0, 0], [512, 2, 0, 0], [1024, 2, 0, 0],
		[2048, 4, 1, 0], [4096, 8, 2, 0], [8192, 16, 3, 1], [16384, 32, 4, 1],
		[32768, 64, 5, 1], [65536, 128, 6, 2], [131072, 256, 7, 2], [262144, 512, 8, 2],
		[524288, 1024, 9, 3], [1048576, 2048, 10, 3], [BIG, 1 << 53, 52, 17],
	]
	for row: Array in rows:
		var highest: int = row[0]
		assert_eq(F.v(CoreRules.window_floor(F.e(highest), config)), row[1], "floor for %d" % highest)
		assert_eq(CoreRules.stars(F.e(highest), config), row[2], "stars for %d" % highest)
		assert_eq(CoreRules.free_earned(F.e(highest), config), row[3], "free boosters for %d" % highest)


## Bart's phone run, GDD 11.5: 2K to 128K give 1 to 7 stars and 0, 0, 1, 1, 1, 2, 2 free boosters.
func test_bart_phone_run_table() -> void:
	var free: Array[int] = [0, 0, 1, 1, 1, 2, 2]
	for step: int in 7:
		var highest: int = 2048 << step
		assert_eq(CoreRules.stars(F.e(highest), config), step + 1, "stars at %d" % highest)
		assert_eq(CoreRules.free_earned(F.e(highest), config), free[step], "free boosters at %d" % highest)
		assert_eq(F.vv(CoreRules._left_window(CoreRules.window_floor(F.e(highest >> 1), config), CoreRules.window_floor(F.e(highest), config))), PackedInt64Array([2 << step]), "the value that left at %d" % highest)


## D-45: 0 while the run highest tile is 1024 or less, otherwise log2 of it
## minus 10, past 2^62 too (GDD 11.5: 2^56 gives 46, the ceiling 65,525).
@warning_ignore("integer_division")
func test_stars_are_log2_minus_10_from_2k_on() -> void:
	assert_eq(CoreRules.stars(0, config), 0, "an empty run highest")
	for power: int in range(1, 200):
		var expected: int = maxi(0, power - 10)
		assert_eq(CoreRules.stars(power, config), expected, "stars for 2^%d" % power)
		assert_eq(CoreRules.free_earned(power, config), expected / 3, "free boosters for 2^%d" % power)
	assert_eq(CoreRules.stars(56, config), 46, "Bart's run, 2^56: 46 stars")
	assert_eq(CoreRules.free_earned(56, config), 15, "and 15 free boosters")
	assert_eq(CoreRules.stars(65535, config), 65525, "the ceiling: 65,525 stars")
	assert_eq(CoreRules.free_earned(65535, config), 21841, "and 21,841 free boosters")


func test_stars_never_go_down_as_the_run_highest_tile_rises() -> void:
	var last: int = 0
	for power: int in range(1, 200):
		var now: int = CoreRules.stars(power, config)
		assert_true(now >= last, "2^%d" % power)
		assert_true(now - last <= 1, "one doubling adds at most one star, 2^%d" % power)
		last = now


## TH4 and GDD 18: the stars move with SPAWN_TOP_MIN, SPAWN_TOP_DIVISOR and SPAWN_WINDOW_SIZE.
func test_stars_follow_the_spawn_constants() -> void:
	config.spawn_top_min = 32
	assert_eq(CoreRules.stars(F.e(1024), config), 0, "SPAWN_TOP_MIN 32: floor 4 at 1024")
	assert_eq(CoreRules.stars(F.e(2048), config), 0, "SPAWN_TOP_MIN 32: still floor 4 at 2048")
	assert_eq(CoreRules.stars(F.e(4096), config), 1, "SPAWN_TOP_MIN 32: the first star at 4096")
	assert_eq(CoreRules.stars(F.e(BIG), config), 51, "SPAWN_TOP_MIN 32: 2^53 is 51 doublings above 4")
	config = GameConfig.new()
	config.spawn_top_divisor = 32
	assert_eq(CoreRules.stars(F.e(512), config), 0, "SPAWN_TOP_DIVISOR 32: none at 512")
	assert_eq(CoreRules.stars(F.e(1024), config), 1, "SPAWN_TOP_DIVISOR 32: the first star at 1024")
	config = GameConfig.new()
	config.spawn_window_size = 3
	assert_eq(CoreRules.stars(F.e(1024), config), 0, "SPAWN_WINDOW_SIZE 3: none at 1024")
	assert_eq(CoreRules.stars(F.e(2048), config), 1, "SPAWN_WINDOW_SIZE 3: the first at 2048")


## TH4: STARS_PER_FREE_BOOSTER sets how many stars each free booster needs.
func test_free_boosters_follow_stars_per_free_booster() -> void:
	config.stars_per_free_booster = 2
	assert_eq(CoreRules.free_earned(F.e(2048), config), 0, "1 star, none")
	assert_eq(CoreRules.free_earned(F.e(4096), config), 1, "2 stars, one")
	assert_eq(CoreRules.free_earned(F.e(8192), config), 1, "3 stars, one")
	assert_eq(CoreRules.free_earned(F.e(16384), config), 2, "4 stars, two")
	config.stars_per_free_booster = 1
	assert_eq(CoreRules.free_earned(F.e(131072), config), 7, "one per star")
	config.stars_per_free_booster = 0
	assert_eq(CoreRules.free_earned(F.e(131072), config), 0, "a constant of 0 earns none instead of dividing by zero")


## D-46: held is earned minus used, from the run highest tile, not from H.
func test_free_held_is_earned_minus_used() -> void:
	var board: PackedInt64Array = _board_with_highest(131072)
	for used: int in 3:
		var state: RunState = RunState.create(board, null, PackedInt64Array(), null, F.e(131072), 5, used)
		assert_eq(_held(state), 2 - used, "%d used of 2" % used)
	var hammered: RunState = RunState.create(_board_with_highest(1024), null, PackedInt64Array(), null, F.e(131072), 5, 1)
	assert_eq(_stars(hammered), 7, "H is 1024 after a Hammer, but the stars come from the run highest tile")
	assert_eq(_held(hammered), 1, "and so do the free boosters")
	var edge: RunState = RunState.create(_board_with_highest(BIG), null, PackedInt64Array(), null, F.e(BIG), 5, 16)
	assert_eq(_held(edge), 1, "2^62: 17 earned, 16 used")
	edge.free_used = 17
	assert_eq(_held(edge), 0, "all 17 used")


# Stars earned per move

## Example SC2. Also everything AT-99 checks about the move, see test_commit_chain.gd.
func test_at_118_the_first_2k_earns_a_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var rng: RunRandom = F.seeded(118)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8])))
	assert_eq(_stars(state), 0, "stars 0 before")
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_int(), 12048, "score 12,048")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 2048, "(4,7) = 2048")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "the 2 on (0,3) cleared")
	assert_eq(_stars(state), 1, "stars 1 after")
	assert_eq(result.stars_earned, 1, "the move reports 1 star earned")
	assert_eq(result.free_earned, 0, "and 0 free boosters earned")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([2]), "notice: no more 2s")


## Example SC3.
func test_at_119_two_stars_in_one_move() -> void:
	var chain: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 7)]
	for seed_value: int in range(1, 201):
		var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024, Vector2i(2, 7): 1024, Vector2i(3, 7): 1024})
		var state: RunState = F.state(board, 0)
		var before: int = _stars(state)
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(seed_value), config)
		var problem: String = ""
		if before != 0 or _stars(state) != 2:
			problem = "stars %d then %d" % [before, _stars(state)]
		elif result.stars_earned != 2 or result.free_earned != 0:
			problem = "earned %d stars and %d free boosters" % [result.stars_earned, result.free_earned]
		elif result.notice_values != F.ev(PackedInt64Array([2, 4])):
			problem = "notice values %s" % result.notice_values
		elif state.score.to_int() != 4096 or result.cleared_small.size() != 20:
			problem = "score %s, %d cleared" % [state.score.to_decimal(), result.cleared_small.size()]
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


## Examples SC4 and SC5 on the AT-38 setup: Hammer the 2048 (spawn 2), then the 1024 pair makes 2048 again.
func test_at_120_hammer_then_a_chain_back_to_the_same_level_earns_no_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(2, 7): 2048, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = F.records(10000, 2048)
	var rng: RunRandom = F.seeded(120)
	rng.script_spawns(F.ev(PackedInt64Array([2, 8, 8])))
	assert_eq(_stars(state), 1, "run highest tile 2048, so 1 star")
	var hammer: MoveResult = _hammer_by_hand(state, records, Vector2i(2, 7), 2048, rng)
	assert_eq(state.score.to_int(), 7952, "after the Hammer: score 7,952")
	assert_eq(F.v(state.highest()), 1024, "H = 1024")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 2, "(2,0) = 2")
	assert_eq(_stars(state), 1, "after the Hammer: 1 star")
	assert_eq(hammer.stars_earned, 0, "0 earned")
	assert_true(hammer.notice_values.is_empty() and hammer.cleared_small.is_empty(), "no notice")
	var chain: MoveResult = _commit(state, records, [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_true(chain.accepted, "the chain commits")
	assert_eq(state.score.to_int(), 10000, "score 10,000")
	assert_eq(_stars(state), 1, "after the chain: still 1 star")
	assert_eq(chain.stars_earned, 0, "0 earned")
	assert_eq(chain.free_earned, 0, "no free booster")
	assert_eq(chain.cleared_small, [Vector2i(2, 0)] as Array[Vector2i], "the 2 on (2,0) is still reported as cleared")
	assert_eq(F.vv(chain.notice_values), PackedInt64Array([2]), "notice values 2: the notice shows without a star")


## Example SC6 on the AT-80 setup: commit, Undo, the same chain again.
func test_at_121_undo_keeps_the_star_and_the_same_chain_earns_none() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var state: RunState = F.state(board, 20000)
	var records: Records = F.records(0, 1024)
	var rng: RunRandom = F.seeded(121)
	var first: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(state.score.to_int(), 22048, "after the first commit: score 22,048")
	assert_eq(_stars(state), 1, "1 star")
	assert_eq(first.stars_earned, 1, "1 earned")
	var undo: MoveResult = _undo_by_hand(state, records, 1024)
	assert_eq(state.cells, board, "Undo brings the setup board back")
	assert_eq(state.score.to_int(), 18976, "after Undo: score 18,976")
	assert_eq(F.v(state.run_highest), 2048, "the run highest tile stays 2048")
	assert_eq(_stars(state), 1, "still 1 star")
	assert_eq(undo.stars_earned, 0, "Undo earns nothing")
	assert_true(undo.notice_values.is_empty(), "and names nothing")
	var again: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(state.score.to_int(), 21024, "after the second commit: score 21,024")
	assert_eq(_stars(state), 1, "still 1 star")
	assert_eq(again.stars_earned, 0, "0 earned")
	assert_eq(again.cleared_small.size(), 12, "the twelve 2s are cleared again")
	assert_eq(F.vv(again.notice_values), PackedInt64Array([2]), "the notice names 2, with no star")


## Example SC8 on the AT-101 setup: Double the 1024.
func test_at_122_a_double_that_raises_the_floor_earns_a_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})
	var state: RunState = F.state(board, 5000)
	var rng: RunRandom = F.seeded(122)
	rng.script_spawns(F.ev(PackedInt64Array([8])))
	assert_eq(_stars(state), 0, "stars 0 before")
	var result: MoveResult = _double_by_hand(state, Records.new(), Vector2i(2, 0), 2048, rng)
	assert_eq(state.score.to_int(), 2952, "score 2,952")
	assert_eq(F.v(state.value_at(Vector2i(2, 0))), 2048, "(2,0) = 2048")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "the 2 on (0,3) cleared")
	assert_eq(F.v(state.value_at(Vector2i(0, 0))), 8, "(0,0) = 8")
	assert_true(state.value_at(Vector2i(0, 3)) == F.e(4) and state.value_at(Vector2i(0, 4)) == F.e(4), "(0,3) and (0,4) are both 4")
	assert_true(CoreRules.has_valid_move(state.cells, BigNum.zero(), config), "the board has a valid move")
	assert_eq(_stars(state), 1, "stars 1 after")
	assert_eq(result.stars_earned, 1, "the move reports 1 star earned")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([2]), "notice: no more 2s")


## Example SC7: Board E has no 2s, so the first 2048 clears nothing and still earns its star.
func test_at_123_a_floor_rise_that_removes_no_tile_still_earns_its_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var rng: RunRandom = F.seeded(123)
	rng.script_spawns(F.ev(PackedInt64Array([4])))
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_int(), 12048, "score 12,048")
	assert_eq(F.v(state.value_at(Vector2i(4, 7))), 2048, "(4,7) = 2048")
	assert_eq(F.v(state.value_at(Vector2i(4, 0))), 4, "(4,0) = 4")
	assert_eq(F.v(state.value_at(Vector2i(4, 1))), 4, "(4,1) = 4")
	assert_true(result.has_valid_move, "the board has a valid move")
	assert_eq(F.v(result.floor_before), 2, "the floor rose from 2")
	assert_eq(F.v(result.floor_after), 4, "to 4")
	assert_true(result.cleared_small.is_empty(), "no cleared tiles")
	assert_true(result.cleared_values.is_empty(), "no cleared values")
	assert_eq(result.stars_earned, 1, "1 star earned")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([2]), "notice values 2")
	assert_eq(_stars(state), 1, "stars 1")


## Example SC9.
func test_at_124_a_new_highest_tile_below_2k_earns_no_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 512, Vector2i(1, 7): 512})
	var state: RunState = F.state(board, 0)
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(124))
	assert_eq(state.score.to_int(), 1024, "score 1,024")
	assert_eq(F.v(state.value_at(Vector2i(1, 7))), 1024, "(1,7) = 1024")
	assert_eq(F.v(state.run_highest), 1024, "run highest tile 1024")
	assert_eq(F.v(result.floor_before), 2, "floor 2")
	assert_eq(F.v(result.floor_after), 2, "stays 2")
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_eq(result.stars_earned, 0, "0 stars earned")
	assert_true(result.notice_values.is_empty(), "no notice values")
	assert_eq(_stars(state), 0, "stars 0")


## Examples SC1 and SC10. (a) new runs. (b) the core half of a load: GameSession.resume
## runs update_records on the loaded state with a fresh result. The save half is a save test.
func test_at_125_the_starting_board_and_a_loaded_run_earn_no_star() -> void:
	for seed_value: int in range(1, 101):
		var fresh: RunState = RunRules.new_run(F.seeded(seed_value), Records.new(), config)
		if _stars(fresh) != 0 or _held(fresh) != 0 or fresh.free_used != 0:
			fail("seed %d: %d stars, %d free boosters held, %d used" % [seed_value, _stars(fresh), _held(fresh), fresh.free_used])
			return
	var boards: Array[PackedInt64Array] = [_board_with_highest(131072), _board_with_highest(65536)]
	for board: PackedInt64Array in boards:
		var loaded: RunState = RunState.create(board, F.big(2400000), PackedInt64Array(), null, F.e(131072), 5, 1)
		var label: String = "loaded with H %d" % loaded.highest()
		assert_eq(_stars(loaded), 7, "%s: 7 stars" % label)
		assert_eq(_held(loaded), 1, "%s: 1 free booster held" % label)
		var result: MoveResult = MoveResult.new()
		result.kind = MoveResult.Kind.NEW_RUN
		RunRules.update_records(loaded, F.records(0, 0), result, config)
		assert_eq(result.stars_earned, 0, "%s: no star earned" % label)
		assert_eq(result.free_earned, 0, "%s: no free booster earned" % label)
		assert_true(result.notice_values.is_empty() and result.cleared_small.is_empty(), "%s: nothing that shows a clear notice" % label)
		assert_eq(F.v(loaded.run_highest), 131072, "%s: run highest kept" % label)
		assert_eq(loaded.free_used, 1, "%s: free boosters used kept" % label)


# Free boosters earned and held, as data

## Example FB1, the core half. The booster statuses are a boosters test.
func test_at_127_the_third_star_earns_a_free_booster() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096})
	var state: RunState = F.state(board, 50000)
	assert_eq(_stars(state), 2, "2 stars before")
	assert_eq(_held(state), 0, "nothing held")
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(127))
	assert_eq(state.score.to_int(), 58192, "score 58,192")
	assert_eq(F.v(state.value_at(Vector2i(1, 7))), 8192, "8192 on (1,7)")
	assert_eq(_stars(state), 3, "3 stars")
	assert_eq(result.stars_earned, 1, "1 star earned")
	assert_eq(result.free_earned, 1, "the move reports 1 free booster earned")
	assert_eq(_held(state), 1, "1 free booster held")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([8]), "the floor rose from 8 to 16")


## Example FB6, the core half: Undo uses the free booster (free_used goes up,
## which is the boosters' job), then the same chain earns nothing.
func test_at_132_a_free_booster_used_on_undo_stays_used() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096})
	var state: RunState = F.state(board, 50000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(132)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(_held(state), 1, "1 held after the commit")
	state.free_used += 1
	var undo: MoveResult = _undo_by_hand(state, records, 0)
	assert_eq(state.cells, board, "the board equals the setup")
	assert_eq(state.score.to_int(), 50000, "score 50,000")
	assert_eq(_stars(state), 3, "still 3 stars: the run highest tile stays 8192")
	assert_eq(undo.stars_earned + undo.free_earned, 0, "the Undo earns nothing")
	assert_eq(_held(state), 0, "0 held")
	var again: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(state.score.to_int(), 58192, "after the second commit: score 58,192")
	assert_eq(_stars(state), 3, "3 stars")
	assert_eq(again.stars_earned, 0, "0 stars earned")
	assert_eq(again.free_earned, 0, "0 free boosters earned")
	assert_eq(_held(state), 0, "0 held")


## Example FB7, the commit row. The free Shuffle and Double after it are boosters tests.
func test_at_133_two_free_boosters_held_after_the_commit() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 32768, Vector2i(1, 7): 32768})
	var state: RunState = F.state(board, 1000000)
	assert_eq(_stars(state), 5, "5 stars")
	assert_eq(_held(state), 1, "1 earned, none used, so 1 held")
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(133))
	assert_eq(state.score.to_int(), 1065536, "score 1,065,536")
	assert_eq(_stars(state), 6, "6 stars")
	assert_eq(result.free_earned, 1, "the sixth star earns the second free booster")
	assert_eq(_held(state), 2, "2 held")


## The core half of AT-75 and AT-134 (example DB2, FB9): a Double on the 4096
## is the third star and earns a free booster. Charging it is a boosters test.
func test_at_75_a_double_that_makes_the_third_star_earns_a_free_booster() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 32})
	var state: RunState = F.state(board, 30000)
	var records: Records = F.records(0, 4096)
	var result: MoveResult = _double_by_hand(state, records, Vector2i(2, 0), 8192, F.seeded(75))
	assert_eq(state.score.to_int(), 21808, "score 21,808")
	assert_eq(F.v(state.value_at(Vector2i(2, 7))), 8192, "the 8192 fell to (2,7)")
	assert_eq(result.cleared_small.size(), 30, "all 30 tiles of 2, 4 and 8 clear")
	assert_eq(F.vv(result.cleared_values), PackedInt64Array([2, 4, 8]), "values 2, 4 and 8")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([8]), "the floor rose from 8 to 16: only 8 left the window")
	assert_eq(F.v(records.best_tile), 8192, "Best Tile 8192")
	assert_eq(_stars(state), 3, "the third star")
	assert_eq(result.stars_earned, 1, "1 star earned")
	assert_eq(result.free_earned, 1, "1 free booster earned")
	assert_eq(_held(state), 1, "1 held")


## The core half of AT-136 (example FB10): the fourth star earns no free booster.
func test_at_136_a_double_to_16k_earns_the_fourth_star_and_no_free_booster() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 8192})
	var state: RunState = F.state(board, 1000)
	var records: Records = F.records(1000, 8192)
	assert_eq(_held(state), 1, "1 held")
	state.free_used += 1
	var result: MoveResult = _double_by_hand(state, records, Vector2i(2, 0), 0, F.seeded(136))
	assert_eq(state.score.to_int(), 1000, "score 1,000")
	assert_eq(records.best_score.to_int(), 1000, "Best Score 1,000")
	assert_eq(F.v(records.best_tile), 16384, "Best Tile 16384")
	assert_eq(F.v(state.run_highest), 16384, "run highest tile 16384")
	assert_eq(_stars(state), 4, "4 stars")
	assert_eq(result.stars_earned, 1, "1 star earned")
	assert_eq(result.free_earned, 0, "no free booster for the fourth star")
	assert_eq(_held(state), 0, "0 held")


## At the 64 bit edge the counts stay exact: 2^61 then 2^62 gives the 52nd star.
func test_stars_at_the_largest_values() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1 << 61, Vector2i(1, 7): 1 << 61})
	var state: RunState = F.state(board, 0)
	assert_eq(_stars(state), 51, "2^61 gives 51 stars")
	assert_eq(_held(state), 17, "17 free boosters")
	var result: MoveResult = _commit(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(62))
	assert_true(result.accepted, "the 2^61 pair commits")
	assert_eq(F.v(state.run_highest), BIG, "run highest 2^62")
	assert_eq(_stars(state), 52, "52 stars")
	assert_eq(result.stars_earned, 1, "1 earned")
	assert_eq(result.free_earned, 0, "52 / 3 is still 17")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([1 << 52]), "2^52 left the window")


## D-46 and 15.1: free_used belongs to the run. Core never changes it, and the
## Undo snapshot is only a board and its points.
func test_core_never_changes_free_used() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 65536, Vector2i(1, 7): 65536})
	var state: RunState = RunState.create(board, F.big(5000), PackedInt64Array(), null, F.e(131072), 5, 2)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(46)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_true(result.accepted, "commits")
	assert_eq(state.free_used, 2, "commit_chain keeps free_used")
	assert_eq(state.snapshot_cells, board, "the snapshot is the board before")
	assert_false(result.free_used, "a chain never uses a free booster")
	RunRules.clear_small(state, F.e(2), MoveResult.new(), config)
	RunRules.settle(state, MoveResult.new(), rng, config)
	RunRules.update_records(state, records, MoveResult.new(), config)
	assert_eq(state.free_used, 2, "clear_small, settle and update_records keep it")


# Notice values (TH12)

func test_notice_values_name_every_value_that_left_the_window() -> void:
	var cases: Array[Array] = [
		[2, 2048, [2]],
		[2, 4096, [2, 4]],
		[2, 65536, [2, 4, 8, 16, 32, 64]],
		[4, 2048, []],
		[2, 1024, []],
		[8, 2048, []],
		[256, 262144, [256]],
	]
	for case: Array in cases:
		var floor_before: int = case[0]
		var highest: int = case[1]
		var state: RunState = F.state(F.changed(F.board_all(2), {Vector2i(2, 3): highest}), 0)
		var result: MoveResult = MoveResult.new()
		RunRules.clear_small(state, F.e(floor_before), result, config)
		var expected: PackedInt64Array = PackedInt64Array(case[2])
		assert_eq(F.vv(result.notice_values), expected, "floor %d, then H %d" % [floor_before, highest])


func test_notice_values_for_the_biggest_jump() -> void:
	var values: PackedInt64Array = CoreRules._left_window(1, 53)
	assert_eq(values.size(), 52, "52 values from 2 to 2^52")
	assert_eq(values[0], 1, "from 2")
	assert_eq(values[51], 52, "to 2^52")
	assert_true(CoreRules._left_window(62, 62).is_empty(), "no rise")
	assert_true(CoreRules._left_window(65526, 65526).is_empty(), "no rise at the ceiling")
	assert_eq(CoreRules._left_window(47, 49), PackedInt64Array([47, 48]), "2^47 and 2^48 left the window")
	assert_true(CoreRules._left_window(0, 10).is_empty(), "a floor of 0 names nothing")
	assert_true(CoreRules._left_window(-4, 10).is_empty(), "nor a negative one")


## GDD 11.5: a move that raised the floor but removed no tile and earned no star
## shows no notice. Only after a Hammer lowered the floor: here the Hammer's new
## tile is an 8, so the chain that brings back 2048 clears nothing.
func test_a_floor_rise_with_nothing_cleared_and_no_star_gives_no_notice() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(2, 7): 2048, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var state: RunState = F.state(board, 10000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(45)
	rng.script_spawns(F.ev(PackedInt64Array([8, 8, 8])))
	_hammer_by_hand(state, records, Vector2i(2, 7), 2048, rng)
	var result: MoveResult = _commit(state, records, [Vector2i(4, 6), Vector2i(4, 7)], rng)
	assert_true(result.accepted, "the chain commits")
	assert_eq(F.vv(result.notice_values), PackedInt64Array([2]), "2 left the window again")
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_eq(result.stars_earned, 0, "no star")
	assert_false(result.stars_earned > 0 or not result.cleared_small.is_empty(), "so the notice rule shows nothing")


# update_records and the config

func test_update_records_reads_the_config_and_defaults_without_one() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 0): 8192})
	var state: RunState = RunState.create(board, null, PackedInt64Array(), null, F.e(4096))
	var without: MoveResult = MoveResult.new()
	RunRules.update_records(state.copy(), Records.new(), without)
	assert_eq(without.stars_earned, 1, "no config: the defaults, 4096 to 8192 is 1 star")
	assert_eq(without.free_earned, 1, "and the third star earns a free booster")
	config.stars_per_free_booster = 1
	var with_config: MoveResult = MoveResult.new()
	RunRules.update_records(state.copy(), Records.new(), with_config, config)
	assert_eq(with_config.free_earned, 1, "one per star: 2 to 3 earns one")
	config.stars_per_free_booster = 2
	var two: MoveResult = MoveResult.new()
	RunRules.update_records(state.copy(), Records.new(), two, config)
	assert_eq(two.free_earned, 0, "two per star: 1 to 1 earns none")
	config = GameConfig.new()
	config.spawn_top_min = 64
	var moved: MoveResult = MoveResult.new()
	RunRules.update_records(state.copy(), Records.new(), moved, config)
	assert_eq(moved.stars_earned, 1, "SPAWN_TOP_MIN 64: floors 8 then 16, 1 star")


## Chains that move the run highest tile up step by step earn one star per
## doubling from 2K on, and the counts always equal the difference.
func test_stars_earned_add_up_over_a_run_of_doublings() -> void:
	var total_stars: int = 0
	var total_free: int = 0
	var value: int = 512
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): value, Vector2i(1, 7): value}), 0)
	var records: Records = Records.new()
	while value < (1 << 20):
		state.cells = F.changed(F.board_d(), {Vector2i(0, 7): value, Vector2i(1, 7): value})
		var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], F.seeded(value))
		assert_true(result.accepted, "%d pair" % value)
		total_stars += result.stars_earned
		total_free += result.free_earned
		value *= 2
	assert_eq(F.v(state.run_highest), 1 << 20, "run highest 1M")
	assert_eq(total_stars, 10, "ten stars earned along the way")
	assert_eq(total_free, 3, "three free boosters earned along the way")
	assert_eq(total_stars, _stars(state), "the earned stars add up to the count")

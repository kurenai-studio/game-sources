extends "res://tests/base_test.gd"
## Unlimited numbers and the ceiling (GDD D-37, D-04, D-15, 6.1, 6.7, 12.1;
## docs/ARCHITECTURE.md section 17). The score is a BigNum with no 64 bit
## limit, tiles keep doubling past 2^62, and one fit test (merge result at
## most MAX_EXPONENT, score below 2^MAX_SCORE_BITS) is shared by pair_fits,
## can_join, step_chain, joinable_cells, is_valid_chain, has_valid_move and
## commit_chain, so the highlight never shows a tile the commit refuses.
## The booster halves of AT-143, AT-144, AT-167 and AT-168 (usability, the
## offer, Double, Shuffle, Hammer through BoosterRules) are boosters tests.

const F := preload("res://tests/core/core_fixtures.gd")
const BART_SCORE: String = "9221253119629040934"
const CEILING: int = 65535

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _n(text: String) -> BigNum:
	return BigNum.parse(text, 20000)


## 2^bits minus amount.
func _below_pow2(bits: int, amount: int) -> BigNum:
	return BigNum.pow2(bits).sub(BigNum.from_int(amount))


func _drag(state: RunState, cells: Array[Vector2i]) -> Array[Vector2i]:
	var chain: Array[Vector2i] = []
	for cell: Vector2i in cells:
		chain = CoreRules.step_chain(state.cells, state.score, chain, cell, config)
	return chain


## Commits chain and checks that the refusal changed nothing at all.
func _assert_refused_and_unchanged(state: RunState, chain: Array[Vector2i], label: String) -> void:
	var before: RunState = state.copy()
	var records: Records = F.records(77, 64)
	var rng: RunRandom = F.seeded(63)
	rng.script_spawns(PackedInt64Array([10]))
	var rng_state: int = rng.get_state()
	var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
	assert_false(result.accepted, "%s: refused" % label)
	assert_eq(result.refusal, &"invalid_chain", "%s: as an invalid chain" % label)
	assert_true(state.equals(before), "%s: the state is unchanged" % label)
	assert_true(records.best_score.to_int() == 77 and records.best_tile == F.e(64), "%s: the records are unchanged" % label)
	assert_eq(rng.get_state(), rng_state, "%s: the generator is unchanged" % label)
	assert_eq(rng.next_spawn(PackedInt64Array([1, 2, 3, 4]), config), 10, "%s: no scripted spawn was used" % label)
	assert_eq(result.has_valid_move, CoreRules.has_valid_move(state.cells, state.score, config), "%s: the result's move check" % label)


# Bart's run (2026-10-21)

## His real board and score: the highlight showed, but every commit was
## refused at the 64 bit limit. Now the 2^50 pair commits and the score
## passes 2^63 exactly.
func test_bart_board_plays_a_chain_past_2_63() -> void:
	var state: RunState = RunState.create(F.bart_board(), _n(BART_SCORE))
	assert_eq(state.run_highest, 56, "run highest 2^56")
	assert_eq(CoreRules.stars(state.run_highest, config), 46, "46 stars")
	assert_eq(CoreRules.free_earned(state.run_highest, config), 15, "15 free boosters earned")
	assert_true(CoreRules.has_valid_move(state.cells, state.score, config), "the move check finds a move")
	var start: Array[Vector2i] = [Vector2i(1, 0)]
	assert_eq(CoreRules.joinable_cells(state.cells, state.score, start, config), [Vector2i(2, 1)] as Array[Vector2i], "the touching 2^50 is the only joinable tile")
	var chain: Array[Vector2i] = _drag(state, [Vector2i(1, 0), Vector2i(2, 1)])
	assert_eq(chain.size(), 2, "the drag joins it")
	var records: Records = F.records(9221253119629040934, 0)
	records.best_tile = 56
	var result: MoveResult = RunRules.commit_chain(state, records, chain, F.seeded(56), config)
	assert_true(result.accepted, "the chain commits")
	assert_eq(result.points.to_decimal(), "2251799813685248", "points 2^51")
	assert_eq(state.score.to_decimal(), "9223504919442726182", "score exactly 9,223,504,919,442,726,182")
	assert_false(state.score.fits_int(), "past 2^63 - 1")
	assert_eq(records.best_score.to_decimal(), "9223504919442726182", "Best Score follows live")
	assert_true(result.new_best_score, "a new Best Score")
	assert_eq(result.result_value, 51, "the result is 2^51")
	assert_eq(NumberFormat.score(state.score), "9,223,504,919B", "shown 9,223,504,919B")


## Every touching equal pair on Bart's board is joinable and commits, at his score.
func test_bart_board_every_pair_commits() -> void:
	var pairs: Array[Vector2i] = F.equal_pairs(F.bart_board())
	assert_true(pairs.size() > 20, "plenty of pairs")
	for position: int in range(0, pairs.size(), 2):
		var state: RunState = RunState.create(F.bart_board(), _n(BART_SCORE))
		var first: Array[Vector2i] = [pairs[position]]
		assert_true(CoreRules.joinable_cells(state.cells, state.score, first, config).has(pairs[position + 1]), "%s joins %s" % [pairs[position], pairs[position + 1]])
		var chain: Array[Vector2i] = [pairs[position], pairs[position + 1]]
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(position), config)
		if not result.accepted:
			fail("the pair %s commits" % [chain])
			return


## AT-160: Board D with a 2^56, a 2^50 pair and Bart's score.
func test_at_160_a_chain_takes_the_score_past_2_63() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(2, 0): 56, Vector2i(0, 7): 50, Vector2i(1, 7): 50})
	var state: RunState = RunState.create(board, _n(BART_SCORE), PackedInt64Array(), null, 56)
	assert_eq(NumberFormat.score(state.score), "9,221,253,119B", "before the chain")
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	assert_eq(CoreRules.joinable_cells(state.cells, state.score, start, config), [Vector2i(1, 7)] as Array[Vector2i], "(1,7) is the only joinable cell")
	var rng: RunRandom = F.seeded(160)
	rng.script_spawns(PackedInt64Array([47]))
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], rng, config)
	assert_true(result.accepted, "accepted")
	assert_eq(state.score.to_decimal(), "9223504919442726182", "the exact new score")
	assert_eq(state.score.compare(BigNum.from_int(9223372036854775807)), 1, "above 2^63 - 1")
	assert_eq(state.value_at(Vector2i(1, 7)), 51, "(1,7) = 2^51")
	var column: PackedInt64Array = PackedInt64Array()
	for row: int in 8:
		column.append(state.value_at(Vector2i(0, row)))
	assert_eq(column, PackedInt64Array([47, 1, 3, 1, 3, 1, 3, 1]), "column 0 reads 2^47, 2, 8, 2, 8, 2, 8, 2")
	assert_true(result.cleared_small.is_empty(), "nothing clears, H stays 2^56")
	assert_eq(NumberFormat.score(state.score), "9,223,504,919B", "after the chain")


# Tiles past 2^62

## AT-161 (a) and (b): the old SEC-01 board now plays, and 2^63 pairs too.
func test_at_161_tiles_past_2_62_merge() -> void:
	var cases: Array[Array] = [[62, "9223372036854775808", "8aa", "9,223,372,036B"], [63, "18446744073709551616", "16aa", "18,446,744T"]]
	for case: Array in cases:
		var k: int = case[0]
		for seed_value: int in range(1, 21):
			var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 7): k, Vector2i(1, 7): k})
			var state: RunState = RunState.create(board, BigNum.zero(), PackedInt64Array(), null, k, 5, CoreRules.free_earned(k, config))
			var label: String = "2^%d seed %d" % [k, seed_value]
			if not CoreRules.has_valid_move(state.cells, state.score, config):
				fail("%s: no valid move" % label)
				return
			var start: Array[Vector2i] = [Vector2i(0, 7)]
			if not CoreRules.joinable_cells(state.cells, state.score, start, config).has(Vector2i(1, 7)):
				fail("%s: (1,7) is not joinable" % label)
				return
			var result: MoveResult = RunRules.commit_chain(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], F.seeded(seed_value), config)
			var problem: String = ""
			if not result.accepted or state.value_at(Vector2i(1, 7)) != k + 1:
				problem = "not 2^%d on (1,7)" % (k + 1)
			elif NumberFormat.tile_label(k + 1) != case[2] or state.score.to_decimal() != case[1] or NumberFormat.score(state.score) != case[3]:
				problem = "labels or score %s" % state.score.to_decimal()
			elif result.floor_before != k - 9 or result.floor_after != k - 8 or result.cleared_small.size() != 38 or result.spawn_cells.size() != 39:
				problem = "floor 2^%d to 2^%d, %d cleared, %d spawns" % [result.floor_before, result.floor_after, result.cleared_small.size(), result.spawn_cells.size()]
			elif not _all_between(result.spawn_values, k - 8, k - 5):
				problem = "spawns %s" % result.spawn_values
			elif result.stars_earned != 1 or result.notice_values != PackedInt64Array([k - 9]):
				problem = "%d stars, notice %s" % [result.stars_earned, result.notice_values]
			if not problem.is_empty():
				fail("%s: %s" % [label, problem])
				return
	assert_eq(NumberFormat.tile_label(53), "8Q", "the AT-161 (a) notice value reads 8Q")


func _all_between(values: PackedInt64Array, low: int, high: int) -> bool:
	for value: int in values:
		if value < low or value > high:
			return false
	return true


## Chains up to 2^100 commit, with exact points and results.
func test_chains_up_to_2_100() -> void:
	var path: Array[Vector2i] = F.snake_from_bottom(7)
	var exponents: PackedInt64Array = PackedInt64Array([95, 95, 96, 97, 98, 99, 100])
	var board: PackedInt64Array = F.board_d()
	for position: int in path.size():
		board[path[position].y * 5 + path[position].x] = exponents[position]
	var state: RunState = RunState.create(board, BigNum.pow2(90))
	var chain: Array[Vector2i] = _drag(state, path)
	assert_eq(chain.size(), 7, "all seven tiles join")
	assert_eq(CoreRules.merge_result(exponents), 101, "2^95 x 2 + 2^96 + ... + 2^100 is exactly 2^101")
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(100), config)
	assert_true(result.accepted, "accepted")
	assert_true(result.points.equals(BigNum.pow2(101)), "points 2^101")
	assert_true(state.score.equals(BigNum.pow2(101).add(BigNum.pow2(90))), "score 2^101 + 2^90")
	assert_eq(result.result_value, 101, "result 2^101")
	assert_eq(NumberFormat.tile_label(101), "2ae", "labelled 2ae")
	assert_eq(state.run_highest, 101, "run highest 2^101")


## A mixed chain whose sum is not a power of two rounds down, past 2^62 too.
func test_mixed_chain_past_2_62_rounds_down() -> void:
	var path: Array[Vector2i] = F.snake_from_bottom(5)
	var exponents: PackedInt64Array = PackedInt64Array([62, 62, 62, 63, 64])
	var board: PackedInt64Array = F.board_d()
	for position: int in path.size():
		board[path[position].y * 5 + path[position].x] = exponents[position]
	var state: RunState = RunState.create(board, BigNum.zero())
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), path, F.seeded(5), config)
	assert_true(result.accepted, "accepted")
	assert_eq(result.points.to_decimal(), "41505174165846491136", "3 x 2^62 + 2^63 + 2^64 = 9 x 2^62")
	assert_eq(result.result_value, 65, "rounds down to 2^65")


# The ceiling: tiles

## AT-143 (a), the core half: two touching ceiling tiles are no move.
func test_at_143_two_touching_ceiling_tiles_are_not_a_move() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 7): CEILING, Vector2i(1, 7): CEILING})
	var earned: int = CoreRules.free_earned(CEILING, config)
	var state: RunState = RunState.create(board, BigNum.zero(), PackedInt64Array(), null, CEILING, 5, earned)
	assert_eq(CoreRules.stars(state.run_highest, config), 65525, "65,525 stars")
	assert_eq(earned, 21841, "21,841 free boosters earned")
	assert_eq(CoreRules.free_held(state, config), 0, "(a) all used, none held")
	assert_false(CoreRules.has_valid_move(state.cells, state.score, config), "no valid move")
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	assert_true(CoreRules.joinable_cells(state.cells, state.score, start, config).is_empty(), "nothing is joinable from (0,7)")
	assert_false(CoreRules.can_join(state.cells, state.score, start, Vector2i(1, 7), config), "can_join agrees")
	assert_eq(CoreRules.step_chain(state.cells, state.score, start, Vector2i(1, 7), config), start, "the finger over (1,7) changes nothing")
	var pair: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
	assert_false(CoreRules.is_valid_chain(state.cells, state.score, pair, config), "the pair is not a valid chain")
	assert_false(CoreRules.pair_fits(CEILING, state.score, config), "pair_fits agrees")
	_assert_refused_and_unchanged(state, pair, "AT-143 commit")
	var doubled: PackedInt64Array = F.changed_exponents(board, {Vector2i(2, 7): 4})
	assert_true(CoreRules.has_valid_move(doubled, state.score, config), "(b) with (2,7) doubled to 16 next to (3,7) = 16, the board has a move")


## AT-143 (c): a pair just below the ceiling makes the ceiling tile.
func test_at_143_c_a_pair_below_the_ceiling_commits() -> void:
	var k: int = CEILING - 1
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 7): k, Vector2i(1, 7): k})
	var state: RunState = RunState.create(board, BigNum.zero(), PackedInt64Array(), null, k, 5, CoreRules.free_earned(k, config))
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	assert_eq(CoreRules.joinable_cells(state.cells, state.score, start, config), [Vector2i(1, 7)] as Array[Vector2i], "(1,7) is joinable")
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], F.seeded(143), config)
	assert_true(result.accepted, "accepted")
	assert_eq(state.value_at(Vector2i(1, 7)), CEILING, "(1,7) = 2^65535")
	assert_eq(NumberFormat.tile_label(state.value_at(Vector2i(1, 7))), "32kiv", "labelled 32kiv")
	assert_true(state.score.equals(BigNum.pow2(CEILING)), "score exactly 2^65535")
	assert_eq(result.cleared_small.size(), 38, "every small tile clears")
	assert_eq(result.stars_earned, 1, "1 star earned")


## AT-144, the core half: an all ceiling board has no move, before and after
## a Hammer (done by hand: empty (0,0), settle with the scripted 2^65526).
func test_at_144_an_all_ceiling_board_has_no_move() -> void:
	var board: PackedInt64Array = F.board_all_exponent(CEILING)
	var state: RunState = RunState.create(board, BigNum.zero(), PackedInt64Array(), null, CEILING, 5, 21840)
	assert_false(CoreRules.has_valid_move(board, state.score, config), "no valid move")
	assert_eq(CoreRules.free_held(state, config), 1, "(a) 1 free booster held")
	for index: int in board.size():
		var chain: Array[Vector2i] = [CoreRules.cell_of(index, F.COLUMNS)]
		if not CoreRules.joinable_cells(board, state.score, chain, config).is_empty():
			fail("%s has a joinable neighbor" % chain[0])
			return
	_assert_refused_and_unchanged(state, [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i], "AT-144 pair")
	var hammered: RunState = RunState.create(F.changed_exponents(board, {Vector2i(0, 0): 0}), BigNum.zero(), PackedInt64Array(), null, CEILING)
	var rng: RunRandom = F.seeded(144)
	rng.script_spawns(PackedInt64Array([65526]))
	RunRules.settle(hammered, MoveResult.new(), rng, config)
	assert_eq(hammered.value_at(Vector2i(0, 0)), 65526, "(0,0) = 2^65526")
	assert_eq(CoreRules.spawn_window(CEILING, config), PackedInt64Array([65526, 65527, 65528, 65529]), "the window at the ceiling")
	assert_false(CoreRules.has_valid_move(hammered.cells, hammered.score, config), "still no valid move after the Hammer")


## AT-144 (b), the core half: at the largest score, a pair of 2^65526 does
## not fit until two Hammers (2^65535 each) have lowered the score.
func test_at_144_b_a_huge_score_and_the_window_floor_pair() -> void:
	var top: BigNum = _below_pow2(65600, 1)
	var board: PackedInt64Array = F.changed_exponents(F.board_all_exponent(CEILING), {Vector2i(0, 0): 65526, Vector2i(1, 0): 65526})
	assert_false(CoreRules.has_valid_move(board, top, config), "at 2^65600 - 1 the 2^65526 pair does not fit")
	assert_false(CoreRules.pair_fits(65526, top, config), "pair_fits agrees")
	var after_two: BigNum = top.sub(BigNum.pow2(CEILING)).sub(BigNum.pow2(CEILING))
	assert_true(CoreRules.has_valid_move(board, after_two, config), "after two Hammers it fits")
	assert_true(CoreRules.pair_fits(65526, after_two, config), "pair_fits agrees")


## On boards of one value near the ceiling, how far a drag gets, the move
## check, the full chain check and the commit all agree. n tiles of 2^k make
## 2^(k + floor(log2 n)), so the chain stops at 1, 3, 7, 15, 31 and 40.
func test_joining_the_move_check_and_commit_agree_at_the_tile_ceiling() -> void:
	var path: Array[Vector2i] = F.snake_from_top(40)
	var lengths: Dictionary[int, int] = {65535: 1, 65534: 3, 65533: 7, 65532: 15, 65531: 31, 65530: 40}
	for k: int in lengths:
		var label: String = "all 2^%d" % k
		var state: RunState = RunState.create(F.board_all_exponent(k), BigNum.zero())
		var chain: Array[Vector2i] = _drag(state, path)
		assert_eq(chain.size(), lengths[k], "%s: the drag joins %d tiles" % [label, lengths[k]])
		assert_eq(CoreRules.has_valid_move(state.cells, state.score, config), chain.size() >= 2, "%s: the move check agrees with joining" % label)
		assert_eq(CoreRules.pair_fits(k, state.score, config), chain.size() >= 2, "%s: pair_fits agrees" % label)
		if chain.size() >= 2:
			assert_true(CoreRules.is_valid_chain(state.cells, state.score, chain, config), "%s: the dragged chain is valid" % label)
			var copy: RunState = state.copy()
			assert_true(RunRules.commit_chain(copy, Records.new(), chain, F.seeded(k), config).accepted, "%s: and commits" % label)
		if chain.size() < 40:
			var longer: Array[Vector2i] = path.slice(0, chain.size() + 1)
			assert_true(CoreRules.joinable_cells(state.cells, state.score, chain, config).is_empty(), "%s: nothing is highlighted" % label)
			assert_false(CoreRules.is_valid_chain(state.cells, state.score, longer, config), "%s: one more is not valid" % label)
			_assert_refused_and_unchanged(state, longer, "%s, one more" % label)


func test_tiles_above_the_ceiling_never_join() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 7): 70000, Vector2i(1, 7): 70000})
	var state: RunState = RunState.create(board, BigNum.zero())
	assert_false(CoreRules.has_valid_move(state.cells, state.score, config), "a tampered pair above the ceiling is no move")
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	assert_true(CoreRules.can_join(state.cells, state.score, [] as Array[Vector2i], Vector2i(0, 7), config), "a lone tile can still start a drag")
	assert_true(CoreRules.joinable_cells(state.cells, state.score, start, config).is_empty(), "but nothing joins it")
	_assert_refused_and_unchanged(state, [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], "above the ceiling")


# The ceiling: score

## AT-167 (a), the core half: a score 2,048 below 2^65600 blocks the 1024 pair.
func test_at_167_a_the_score_ceiling_blocks_the_pair() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	for seed_value: int in range(1, 21):
		var state: RunState = RunState.create(board, _below_pow2(65600, 2048), PackedInt64Array(), null, 10)
		if CoreRules.has_valid_move(state.cells, state.score, config):
			fail("seed %d: a valid move" % seed_value)
			return
		var start: Array[Vector2i] = [Vector2i(0, 7)]
		if not CoreRules.joinable_cells(state.cells, state.score, start, config).is_empty():
			fail("seed %d: (1,7) is joinable" % seed_value)
			return
		var before: RunState = state.copy()
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], F.seeded(seed_value), config)
		if result.accepted or not state.equals(before) or result.has_valid_move:
			fail("seed %d: the commit was not refused cleanly" % seed_value)
			return
	# After a Shuffle (charged 1,024 by BoosterRules) the small pairs fit again.
	var shuffled: BigNum = _below_pow2(65600, 3072)
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(0, 0): 4}), shuffled, config), "at 2^65600 - 3,072 a 4 pair fits")
	assert_true(CoreRules.has_valid_move(board, shuffled, config), "and so does the 1024 pair")


## AT-167 (b), the core half: one point more room, and the pair commits to
## the largest score; then nothing on any board fits.
func test_at_167_b_the_pair_commits_to_the_largest_score() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	for seed_value: int in range(1, 21):
		var state: RunState = RunState.create(board, _below_pow2(65600, 2049), PackedInt64Array(), null, 10)
		var start: Array[Vector2i] = [Vector2i(0, 7)]
		var only: Array[Vector2i] = [Vector2i(1, 7)]
		var problem: String = ""
		if not CoreRules.has_valid_move(state.cells, state.score, config):
			problem = "no valid move before"
		elif CoreRules.joinable_cells(state.cells, state.score, start, config) != only:
			problem = "(1,7) is not the joinable cell"
		var result: MoveResult = RunRules.commit_chain(state, Records.new(), [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], F.seeded(seed_value), config)
		if problem.is_empty():
			if not result.accepted or not state.score.equals(_below_pow2(65600, 1)):
				problem = "not committed to 2^65600 - 1"
			elif state.value_at(Vector2i(1, 7)) != 11 or result.cleared_small.size() != 12:
				problem = "(1,7) = 2^%d, %d cleared" % [state.value_at(Vector2i(1, 7)), result.cleared_small.size()]
			elif result.has_valid_move or CoreRules.has_valid_move(state.cells, state.score, config):
				problem = "a valid move after"
		if problem.is_empty():
			for index: int in state.cells.size():
				var chain: Array[Vector2i] = [CoreRules.cell_of(index, F.COLUMNS)]
				if not CoreRules.joinable_cells(state.cells, state.score, chain, config).is_empty():
					problem = "%s has a joinable neighbor" % chain[0]
					break
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return
	assert_eq(NumberFormat.score(_below_pow2(65600, 1)), "36,958,603kjy", "the HUD score: 8 digits and kjy")
	assert_false(CoreRules.has_valid_move(F.board_all(2), _below_pow2(65600, 1), config), "not even a pair of 2s fits")
	assert_true(CoreRules.has_valid_move(F.board_all(2), _below_pow2(65600, 5), config), "until the score drops by 4")


## The fit test exactly at the score ceiling: points that land on
## 2^MAX_SCORE_BITS - 1 fit, one more does not.
func test_the_score_ceiling_edge() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 2, Vector2i(1, 7): 2})
	var pair: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
	var edge: RunState = RunState.create(board, _below_pow2(65600, 5))
	assert_true(CoreRules.is_valid_chain(edge.cells, edge.score, pair, config), "landing on 2^65600 - 1 fits")
	assert_true(RunRules.commit_chain(edge, Records.new(), pair, F.seeded(1), config).accepted, "and commits")
	assert_eq(edge.score.bit_length(), 65600, "the largest score")
	var over: RunState = RunState.create(board, _below_pow2(65600, 4))
	assert_false(CoreRules.is_valid_chain(over.cells, over.score, pair, config), "landing on 2^65600 does not fit")
	_assert_refused_and_unchanged(over, pair, "landing on 2^65600")
	var already: RunState = RunState.create(board, BigNum.pow2(65601))
	assert_false(CoreRules.has_valid_move(already.cells, already.score, config), "a score already past the ceiling blocks every pair")
	_assert_refused_and_unchanged(already, pair, "a score past the ceiling")


## The score is a required argument of every chain function (2026-10-21):
## each one gives the commit's answer for the score it is handed.
func test_every_chain_function_follows_the_score_it_is_given() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 32, Vector2i(1, 7): 32})
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	var pair: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
	var fits: BigNum = _below_pow2(65600, 65)
	var blocked: BigNum = _below_pow2(65600, 64)
	assert_true(CoreRules.pair_fits(5, fits, config), "pair_fits: room")
	assert_false(CoreRules.pair_fits(5, blocked, config), "pair_fits: no room")
	assert_true(CoreRules.has_valid_move(board, fits, config), "has_valid_move: room")
	assert_false(CoreRules.has_valid_move(board, blocked, config), "has_valid_move: no room")
	assert_true(CoreRules.can_join(board, fits, start, Vector2i(1, 7), config), "can_join: room")
	assert_false(CoreRules.can_join(board, blocked, start, Vector2i(1, 7), config), "can_join: no room")
	assert_eq(CoreRules.joinable_cells(board, fits, start, config), [Vector2i(1, 7)] as Array[Vector2i], "joinable_cells: room")
	assert_true(CoreRules.joinable_cells(board, blocked, start, config).is_empty(), "joinable_cells: no room")
	assert_eq(CoreRules.step_chain(board, fits, start, Vector2i(1, 7), config), pair, "step_chain: room")
	assert_eq(CoreRules.step_chain(board, blocked, start, Vector2i(1, 7), config), start, "step_chain: no room")
	assert_true(CoreRules.is_valid_chain(board, fits, pair, config), "is_valid_chain: room")
	assert_false(CoreRules.is_valid_chain(board, blocked, pair, config), "is_valid_chain: no room")


func test_pair_fits_edges() -> void:
	var zero: BigNum = BigNum.zero()
	assert_true(CoreRules.pair_fits(1, zero, config), "2")
	assert_true(CoreRules.pair_fits(62, zero, config), "2^62 now fits")
	assert_true(CoreRules.pair_fits(CEILING - 1, zero, config), "2^65534")
	assert_false(CoreRules.pair_fits(CEILING, zero, config), "2^65535: the result would pass the ceiling")
	assert_false(CoreRules.pair_fits(0, zero, config), "0 is no tile")
	assert_false(CoreRules.pair_fits(-1, zero, config), "a negative exponent")
	assert_false(CoreRules.pair_fits(9223372036854775807, zero, config), "the largest int")
	assert_true(CoreRules.pair_fits(1, _below_pow2(65600, 5), config), "a 2 pair lands on 2^65600 - 1")
	assert_false(CoreRules.pair_fits(1, _below_pow2(65600, 4), config), "a 2 pair lands on 2^65600")


# AT-168, the core half

## Constants lowered (TH4): MAX_EXPONENT 8 and MAX_SCORE_BITS 12. Random runs
## with random scores below 4,096. At every step the highlight equals an
## oracle written from GDD 6.1 with plain ints; a highlighted tile and a
## tile that is not highlighted, each tried on a copy, commit and are refused
## as the highlight says; every lift of a dragged chain commits; and the move
## check says yes exactly when some touching equal pair would commit. The
## boosters half is in tests/boosters.
## Seeds for AT-168. The GDD allows at least 10 in the automated test; QA's
## full run of 200 seeds stays a manual check (QA21-02).
const AT_168_SEEDS: int = 10
const AT_168_ACTIONS: int = 500
const AT_168_MOVES: int = 15


func test_at_168_the_highlight_never_shows_a_tile_the_commit_would_refuse() -> void:
	config.max_exponent = 8
	config.max_score_bits = 12
	var lifts: int = 0
	var highlighted_seen: int = 0
	var refusals_seen: int = 0
	var backtracks: int = 0
	var blocked: int = 0
	for seed_value: int in range(1, AT_168_SEEDS + 1):
		var moves: RandomNumberGenerator = RandomNumberGenerator.new()
		moves.seed = seed_value
		var rng: RunRandom = F.seeded(seed_value)
		var records: Records = Records.new()
		var state: RunState = RunRules.new_run(rng, records, config)
		state.score = BigNum.from_int(moves.randi_range(0, 4095))
		for action: int in AT_168_ACTIONS:
			var where: String = "seed %d action %d" % [seed_value, action]
			var chain: Array[Vector2i] = []
			chain = CoreRules.step_chain(state.cells, state.score, chain, Vector2i(moves.randi_range(0, 4), moves.randi_range(0, 7)), config)
			if chain.size() != 1:
				fail("%s: the first touch did not start a chain" % where)
				return
			# A move onto a tile that does not join leaves the chain as it was,
			# so the same board and chain would give the same answers again;
			# each chain is tried once and later steps on it only move on.
			var tried: Array[Vector2i] = []
			for step: int in moves.randi_range(1, AT_168_MOVES):
				var shown: Array[Vector2i] = CoreRules.joinable_cells(state.cells, state.score, chain, config)
				var oracle: Array[Vector2i] = _oracle_joinable(state, chain)
				if shown != oracle:
					fail("%s: highlight %s, rules say %s" % [where, shown, oracle])
					return
				# Every touching tile not in the chain, tried on a copy.
				var last: Vector2i = chain[chain.size() - 1]
				var touching: Array[Vector2i] = []
				var fresh: bool = chain != tried
				tried = chain
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var cell: Vector2i = last + Vector2i(dx, dy)
						if cell == last or not CoreRules.in_bounds(cell, config):
							continue
						touching.append(cell)
						if chain.has(cell) or not fresh:
							continue
						var commits: bool = _commits_on_copy(state, chain, cell, rng)
						if commits != shown.has(cell):
							fail("%s: %s highlighted %s, commit accepts %s" % [where, cell, shown.has(cell), commits])
							return
						if commits:
							highlighted_seen += 1
						else:
							refusals_seen += 1
				# The next finger move: back onto the previous tile, or onto any
				# touching cell (joinable or not).
				var target: Vector2i = touching[moves.randi_range(0, touching.size() - 1)]
				if chain.size() >= 2 and moves.randi_range(0, 3) == 0:
					target = chain[chain.size() - 2]
					backtracks += 1
				chain = CoreRules.step_chain(state.cells, state.score, chain, target, config)
			if chain.size() >= 2:
				var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
				if not result.accepted:
					fail("%s: a dragged chain %s was refused" % [where, chain])
					return
				lifts += 1
			var problem: String = _check_move_check_and_limits(state)
			if not problem.is_empty():
				fail("%s: %s" % [where, problem])
				return
			# The offer and the end of run are booster tests (tests/boosters/);
			# here a blocked board starts a new run, so play never stalls.
			if not CoreRules.has_valid_move(state.cells, state.score, config):
				blocked += 1
				state = RunRules.new_run(rng, records, config)
				state.score = BigNum.from_int(moves.randi_range(0, 4095))
	var floor_count: int = AT_168_SEEDS * 100
	assert_true(lifts > floor_count, "plenty of lifts (%d)" % lifts)
	assert_true(highlighted_seen > floor_count, "plenty of highlighted tiles tried (%d)" % highlighted_seen)
	assert_true(refusals_seen > floor_count, "plenty of other tiles tried (%d)" % refusals_seen)
	assert_true(backtracks > floor_count, "plenty of backtracks (%d)" % backtracks)
	assert_true(blocked > 0, "some boards blocked by the score ceiling (%d)" % blocked)


## GDD 6.1 conditions 1 to 5 with plain ints, for the lowered constants.
func _oracle_joinable(state: RunState, chain: Array[Vector2i]) -> Array[Vector2i]:
	var joinable: Array[Vector2i] = []
	var last: Vector2i = chain[chain.size() - 1]
	var last_value: int = 1 << state.value_at(last)
	var total: int = 0
	for cell: Vector2i in chain:
		total += 1 << state.value_at(cell)
	var score: int = state.score.to_int()
	for row: int in range(last.y - 1, last.y + 2):
		for column: int in range(last.x - 1, last.x + 2):
			var cell: Vector2i = Vector2i(column, row)
			if not CoreRules.in_bounds(cell, config) or chain.has(cell):
				continue
			var value: int = 1 << state.value_at(cell)
			if value != last_value and not (chain.size() >= 2 and value == last_value * 2):
				continue
			var sum: int = total + value
			var result: int = 1
			while result * 2 <= sum:
				result *= 2
			if result <= (1 << config.max_exponent) and score + sum < (1 << config.max_score_bits):
				joinable.append(cell)
	return joinable


func _commits_on_copy(state: RunState, chain: Array[Vector2i], cell: Vector2i, rng: RunRandom) -> bool:
	var longer: Array[Vector2i] = chain.duplicate()
	longer.append(cell)
	var copy: RunState = state.copy()
	var copy_rng: RunRandom = RunRandom.new()
	copy_rng.set_state(rng.get_state())
	return RunRules.commit_chain(copy, Records.new(), longer, copy_rng, config).accepted


## The move check against every touching equal pair tried as a commit on a
## copy, and the lowered ceilings.
func _check_move_check_and_limits(state: RunState) -> String:
	var any: bool = false
	var pairs: Array[Vector2i] = F.equal_pairs(state.cells)
	for position: int in range(0, pairs.size(), 2):
		var copy: RunState = state.copy()
		var pair: Array[Vector2i] = [pairs[position], pairs[position + 1]]
		if RunRules.commit_chain(copy, Records.new(), pair, F.seeded(1), config).accepted:
			any = true
			break
	if any != CoreRules.has_valid_move(state.cells, state.score, config):
		return "the move check says %s, the pairs say %s" % [not any, any]
	if CoreRules.highest(state.cells) > 8:
		return "a tile above 2^8"
	if state.score.bit_length() > 12:
		return "a score of %s" % state.score.to_decimal()
	return ""

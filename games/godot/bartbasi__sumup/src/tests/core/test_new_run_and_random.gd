extends "res://tests/base_test.gd"
## The starting board (D-14) through RunRules.new_run, and the run's random
## generator with its test overrides (GDD 9.5, TH5 to TH8).

const F := preload("res://tests/core/core_fixtures.gd")
const START_WINDOW: PackedInt64Array = [2, 4, 8, 16]
## The starting window as exponents, the way RunRandom takes it.
const START: PackedInt64Array = [1, 2, 3, 4]

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


# Starting board

func test_at_01_board_size_and_starting_values() -> void:
	var state: RunState = RunRules.new_run(F.seeded(1), Records.new(), config)
	assert_eq(state.cells.size(), 40, "40 tiles")
	assert_eq(state.columns, 5, "5 columns")
	assert_eq(state.cells.size() / state.columns, 8, "8 rows")
	assert_true(F.all_in(state.cells, START_WINDOW), "every value is 2, 4, 8 or 16 and no cell is empty")
	assert_true(state.score.is_zero(), "score 0")
	assert_false(state.has_snapshot(), "no Undo snapshot, so Undo is not usable")
	assert_true(state.snapshot_points.is_zero(), "no snapshot points")


func test_at_02_starting_board_always_has_a_move() -> void:
	var records: Records = Records.new()
	for seed_value: int in range(1, 1001):
		var state: RunState = RunRules.new_run(F.seeded(seed_value), records, config)
		if F.equal_pairs(state.cells).is_empty():
			fail("seed %d: no two touching tiles of equal value" % seed_value)
			return


func test_at_03_starting_board_fallback() -> void:
	var rng: RunRandom = F.seeded(3)
	rng.force_start_board(F.board_d())
	var state: RunState = RunRules.new_run(rng, Records.new(), config)
	assert_eq(rng.start_attempts, 100, "exactly 100 attempts")
	assert_eq(state.cells, F.changed(F.board_d(), {Vector2i(1, 7): 8}), "Board D with (1,7) = 8")
	assert_true(CoreRules.has_valid_move(state.cells, BigNum.zero(), config), "it has a valid move")
	var pair: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
	assert_true(CoreRules.is_valid_chain(state.cells, BigNum.zero(), pair, config), "(0,7) and (1,7) are a valid move")


func test_starting_board_fallback_follows_the_attempt_limit() -> void:
	var rng: RunRandom = F.seeded(3)
	rng.force_start_board(F.board_d())
	config.start_board_max_attempts = 7
	RunRules.new_run(rng, Records.new(), config)
	assert_eq(rng.start_attempts, 7, "START_BOARD_MAX_ATTEMPTS overridden to 7")


## ST1: the first attempt with a move is used as it is.
func test_starting_board_with_a_move_is_used_as_is() -> void:
	var rng: RunRandom = F.seeded(3)
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4})
	rng.force_start_board(board)
	var state: RunState = RunRules.new_run(rng, Records.new(), config)
	assert_eq(rng.start_attempts, 1, "one attempt")
	assert_eq(state.cells, board, "the board is used unchanged")


func test_start_attempts_counts_real_redraws() -> void:
	var total: int = 0
	for seed_value: int in range(1, 201):
		var rng: RunRandom = F.seeded(seed_value)
		RunRules.new_run(rng, Records.new(), config)
		if rng.start_attempts < 1 or rng.start_attempts > 100:
			fail("seed %d: %d attempts" % [seed_value, rng.start_attempts])
			return
		total += rng.start_attempts
	assert_true(total < 300, "a random board almost always has a move at once (%d attempts for 200 runs)" % total)


func test_at_04_starting_value_mix() -> void:
	var counts: Dictionary[int, int] = {2: 0, 4: 0, 8: 0, 16: 0}
	var tiles: int = 0
	var records: Records = Records.new()
	for seed_value: int in range(1, 2501):
		var state: RunState = RunRules.new_run(F.seeded(seed_value), records, config)
		for value: int in state.cells:
			counts[F.v(value)] += 1
			tiles += 1
	assert_eq(tiles, 100000, "100,000 tiles")
	var shares: Dictionary[int, float] = {2: 40.0, 4: 30.0, 8: 20.0, 16: 10.0}
	for value: int in shares:
		assert_near(counts[value] * 100.0 / tiles, shares[value], 1.0, "share of %d" % value)


func test_at_05_best_tile_from_the_starting_board() -> void:
	var records: Records = Records.new()
	var state: RunState = RunRules.new_run(F.seeded(5), records, config)
	assert_eq(records.best_tile, state.highest(), "Best Tile equals the starting board's highest tile")
	assert_true(records.best_score.is_zero(), "Best Score is 0")


## RH1 and RH7: the run highest tile starts from the new board, records stay.
func test_new_run_sets_run_highest_and_keeps_higher_records() -> void:
	var records: Records = F.records(96520, 16384)
	var state: RunState = RunRules.new_run(F.seeded(7), records, config)
	assert_eq(state.run_highest, state.highest(), "run highest is the board's highest tile")
	assert_true(state.run_highest <= F.e(16), "at most 16")
	assert_eq(records.best_tile, F.e(16384), "Best Tile never drops")
	assert_eq(records.best_score.to_int(), 96520, "Best Score never drops")


## D-39: making the starting board is not a move, so nothing clears even when
## a forced board holds tiles below its own floor.
func test_starting_board_never_clears_small_tiles() -> void:
	var rng: RunRandom = F.seeded(9)
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 8})
	rng.force_start_board(board)
	var records: Records = Records.new()
	var state: RunState = RunRules.new_run(rng, records, config)
	assert_eq(state.cells, board, "the 2s and 4s stay")
	assert_eq(state.run_highest, F.e(4096), "run highest from the board")
	assert_eq(records.best_tile, F.e(4096), "Best Tile from the board")


func test_new_run_never_uses_scripted_spawns() -> void:
	var rng: RunRandom = F.seeded(8)
	rng.script_spawns(F.ev(PackedInt64Array([1024, 2048])))
	var state: RunState = RunRules.new_run(rng, Records.new(), config)
	assert_true(F.all_in(state.cells, START_WINDOW), "the start board ignores scripted values")
	assert_eq(F.v(rng.next_spawn(START, config)), 1024, "the scripted values are still waiting for next_spawn")
	assert_eq(F.v(rng.next_spawn(START, config)), 2048, "in order")


# Seeds and state (TH5)

func test_the_same_seed_gives_the_same_game() -> void:
	var first_rng: RunRandom = F.seeded(42)
	var second_rng: RunRandom = F.seeded(42)
	var first: RunState = RunRules.new_run(first_rng, Records.new(), config)
	var second: RunState = RunRules.new_run(second_rng, Records.new(), config)
	assert_true(first.equals(second), "the same starting board")
	var pairs: Array[Vector2i] = F.equal_pairs(first.cells)
	var chain: Array[Vector2i] = [pairs[0], pairs[1]]
	var first_move: MoveResult = RunRules.commit_chain(first, Records.new(), chain, first_rng, config)
	var second_move: MoveResult = RunRules.commit_chain(second, Records.new(), chain, second_rng, config)
	assert_eq(first_move.spawn_values, second_move.spawn_values, "the same spawns")
	assert_true(first.equals(second), "the same board after the move")


func test_different_seeds_give_different_boards() -> void:
	var first: RunState = RunRules.new_run(F.seeded(1), Records.new(), config)
	var second: RunState = RunRules.new_run(F.seeded(2), Records.new(), config)
	assert_ne(first.cells, second.cells, "seeds 1 and 2 differ")


func test_state_can_be_read_and_restored() -> void:
	var rng: RunRandom = F.seeded(9)
	rng.next_spawn(START, config)
	var saved: int = rng.get_state()
	var first: PackedInt64Array = PackedInt64Array()
	for draw: int in 50:
		first.append(rng.next_spawn(START, config))
	var shuffled_first: PackedInt64Array = rng.shuffle_attempt(F.board_d())
	rng.set_state(saved)
	assert_eq(rng.get_state(), saved, "the state reads back")
	var second: PackedInt64Array = PackedInt64Array()
	for draw: int in 50:
		second.append(rng.next_spawn(START, config))
	assert_eq(second, first, "the same draws after restoring")
	assert_eq(rng.shuffle_attempt(F.board_d()), shuffled_first, "the same arrangement after restoring")


func test_a_restored_state_moves_to_another_generator() -> void:
	var source: RunRandom = F.seeded(10)
	source.next_spawn(START, config)
	var other: RunRandom = F.seeded(999)
	other.set_state(source.get_state())
	for draw: int in 20:
		assert_eq(other.next_spawn(START, config), source.next_spawn(START, config), "draw %d" % draw)


func test_use_random_seed_gives_a_working_generator() -> void:
	var rng: RunRandom = F.seeded(1)
	var before: int = rng.get_state()
	rng.use_random_seed()
	assert_ne(rng.get_state(), before, "a fresh seed")
	var state: RunState = RunRules.new_run(rng, Records.new(), config)
	assert_true(F.all_in(state.cells, START_WINDOW), "it still draws from the window")
	assert_true(CoreRules.has_valid_move(state.cells, BigNum.zero(), config), "and the board has a move")


# Scripted spawns (TH6)

func test_scripted_spawns_come_first_then_random_draws() -> void:
	var rng: RunRandom = F.seeded(11)
	var window: PackedInt64Array = F.ev(PackedInt64Array([4, 8, 16, 32]))
	rng.script_spawns(F.ev(PackedInt64Array([2, 1024])))
	var saved: int = rng.get_state()
	assert_eq(F.v(rng.next_spawn(window, config)), 2, "first scripted value, even below the window")
	assert_eq(F.v(rng.next_spawn(window, config)), 1024, "second scripted value")
	assert_eq(rng.get_state(), saved, "scripted values use no draws")
	for draw: int in 20:
		assert_true(window.has(rng.next_spawn(window, config)), "then random draws from the window")
	assert_ne(rng.get_state(), saved, "random draws use the generator")


func test_script_spawns_replaces_and_can_stop() -> void:
	var rng: RunRandom = F.seeded(12)
	rng.script_spawns(F.ev(PackedInt64Array([1024, 1024])))
	rng.script_spawns(F.ev(PackedInt64Array([2048])))
	assert_eq(F.v(rng.next_spawn(START, config)), 2048, "a new script replaces the old one")
	rng.script_spawns(F.ev(PackedInt64Array([4096])))
	rng.script_spawns(PackedInt64Array())
	assert_true(START.has(rng.next_spawn(START, config)), "an empty script stops scripting")


func test_scripted_values_are_copied() -> void:
	var rng: RunRandom = F.seeded(13)
	var values: PackedInt64Array = F.ev(PackedInt64Array([64]))
	rng.script_spawns(values)
	values[0] = F.e(128)
	assert_eq(F.v(rng.next_spawn(START, config)), 64, "later changes to the caller's array do not count")


func test_shuffle_attempt_never_uses_scripted_spawns() -> void:
	var rng: RunRandom = F.seeded(14)
	rng.script_spawns(F.ev(PackedInt64Array([1024])))
	var arranged: PackedInt64Array = rng.shuffle_attempt(F.board_d())
	var sorted_before: PackedInt64Array = F.board_d()
	sorted_before.sort()
	arranged.sort()
	assert_eq(arranged, sorted_before, "the same values")
	assert_eq(F.v(rng.next_spawn(START, config)), 1024, "the scripted value is still waiting")


# Start board and Shuffle attempts (TH7, TH8)

func test_start_board_attempt_fills_in_fill_order() -> void:
	var rng: RunRandom = F.seeded(15)
	var copy: RunRandom = F.seeded(15)
	var board: PackedInt64Array = rng.start_board_attempt(config)
	var window: PackedInt64Array = CoreRules.spawn_window(0, config)
	for column: int in 5:
		for row: int in 8:
			var expected: int = copy.next_spawn(window, config)
			assert_eq(board[row * 5 + column], expected, "one draw per cell, column by column, top down (%d, %d)" % [column, row])


func test_force_start_board_returns_copies_until_turned_off() -> void:
	var rng: RunRandom = F.seeded(16)
	var forced: PackedInt64Array = F.board_e()
	rng.force_start_board(forced)
	forced[0] = F.e(1024)
	var first: PackedInt64Array = rng.start_board_attempt(config)
	assert_eq(first, F.board_e(), "the forced board, copied when set")
	first[0] = F.e(2048)
	assert_eq(rng.start_board_attempt(config), F.board_e(), "each attempt is a fresh copy")
	rng.force_start_board(PackedInt64Array())
	assert_true(F.all_in(rng.start_board_attempt(config), START_WINDOW), "an empty board turns forcing off")


func test_force_shuffle_returns_the_forced_arrangement() -> void:
	var rng: RunRandom = F.seeded(17)
	var saved: int = rng.get_state()
	rng.force_shuffle(F.board_d())
	assert_eq(rng.shuffle_attempt(F.board_p()), F.board_d(), "the forced arrangement")
	assert_eq(rng.get_state(), saved, "no draws")
	rng.force_shuffle(PackedInt64Array())
	var arranged: PackedInt64Array = rng.shuffle_attempt(F.board_p())
	var sorted_p: PackedInt64Array = F.board_p()
	sorted_p.sort()
	arranged.sort()
	assert_eq(arranged, sorted_p, "an empty arrangement turns forcing off")


func test_shuffle_attempt_keeps_values_and_leaves_the_input() -> void:
	var rng: RunRandom = F.seeded(18)
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 1024})
	var arranged: PackedInt64Array = rng.shuffle_attempt(board)
	assert_eq(board, F.changed(F.board_d(), {Vector2i(2, 0): 1024}), "the input is not changed")
	assert_ne(arranged, board, "the arrangement moved tiles")
	var sorted_board: PackedInt64Array = board.duplicate()
	sorted_board.sort()
	arranged.sort()
	assert_eq(arranged, sorted_board, "the same 40 values")


func test_shuffle_attempt_makes_every_arrangement_equally_likely() -> void:
	var rng: RunRandom = F.seeded(19)
	var counts: Dictionary[String, int] = {}
	for draw: int in 6000:
		var key: String = str(rng.shuffle_attempt(PackedInt64Array([2, 4, 8])))
		counts[key] = counts.get(key, 0) + 1
	assert_eq(counts.size(), 6, "all six orders appear")
	for key: String in counts:
		assert_true(counts[key] > 850 and counts[key] < 1150, "order %s appears about 1,000 times (%d)" % [key, counts[key]])

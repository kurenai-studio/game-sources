extends "res://tests/base_test.gd"
## GameConfig, RunState, Records, MoveResult, BoosterStatus and RunSummary
## (docs/ARCHITECTURE.md sections 4 and 17, GDD sections 11, 15.1 and 18).
## Boards and tile values are exponents; scores and points are BigNum.

const F := preload("res://tests/core/core_fixtures.gd")


func test_game_config_defaults_match_gdd_section_18() -> void:
	var config: GameConfig = GameConfig.new()
	assert_eq(config.columns, 5, "BOARD_COLUMNS")
	assert_eq(config.rows, 8, "BOARD_ROWS")
	assert_eq(config.cell_count(), 40, "cell count")
	assert_eq(config.min_chain_length, 2, "MIN_CHAIN_LENGTH")
	assert_near(config.join_radius, 0.42, 0.000001, "JOIN_RADIUS")
	assert_eq(config.spawn_window_size, 4, "SPAWN_WINDOW_SIZE")
	assert_eq(config.spawn_weights, PackedInt32Array([40, 30, 20, 10]), "SPAWN_WEIGHTS")
	assert_eq(config.spawn_top_min, 16, "SPAWN_TOP_MIN")
	assert_eq(config.spawn_top_divisor, 64, "SPAWN_TOP_DIVISOR")
	assert_eq(config.start_board_max_attempts, 100, "START_BOARD_MAX_ATTEMPTS")
	assert_eq(config.shuffle_max_attempts, 100, "SHUFFLE_MAX_ATTEMPTS")
	assert_eq(config.cost_basis_min, 128, "COST_BASIS_MIN")
	assert_eq(config.cost_shift[&"hammer"], 0, "COST_HAMMER is B")
	assert_eq(config.cost_shift[&"swap"], 0, "COST_SWAP is B")
	assert_eq(config.cost_shift[&"shuffle"], 0, "COST_SHUFFLE is B")
	assert_eq(config.cost_shift[&"double"], 1, "COST_DOUBLE is 2 x B")
	assert_eq(config.cost_shift[&"undo"], -1, "COST_UNDO is B / 2")
	assert_eq(config.cost_shift.size(), 5, "one cost per booster")
	assert_eq(config.label_full_max, 10, "LABEL_FULL_MAX, the exponent of 1024")
	assert_eq(config.label_step, 1024, "LABEL_STEP")
	assert_eq(config.stars_per_free_booster, 3, "STARS_PER_FREE_BOOSTER")
	assert_eq(config.max_exponent, 65535, "MAX_EXPONENT (D-37)")
	assert_eq(config.max_score_bits, 65600, "MAX_SCORE_BITS (D-37)")


func test_game_config_overrides_stay_in_their_instance() -> void:
	var changed: GameConfig = GameConfig.new()
	changed.rows = 6
	changed.cost_shift[&"undo"] = 2
	changed.spawn_weights[0] = 70
	changed.max_exponent = 20
	var fresh: GameConfig = GameConfig.new()
	assert_eq(changed.cell_count(), 30, "cell count follows rows")
	assert_eq(fresh.rows, 8, "another instance keeps its rows")
	assert_eq(fresh.cost_shift[&"undo"], -1, "another instance keeps its costs")
	assert_eq(fresh.spawn_weights[0], 40, "another instance keeps its weights")
	assert_eq(fresh.max_exponent, 65535, "another instance keeps its ceiling")


func test_run_state_create_fills_every_field() -> void:
	var board: PackedInt64Array = F.board_p()
	var snapshot: PackedInt64Array = F.board_d()
	var state: RunState = RunState.create(board, F.big(1234), snapshot, F.big(40), F.e(4096), 5, 1, F.big(38500))
	assert_eq(state.best_at_start.to_decimal(), "38500", "Best Score at the start as given (QA6-03)")
	assert_eq(state.cells, F.board_p(), "cells")
	assert_eq(state.score.to_decimal(), "1234", "score")
	assert_eq(state.snapshot_cells, F.board_d(), "snapshot cells")
	assert_eq(state.snapshot_points.to_decimal(), "40", "snapshot points")
	assert_eq(state.run_highest, 12, "run highest as given, the exponent of 4096")
	assert_eq(state.columns, 5, "columns")
	assert_eq(state.free_used, 1, "free boosters used as given (D-46)")
	assert_true(state.has_snapshot(), "has a snapshot")


func test_run_state_create_defaults() -> void:
	var state: RunState = RunState.create(F.board_p(), BigNum.zero())
	assert_false(state.has_snapshot(), "no snapshot by default")
	assert_true(state.snapshot_points.is_zero(), "no snapshot points")
	assert_eq(state.run_highest, 5, "run highest 0 means the board's highest tile, 32")
	assert_eq(state.columns, 5, "five columns")
	assert_eq(state.free_used, 0, "no free boosters used by default")
	assert_eq(state.highest(), 5, "H is the exponent 5")
	assert_eq(RunState.new().free_used, 0, "a bare state has used none")
	assert_null(state.best_at_start, "Best Score at the start is unknown (null) by default")
	assert_null(RunState.new().best_at_start, "and on a bare state")
	assert_true(RunState.new().score.is_zero(), "a bare state scores 0")
	assert_true(RunState.new().snapshot_points.is_zero(), "with 0 snapshot points")


func test_run_state_create_treats_a_null_score_as_zero() -> void:
	var state: RunState = RunState.create(F.board_p(), null, PackedInt64Array(), null)
	assert_true(state.score.is_zero(), "score 0")
	assert_true(state.snapshot_points.is_zero(), "snapshot points 0")


func test_run_state_create_copies_the_given_arrays() -> void:
	var board: PackedInt64Array = F.board_d()
	var snapshot: PackedInt64Array = F.board_e()
	var state: RunState = RunState.create(board, BigNum.zero(), snapshot, F.big(8))
	board[0] = 10
	snapshot[0] = 10
	assert_eq(state.cells, F.board_d(), "later changes to the caller's board do not reach the state")
	assert_eq(state.snapshot_cells, F.board_e(), "later changes to the caller's snapshot do not reach the state")


func test_run_state_holds_tiles_past_2_62() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 0): 100, Vector2i(4, 7): 65535})
	var state: RunState = RunState.create(board, BigNum.pow2(200))
	assert_eq(state.value_at(Vector2i(0, 0)), 100, "a 2^100 tile")
	assert_eq(state.highest(), 65535, "H at the ceiling")
	assert_eq(state.run_highest, 65535, "run highest from the board")
	assert_eq(state.score.bit_length(), 201, "a score of 2^200")


func test_run_state_value_at_corners_and_off_board() -> void:
	var state: RunState = RunState.create(F.board_p(), BigNum.zero())
	assert_eq(state.value_at(Vector2i(0, 0)), F.e(2), "top left")
	assert_eq(state.value_at(Vector2i(4, 0)), F.e(2), "top right")
	assert_eq(state.value_at(Vector2i(0, 7)), F.e(8), "bottom left")
	assert_eq(state.value_at(Vector2i(4, 7)), F.e(8), "bottom right")
	assert_eq(state.value_at(Vector2i(2, 7)), F.e(32), "the 32")
	assert_eq(state.value_at(Vector2i(-1, 0)), 0, "left of the board")
	assert_eq(state.value_at(Vector2i(5, 0)), 0, "right of the board, not the next row")
	assert_eq(state.value_at(Vector2i(0, 8)), 0, "below the board")
	assert_eq(state.value_at(Vector2i(0, -1)), 0, "above the board")
	assert_eq(state.value_at(Vector2i(-1, -1)), 0, "no cell")


func test_run_state_copy_is_deep_and_equal() -> void:
	var state: RunState = RunState.create(F.board_p(), F.big(500), F.board_d(), F.big(16), F.e(8192), 5, 1, BigNum.zero())
	var other: RunState = state.copy()
	assert_true(other.equals(state), "a copy equals the original")
	assert_true(state.equals(other), "equality goes both ways")
	assert_eq(other.free_used, 1, "the copy keeps free_used")
	assert_true(other.best_at_start.is_zero(), "the copy keeps best_at_start")
	other.cells[0] = 10
	other.snapshot_cells[0] = 10
	assert_eq(state.cells, F.board_p(), "changing the copy's board leaves the original")
	assert_eq(state.snapshot_cells, F.board_d(), "changing the copy's snapshot leaves the original")
	assert_false(other.equals(state), "the changed copy is no longer equal")


func test_run_state_copy_keeps_a_zero_run_highest() -> void:
	var state: RunState = RunState.new()
	state.cells = F.board_d()
	var other: RunState = state.copy()
	assert_eq(other.run_highest, 0, "copy takes run_highest as it is")
	assert_true(other.equals(state), "and stays equal")


func test_run_state_equals_checks_every_field() -> void:
	var base: RunState = RunState.create(F.board_p(), F.big(500), F.board_d(), F.big(16), F.e(64))
	assert_false(base.equals(null), "never equal to null")
	var other: RunState = base.copy()
	assert_true(base.equals(other), "a copy is equal")
	other.cells[39] = F.e(16)
	assert_false(base.equals(other), "a different cell")
	other = base.copy()
	other.score = F.big(501)
	assert_false(base.equals(other), "a different score")
	other = base.copy()
	other.score = F.big(500)
	assert_true(base.equals(other), "an equal score in another BigNum")
	other = base.copy()
	other.snapshot_cells = PackedInt64Array()
	assert_false(base.equals(other), "no snapshot")
	other = base.copy()
	other.snapshot_cells[5] = F.e(4)
	assert_false(base.equals(other), "a different snapshot board")
	other = base.copy()
	other.snapshot_points = F.big(17)
	assert_false(base.equals(other), "different snapshot points")
	other = base.copy()
	other.run_highest = F.e(128)
	assert_false(base.equals(other), "a different run highest")
	other = base.copy()
	other.columns = 4
	assert_false(base.equals(other), "different columns")
	other = base.copy()
	other.free_used = 1
	assert_false(base.equals(other), "different free boosters used")
	other = base.copy()
	other.best_at_start = BigNum.zero()
	assert_false(base.equals(other), "a different Best Score at the start, 0 against unknown")
	assert_false(other.equals(base), "unknown against 0, the other way")
	var both: RunState = other.copy()
	both.best_at_start = BigNum.zero()
	assert_true(other.equals(both), "0 and 0 are equal")
	both.best_at_start = F.big(1)
	assert_false(other.equals(both), "0 and 1 are not")


## QA6-03: core never sets best_at_start. A chain keeps it, and the Undo
## snapshot is only a board and its points.
func test_core_never_changes_best_at_start() -> void:
	var starts: Array[BigNum] = [null, BigNum.zero(), F.big(38500)]
	for start: BigNum in starts:
		var label: String = "null" if start == null else start.to_decimal()
		var state: RunState = RunState.create(F.board_p(), F.big(1000), PackedInt64Array(), null, 0, 5, 0, start)
		var records: Records = F.records(40000, 32)
		var result: MoveResult = RunRules.commit_chain(state, records, [Vector2i(1, 6), Vector2i(2, 6)] as Array[Vector2i], F.seeded(6), GameConfig.new())
		assert_true(result.accepted, "%s: the chain commits" % label)
		RunRules.update_records(state, records, MoveResult.new())
		assert_true(state.best_at_start == start, "%s: kept through a commit and the records" % label)
		assert_eq(state.snapshot_cells, F.board_p(), "%s: the snapshot is the board before" % label)
	var fresh: RunState = RunRules.new_run(F.seeded(1), F.records(5000, 64), GameConfig.new())
	assert_null(fresh.best_at_start, "new_run leaves it unknown for GameSession to set")


func test_records_rise_and_never_drop() -> void:
	var records: Records = Records.new()
	assert_true(records.best_score.is_zero(), "Best Score starts at 0")
	assert_eq(records.best_tile, 0, "Best Tile starts at none")
	assert_true(records.update_from(F.state(F.board_d(), 100)), "both rise")
	assert_eq(records.best_score.to_int(), 100, "Best Score")
	assert_eq(records.best_tile, F.e(16), "Best Tile is H")
	assert_false(records.update_from(F.state(F.board_d(), 50)), "a lower score changes nothing")
	assert_eq(records.best_score.to_int(), 100, "Best Score never drops")
	assert_true(records.update_from(F.state(F.board_p(), 50)), "a higher tile alone rises")
	assert_eq(records.best_tile, F.e(32), "Best Tile rose")
	assert_eq(records.best_score.to_int(), 100, "Best Score kept")
	assert_true(records.update_from(F.state(F.board_d(), 101)), "a higher score alone rises")
	assert_eq(records.best_tile, F.e(32), "Best Tile never drops when H is lower")
	assert_false(records.update_from(F.state(F.board_d(), 101)), "an equal score changes nothing")


func test_records_past_64_bits() -> void:
	var records: Records = F.records(9221253119629040934, 0)
	var past: BigNum = BigNum.parse("9223504918442726182", 30)
	assert_true(records.update_from(RunState.create(F.bart_board(), past)), "a score past 2^63 - 1 is a new Best Score")
	assert_eq(records.best_score.to_decimal(), "9223504918442726182", "kept exactly")
	assert_eq(records.best_tile, 56, "Best Tile 2^56")
	var huge: PackedInt64Array = F.changed_exponents(F.bart_board(), {Vector2i(0, 0): 300})
	assert_true(records.update_from(RunState.create(huge, past)), "a 2^300 tile is a new Best Tile")
	assert_eq(records.best_tile, 300, "Best Tile 2^300")


## GDD 11.2 example B1 and B2: Best Score follows the score live and stays when spending lowers the score.
func test_records_b1_b2_best_score_live() -> void:
	var records: Records = F.records(10000, 0)
	records.update_from(F.state(F.board_d(), 10500))
	assert_eq(records.best_score.to_int(), 10500, "B1")
	records.update_from(F.state(F.board_d(), 8452))
	assert_eq(records.best_score.to_int(), 10500, "B2")


func test_records_copy_is_independent() -> void:
	var records: Records = F.records(5000, 512)
	var other: Records = records.copy()
	assert_eq(other.best_score.to_int(), 5000, "copied Best Score")
	assert_eq(other.best_tile, F.e(512), "copied Best Tile")
	other.best_score = F.big(1)
	other.best_tile = 1
	assert_eq(records.best_score.to_int(), 5000, "the original Best Score is untouched")
	assert_eq(records.best_tile, F.e(512), "the original Best Tile is untouched")


func test_move_result_defaults() -> void:
	var result: MoveResult = MoveResult.new()
	assert_false(result.accepted, "not accepted")
	assert_eq(result.refusal, &"", "no refusal")
	assert_eq(result.result_cell, Vector2i(-1, -1), "no result cell")
	assert_true(result.has_valid_move, "has_valid_move defaults to true")
	assert_true(result.chain.is_empty(), "no chain")
	assert_true(result.spawn_values.is_empty(), "no spawns")
	assert_false(result.offer_opens, "no offer")
	assert_false(result.run_ends, "no run end")
	assert_eq(MoveResult.Kind.size(), 7, "seven kinds")
	assert_true(result.notice_values.is_empty(), "no notice values (D-45)")
	assert_eq(result.stars_earned, 0, "no stars earned")
	assert_eq(result.free_earned, 0, "no free boosters earned (D-46)")
	assert_false(result.free_used, "no free booster used")
	assert_true(result.points.is_zero(), "no points")
	assert_true(result.cost.is_zero(), "no cost")


func test_booster_status_and_run_summary_hold_their_fields() -> void:
	var status: BoosterStatus = BoosterStatus.new()
	assert_false(status.free, "not free by default")
	status.id = &"undo"
	status.cost = 6
	status.usable = false
	status.reason = BoosterStatus.Usability.NO_SNAPSHOT
	status.active = false
	status.suggested = true
	status.free = true
	assert_eq(status.reason, BoosterStatus.Usability.NO_SNAPSHOT, "reason")
	assert_true(status.free, "free (D-46)")
	assert_eq(status.cost, 6, "the price, as an exponent, stays while free (AT-56)")
	assert_eq(BoosterStatus.Usability.size(), 4, "four usability values")
	var summary: RunSummary = RunSummary.new()
	assert_eq(summary.stars, 0, "no stars by default")
	assert_true(summary.final_score.is_zero(), "final score defaults to 0")
	summary.final_score = F.big(476)
	summary.run_highest = F.e(1024)
	summary.no_moves_left = true
	summary.stars = 7
	assert_eq(summary.final_score.to_int(), 476, "final score")
	assert_eq(summary.run_highest, 10, "run highest as an exponent")
	assert_eq(summary.stars, 7, "this run's stars (D-45)")
	assert_true(summary.best_score.is_zero(), "best score defaults to 0")
	assert_false(summary.new_best_score, "no badge by default")


## SEC-01: NO_TARGET is appended last, so saved or compared numbers of the
## older values never change.
func test_usability_values_keep_their_numbers() -> void:
	assert_eq(int(BoosterStatus.Usability.USABLE), 0, "USABLE")
	assert_eq(int(BoosterStatus.Usability.CANNOT_AFFORD), 1, "CANNOT_AFFORD")
	assert_eq(int(BoosterStatus.Usability.NO_SNAPSHOT), 2, "NO_SNAPSHOT")
	assert_eq(int(BoosterStatus.Usability.NO_TARGET), 3, "NO_TARGET, last")

@tool
extends McpTestSuite

const RunEngineScript = preload("res://scripts/run_engine.gd")

var engine


func suite_name() -> String:
	return "run_engine"


func setup() -> void:
	engine = RunEngineScript.new()
	engine.start_run(20261023)


func test_initial_state_is_ready() -> void:
	assert_eq(engine.board.size(), 9, "board should always have nine cells")
	assert_eq(engine.phase, RunEngineScript.PHASE_PLAYING)
	assert_true(engine.has_pending)
	assert_true(engine.pending_value >= 1 and engine.pending_value <= 3, "initial tile should be low value")
	assert_true(engine.next_value >= 1 and engine.next_value <= 3, "next preview should also be low value")
	assert_eq(engine.get_matches().size(), 0)


func test_single_line_merges_to_center_with_plus_one() -> void:
	engine.board.assign([1, 1, 0, 2, 0, 0, 0, 0, 0])
	engine.pending_value = 1
	engine.has_pending = true
	var result = engine.place(2)
	assert_true(result.ok)
	assert_eq(engine.lines_cleared, 1)
	assert_eq(engine.board[1], 2, "new center tile should be source value + 1")
	assert_eq(engine.board[0], 0)
	assert_eq(engine.board[3], 2, "tiles outside the completed line should remain")
	assert_gt(engine.score, 0)


func test_simultaneous_shared_center_combines_upgrades() -> void:
	engine.board.assign([3, 0, 0, 3, 0, 3, 0, 0, 3])
	engine.pending_value = 3
	engine.has_pending = true
	var result = engine.place(4)
	assert_true(result.ok)
	assert_eq(result.resolution.lines_cleared, 2)
	assert_eq(engine.board[4], 8, "two upgrades sharing a center should aggregate")
	assert_eq(result.resolution.results.size(), 1)
	assert_eq(engine.best_simultaneous, 2)


func test_cascade_chains_into_second_match() -> void:
	engine.board.assign([2, 2, 0, 0, 3, 0, 0, 3, 0])
	engine.pending_value = 2
	engine.has_pending = true
	var result = engine.place(2)
	assert_true(result.ok)
	assert_eq(result.resolution.cascades, 2)
	assert_eq(engine.best_cascade, 2)
	assert_eq(engine.board[4], 4, "second cascade should upgrade the next center")


func test_wildcard_can_complete_a_line() -> void:
	engine.board.assign([1, RunEngineScript.WILD_VALUE, 0, 2, 0, 0, 0, 0, 0])
	engine.pending_value = 1
	engine.has_pending = true
	var result = engine.place(2)
	assert_true(result.ok)
	assert_eq(result.resolution.lines_cleared, 1)
	assert_eq(engine.board[1], 2)
	assert_eq(engine.board[0], 0)


func test_reward_opens_at_threshold_and_choice_sticks() -> void:
	engine.score = 70
	engine.board.assign([1, 1, 0, 2, 0, 0, 0, 0, 0])
	engine.pending_value = 1
	engine.has_pending = true
	engine.place(2)
	assert_eq(engine.phase, RunEngineScript.PHASE_REWARD)
	assert_eq(engine.pending_choices.size(), 2, "reward offers exactly two distinct rules")
	assert_ne(engine.pending_choices[0], engine.pending_choices[1])
	var chosen = engine.pending_choices[0]
	var choice = engine.choose_rule(chosen)
	assert_true(choice.ok)
	assert_eq(engine.get_rule_stack(chosen), 1)
	assert_eq(engine.phase, RunEngineScript.PHASE_PLAYING)
	assert_true(engine.has_pending)


func test_next_preview_is_preserved_across_reward() -> void:
	engine.score = 49
	engine.board.assign([1, 1, 0, 2, 0, 0, 0, 0, 0])
	engine.pending_value = 1
	engine.next_value = 3
	engine.has_pending = true
	engine.place(2)
	assert_eq(engine.phase, RunEngineScript.PHASE_REWARD)
	var preview: int = int(engine.next_value)
	var choice = engine.pending_choices[0]
	engine.choose_rule(choice)
	assert_eq(engine.pending_value, 3, "the shown next tile must become current")
	assert_eq(engine.pending_value, preview)
	assert_true(engine.has_pending)


func test_full_stalemate_ends_run() -> void:
	engine.board.assign([1, 1, 2, 1, 1, 2, 2, 2, 0])
	engine.pending_value = 3
	engine.has_pending = true
	engine.place(8)
	assert_eq(engine.phase, RunEngineScript.PHASE_GAME_OVER)
	assert_false(engine.has_pending)
	assert_true(engine.is_deadlocked())


func test_second_wind_consumes_charge_and_clears_a_cell() -> void:
	engine.stacks["second_wind"] = 1
	engine.rescue_charges = 1
	engine.board.assign([1, 1, 2, 1, 1, 2, 2, 2, 0])
	engine.pending_value = 3
	engine.has_pending = true
	engine.place(8)
	assert_eq(engine.phase, RunEngineScript.PHASE_PLAYING)
	assert_eq(engine.rescue_charges, 0)
	assert_eq(engine.rescues_used, 1)
	assert_true(engine.has_pending)
	var occupied := 0
	for value in engine.board:
		if value != 0:
			occupied += 1
	assert_eq(occupied, 8, "rescue should free exactly one cell")


func test_contract_discounts_future_threshold() -> void:
	engine.stacks["contract"] = 1
	assert_eq(engine.next_threshold(), 45)


func test_result_plus_increases_upgrade_value() -> void:
	engine.stacks["result_plus"] = 1
	engine.board.assign([2, 2, 0, 0, 0, 0, 0, 0, 0])
	engine.pending_value = 2
	engine.has_pending = true
	engine.place(2)
	assert_eq(engine.board[1], 4, "result_plus should add another level")

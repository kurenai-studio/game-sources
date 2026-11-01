extends "res://tests/base_test.gd"
## The no moves offer through GameSession (GDD 12.2: D-19, D-42; worked
## examples GO1 to GO7; flow rules 3 to 5): opening, refreshing and closing,
## targeting entered from the offer and cancelled back to it, End run, and
## the offer coming back after a restart.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)

var recorder: BF.Recorder


func before_each() -> void:
	recorder = BF.Recorder.new()


func _names(list: Array) -> PackedStringArray:
	return PackedStringArray(list)


## A session resumed on the state with the move check run, recorder on.
func _session(state: RunState, seed_value: int = 1, records: Records = null) -> GameSession:
	var session: GameSession = BF.ready_session(state, records, seed_value)
	recorder.watch(session)
	return session


## Board D1024 with a snapshot worth 40 whose board has a valid move.
func _with_snapshot(score: int) -> RunState:
	return BF.make(BF.board_d1024(), score, BF.snapshot_board(), 40)


## The AT-52 board: Board D1024 with (0,0) = 32 and (4,7) = 32. No valid move.
func _two_32s() -> PackedInt64Array:
	return F.changed(BF.board_d1024(), {Vector2i(0, 0): 32, Vector2i(4, 7): 32})


func _costs(session: GameSession) -> Array[int]:
	var list: Array[int] = []
	for status: BoosterStatus in session.booster_statuses():
		list.append(F.v(status.cost))
	return list


# Opening the offer

func test_at_46_a_move_that_leaves_no_valid_move_opens_the_offer() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 0): 4, Vector2i(1, 0): 2})
	var session: GameSession = _session(F.state(board, 5000))
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "the setup has a move")
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	var result: MoveResult = session.tap_cell(Vector2i(1, 0))
	assert_eq(session.state.cells, F.board_d(), "the board is now Board D")
	assert_eq(BF.n(session.state.score), 4872, "score 4,872")
	assert_true(result.offer_opens, "the result says the offer opens")
	assert_false(result.has_valid_move, "no valid move")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed"]), "the offer opens after the view")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "with Shuffle suggested")
	assert_true(session.is_offer_open(), "offer open")
	assert_false(session.can_start_chain(), "dragging builds no chain")
	assert_false(session.begin_drag(), "no drag")


func test_a_chain_that_leaves_no_valid_move_opens_the_offer() -> void:
	# Board E with (0,1) = 4. Merging (0,0) and (0,1) puts an 8 back on (0,1),
	# and a scripted 2 on (0,0) leaves Board E with (0,0) = 2: no move.
	var session: GameSession = _session(F.state(F.changed(F.board_e(), {Vector2i(0, 1): 4}), 5000))
	session.rng.script_spawns(F.ev(PackedInt64Array([2])))
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(0, 0), Vector2i(0, 1)]))
	assert_eq(session.state.cells, F.changed(F.board_e(), {Vector2i(0, 0): 2}), "Board E with (0,0) = 2")
	assert_true(result.accepted, "the chain commits")
	assert_true(result.offer_opens, "no valid move after it")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.OFFER, "OFFER")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "Shuffle suggested")


func test_at_47_what_the_offer_shows() -> void:
	var session: GameSession = _session(_with_snapshot(5000))
	assert_true(session.is_offer_open(), "the offer opens")
	assert_eq(recorder.names, PackedStringArray(), "nothing more without input")
	assert_eq(BF.usable_ids(session), BoosterRules.ALL, "all five enabled")
	assert_eq(_costs(session), [1024, 1024, 1024, 2048, 512] as Array[int], "Hammer 1,024, Swap 1,024, Shuffle 1,024, Double 2,048, Undo 512")
	assert_eq(BF.suggested_id(session), BoosterRules.SHUFFLE, "Shuffle is marked as suggested")
	assert_eq(session.state.cells, BF.board_d1024(), "the board stays as it is")
	assert_eq(session.phase(), GameSession.Phase.OFFER, "still OFFER")


func test_at_48_go1_shuffle_rescues() -> void:
	var session: GameSession = _session(_with_snapshot(5000), 48)
	recorder.clear()
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_true(result != null and result.accepted, "Shuffle applies at once from the offer")
	assert_eq(recorder.names, _names(["move_resolved", "status_changed", "save_requested"]), "rule 2")
	assert_eq(BF.n(session.state.score), 3976, "score 3,976")
	assert_true(result.has_valid_move, "the board has a valid move")
	assert_false(result.offer_opens, "the offer will close")
	assert_true(session.is_offer_open(), "the offer stays open while the move shows")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed"]), "the offer closes")
	assert_eq(recorder.offers[0], [false, &""], "closed")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "play goes on")
	assert_true(session.can_start_chain(), "chains can be dragged")
	assert_eq(BF.suggested_id(session), &"", "nothing is marked outside the offer")


func test_at_49_go2_only_undo_is_usable() -> void:
	var session: GameSession = _session(_with_snapshot(600))
	assert_true(session.is_offer_open(), "the offer opens")
	assert_eq(BF.usable_ids(session), [BoosterRules.UNDO] as Array[StringName], "only Undo is enabled")
	assert_eq(BF.suggested_id(session), BoosterRules.UNDO, "and marked as the suggested rescue (D-42)")
	var result: MoveResult = session.press_booster(BoosterRules.UNDO)
	assert_true(result.accepted, "Undo applies at once")
	assert_eq(session.state.cells, BF.snapshot_board(), "the board equals the snapshot board")
	assert_eq(BF.n(session.state.score), 48, "score 48")
	session.move_shown()
	assert_false(session.is_offer_open(), "the offer closes")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "play goes on")


func test_go3_and_go6_nothing_usable_ends_the_run() -> void:
	var go3: GameSession = GameSession.new()
	recorder.watch(go3)
	go3.resume(_with_snapshot(300))
	go3.move_shown()
	assert_eq(go3.phase(), GameSession.Phase.ENDED, "GO3: the run ends at once")
	assert_eq(recorder.count("offer_changed"), 0, "no offer")
	assert_eq(BF.n(recorder.summaries[0].final_score), 300, "final score 300")

	recorder.clear()
	var go6: GameSession = _session(F.state(BF.board_d1024(), 1500))
	go6.rng.script_spawns(F.ev(PackedInt64Array([4])))
	go6.press_booster(BoosterRules.HAMMER)
	var result: MoveResult = go6.tap_cell(Vector2i(1, 0))
	assert_eq(go6.state.cells, BF.board_d1024(), "GO6: the hammered 4 came back as a 4, still no move")
	assert_true(result.run_ends, "GO6: nothing usable at 476")
	go6.move_shown()
	assert_eq(go6.phase(), GameSession.Phase.ENDED, "the run ends at once")
	assert_eq(BF.n(recorder.summaries[0].final_score), 476, "final score 476")
	assert_eq(recorder.offers[recorder.offers.size() - 1], [false, &""], "the offer closed first")


func test_at_51_go4_cancelling_targeting_returns_to_the_offer() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 1500))
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle"] as Array[StringName], "Hammer, Swap and Shuffle enabled, Double and Undo disabled")
	recorder.clear()
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(recorder.names, _names(["targeting_changed", "status_changed"]), "targeting entered with no offer_changed")
	assert_eq(session.phase(), GameSession.Phase.TARGETING, "TARGETING")
	assert_true(session.is_offer_open(), "the offer stays open while targeting from it")
	assert_eq(BF.suggested_id(session), BoosterRules.SHUFFLE, "still marked while targeting from the offer")
	recorder.clear()
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(recorder.names, _names(["targeting_changed", "offer_changed", "status_changed"]), "back to the offer, worked out afresh")
	assert_eq(recorder.targeting[0], [&"", NO_CELL], "targeting ended")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "the offer again")
	assert_eq(session.phase(), GameSession.Phase.OFFER, "OFFER")
	assert_eq(BF.n(session.state.score), 1500, "score still 1,500")


func test_cancel_targeting_from_the_offer_by_back_or_pause() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 1500))
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	recorder.clear()
	session.cancel_targeting()
	assert_eq(recorder.names, _names(["targeting_changed", "offer_changed", "status_changed"]), "back to the offer")
	assert_eq(session.phase(), GameSession.Phase.OFFER, "OFFER")
	assert_eq(session.swap_first(), NO_CELL, "the selection is gone")
	assert_eq(BF.n(session.state.score), 1500, "nothing charged")


func test_at_52_go5_swap_rescues() -> void:
	var session: GameSession = _session(F.state(_two_32s(), 1500))
	assert_true(session.is_offer_open(), "the offer is open")
	session.press_booster(BoosterRules.HAMMER)
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(session.phase(), GameSession.Phase.OFFER, "GO4 cancel, then GO5")
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(4, 7))
	var result: MoveResult = session.tap_cell(Vector2i(1, 0))
	assert_eq(F.v(session.state.value_at(Vector2i(1, 0))), 32, "(1,0) = 32")
	assert_eq(F.v(session.state.value_at(Vector2i(4, 7))), 4, "(4,7) = 4")
	assert_eq(BF.n(session.state.score), 476, "score 476")
	assert_true(result.has_valid_move, "the two 32s now touch")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.offers, [[false, &""]] as Array[Array], "the offer closes")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "play goes on")


func test_at_53_the_offer_repeats_then_the_run_ends() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 1500))
	session.rng.script_spawns(F.ev(PackedInt64Array([8])))
	session.press_booster(BoosterRules.HAMMER)
	var result: MoveResult = session.tap_cell(Vector2i(4, 7))
	assert_eq(F.column_of(session.state.cells, 4), PackedInt64Array([8, 2, 8, 2, 8, 2, 8, 2]), "column 4 reads 8, 2, 8, 2, 8, 2, 8, 2")
	assert_eq(BF.n(session.state.score), 476, "score 476")
	assert_false(result.has_valid_move, "still no valid move")
	assert_true(result.run_ends, "every cost is at least 512")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "the run ends at once")
	assert_eq(BF.n(recorder.summaries[0].final_score), 476, "final score 476")
	assert_true(recorder.summaries[0].no_moves_left, "because no moves were left")


func test_the_offer_refreshes_after_a_booster_that_leaves_no_move() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 5000))
	session.rng.script_spawns(F.ev(PackedInt64Array([2])))
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	var result: MoveResult = session.tap_cell(Vector2i(4, 0))
	assert_true(result.offer_opens, "still no move, still something usable")
	assert_eq(session.phase(), GameSession.Phase.OFFER, "the phase is OFFER while the move shows")
	assert_true(session.is_offer_open(), "the offer stays open")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed"]), "the offer refreshes; the status already changed with the move")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "worked out afresh")
	assert_eq(BF.n(session.state.score), 3976, "Hammer charged 1,024")


func test_the_offer_refresh_moves_the_suggestion_to_undo() -> void:
	# Score 2,000 with a snapshot worth 40. A Hammer that leaves no move costs
	# 1,024, leaving 976: Shuffle is no longer usable, Undo (512) is.
	var session: GameSession = _session(_with_snapshot(2000))
	session.rng.script_spawns(F.ev(PackedInt64Array([2])))
	session.press_booster(BoosterRules.HAMMER)
	session.tap_cell(Vector2i(4, 0))
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.offers, [[true, BoosterRules.UNDO]] as Array[Array], "the offer opens again with Undo marked (12.2 step 6)")
	assert_eq(BF.usable_ids(session), [BoosterRules.UNDO] as Array[StringName], "only Undo is usable")


func test_at_101_a_double_from_the_offer_clears_and_rescues() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})
	var session: GameSession = _session(F.state(board, 5000))
	assert_true(session.is_offer_open(), "the offer is open")
	session.rng.script_spawns(F.ev(PackedInt64Array([8])))
	session.press_booster(BoosterRules.DOUBLE)
	assert_true(session.is_offer_open(), "targeting from the offer")
	recorder.clear()
	var result: MoveResult = session.tap_cell(Vector2i(2, 0))
	assert_eq(recorder.names, _names(["targeting_changed", "move_resolved", "status_changed", "save_requested"]), "targeting ends, the move resolves and saves")
	assert_eq(BF.n(session.state.score), 2952, "score 2,952")
	assert_eq(F.v(session.state.value_at(Vector2i(2, 0))), 2048, "(2,0) = 2048")
	assert_eq(result.cleared_small, [Vector2i(0, 3)] as Array[Vector2i], "the 2 on (0,3) was cleared")
	assert_eq(F.v(session.state.value_at(Vector2i(0, 0))), 8, "(0,0) = 8")
	assert_eq([F.v(session.state.value_at(Vector2i(0, 3))), F.v(session.state.value_at(Vector2i(0, 4)))], [4, 4], "(0,3) and (0,4) are both 4")
	assert_true(result.has_valid_move, "the board has a valid move")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed"]), "the offer closes")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "PLAYING")


func test_at_73_shuffle_with_no_equal_pair_opens_the_offer_again() -> void:
	var board: PackedInt64Array = PackedInt64Array()
	for exponent: int in range(1, 41):
		board.append(exponent)
	var session: GameSession = _session(BF.none_held(F.state(board, 1 << 41)), 73)
	assert_eq(session.phase(), GameSession.Phase.OFFER, "no move: the offer is open")
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(BF.n(session.state.score), 1 << 40, "score 2^40")
	assert_true(result.offer_opens, "the no moves offer opens")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.offers, [[true, BoosterRules.SHUFFLE]] as Array[Array], "the offer again, Shuffle still affordable")


func test_at_109_the_offer_marks_the_suggested_rescue() -> void:
	assert_eq(BF.suggested_id(_session(_with_snapshot(5000))), BoosterRules.SHUFFLE, "(a) Shuffle")
	assert_eq(BF.suggested_id(_session(_with_snapshot(600))), BoosterRules.UNDO, "(b) Undo")
	assert_eq(BF.suggested_id(_session(F.state(BF.board_d1024(), 1500))), BoosterRules.SHUFFLE, "(c) Shuffle")
	var config: GameConfig = GameConfig.new()
	config.cost_shift = {&"hammer": 0, &"swap": 0, &"shuffle": 2, &"double": 1, &"undo": 2}
	var d: GameSession = BF.ready_session(_with_snapshot(1500), null, 1, config)
	assert_true(d.is_offer_open(), "(d) the offer opens")
	assert_eq(BF.usable_ids(d), [&"hammer", &"swap"] as Array[StringName], "(d) Hammer and Swap usable")
	assert_eq(BF.suggested_id(d), &"", "(d) nothing is marked")


# End run (D-19 step 7, 12.3)

func test_at_54_end_run() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 1500), 1, F.records(900, 512))
	recorder.clear()
	session.end_run()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed", "run_ended"]), "the offer closes and the run ends")
	assert_eq(recorder.count("save_requested"), 0, "the ended run is never saved again")
	var summary: RunSummary = recorder.summaries[0]
	assert_eq(BF.n(summary.final_score), 1500, "final score")
	assert_eq(BF.n(summary.best_score), 1500, "Best Score")
	assert_eq(F.v(summary.best_tile), 1024, "Best Tile")
	assert_eq(F.v(summary.run_highest), 1024, "this run's highest tile")
	assert_true(summary.new_best_score, "this run beat 900")
	assert_false(summary.no_moves_left, "the player chose End run")
	assert_eq(session.phase(), GameSession.Phase.ENDED, "ENDED")
	assert_false(session.is_run_in_progress(), "nothing to resume")


func test_end_run_while_targeting_from_the_offer() -> void:
	var session: GameSession = _session(F.state(BF.board_d1024(), 1500))
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	recorder.clear()
	session.end_run()
	assert_eq(recorder.names, _names(["targeting_changed", "offer_changed", "status_changed", "run_ended"]), "targeting ends, the offer closes, the run ends")
	assert_eq(session.targeting_booster(), &"", "no targeting")
	assert_eq(session.swap_first(), NO_CELL, "no selection")
	assert_eq(BF.n(session.state.score), 1500, "nothing charged")


func test_end_run_needs_an_open_offer_and_no_move_showing() -> void:
	var playing: GameSession = _session(F.state(F.board_p(), 5000))
	recorder.clear()
	playing.end_run()
	assert_eq(playing.phase(), GameSession.Phase.PLAYING, "ignored in play")
	playing.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	playing.end_run()
	assert_eq(playing.phase(), GameSession.Phase.TARGETING, "ignored while targeting outside the offer")
	assert_eq(recorder.names, PackedStringArray(), "no signal")

	var showing: GameSession = _session(_with_snapshot(5000))
	showing.press_booster(BoosterRules.SHUFFLE)
	recorder.clear()
	showing.end_run()
	assert_eq(recorder.names, PackedStringArray(), "ignored while the rescue is still showing")
	assert_true(showing.is_run_in_progress(), "the run goes on")
	var idle: GameSession = GameSession.new()
	idle.end_run()
	assert_eq(idle.phase(), GameSession.Phase.NONE, "ignored with no run")


# After a restart (D-33, 15.1)

func test_at_55_go7_the_offer_survives_a_restart() -> void:
	var session: GameSession = _session(F.state(_two_32s(), 1500))
	assert_true(session.is_offer_open(), "the offer is open")
	var saved: RunState = session.state.copy()
	var reopened: GameSession = GameSession.new()
	recorder.clear()
	recorder.watch(reopened)
	reopened.resume(saved)
	assert_true(recorder.started[0].spawn_cells.is_empty(), "the board shows without a spawn animation")
	assert_false(reopened.is_offer_open(), "the offer waits until the board is shown")
	reopened.move_shown()
	assert_eq(recorder.offers, [[true, BoosterRules.SHUFFLE]] as Array[Array], "the offer opens again, unchanged")
	assert_eq(reopened.state.cells, _two_32s(), "same board")
	assert_eq(BF.n(reopened.state.score), 1500, "same score")
	assert_eq(BF.usable_ids(reopened), [&"hammer", &"swap", &"shuffle"] as Array[StringName], "same choices")


func test_at_83_the_undo_snapshot_survives_a_restart() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 512, Vector2i(1, 7): 8, Vector2i(2, 7): 16})
	var session: GameSession = _session(F.state(board, 1000), 83)
	session.commit_chain(BF.targets([Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]))
	session.move_shown()
	var undo_before: BoosterStatus = BF.status_of(session, BoosterRules.UNDO)
	assert_true(undo_before.usable, "Undo enabled right after the chain")
	var saved: RunState = session.state.copy()
	var reopened: GameSession = BF.ready_session(saved, null, 84)
	var undo_after: BoosterStatus = BF.status_of(reopened, BoosterRules.UNDO)
	assert_true(undo_after.usable, "Undo still enabled after reopening")
	assert_eq(undo_after.cost, undo_before.cost, "at the same cost")
	var result: MoveResult = reopened.press_booster(BoosterRules.UNDO)
	assert_true(result.accepted, "Undo works")
	assert_eq(reopened.state.cells, board, "the board from before that chain")
	assert_eq(BF.n(reopened.state.score), 744, "the expected score")


func test_at_91_resume_keeps_board_score_records_and_undo() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024})
	var records: Records = F.records(0, 1024)
	var session: GameSession = _session(F.state(board, 20000), 91, records)
	session.commit_chain(BF.targets([Vector2i(0, 7), Vector2i(1, 7)]))
	session.move_shown()
	var saved: RunState = session.state.copy()
	var saved_records: Records = records.copy()
	var undo_cost: int = BF.status_of(session, BoosterRules.UNDO).cost
	var reopened: GameSession = BF.ready_session(saved, saved_records, 92)
	assert_true(reopened.state.equals(saved), "the same board, score, snapshot and run highest tile")
	assert_eq(BF.n(reopened.records.best_score), 22048, "the same Best Score")
	assert_eq(F.v(reopened.records.best_tile), 2048, "the same Best Tile")
	assert_eq(F.v(reopened.state.run_highest), 2048, "the same run highest tile")
	assert_true(BF.status_of(reopened, BoosterRules.UNDO).usable, "Undo enabled")
	assert_eq(BF.status_of(reopened, BoosterRules.UNDO).cost, undo_cost, "at the same cost")

extends "res://tests/base_test.gd"
## GameSession's own contract (docs/ARCHITECTURE.md section 5): new runs and
## resume (flow rule 7), the order of signals for a move (rule 2), the waiting
## flag and move_shown() (rules 1 and 3, D-35), refused input in every locked
## state, drags (D-08), queries, and the end of a run (rule 8, 12.3).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)
const P_CHAIN: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)]

var recorder: BF.Recorder


func before_each() -> void:
	recorder = BF.Recorder.new()


func _names(list: Array) -> PackedStringArray:
	return PackedStringArray(list)


## A session in PLAYING on Board P with the given score, ready for input.
func _playing(score: int = 5000) -> GameSession:
	var session: GameSession = BF.ready_session(F.state(F.board_p(), score))
	recorder.watch(session)
	return session


## A session whose run has ended: Board D1024, score 300, nothing usable.
func _ended() -> GameSession:
	var session: GameSession = BF.ready_session(BF.make(BF.board_d1024(), 300, BF.snapshot_board(), 40))
	recorder.watch(session)
	return session


func _status_ids_where_usable(session: GameSession) -> Array[StringName]:
	return BF.usable_ids(session)


# A new session

func test_a_new_session_waits_in_phase_none() -> void:
	var session: GameSession = GameSession.new()
	assert_eq(session.phase(), GameSession.Phase.NONE, "phase NONE")
	assert_false(session.is_run_in_progress(), "no run in progress")
	assert_false(session.is_offer_open(), "no offer")
	assert_false(session.is_waiting_for_view(), "not waiting")
	assert_false(session.can_start_chain(), "no chain")
	assert_false(session.begin_drag(), "no drag")
	assert_false(session.is_dragging(), "still no drag")
	assert_eq(session.targeting_booster(), &"", "no targeting")
	assert_eq(session.swap_first(), NO_CELL, "no Swap selection")
	assert_not_null_services(session)
	var statuses: Array[BoosterStatus] = session.booster_statuses()
	assert_eq(statuses.size(), 5, "five boosters")
	for status: BoosterStatus in statuses:
		assert_false(status.usable, "%s disabled before a run" % status.id)
		assert_false(status.active or status.suggested, "%s neither active nor suggested" % status.id)
	assert_eq(F.v(session.preview_value(P_CHAIN)), 0, "no preview on an empty board")
	assert_true(session.joinable_cells([Vector2i(0, 0)] as Array[Vector2i]).is_empty(), "nothing joins on an empty board")


func assert_not_null_services(session: GameSession) -> void:
	assert_true(session.config != null and session.rng != null and session.records != null and session.state != null, "missing services are created")
	assert_eq(BF.n(session.state.score), 0, "an empty state with score 0")


func test_the_services_given_are_the_ones_used() -> void:
	var config: GameConfig = GameConfig.new()
	var rng: RunRandom = RunRandom.new()
	var records: Records = F.records(77, 8)
	var session: GameSession = GameSession.new(config, rng, records)
	assert_true(session.config == config and session.rng == rng and session.records == records, "same objects")


# New run (D-14) and resume (D-33, flow rule 7)

func test_start_new_run_emits_run_started_status_and_save() -> void:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.rng.force_start_board(F.board_p())
	session.start_new_run()
	assert_eq(recorder.names, _names(["run_started", "status_changed", "save_requested"]), "signals in order")
	var result: MoveResult = recorder.started[0]
	assert_eq(result.kind, MoveResult.Kind.NEW_RUN, "kind NEW_RUN")
	assert_true(result.accepted, "accepted")
	assert_eq(result.cells_after, F.board_p(), "cells_after is the new board")
	assert_eq(result.cells_before, F.board_p(), "cells_before too")
	assert_eq(result.spawn_cells.size(), 40, "all 40 cells spawn")
	assert_eq(result.spawn_cells[0], Vector2i(0, 0), "in fill order: column 0 from the top")
	assert_eq(result.spawn_cells[1], Vector2i(0, 1), "then down the column")
	assert_eq(result.spawn_cells[8], Vector2i(1, 0), "then the next column")
	var replayed: PackedInt64Array = PackedInt64Array()
	replayed.resize(40)
	for position: int in 40:
		replayed[CoreRules.index_of(result.spawn_cells[position], 5)] = result.spawn_values[position]
	assert_eq(replayed, F.board_p(), "spawn values rebuild the board")
	assert_true(result.has_valid_move, "the starting board has a move")
	assert_false(result.offer_opens or result.run_ends, "play goes on")
	assert_true(result.new_best_tile, "Best Tile rose from 0 to 32")
	assert_eq(F.v(session.records.best_tile), 32, "Best Tile from the starting board (AT-05)")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "PLAYING")
	assert_true(session.is_waiting_for_view(), "waiting for the view")
	assert_false(session.can_start_chain(), "no chain until the board is shown")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, PackedStringArray(), "the move check finds a move: no signal")
	assert_true(session.can_start_chain(), "chains can start")


func test_at_01_a_new_run_through_the_session() -> void:
	var session: GameSession = GameSession.new()
	session.start_new_run()
	session.move_shown()
	assert_eq(session.state.cells.size(), 40, "40 tiles")
	assert_true(F.all_in(session.state.cells, PackedInt64Array([2, 4, 8, 16])), "every value is 2, 4, 8 or 16")
	assert_eq(BF.n(session.state.score), 0, "score 0")
	assert_eq(BF.status_of(session, BoosterRules.UNDO).reason, BoosterStatus.Usability.NO_SNAPSHOT, "Undo not usable")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "a run never starts dead")


func test_start_new_run_takes_a_fresh_random_seed() -> void:
	var session: GameSession = GameSession.new()
	session.rng.set_seed(5)
	session.start_new_run()
	var seeded: RunState = RunRules.new_run(F.seeded(5), Records.new(), GameConfig.new())
	assert_ne(session.state.cells, seeded.cells, "the seed set before was replaced")


func test_resume_emits_run_started_without_spawns_then_the_move_check() -> void:
	var saved: RunState = F.state(BF.board_d1024(), 5000)
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(saved)
	assert_eq(recorder.names, _names(["run_started", "status_changed", "save_requested"]), "signals in order")
	var result: MoveResult = recorder.started[0]
	assert_eq(result.kind, MoveResult.Kind.NEW_RUN, "kind NEW_RUN")
	assert_eq(result.cells_before, saved.cells, "cells_before is the loaded board")
	assert_eq(result.cells_after, saved.cells, "cells_after is the loaded board")
	assert_true(result.spawn_cells.is_empty(), "no spawn animation")
	assert_true(result.offer_opens, "the result already says the offer opens")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "PLAYING while the board is shown")
	assert_true(session.is_waiting_for_view(), "waiting")
	assert_false(session.is_offer_open(), "the offer waits for move_shown()")
	assert_false(session.can_start_chain(), "no chain while waiting")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed"]), "the move check opens the offer")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "with Shuffle suggested")
	assert_eq(session.phase(), GameSession.Phase.OFFER, "OFFER")
	assert_true(session.is_offer_open(), "offer open")
	assert_false(session.begin_drag(), "dragging builds no chain (D-19 step 1)")


func test_resume_copies_the_saved_state_and_updates_records() -> void:
	var saved: RunState = BF.make(BF.board_d1024(), 7000, BF.snapshot_board(), 40, 2048, 5, 0, 50)
	var records: Records = F.records(100, 16)
	var session: GameSession = GameSession.new(null, null, records)
	session.resume(saved)
	assert_true(session.state.equals(saved), "the state is the saved run exactly")
	assert_false(session.state == saved, "but a copy")
	saved.score = F.big(1)
	assert_eq(BF.n(session.state.score), 7000, "changing the saved object later changes nothing")
	assert_eq(BF.n(records.best_score), 7000, "Best Score updated from the run (step 7)")
	assert_eq(F.v(records.best_tile), 1024, "Best Tile updated from the board")
	assert_eq(F.v(session.state.run_highest), 2048, "the saved run highest tile is kept")
	assert_true(BF.status_of(session, BoosterRules.UNDO).usable, "the snapshot came along: Undo usable")


func test_resume_takes_a_fresh_random_seed() -> void:
	var session: GameSession = GameSession.new()
	session.rng.set_seed(5)
	var seeded: int = session.rng.get_state()
	session.resume(F.state(F.board_p(), 0))
	assert_ne(session.rng.get_state(), seeded, "a fresh seed (9.5)")


func test_resume_of_nothing_is_ignored() -> void:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(null)
	assert_eq(session.phase(), GameSession.Phase.NONE, "still NONE")
	assert_eq(recorder.names, PackedStringArray(), "no signal")


func test_at_96_new_game_during_a_run() -> void:
	var session: GameSession = _playing(9000)
	session.begin_drag()
	session.commit_chain(P_CHAIN)
	session.move_shown()
	assert_eq(BF.n(session.records.best_score), 9016, "Best Score followed the run")
	session.start_new_run()
	session.move_shown()
	assert_eq(BF.n(session.state.score), 0, "a new run starts with score 0")
	assert_eq(BF.status_of(session, BoosterRules.UNDO).reason, BoosterStatus.Usability.NO_SNAPSHOT, "Undo disabled")
	assert_eq(BF.n(session.records.best_score), 9016, "Best Score still holds the old run's highest score")
	assert_false(session.is_dragging(), "no drag carried over")


func test_new_run_from_the_offer_closes_it_and_from_targeting_ends_it() -> void:
	var session: GameSession = BF.ready_session(F.state(BF.board_d1024(), 5000))
	recorder.watch(session)
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	session.start_new_run()
	assert_eq(recorder.names, _names(["targeting_changed", "offer_changed", "run_started", "status_changed", "save_requested"]), "targeting and the offer close first")
	assert_eq(recorder.targeting[0], [&"", NO_CELL], "targeting ends")
	assert_eq(recorder.offers[0], [false, &""], "the offer closes")
	assert_eq(session.targeting_booster(), &"", "no targeting")
	assert_false(session.is_offer_open(), "no offer")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "PLAYING")


# A move: signals, waiting and move_shown() (flow rules 2 and 3, D-35)

func test_signal_order_for_a_chain() -> void:
	var session: GameSession = _playing(1000)
	assert_true(session.begin_drag(), "a drag opens")
	assert_true(session.is_dragging(), "dragging")
	var result: MoveResult = session.commit_chain(P_CHAIN)
	assert_true(result.accepted, "the chain commits")
	assert_eq(recorder.names, _names(["move_resolved", "status_changed", "save_requested"]), "move_resolved, status_changed, save_requested")
	assert_true(recorder.resolved[0] == result, "move_resolved carries the returned result")
	assert_false(session.is_dragging(), "commit_chain ended the drag")
	assert_true(session.is_waiting_for_view(), "waiting for the view")
	assert_false(result.offer_opens or result.run_ends, "play goes on")
	assert_eq(BF.n(session.state.score), 1016, "the model already resolved the move (AT-17)")
	assert_true(BF.status_of(session, BoosterRules.UNDO).usable, "Undo usable at once")


func test_at_97_one_move_at_a_time() -> void:
	var session: GameSession = _playing(5000)
	session.begin_drag()
	session.commit_chain(P_CHAIN)
	var before: RunState = session.state.copy()
	recorder.clear()
	assert_false(session.can_start_chain(), "no chain while the move shows")
	assert_false(session.begin_drag(), "a new drag is ignored")
	var again: MoveResult = session.commit_chain(BF.targets([Vector2i(0, 7), Vector2i(1, 7)]))
	assert_eq(again.refusal, &"not_now", "a commit is refused with not_now")
	assert_true(null == session.press_booster(BoosterRules.SHUFFLE), "a booster tap is ignored")
	assert_true(null == session.press_booster(BoosterRules.HAMMER), "a targeting booster tap is ignored")
	assert_eq(session.targeting_booster(), &"", "no targeting")
	assert_true(session.state.equals(before), "nothing changed")
	assert_eq(recorder.names, PackedStringArray(), "nothing emitted, nothing queued")
	session.move_shown()
	assert_false(session.is_waiting_for_view(), "the move is shown")
	assert_true(session.can_start_chain(), "chains work again")
	assert_true(null != session.press_booster(BoosterRules.SHUFFLE), "boosters work again")


func test_move_shown_only_counts_once_per_move() -> void:
	var session: GameSession = _playing(5000)
	session.move_shown()
	assert_eq(recorder.names, PackedStringArray(), "nothing to show: ignored")
	session.commit_chain(P_CHAIN)
	session.move_shown()
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, PackedStringArray(), "a second call is ignored")
	assert_true(session.can_start_chain(), "still playing")


func test_signal_order_for_an_instant_booster() -> void:
	var session: GameSession = _playing(5000)
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_true(result != null and result.accepted, "Shuffle applies at once")
	assert_eq(recorder.names, _names(["move_resolved", "status_changed", "save_requested"]), "rule 2 order")
	assert_eq(BF.n(result.cost), 128, "charged")
	assert_true(session.is_waiting_for_view(), "waiting")


# Refused input in each locked state (flow rule 1)

func _assert_locked(session: GameSession, label: String, chain_refused: bool) -> void:
	var before: RunState = session.state.copy()
	var phase_before: GameSession.Phase = session.phase()
	recorder.clear()
	if chain_refused:
		var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))
		assert_false(result.accepted, "%s: commit refused" % label)
		assert_eq(result.refusal, &"not_now", "%s: with not_now" % label)
		assert_eq(result.cells_after, result.cells_before, "%s: the refused result shows no change" % label)
	for id: StringName in BoosterRules.ALL:
		assert_true(null == session.press_booster(id), "%s: %s does nothing" % [label, id])
	assert_true(null == session.tap_cell(Vector2i(0, 0)), "%s: a tile tap does nothing" % label)
	assert_true(session.state.equals(before), "%s: state unchanged" % label)
	assert_eq(session.phase(), phase_before, "%s: phase unchanged" % label)
	assert_eq(session.targeting_booster(), &"", "%s: no targeting" % label)
	assert_eq(recorder.names, PackedStringArray(), "%s: no signal" % label)


func test_input_is_refused_in_phase_none() -> void:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	_assert_locked(session, "NONE", true)


func test_input_is_refused_while_waiting_for_the_view() -> void:
	var session: GameSession = _playing(9000)
	session.commit_chain(P_CHAIN)
	_assert_locked(session, "waiting", true)


func test_input_is_refused_after_the_run_ended() -> void:
	var session: GameSession = _ended()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "ENDED")
	_assert_locked(session, "ENDED", true)
	assert_false(session.begin_drag(), "ENDED: no drag")
	session.cancel_targeting()
	session.end_run()
	session.move_shown()
	assert_eq(recorder.names, PackedStringArray(), "ENDED: nothing more happens")


func test_at_23_booster_taps_are_ignored_during_a_drag() -> void:
	var session: GameSession = _playing(5000)
	assert_true(session.begin_drag(), "a chain is being dragged")
	_assert_locked(session, "dragging", false)
	assert_true(session.is_dragging(), "the drag is still open")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))
	assert_true(result.accepted, "the drag can still commit")


func test_commit_chain_needs_playing() -> void:
	var offer: GameSession = BF.ready_session(F.state(BF.board_d1024(), 5000))
	assert_eq(offer.commit_chain(BF.targets([Vector2i(0, 0), Vector2i(1, 0)])).refusal, &"not_now", "refused in OFFER")
	var targeting: GameSession = _playing(5000)
	targeting.press_booster(BoosterRules.DOUBLE)
	assert_eq(targeting.commit_chain(P_CHAIN).refusal, &"not_now", "refused in TARGETING")
	assert_eq(BF.n(targeting.state.score), 5000, "nothing charged")


# Drags (D-06, D-08)

func test_begin_and_end_drag() -> void:
	var session: GameSession = _playing(0)
	assert_true(session.begin_drag(), "the first finger opens a drag")
	assert_false(session.can_start_chain(), "a drag is open")
	assert_false(session.begin_drag(), "a second drag is refused")
	assert_true(session.is_dragging(), "the first drag stays open")
	session.end_drag()
	assert_false(session.is_dragging(), "ended by a cancel")
	assert_true(session.can_start_chain(), "a new chain can start")


func test_a_refused_chain_ends_the_drag_and_emits_nothing() -> void:
	var session: GameSession = _playing(0)
	var before: RunState = session.state.copy()
	session.begin_drag()
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(1, 5)]))
	assert_eq(result.refusal, &"invalid_chain", "RunRules refuses the chain")
	assert_false(session.is_dragging(), "the drag ended")
	assert_false(session.is_waiting_for_view(), "nothing to show")
	assert_true(session.state.equals(before), "nothing changed")
	assert_eq(recorder.names, PackedStringArray(), "nothing emitted")


func test_preview_value_and_joinable_cells() -> void:
	var session: GameSession = _playing(0)
	assert_eq(F.v(session.preview_value(BF.no_targets())), 0, "no chain, no preview")
	assert_eq(F.v(session.preview_value(BF.targets([Vector2i(1, 6)]))), 0, "hidden at 1 tile (D-03)")
	assert_eq(F.v(session.preview_value(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))), 4, "2, 2 makes 4")
	assert_eq(F.v(session.preview_value(BF.targets([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]))), 8, "2, 2, 4 makes 8")
	assert_eq(F.v(session.preview_value(P_CHAIN)), 16, "2, 2, 4, 8 makes 16")
	assert_eq(F.v(session.preview_value(BF.targets([Vector2i(1, 6), Vector2i(1, 5)]))), 0, "a list that breaks the joining rule shows nothing")
	assert_eq(F.v(session.preview_value(BF.targets([Vector2i(1, 6), Vector2i(9, 9)]))), 0, "off the board shows nothing")
	var chain: Array[Vector2i] = BF.targets([Vector2i(1, 6), Vector2i(2, 6)])
	assert_eq(session.joinable_cells(chain), CoreRules.joinable_cells(F.board_p(), BigNum.zero(), chain, GameConfig.new()), "joinable cells come from the joining rule (D-40)")


# Phases and statuses

func test_is_run_in_progress_in_each_phase() -> void:
	var session: GameSession = GameSession.new()
	assert_false(session.is_run_in_progress(), "NONE")
	session.resume(F.state(BF.board_d1024(), 5000))
	assert_true(session.is_run_in_progress(), "PLAYING while waiting")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.OFFER, "OFFER")
	assert_true(session.is_run_in_progress(), "OFFER")
	session.press_booster(BoosterRules.SWAP)
	assert_eq(session.phase(), GameSession.Phase.TARGETING, "TARGETING")
	assert_true(session.is_run_in_progress(), "TARGETING")
	session.cancel_targeting()
	session.end_run()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "ENDED")
	assert_false(session.is_run_in_progress(), "ENDED")
	var playing: GameSession = _playing(0)
	assert_eq(playing.phase(), GameSession.Phase.PLAYING, "PLAYING")
	assert_true(playing.is_run_in_progress(), "PLAYING")


func test_booster_statuses_in_bar_order_and_fresh_every_call() -> void:
	var session: GameSession = _playing(200)
	var first: Array[BoosterStatus] = session.booster_statuses()
	var ids: Array[StringName] = []
	for status: BoosterStatus in first:
		ids.append(status.id)
	assert_eq(ids, BoosterRules.ALL, "bar order")
	assert_eq([F.v(first[0].cost), F.v(first[3].cost), F.v(first[4].cost)], [128, 256, 64], "costs from the board")
	assert_eq(_status_ids_where_usable(session), [&"hammer", &"swap", &"shuffle"] as Array[StringName], "usable at 200")
	assert_eq(first[3].reason, BoosterStatus.Usability.CANNOT_AFFORD, "Double cannot be afforded")
	assert_eq(first[4].reason, BoosterStatus.Usability.NO_SNAPSHOT, "Undo has no snapshot")
	first[0].usable = false
	var second: Array[BoosterStatus] = session.booster_statuses()
	assert_false(second[0] == first[0], "new objects every call")
	assert_true(second[0].usable, "unaffected by changes to an old list")
	for status: BoosterStatus in second:
		assert_false(status.suggested, "nothing suggested outside the offer")


# The end of a run (12.3, flow rules 3 and 8)

func test_at_50_nothing_usable_ends_the_run_at_once() -> void:
	var session: GameSession = GameSession.new(null, null, F.records(0, 0))
	recorder.watch(session)
	session.resume(BF.make(BF.board_d1024(), 300, BF.snapshot_board(), 40))
	assert_true(recorder.started[0].run_ends, "the result already says the run ends")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["status_changed", "run_ended"]), "no offer: the run ends at once")
	assert_eq(recorder.count("save_requested"), 0, "never save_requested at END")
	var summary: RunSummary = recorder.summaries[0]
	assert_eq(BF.n(summary.final_score), 300, "final score 300")
	assert_eq(F.v(summary.run_highest), 1024, "this run's highest tile 1024")
	assert_eq(BF.n(summary.best_score), 300, "Best Score")
	assert_eq(F.v(summary.best_tile), 1024, "Best Tile")
	assert_true(summary.no_moves_left, "it ended because no moves were left")
	assert_true(summary.new_best_score, "this run set the Best Score")
	assert_eq(session.phase(), GameSession.Phase.ENDED, "ENDED")
	assert_false(session.is_run_in_progress(), "the App must not save this run")
	assert_false(session.is_offer_open(), "no offer")


func test_z3_score_zero_and_no_moves_ends_the_run() -> void:
	var session: GameSession = _ended_with(F.state(F.board_d(), 0))
	assert_eq(session.phase(), GameSession.Phase.ENDED, "the run ends at once")
	assert_eq(BF.n(recorder.summaries[0].final_score), 0, "final score 0")


func _ended_with(state: RunState) -> GameSession:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(state)
	session.move_shown()
	return session


func test_a_move_that_ends_the_run_saves_first_and_never_after() -> void:
	var session: GameSession = BF.ready_session(F.state(BF.board_d1024(), 1500))
	recorder.watch(session)
	session.rng.script_spawns(F.ev(PackedInt64Array([8])))
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	var result: MoveResult = session.tap_cell(Vector2i(4, 7))
	assert_true(result.run_ends, "the result says the run ends")
	assert_false(result.offer_opens, "and that no offer opens")
	assert_eq(recorder.names, _names(["targeting_changed", "move_resolved", "status_changed", "save_requested"]), "the move is saved at once, while the run is in progress")
	assert_true(session.is_run_in_progress(), "still in progress while the move shows")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.names, _names(["offer_changed", "status_changed", "run_ended"]), "the offer closes, then the run ends")
	assert_eq(recorder.offers[0], [false, &""], "offer closed")
	assert_eq(BF.n(recorder.summaries[0].final_score), 476, "final score 476 (AT-53)")
	assert_true(recorder.summaries[0].no_moves_left, "no moves left")


func test_summary_new_best_score_only_when_this_run_set_it() -> void:
	var records: Records = F.records(10000, 0)
	var session: GameSession = BF.ready_session(F.state(BF.board_d1024(), 5000), records)
	recorder.watch(session)
	session.end_run()
	assert_false(recorder.summaries[0].new_best_score, "5,000 never beat 10,000")
	assert_false(recorder.summaries[0].no_moves_left, "ended by End run")
	var winner: GameSession = BF.ready_session(F.state(F.changed(F.board_d(), {Vector2i(0, 0): 8}), 9990), F.records(10000, 0))
	recorder.watch(winner)
	winner.commit_chain(BF.targets([Vector2i(0, 0), Vector2i(0, 1)]))
	winner.move_shown()
	winner.press_booster(BoosterRules.SHUFFLE)
	winner.move_shown()
	winner.start_new_run()
	winner.move_shown()
	assert_eq(BF.n(winner.records.best_score), 10006, "the old run set 10,006")
	var fresh: MoveResult = recorder.started[recorder.started.size() - 1]
	assert_false(fresh.new_best_score, "a new run's board sets no Best Score")

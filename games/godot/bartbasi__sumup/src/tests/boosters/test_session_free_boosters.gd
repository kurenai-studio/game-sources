extends "res://tests/base_test.gd"
## Stars and free boosters through GameSession (GDD 11.5, 13.9: D-45, D-46):
## stars() and free_held(), the free flag on every status, targeting and
## cancelling that keep the free booster, the out of moves offer with a free
## booster held, the run summary's stars, and free boosters ending with the
## run. Worked examples FB1, FB3, FB5, FB8, FB11 and FB12.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const CANNOT_AFFORD: BoosterStatus.Usability = BoosterStatus.Usability.CANNOT_AFFORD
const NO_SNAPSHOT: BoosterStatus.Usability = BoosterStatus.Usability.NO_SNAPSHOT
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


func _costs(session: GameSession) -> Array[int]:
	var list: Array[int] = []
	for status: BoosterStatus in session.booster_statuses():
		list.append(F.v(status.cost))
	return list


func _reasons(session: GameSession) -> Array[BoosterStatus.Usability]:
	var list: Array[BoosterStatus.Usability] = []
	for status: BoosterStatus in session.booster_statuses():
		list.append(status.reason)
	return list


# Reads (D-45, D-46)

func test_stars_and_free_held_are_0_with_no_run() -> void:
	var session: GameSession = GameSession.new()
	assert_eq(session.stars(), 0, "no stars before a run")
	assert_eq(session.free_held(), 0, "no free booster before a run")
	assert_true(BF.free_ids(session).is_empty(), "no booster reads Free")


func test_a_new_run_has_no_stars_and_no_free_boosters() -> void:
	var session: GameSession = GameSession.new()
	session.start_new_run()
	assert_eq(session.stars(), 0, "0 stars (SC1)")
	assert_eq(session.free_held(), 0, "0 free boosters")
	assert_eq(session.state.free_used, 0, "none used")


## AT-125 (b) and AT-138 through the session: the saved run highest tile and
## free boosters used give the stars and free boosters held. Loading earns
## nothing and reports nothing a clear notice would show.
func test_resume_reads_stars_and_free_boosters_from_the_saved_run() -> void:
	var saved: RunState = BF.make(BF.board_d1024(), 5000, BF.snapshot_board(), 40, 131072, 5, 1)
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(saved)
	assert_eq(session.stars(), 7, "7 stars (SC10)")
	assert_eq(session.free_held(), 1, "2 earned, 1 used: 1 held")
	var loaded: MoveResult = recorder.started[0]
	assert_eq([loaded.stars_earned, loaded.free_earned], [0, 0], "the load earns nothing")
	assert_true(loaded.notice_values.is_empty() and loaded.cleared_small.is_empty(), "and shows no clear notice")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "every booster reads Free")
	session.move_shown()
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(BF.n(result.cost), 0, "the booster used next charges nothing")
	assert_eq(session.free_held(), 0, "and uses the free booster")


func test_at_127_every_status_reads_free_after_the_third_star() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096})
	var session: GameSession = _session(F.state(board, 50000), 127, F.records(0, 4096))
	assert_eq([session.stars(), session.free_held()], [2, 0], "2 stars, nothing held")
	assert_true(BF.free_ids(session).is_empty(), "no booster reads Free")
	recorder.clear()
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(0, 7), Vector2i(1, 7)]))
	assert_eq(recorder.names, _names(["move_resolved", "status_changed", "save_requested"]), "status_changed tells the HUD to read the stars again")
	assert_eq(BF.n(session.state.score), 58192, "score 58,192")
	assert_eq(result.free_earned, 1, "the move result reports 1 free booster earned")
	assert_eq([session.stars(), session.free_held()], [3, 1], "3 stars, 1 free booster held")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "every booster status shows it as free")
	assert_eq(_costs(session), [8192, 8192, 8192, 16384, 4096] as Array[int], "with its cost unchanged")
	assert_eq(BF.usable_ids(session), BoosterRules.ALL, "all five usable, Undo because 58,192 minus 8,192 is at least 0")


func test_at_129_a_free_booster_makes_an_unaffordable_booster_usable() -> void:
	var session: GameSession = _session(BF.holding(1, F.board_p(), 0, 8192))
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "before: Hammer, Swap, Shuffle and Double are usable")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "all five read Free")
	assert_eq(BF.status_of(session, BoosterRules.UNDO).reason, NO_SNAPSHOT, "Undo is free but not usable: no snapshot")
	session.press_booster(BoosterRules.DOUBLE)
	var result: MoveResult = session.tap_cell(Vector2i(0, 0))
	assert_true(result != null and result.accepted, "the Double applies")
	assert_eq(BF.n(result.cost), 0, "free")
	assert_eq(F.v(session.state.value_at(Vector2i(0, 0))), 4, "(0,0) = 4")
	assert_eq(BF.n(session.state.score), 0, "score 0")
	assert_eq(session.free_held(), 0, "0 free boosters held")
	assert_true(BF.usable_ids(session).is_empty(), "all five are disabled")
	assert_true(BF.free_ids(session).is_empty(), "and read their costs")
	assert_eq(_reasons(session), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "score 0, cheapest cost 64")


# Targeting and cancel keep the free booster (13.9)

## Still 1 held, score 5,000, all five read Free, nothing saved.
func _assert_kept(session: GameSession, label: String) -> void:
	assert_eq(session.free_held(), 1, "%s: still 1 free booster held" % label)
	assert_eq(BF.n(session.state.score), 5000, "%s: score 5,000" % label)
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "%s: all five read Free" % label)
	assert_eq(session.state.cells, F.board_p(), "%s: board unchanged" % label)
	assert_eq(recorder.count("save_requested"), 0, "%s: nothing to save" % label)


func test_at_131_cancelling_targeting_keeps_the_free_booster() -> void:
	var session: GameSession = _session(BF.holding(1, F.board_p(), 5000, 8192), 131)
	recorder.clear()
	session.press_booster(BoosterRules.HAMMER)
	session.press_booster(BoosterRules.HAMMER)
	_assert_kept(session, "Hammer, Hammer")
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	_assert_kept(session, "Swap, select (0,0)")
	session.tap_cell(Vector2i(0, 0))
	session.press_booster(BoosterRules.SWAP)
	_assert_kept(session, "deselect (0,0), Swap")
	session.press_booster(BoosterRules.DOUBLE)
	session.press_booster(BoosterRules.HAMMER)
	_assert_kept(session, "Double, switch to Hammer")
	session.cancel_targeting()
	_assert_kept(session, "back")
	session.press_booster(BoosterRules.DOUBLE)
	session.cancel_targeting()
	_assert_kept(session, "Double, Pause, resume")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "back in play")
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_true(result != null and result.accepted, "the Shuffle applies")
	assert_eq(BF.n(result.cost), 0, "and is free")
	assert_true(result.free_used, "using the free booster")
	assert_eq(BF.n(session.state.score), 5000, "score 5,000")
	assert_eq(session.free_held(), 0, "0 held")
	assert_eq(F.v(BF.status_of(session, BoosterRules.HAMMER).cost), 128, "Hammer costs 128 again")
	assert_true(BF.free_ids(session).is_empty(), "nothing reads Free")


func test_cancel_keeps_the_free_booster_in_the_offer() -> void:
	var session: GameSession = _session(BF.holding(1, BF.board_d1024(), 0, 8192))
	assert_true(session.is_offer_open(), "the offer is open")
	session.press_booster(BoosterRules.HAMMER)
	session.press_booster(BoosterRules.HAMMER)
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	assert_true(null == session.tap_cell(Vector2i(4, 0)), "a second 2 is ignored (D-24)")
	session.tap_cell(Vector2i(0, 0))
	session.cancel_targeting()
	session.press_booster(BoosterRules.DOUBLE)
	session.press_booster(BoosterRules.SWAP)
	session.cancel_targeting()
	assert_eq(session.phase(), GameSession.Phase.OFFER, "back at the offer")
	assert_eq(session.free_held(), 1, "still 1 free booster held")
	assert_eq(BF.n(session.state.score), 0, "score 0")
	assert_eq(session.state.cells, BF.board_d1024(), "board unchanged")
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "the same choices")


func test_a_move_while_free_but_not_a_booster_uses_nothing() -> void:
	var session: GameSession = _session(BF.holding(1, F.board_p(), 5000, 8192))
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))
	assert_true(result.accepted, "a chain commits")
	assert_false(result.free_used, "a chain is not a booster")
	assert_eq(session.free_held(), 1, "the free booster waits for the next booster")


# The out of moves offer (D-19, D-42)

func test_at_135_a_the_offer_with_a_free_booster() -> void:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(BF.holding(1, BF.board_d1024(), 0, 8192))
	assert_true(recorder.started[0].offer_opens, "the move check opens the offer instead of ending the run")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.OFFER, "the offer opens")
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "Hammer, Swap, Shuffle and Double are usable")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "and read Free")
	assert_eq(BF.status_of(session, BoosterRules.UNDO).reason, NO_SNAPSHOT, "Undo is disabled")
	assert_eq(recorder.offers[0], [true, BoosterRules.SHUFFLE], "Shuffle is marked as the suggested rescue")
	assert_eq(BF.suggested_id(session), BoosterRules.SHUFFLE, "on its status too")
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(BF.n(result.cost), 0, "the Shuffle is free")
	assert_eq(BF.n(session.state.score), 0, "score 0")
	assert_true(result.has_valid_move, "the board has a valid move")
	assert_eq(session.free_held(), 0, "0 free boosters held")
	recorder.clear()
	session.move_shown()
	assert_eq(recorder.offers, [[false, &""]] as Array[Array], "the offer closes")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "play goes on")


func test_at_135_b_nothing_held_ends_the_run_at_once() -> void:
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(BF.holding(0, BF.board_d1024(), 0, 8192))
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "nothing is usable, so the run ends at once")
	assert_eq(recorder.count("offer_changed"), 0, "no offer")
	assert_eq(BF.n(recorder.summaries[0].final_score), 0, "final score 0, as in AT-50")
	assert_true(recorder.summaries[0].no_moves_left, "no moves left")


# The end of the run (13.9)

func test_at_137_unused_free_boosters_end_with_the_run() -> void:
	var session: GameSession = _session(BF.holding(1, BF.board_d1024(), 5000, 8192))
	assert_true(session.is_offer_open(), "the offer is open")
	assert_eq(session.free_held(), 1, "1 free booster held")
	session.end_run()
	var summary: RunSummary = recorder.summaries[0]
	assert_eq(F.v(summary.run_highest), 8192, "the end of run screen shows this run's highest tile 8K")
	assert_eq(summary.stars, 3, "and its 3 stars")
	session.start_new_run()
	session.move_shown()
	assert_eq(session.stars(), 0, "the new run has 0 stars")
	assert_eq(session.free_held(), 0, "and 0 free boosters held")
	assert_true(BF.free_ids(session).is_empty(), "its boosters show costs, not Free")
	assert_eq(F.v(BF.status_of(session, BoosterRules.HAMMER).cost), 128, "Hammer 128")


## FB12: a run like Bart's phone run, highest tile 128K, ends with its second
## free booster unused. It is lost with the run.
func test_fb12_a_free_booster_still_held_is_lost_with_the_run() -> void:
	var session: GameSession = _session(BF.make(BF.board_d1024(), 5000, PackedInt64Array(), 0, 131072, 5, 1))
	assert_eq([session.stars(), session.free_held()], [7, 1], "7 stars, 2 earned, 1 used")
	session.end_run()
	assert_eq(recorder.summaries[0].stars, 7, "the summary carries 7 stars")
	session.start_new_run()
	assert_eq([session.stars(), session.free_held()], [0, 0], "nothing carries over")


func test_new_game_during_a_run_discards_the_free_boosters() -> void:
	var session: GameSession = _session(BF.holding(2, F.board_p(), 5000, 65536))
	assert_eq(session.free_held(), 2, "2 held")
	session.start_new_run()
	assert_eq([session.stars(), session.free_held()], [0, 0], "New game discards them (D-34)")

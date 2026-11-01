extends "res://tests/base_test.gd"
## Booster taps and targeting through GameSession (GDD 13.1: D-21, D-22,
## D-43; 13.4: D-24; flow rules 4 to 6), including targeting that is never
## saved (D-33).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)

var recorder: BF.Recorder


func before_each() -> void:
	recorder = BF.Recorder.new()


func _names(list: Array) -> PackedStringArray:
	return PackedStringArray(list)


## A session in PLAYING on the board, ready for input, with the recorder on.
func _session(board: PackedInt64Array, score: int, seed_value: int = 1) -> GameSession:
	var session: GameSession = BF.ready_session(F.state(board, score), null, seed_value)
	recorder.watch(session)
	return session


func _active_ids(session: GameSession) -> Array[StringName]:
	var ids: Array[StringName] = []
	for status: BoosterStatus in session.booster_statuses():
		if status.active:
			ids.append(status.id)
	return ids


# Entering, cancelling and switching (D-22)

func test_entering_targeting_signals_and_charges_nothing() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	assert_true(null == session.press_booster(BoosterRules.HAMMER), "no move happened")
	assert_eq(recorder.names, _names(["targeting_changed", "status_changed"]), "targeting_changed, then status_changed")
	assert_eq(recorder.targeting[0], [BoosterRules.HAMMER, NO_CELL], "Hammer with no Swap selection")
	assert_eq(session.phase(), GameSession.Phase.TARGETING, "TARGETING")
	assert_eq(session.targeting_booster(), BoosterRules.HAMMER, "Hammer is active")
	assert_eq(_active_ids(session), [BoosterRules.HAMMER] as Array[StringName], "the player sees which booster is active")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")
	assert_false(session.is_waiting_for_view(), "no move to show")


func test_at_61_entering_and_cancelling_targeting_charges_nothing() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	var before: RunState = session.state.copy()
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(session.targeting_booster(), BoosterRules.HAMMER, "targeting turns on")
	recorder.clear()
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(recorder.names, _names(["targeting_changed", "status_changed"]), "the same booster again cancels")
	assert_eq(recorder.targeting[0], [&"", NO_CELL], "targeting ends")
	assert_eq(session.targeting_booster(), &"", "targeting turns off")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "back to play")
	assert_true(session.state.equals(before), "score stays 5,000, nothing changed")
	assert_true(session.begin_drag(), "the drag then starts normally")
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))
	assert_true(result.accepted, "and builds the chain 2, 2")


func test_cancel_targeting_by_back_pause_or_focus_loss() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.DOUBLE)
	recorder.clear()
	session.cancel_targeting()
	assert_eq(recorder.names, _names(["targeting_changed", "status_changed"]), "targeting ends")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "PLAYING")
	recorder.clear()
	session.cancel_targeting()
	assert_eq(recorder.names, PackedStringArray(), "cancelling with no targeting does nothing")


func test_at_64_back_cancels_targeting_with_a_swap_selection() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	assert_eq(session.swap_first(), Vector2i(0, 0), "one tile selected")
	session.cancel_targeting()
	assert_eq(session.targeting_booster(), &"", "targeting ends")
	assert_eq(session.swap_first(), NO_CELL, "the selection is gone")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "the game stays on the board")


func test_at_63_switching_boosters() -> void:
	var session: GameSession = _session(F.board_p(), 5000, 63)
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	session.press_booster(BoosterRules.DOUBLE)
	assert_eq(recorder.names, _names(["targeting_changed", "status_changed"]), "a straight switch")
	assert_eq(recorder.targeting[0], [BoosterRules.DOUBLE, NO_CELL], "Double is now targeting")
	assert_eq(_active_ids(session), [BoosterRules.DOUBLE] as Array[StringName], "Double active, Hammer not")
	assert_eq(BF.n(session.state.score), 5000, "score 5,000")
	recorder.clear()
	var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
	assert_true(result != null and result.accepted, "Shuffle applies at once")
	assert_eq(recorder.names, _names(["targeting_changed", "move_resolved", "status_changed", "save_requested"]), "Double's targeting is cancelled first")
	assert_eq(recorder.targeting[0], [&"", NO_CELL], "targeting ended with nothing charged")
	assert_eq(BF.n(result.cost), 128, "only the Shuffle was charged")
	assert_eq(BF.n(session.state.score), 4872, "score 4,872")
	assert_true(_active_ids(session).is_empty(), "Double is no longer active")
	assert_ne(session.state.cells, F.board_p(), "the board is shuffled")
	assert_eq(BF.sorted(session.state.cells), BF.sorted(F.board_p()), "with the same values")


func test_switching_to_a_swap_drops_nothing_and_resets_the_selection() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	recorder.clear()
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(recorder.targeting[0], [BoosterRules.HAMMER, NO_CELL], "Hammer with no selection")
	assert_eq(session.swap_first(), NO_CELL, "Swap's selection is dropped")
	session.press_booster(BoosterRules.SWAP)
	assert_eq(session.swap_first(), NO_CELL, "Swap starts again with no selection")


func test_an_unusable_booster_tap_does_nothing_even_while_targeting() -> void:
	var session: GameSession = _session(F.board_p(), 200)
	assert_true(null == session.press_booster(BoosterRules.DOUBLE), "Double costs 256: nothing")
	assert_true(null == session.press_booster(BoosterRules.UNDO), "Undo has no snapshot: nothing")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "still playing")
	assert_eq(recorder.names, PackedStringArray(), "no signal")
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	session.press_booster(BoosterRules.DOUBLE)
	session.press_booster(BoosterRules.UNDO)
	assert_eq(session.targeting_booster(), BoosterRules.HAMMER, "Hammer stays active")
	assert_eq(recorder.names, PackedStringArray(), "no signal")
	assert_true(null == session.press_booster(&"rocket"), "an unknown id does nothing")
	assert_eq(BF.n(session.state.score), 200, "nothing charged")


func test_at_57_tapping_unaffordable_boosters_does_nothing() -> void:
	var session: GameSession = _session(F.board_p(), 127)
	var before: RunState = session.state.copy()
	for id: StringName in BoosterRules.ALL:
		assert_false(BF.status_of(session, id).usable, "%s disabled at 127" % id)
		assert_true(null == session.press_booster(id), "%s does nothing" % id)
	assert_true(session.state.equals(before), "nothing changed")
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "no targeting")
	assert_eq(recorder.names, PackedStringArray(), "no signal")
	var at_128: GameSession = BF.ready_session(F.state(F.board_p(), 128))
	assert_eq(BF.usable_ids(at_128), [&"hammer", &"swap", &"shuffle"] as Array[StringName], "at 128 Hammer, Swap and Shuffle are enabled")
	assert_true(null == at_128.press_booster(BoosterRules.DOUBLE), "Double still does nothing")
	at_128.press_booster(BoosterRules.HAMMER)
	assert_eq(at_128.targeting_booster(), BoosterRules.HAMMER, "Hammer can be tapped at 128")
	var at_256: GameSession = BF.ready_session(F.state(F.board_p(), 256))
	assert_eq(BF.usable_ids(at_256), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "at 256 Double too")
	assert_eq(BF.status_of(at_256, BoosterRules.UNDO).reason, BoosterStatus.Usability.NO_SNAPSHOT, "Undo stays disabled: no snapshot")
	assert_true(BF.free_ids(at_256).is_empty(), "no booster reads Free")


func test_at_62_no_chains_while_targeting() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.DOUBLE)
	var before: RunState = session.state.copy()
	assert_false(session.can_start_chain(), "chains cannot start")
	assert_false(session.begin_drag(), "a drag builds no chain")
	var result: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6)]))
	assert_eq(result.refusal, &"not_now", "a commit is refused")
	assert_true(session.state.equals(before), "nothing doubled, nothing charged")
	assert_eq(session.targeting_booster(), BoosterRules.DOUBLE, "Double is still active")


func test_at_66_taps_elsewhere_do_nothing_while_targeting() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.HAMMER)
	recorder.clear()
	for cell: Vector2i in [Vector2i(-1, -1), Vector2i(5, 0), Vector2i(0, 8), Vector2i(-1, 4), Vector2i(99, 99)]:
		assert_true(null == session.tap_cell(cell), "a tap off the board at %s does nothing" % cell)
	assert_eq(session.targeting_booster(), BoosterRules.HAMMER, "Hammer stays active")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")
	assert_eq(recorder.names, PackedStringArray(), "no signal")


func test_tile_taps_outside_targeting_do_nothing() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	assert_true(null == session.tap_cell(Vector2i(2, 7)), "PLAYING: a tile tap does nothing")
	assert_eq(recorder.names, PackedStringArray(), "no signal")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")


# Targeting taps (D-43)

func test_at_110_hammer_and_double_act_on_one_tap() -> void:
	var session: GameSession = _session(F.board_p(), 5000, 110)
	session.press_booster(BoosterRules.HAMMER)
	assert_eq(BF.n(session.state.score), 5000, "(a) nothing is charged before the tap")
	assert_eq(session.state.cells, F.board_p(), "(a) the board is unchanged")
	recorder.clear()
	var result: MoveResult = session.tap_cell(Vector2i(2, 7))
	assert_true(result != null and result.accepted, "(b) Hammer applies at once, no confirm step")
	assert_eq(result.kind, MoveResult.Kind.HAMMER, "a Hammer")
	assert_eq(result.emptied, [Vector2i(2, 7)] as Array[Vector2i], "(2,7) is removed")
	assert_eq(BF.count(session.state.cells, 32), 0, "the 32 is gone")
	assert_eq(BF.n(session.state.score), 4872, "score 4,872")
	assert_eq(recorder.names, _names(["targeting_changed", "move_resolved", "status_changed", "save_requested"]), "targeting ends, then rule 2")
	assert_eq(recorder.targeting[0], [&"", NO_CELL], "targeting ended")
	assert_eq(session.targeting_booster(), &"", "no booster active")
	session.move_shown()
	session.press_booster(BoosterRules.DOUBLE)
	var before: RunState = session.state.copy()
	assert_eq(session.targeting_booster(), BoosterRules.DOUBLE, "(c) Double is active")
	assert_true(session.state.equals(before), "(c) with no tap, nothing is doubled or charged")


func test_double_applies_on_one_tap() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 32})
	var session: GameSession = _session(board, 30000)
	session.press_booster(BoosterRules.DOUBLE)
	var result: MoveResult = session.tap_cell(Vector2i(1, 1))
	assert_true(result.accepted, "Double applies on the tap (AT-74)")
	assert_eq(F.v(session.state.value_at(Vector2i(1, 1))), 32, "(1,1) = 32")
	assert_eq(BF.n(session.state.score), 21808, "score 21,808")
	assert_false(result.offer_opens or result.run_ends, "the board has a valid move")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "the offer closed")


func test_at_111_swap_selects_on_its_first_tap_and_acts_on_its_second() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.SWAP)
	recorder.clear()
	assert_true(null == session.tap_cell(Vector2i(0, 0)), "the first tap is not a move")
	assert_eq(recorder.names, _names(["targeting_changed"]), "only the selection changes")
	assert_eq(recorder.targeting[0], [BoosterRules.SWAP, Vector2i(0, 0)], "(0,0) is selected")
	assert_eq(session.swap_first(), Vector2i(0, 0), "swap_first")
	assert_eq(BF.n(session.state.score), 5000, "nothing charged")
	recorder.clear()
	var result: MoveResult = session.tap_cell(Vector2i(2, 7))
	assert_true(result != null and result.accepted, "the second tap applies the swap at once")
	assert_eq(result.targets, [Vector2i(0, 0), Vector2i(2, 7)] as Array[Vector2i], "first tile, then second")
	assert_eq(F.v(session.state.value_at(Vector2i(0, 0))), 32, "(0,0) = 32")
	assert_eq(F.v(session.state.value_at(Vector2i(2, 7))), 2, "(2,7) = 2")
	assert_eq(BF.n(session.state.score), 4872, "score 4,872")
	assert_eq(recorder.names, _names(["targeting_changed", "move_resolved", "status_changed", "save_requested"]), "targeting ends, then rule 2")
	assert_eq(session.targeting_booster(), &"", "targeting ends")
	assert_eq(session.swap_first(), NO_CELL, "no selection")


func test_at_68_swap_through_the_session() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 2048, Vector2i(0, 0): 32})
	var session: GameSession = _session(board, 10000)
	assert_true(session.is_offer_open(), "Board D has no move, so the offer is open")
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	var result: MoveResult = session.tap_cell(Vector2i(4, 7))
	assert_eq(session.state.cells, F.changed(board, {Vector2i(0, 0): 8, Vector2i(4, 7): 32}), "(0,0) = 8, (4,7) = 32, nothing else")
	assert_true(result.spawn_cells.is_empty(), "no new tiles")
	assert_eq(BF.n(session.state.score), 7952, "score 7,952")


func test_at_69_swap_ignores_equal_values_and_can_deselect() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 0): 32, Vector2i(4, 7): 32})
	var session: GameSession = _session(board, 5000)
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	recorder.clear()
	assert_true(null == session.tap_cell(Vector2i(4, 7)), "tapping the other 32 does nothing (SW2)")
	assert_eq(recorder.names, PackedStringArray(), "no signal for a refused second pick")
	assert_eq(session.swap_first(), Vector2i(0, 0), "(0,0) stays selected")
	session.tap_cell(Vector2i(0, 0))
	assert_eq(recorder.targeting[0], [BoosterRules.SWAP, NO_CELL], "tapping (0,0) again deselects it (SW3)")
	assert_eq(session.swap_first(), NO_CELL, "deselected")
	assert_eq(session.targeting_booster(), BoosterRules.SWAP, "Swap stays active")
	session.press_booster(BoosterRules.SWAP)
	assert_eq(session.targeting_booster(), &"", "tapping Swap ends targeting")
	assert_eq(session.state.cells, board, "board unchanged")
	assert_eq(BF.n(session.state.score), 5000, "score 5,000 throughout")


func test_a_refused_double_tap_keeps_targeting() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_p(), {Vector2i(2, 7): 65535})
	var session: GameSession = BF.ready_session(BF.none_held(RunState.create(board, BigNum.pow2(65536))))
	recorder.watch(session)
	session.press_booster(BoosterRules.DOUBLE)
	recorder.clear()
	assert_true(null == session.tap_cell(Vector2i(2, 7)), "doubling 2^65535 is refused (13.6)")
	assert_eq(session.targeting_booster(), BoosterRules.DOUBLE, "Double stays active")
	assert_true(session.state.score.equals(BigNum.pow2(65536)), "nothing charged")
	assert_eq(recorder.names, PackedStringArray(), "no signal")


# Targeting is never saved (D-33, 13.1)

func test_at_65_targeting_is_not_saved() -> void:
	var session: GameSession = _session(F.board_p(), 5000)
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	assert_eq(recorder.count("save_requested"), 0, "entering targeting and selecting a tile ask for no save")
	var saved: RunState = session.state.copy()
	assert_eq(BF.n(saved.score), 5000, "the saved run holds score 5,000")
	assert_eq(saved.cells, F.board_p(), "and the board, with nothing charged")
	var reopened: GameSession = BF.ready_session(saved)
	assert_eq(reopened.targeting_booster(), &"", "no booster active")
	assert_eq(reopened.swap_first(), NO_CELL, "no tile selected")
	assert_eq(BF.n(reopened.state.score), 5000, "score 5,000")
	assert_eq(reopened.phase(), GameSession.Phase.PLAYING, "playing")
	for status: BoosterStatus in reopened.booster_statuses():
		assert_false(status.active, "%s not active" % status.id)

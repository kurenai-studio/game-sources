extends "res://tests/base_test.gd"
## How the board shows a move (DESIGN_SYSTEM.md 1.6 and 3.6, GDD 8, 13 and
## D-35): the effect order per move kind, waiting for the lengths the view
## returns, set_board(cells_after), move_shown() and animation_finished,
## input closed meanwhile (AT-97), the small tile clear inside the move
## (AT-104), falls and spawns that start together, new and resumed runs,
## and the live skin switch.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)

var rig: BF.Rig = null


func after_each() -> void:
	if rig != null:
		rig.free_all()


func _effects() -> PackedStringArray:
	return rig.view().effects


## AT-99's board: Board E with (0,3) = 2 and a 1024 pair at (4,6), (4,7).
## Merging the pair raises the floor and clears the 2.
func _clear_board() -> PackedInt64Array:
	return F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})


## AT-101's board: Board E with (0,3) = 2 and (2,0) = 1024. No valid move.
func _double_board() -> PackedInt64Array:
	return F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})


func _assert_shown(message: String) -> void:
	assert_false(rig.board.is_animating(), "%s: the board is at rest" % message)
	assert_false(rig.session.is_waiting_for_view(), "%s: the session heard the move was shown" % message)
	assert_eq(rig.finished, 1, "%s: animation_finished once" % message)
	assert_eq(rig.view().boards.back(), rig.session.state.cells, "%s: the view ends on the resolved board" % message)


# Effect order per move kind, all effects 0 seconds long.

func test_at_104_a_chain_merges_then_clears_small_tiles_then_falls_and_spawns() -> void:
	rig = BF.rig(_clear_board(), 10000)
	rig.play([Vector2i(4, 6), Vector2i(4, 7)])
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_clear", "play_fall", "play_spawn", "set_board"]), "merge, clear, fall and spawn, then the final board")
	assert_eq(rig.view().merges, [[BF.cells([Vector2i(4, 6), Vector2i(4, 7)]), Vector2i(4, 7), F.e(2048)]], "the merge")
	assert_eq(rig.view().clears, [BF.cells([Vector2i(0, 3)])], "the 2 clears inside the move")
	_assert_shown("chain with a clear")


func test_a_chain_with_no_clear_merges_then_falls_and_spawns() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.play([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)])
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn", "set_board"]), "no clear step")
	_assert_shown("chain")


func test_a_chain_on_the_top_row_only_spawns() -> void:
	var durations: Dictionary[StringName, float] = {&"play_spawn": 0.2}
	rig = BF.rig(F.board_all(4), 0, durations)
	rig.play([Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_spawn"]), "with nothing to fall, the spawn follows the merge at once")
	rig.advance(0.21)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_spawn", "set_board"]), "nothing above the top row falls")
	assert_eq(rig.view().spawns[0][0], BF.cells([Vector2i(0, 0)]), "the emptied cell spawns")


func test_hammer_clears_then_falls_and_spawns() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.HAMMER)
	rig.tap(Vector2i(2, 4))
	assert_eq(_effects(), PackedStringArray(["play_clear", "play_fall", "play_spawn", "set_board"]), "clear, then fall and spawn")
	assert_eq(rig.view().clears, [BF.cells([Vector2i(2, 4)])], "the hammered tile")
	_assert_shown("Hammer")


func test_swap_swaps() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.SWAP)
	rig.tap(Vector2i(0, 0))
	rig.tap(Vector2i(4, 7))
	assert_eq(_effects(), PackedStringArray(["play_swap", "set_board"]), "swap")
	_assert_shown("Swap")


func test_shuffle_rearranges() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(_effects(), PackedStringArray(["play_rearrange", "set_board"]), "rearrange")
	assert_eq(rig.view().rearranges, [rig.session.state.cells], "to the shuffled board")
	_assert_shown("Shuffle")


func test_undo_rearranges() -> void:
	rig = BF.rig(F.board_p(), 5000)
	var before: PackedInt64Array = rig.session.state.cells.duplicate()
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	rig.forget()
	rig.session.press_booster(BoosterRules.UNDO)
	assert_eq(_effects(), PackedStringArray(["play_rearrange", "set_board"]), "rearrange")
	assert_eq(rig.view().rearranges, [before], "back to the board before the chain")
	_assert_shown("Undo")


func test_double_with_no_clear_only_changes_the_value() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.DOUBLE)
	rig.tap(Vector2i(0, 0))
	assert_eq(_effects(), PackedStringArray(["play_value_change", "set_board"]), "no clear, fall or spawn")
	_assert_shown("Double")


func test_at_101_double_that_clears_changes_the_value_then_clears_falls_and_spawns() -> void:
	rig = BF.rig(_double_board(), 5000)
	assert_true(rig.session.is_offer_open(), "the offer is open")
	rig.session.press_booster(BoosterRules.DOUBLE)
	rig.tap(Vector2i(2, 0))
	assert_eq(_effects(), PackedStringArray(["play_value_change", "play_clear", "play_fall", "play_spawn", "set_board"]), "value, clear, then fall and spawn")
	assert_eq(rig.view().value_changes, [[Vector2i(2, 0), F.e(2048)]], "the 1024 becomes 2048")
	assert_eq(rig.view().clears, [BF.cells([Vector2i(0, 3)])], "the 2 clears")
	_assert_shown("Double with a clear")
	assert_false(rig.session.is_offer_open(), "the offer closes once the move is shown")


func test_a_new_run_spawns_every_tile() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.session.start_new_run()
	assert_eq(_effects(), PackedStringArray(["play_spawn", "set_board"]), "spawn, then the board")
	var spawned: Array = rig.view().spawns[0]
	assert_eq((spawned[0] as Array).size(), 40, "all 40 cells spawn")
	assert_eq(rig.view().boards[0], rig.session.state.cells, "the new board")
	_assert_shown("new run")


func test_a_resumed_run_just_shows_the_board() -> void:
	rig = BF.rig(F.board_p(), 0)
	var saved: RunState = RunState.create(F.board_all(8), BigNum.from_int(1234))
	rig.session.resume(saved)
	assert_eq(_effects(), PackedStringArray(["set_board"]), "no effect")
	assert_eq(rig.view().boards[0], F.board_all(8), "the saved board")
	_assert_shown("resume")


func test_a_resumed_dead_board_opens_the_offer_once_shown() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.session.resume(RunState.create(_double_board(), BigNum.from_int(5000)))
	assert_true(rig.session.is_offer_open(), "move_shown ran the move check (GO7)")


# Waiting for the lengths the view returns.

func test_a_chain_waits_for_each_step() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.5, &"play_clear": 0.2, &"play_fall": 0.3, &"play_spawn": 0.4}
	rig = BF.rig(_clear_board(), 10000, durations)
	var travel: float = rig.skin.duration(&"merge_travel")
	assert_true(travel > 0.02 and travel < 0.3, "the skin's merge_travel suits this test")
	rig.play([Vector2i(4, 6), Vector2i(4, 7)])
	assert_eq(_effects(), PackedStringArray(["play_merge"]), "the merge starts")
	assert_true(rig.board.is_animating(), "animating")
	rig.advance(travel - 0.01)
	assert_eq(_effects().size(), 1, "the clear waits for the travel")
	rig.advance(0.02)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_clear"]), "the clear starts with the pop, as the travel ends")
	# Next step after the longer of the rest of the merge (0.5 - travel) and the clear (0.2).
	var rest: float = maxf(0.5 - travel, 0.2)
	rig.advance(rest - 0.01)
	assert_eq(_effects().size(), 2, "fall and spawn wait for the pop and the clear")
	rig.advance(0.02)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_clear", "play_fall", "play_spawn"]), "fall and spawn start together")
	rig.advance(0.39)
	assert_true(rig.board.is_animating(), "the spawn (0.4), the longer of the two, still runs")
	assert_true(rig.session.is_waiting_for_view(), "the session still waits")
	assert_eq(rig.finished, 0, "not finished")
	rig.advance(0.02)
	assert_eq(_effects().size(), 5, "then the final board")
	_assert_shown("timed chain")


func test_a_hammer_waits_for_its_clear() -> void:
	var durations: Dictionary[StringName, float] = {&"play_clear": 0.2, &"play_fall": 0.3, &"play_spawn": 0.1}
	rig = BF.rig(F.board_p(), 5000, durations)
	rig.session.press_booster(BoosterRules.HAMMER)
	rig.tap(Vector2i(2, 4))
	assert_eq(_effects(), PackedStringArray(["play_clear"]), "the clear starts")
	rig.advance(0.21)
	assert_eq(_effects(), PackedStringArray(["play_clear", "play_fall", "play_spawn"]), "then fall and spawn together")
	rig.advance(0.29)
	assert_eq(rig.finished, 0, "the fall (0.3), the longer of the two, still runs")
	rig.advance(0.02)
	_assert_shown("timed Hammer")


func test_a_double_waits_for_its_value_change_before_clearing() -> void:
	var durations: Dictionary[StringName, float] = {&"play_value_change": 0.3, &"play_clear": 0.2, &"play_fall": 0.1, &"play_spawn": 0.1}
	rig = BF.rig(_double_board(), 5000, durations)
	rig.session.press_booster(BoosterRules.DOUBLE)
	rig.tap(Vector2i(2, 0))
	assert_eq(_effects(), PackedStringArray(["play_value_change"]), "the value changes first")
	rig.advance(0.31)
	assert_eq(_effects(), PackedStringArray(["play_value_change", "play_clear"]), "then the clear")
	rig.advance(0.21)
	assert_eq(_effects(), PackedStringArray(["play_value_change", "play_clear", "play_fall", "play_spawn"]), "then fall and spawn together")
	rig.advance(0.09)
	assert_eq(rig.finished, 0, "the spawn (0.1) still runs")
	rig.advance(0.02)
	_assert_shown("timed Double")


func test_bad_lengths_count_as_zero() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": NAN, &"play_fall": -1.0, &"play_spawn": INF}
	rig = BF.rig(F.board_p(), 0, durations)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	_assert_shown("NaN, negative and infinite lengths")


# One move at a time (D-35).

func test_at_97_input_is_ignored_while_a_move_plays() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 1.0}
	rig = BF.rig(F.board_p(), 5000, durations)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	assert_true(rig.board.is_animating(), "the chain is playing")
	var events: int = rig.chain_events.size()
	var clicks: int = rig.clicks()
	var after_chain: RunState = rig.session.state.copy()
	rig.play([Vector2i(0, 6), Vector2i(1, 7)])
	rig.send(BF.mouse_button(rig.point(Vector2i(3, 6)), true))
	rig.send(BF.mouse_button(rig.point(Vector2i(3, 6)), false))
	assert_true(rig.session.press_booster(BoosterRules.SHUFFLE) == null, "a booster tap is ignored")
	assert_eq(rig.chain_events.size(), events, "no chain")
	assert_eq(rig.clicks(), clicks, "no click")
	assert_false(rig.session.is_dragging(), "no drag")
	assert_true(rig.session.state.equals(after_chain), "nothing changed")
	rig.settle()
	assert_false(rig.board.is_animating(), "the move has finished")
	rig.drag_cells([Vector2i(0, 7), Vector2i(1, 7)])
	assert_eq(rig.last_chain().size(), 2, "chains work again")
	rig.board.cancel_drag()
	assert_eq(rig.session.press_booster(BoosterRules.SHUFFLE).accepted, true, "and so do boosters")


func test_a_finger_put_down_during_a_move_stays_ignored_after_it() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.5}
	rig = BF.rig(F.board_p(), 0, durations)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	rig.down(Vector2i(0, 7))
	rig.settle()
	var events: int = rig.chain_events.size()
	rig.move(Vector2i(1, 7))
	rig.up(Vector2i(1, 7))
	assert_eq(rig.chain_events.size(), events, "input is ignored, not queued")
	rig.play([Vector2i(0, 7), Vector2i(1, 7)])
	assert_eq(rig.score(), 4 + 16, "a fresh touch works")


func test_a_new_run_during_a_move_replaces_it() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 1.0, &"play_spawn": 0.5}
	rig = BF.rig(F.board_p(), 0, durations)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	rig.session.start_new_run()
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_spawn"]), "the new run's spawn starts")
	rig.advance(0.51)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_spawn", "set_board"]), "only the new run finishes")
	_assert_shown("new run over a move")


# Live skin switch.

func test_set_skin_rebuilds_the_view_and_keeps_the_board() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	var old_view: SkinBoardView = rig.view()
	var slate: SkinData = SkinCatalog.get_skin(&"slate")
	rig.board.set_skin(slate)
	assert_false(is_instance_valid(old_view), "the old view is freed")
	assert_eq(rig.board.views_made, 2, "a new view")
	assert_eq(rig.view().setup_skin, slate, "set up with the new skin")
	assert_eq(rig.view().setup_columns, 5, "and the board's columns")
	assert_eq(rig.view().setup_rows, 8, "and rows")
	assert_eq(rig.view().boards, [rig.session.state.cells], "showing the same board")
	assert_eq(rig.view().get_parent(), rig.board, "inside the board")
	rig.play([Vector2i(0, 7), Vector2i(1, 7)])
	assert_eq(rig.score(), 4 + 16, "play goes on")


func test_set_skin_keeps_targeting_and_the_swap_selection() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.SWAP)
	rig.tap(Vector2i(0, 0))
	rig.board.set_skin(SkinCatalog.get_skin(&"nova"))
	assert_eq(rig.view().targeting, [BoosterRules.SWAP] as Array[StringName], "still targeting Swap")
	assert_eq(rig.view().swap_selected, BF.cells([Vector2i(0, 0)]), "(0,0) still selected")


func test_set_skin_during_a_drag_keeps_the_chain() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	rig.board.set_skin(SkinCatalog.get_skin(&"slate"))
	assert_eq(rig.view().chain, BF.cells([Vector2i(1, 6), Vector2i(2, 6)]), "the chain")
	assert_eq(rig.view_preview(), 4, "the preview")
	assert_eq(rig.view().joinable, BF.cells([Vector2i(1, 5), Vector2i(3, 6)]), "the highlight")
	rig.move(Vector2i(3, 6))
	rig.up(Vector2i(3, 6))
	assert_eq(rig.score(), 8, "the drag goes on and commits")


func test_set_skin_during_a_move_finishes_it() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 1.0}
	rig = BF.rig(F.board_p(), 0, durations)
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	rig.board.set_skin(SkinCatalog.get_skin(&"slate"))
	_assert_shown("skin switch during a move")
	assert_eq(rig.view().effects, PackedStringArray(["set_board", "set_board"]), "the new view only shows the board")

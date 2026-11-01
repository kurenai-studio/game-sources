extends "res://tests/base_test.gd"
## The show gate (QA6-06, GDD D-33, 15.1 and 15.3, AT-146): a move's effects
## start only once the gate says its save has landed. The first check comes
## after the session's save_requested, then one check a frame. Meanwhile the
## view keeps the board as it was at the lift, input stays closed and the
## session still waits for the view. Also pause, focus loss, a skin switch
## and a new move while a move waits, and gates that would freeze the game.
##
## Tests cannot run the frame's message queue, so they call _check_gate()
## where the deferred check would run, and _process() for each frame.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
const StubBoardController: GDScript = preload("res://tests/board/stub_board_controller.gd")
const FRAME: float = 1.0 / 60.0
## Two 2s on Board P. Merging them makes a 4 at (2, 6) and scores 4.
const PAIR: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]


## Stands in for SaveService (TH23): each save_requested queues a write that
## lands only once released, and is_idle() is the gate.
class StubSave extends RefCounted:
	## Queued writes wait until release().
	var held: bool = true
	var queued: int = 0
	var requests: int = 0
	var checks: int = 0

	func on_save_requested() -> void:
		requests += 1
		if held:
			queued += 1

	func is_idle() -> bool:
		checks += 1
		return queued == 0

	func release() -> void:
		held = false
		queued = 0


var rig: BF.Rig = null
## The stub gate's answer, and how often the board asked.
var _open: bool = false
var _gate_calls: int = 0
## How many boards the view had each time the offer opened.
var _boards_at_offer: Array[int] = []


func after_each() -> void:
	if rig != null:
		rig.free_all()


func _gate() -> bool:
	_gate_calls += 1
	return _open


func _on_offer_changed(is_open: bool, _suggested: StringName) -> void:
	if is_open:
		_boards_at_offer.append(rig.view().boards.size())


func _effects() -> PackedStringArray:
	return rig.view().effects


## A rig whose board waits for the stub gate, closed at first.
func _gated_rig(board_cells: PackedInt64Array, score: int, durations: Dictionary[StringName, float] = {}) -> void:
	rig = BF.rig(board_cells, score, durations)
	rig.board.set_show_gate(_gate)


## The check the board defers to the end of the frame's input handling.
func _deferred_check() -> void:
	rig.board._check_gate()


func _frames(count: int) -> void:
	for i: int in count:
		rig.advance(FRAME)


## AT-101's board: no valid move, so a resume opens the offer once shown.
func _dead_board() -> PackedInt64Array:
	return F.changed(F.board_e(), {Vector2i(0, 3): 2, Vector2i(2, 0): 1024})


## The move waits at the gate and nothing of it has reached the view.
func _assert_held(message: String) -> void:
	assert_true(rig.board.is_waiting_for_save(), "%s: waiting for the save" % message)
	assert_true(rig.board.is_animating(), "%s: input stays closed (D-35)" % message)
	assert_true(rig.session.is_waiting_for_view(), "%s: the session has not heard the move was shown" % message)
	assert_eq(rig.started, 0, "%s: no move_started" % message)
	assert_eq(rig.finished, 0, "%s: no animation_finished" % message)
	assert_eq(_effects(), PackedStringArray(), "%s: no effect and no new board on the view" % message)


## The move has played and the board is at rest on the session's board.
func _assert_shown_once(message: String) -> void:
	assert_false(rig.board.is_waiting_for_save(), "%s: not waiting for the save" % message)
	assert_false(rig.board.is_animating(), "%s: at rest" % message)
	assert_false(rig.session.is_waiting_for_view(), "%s: the session heard the move was shown" % message)
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "%s: move_started, then animation_finished, once each" % message)
	assert_eq(rig.view().boards.back(), rig.session.state.cells, "%s: the view ends on the session's board" % message)


# No gate.

func test_with_no_gate_a_move_shows_at_once() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.play(PAIR)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn", "set_board"]), "every effect runs inside the lift")
	assert_eq(rig.effects_at_start, [0] as Array[int], "move_started comes right before the first effect")
	_assert_shown_once("no gate")


func test_move_started_comes_once_for_every_kind_of_move() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.resume(RunState.create(F.board_p(), BigNum.from_int(5000)))
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "a resume, which has no effect")
	rig.forget()
	rig.play(PAIR)
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "a chain")
	rig.forget()
	rig.session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "a Shuffle")
	rig.forget()
	rig.session.start_new_run()
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "a new run")


func test_an_empty_gate_shows_at_once_again() -> void:
	_gated_rig(F.board_p(), 0)
	rig.board.set_show_gate(Callable())
	rig.play(PAIR)
	assert_false(rig.board.is_waiting_for_save(), "never waits")
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn", "set_board"]), "every effect runs inside the lift")
	_assert_shown_once("empty gate")
	assert_eq(_gate_calls, 0, "the old gate is not asked")


# Holding and opening.

func test_a_closed_gate_holds_the_move() -> void:
	_gated_rig(F.board_p(), 0)
	assert_false(rig.board.is_waiting_for_save(), "nothing waits before a move")
	rig.play(PAIR)
	assert_eq(rig.score(), 4, "the session resolved the move")
	_assert_held("after the lift")
	assert_eq(_gate_calls, 0, "the gate is not read inside the lift")
	assert_eq(rig.view().chain, [] as Array[Vector2i], "the chain line cleared at the lift, as without a gate")
	assert_eq(rig.view_preview(), 0, "and the preview")
	_deferred_check()
	_assert_held("after the deferred check")
	_frames(30)
	_assert_held("after 30 frames")
	assert_eq(_gate_calls, 31, "one deferred check, then one a frame")


func test_the_move_starts_the_frame_the_gate_opens() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.5, &"play_fall": 0.3, &"play_spawn": 0.4}
	_gated_rig(F.board_p(), 0, durations)
	var travel: float = rig.skin.duration(&"merge_travel")
	assert_true(travel > 0.02 and travel < 0.3, "the skin's merge_travel suits this test")
	rig.play(PAIR)
	_deferred_check()
	_frames(2)
	_open = true
	_assert_held("the gate opened between frames")
	rig.advance(FRAME)
	assert_eq(rig.started, 1, "move_started in the frame the gate opens")
	assert_eq(_effects(), PackedStringArray(["play_merge"]), "and the merge starts in that frame")
	assert_eq(rig.effects_at_start, [0] as Array[int], "move_started right before it")
	assert_false(rig.board.is_waiting_for_save(), "no longer waiting for the save")
	assert_true(rig.board.is_animating(), "the effects play, so input stays closed")
	rig.advance(travel - 0.01)
	assert_eq(_effects().size(), 1, "the opening frame did not eat into the travel")
	rig.advance(0.02)
	rig.advance(maxf(0.5 - travel, 0.0) + 0.01)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn"]), "fall and spawn start together")
	rig.advance(0.38)
	assert_true(rig.session.is_waiting_for_view(), "move_shown() waits for the last effect")
	assert_eq(rig.finished, 0, "not finished")
	rig.advance(0.03)
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn", "set_board"]), "then the final board")
	_assert_shown_once("gated chain")


func test_the_first_check_comes_after_the_save_request() -> void:
	rig = BF.rig(F.board_p(), 0)
	var save: StubSave = StubSave.new()
	# Every write lands at once (or fails, which is idle too), so the gate is
	# open whenever it is read.
	save.held = false
	rig.session.save_requested.connect(save.on_save_requested)
	rig.board.set_show_gate(save.is_idle)
	rig.play(PAIR)
	assert_eq(save.requests, 1, "the session asked for the save")
	assert_eq(save.checks, 0, "the board did not read the gate inside move_resolved, before the save was queued")
	assert_true(rig.board.is_waiting_for_save(), "so the move waits for the deferred check, even with the save idle")
	assert_eq(_effects(), PackedStringArray(), "nothing shows yet")
	_deferred_check()
	assert_eq(save.checks, 1, "the deferred check reads the gate")
	assert_eq(_effects(), PackedStringArray(["play_merge", "play_fall", "play_spawn", "set_board"]), "and the move plays")
	_assert_shown_once("open at the deferred check")


func test_at_146_a_held_save_keeps_the_move_off_the_board() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.2, &"play_fall": 0.2, &"play_spawn": 0.2}
	rig = BF.rig(F.board_p(), 0, durations)
	var save: StubSave = StubSave.new()
	rig.session.save_requested.connect(save.on_save_requested)
	rig.board.set_show_gate(save.is_idle)
	var before: PackedInt64Array = rig.session.state.cells.duplicate()
	rig.play(PAIR)
	var after: RunState = rig.session.state.copy()
	assert_ne(after.cells, before, "the session resolved the move")
	assert_eq(save.queued, 1, "its save is held back")
	_deferred_check()
	_frames(10)
	_assert_held("while the save is held back")
	assert_true(save.checks >= 11, "the board kept asking")
	save.release()
	rig.advance(FRAME)
	assert_eq(rig.started, 1, "once the save lands, the move starts")
	assert_eq(_effects(), PackedStringArray(["play_merge"]), "with its first effect")
	assert_eq(rig.view().merges, [[PAIR, Vector2i(2, 6), F.e(4)]], "the merge of the pair")
	rig.settle()
	assert_eq(rig.view().boards, [after.cells] as Array[PackedInt64Array], "the move shows once and ends on the saved board")
	assert_true(rig.session.state.equals(after), "nothing changed meanwhile")
	_assert_shown_once("AT-146")


func test_move_shown_reaches_the_session_only_after_the_view() -> void:
	_gated_rig(F.board_p(), 0)
	# A method, not a lambda: a lambda that reads rig holds this test, and the
	# session's connection would then keep the test and the rig alive (QA6-09).
	rig.session.offer_changed.connect(_on_offer_changed)
	rig.session.resume(RunState.create(_dead_board(), BigNum.from_int(5000)))
	_deferred_check()
	_frames(3)
	_assert_held("a resumed run")
	assert_false(rig.session.is_offer_open(), "the move check waits for the view")
	_open = true
	rig.advance(FRAME)
	assert_true(rig.session.is_offer_open(), "move_shown() ran the move check (GO7)")
	assert_eq(_boards_at_offer, [1] as Array[int], "after the view was set to the saved board")
	assert_eq(rig.view().boards, [_dead_board()] as Array[PackedInt64Array], "the saved board")
	_assert_shown_once("resume")


func test_a_hammer_tap_waits_at_the_gate() -> void:
	_gated_rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.HAMMER)
	rig.tap(Vector2i(2, 4))
	assert_true(rig.session.is_waiting_for_view(), "the Hammer resolved")
	_deferred_check()
	_assert_held("a Hammer tap")
	_open = true
	rig.advance(FRAME)
	assert_eq(_effects(), PackedStringArray(["play_clear", "play_fall", "play_spawn", "set_board"]), "the Hammer plays")
	_assert_shown_once("Hammer")


func test_a_shuffle_waits_at_the_gate() -> void:
	_gated_rig(F.board_p(), 5000)
	assert_true(rig.session.press_booster(BoosterRules.SHUFFLE).accepted, "the Shuffle resolved")
	_deferred_check()
	_assert_held("a Shuffle")
	_open = true
	rig.advance(FRAME)
	assert_eq(_effects(), PackedStringArray(["play_rearrange", "set_board"]), "the Shuffle plays")
	_assert_shown_once("Shuffle")


func test_a_new_run_waits_at_the_gate() -> void:
	_gated_rig(F.board_p(), 0)
	rig.session.start_new_run()
	_deferred_check()
	_assert_held("a new run")
	_open = true
	rig.advance(FRAME)
	assert_eq(_effects(), PackedStringArray(["play_spawn", "set_board"]), "the spawn plays")
	assert_eq((rig.view().spawns[0][0] as Array).size(), 40, "all 40 cells")
	_assert_shown_once("new run")


# One move at a time (D-35).

func test_input_stays_closed_while_a_move_waits() -> void:
	_gated_rig(F.board_p(), 5000)
	rig.play(PAIR)
	_deferred_check()
	var events: int = rig.chain_events.size()
	var clicks: int = rig.clicks()
	var after: RunState = rig.session.state.copy()
	rig.play([Vector2i(0, 7), Vector2i(1, 7)])
	rig.send(BF.mouse_button(rig.point(Vector2i(3, 6)), true))
	rig.send(BF.mouse_button(rig.point(Vector2i(3, 6)), false))
	assert_true(rig.session.press_booster(BoosterRules.SHUFFLE) == null, "a booster tap is ignored")
	assert_eq(rig.chain_events.size(), events, "no chain")
	assert_eq(rig.clicks(), clicks, "no click")
	assert_false(rig.session.is_dragging(), "no drag")
	assert_true(rig.session.state.equals(after), "nothing changed")
	_open = true
	rig.advance(FRAME)
	rig.settle()
	rig.play([Vector2i(0, 7), Vector2i(1, 7)])
	assert_eq(rig.score(), 5000 + 4 + 16, "a fresh chain works once the move has shown")


# Cancel paths while a move waits.

func test_pause_or_focus_loss_while_a_move_waits_keeps_it() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.2}
	_gated_rig(F.board_p(), 0, durations)
	rig.play(PAIR)
	var after: RunState = rig.session.state.copy()
	_deferred_check()
	# What the App does when Pause opens and on focus loss (flow 8 and 9).
	rig.board.cancel_drag()
	rig.session.cancel_targeting()
	_frames(2)
	_assert_held("after the interruption")
	assert_true(rig.session.state.equals(after), "the session keeps the move")
	# The App's save on focus loss lands it.
	_open = true
	rig.advance(FRAME)
	rig.settle()
	assert_eq(rig.view().merges.size(), 1, "the move plays once")
	assert_eq(rig.view().boards, [after.cells] as Array[PackedInt64Array], "and ends on its board")
	assert_true(rig.session.state.equals(after), "nothing lost and nothing doubled")
	_assert_shown_once("interrupted")


func test_a_skin_switch_while_a_move_waits_keeps_it_waiting() -> void:
	var durations: Dictionary[StringName, float] = {&"play_merge": 0.2}
	_gated_rig(F.board_p(), 0, durations)
	var before: PackedInt64Array = rig.session.state.cells.duplicate()
	rig.play(PAIR)
	var after: RunState = rig.session.state.copy()
	_deferred_check()
	var old_view: SkinBoardView = rig.view()
	var slate: SkinData = SkinCatalog.get_skin(&"slate")
	rig.board.set_skin(slate)
	assert_false(is_instance_valid(old_view), "the old view is freed")
	assert_eq(rig.view().setup_skin, slate, "a new view in the new skin")
	assert_eq(rig.view().effects, PackedStringArray(["set_board"]), "showing only a board")
	assert_eq(rig.view().boards, [before] as Array[PackedInt64Array], "the board as it was at the lift")
	assert_true(rig.board.is_waiting_for_save(), "the move still waits for the save")
	assert_true(rig.board.is_animating(), "input stays closed")
	assert_true(rig.session.is_waiting_for_view(), "the session still waits")
	assert_eq(rig.started + rig.finished, 0, "nothing started or finished")
	_open = true
	rig.advance(FRAME)
	assert_eq(rig.view().merges, [[PAIR, Vector2i(2, 6), F.e(4)]], "the move plays on the new view")
	rig.settle()
	assert_eq(rig.view().effects, PackedStringArray(["set_board", "play_merge", "play_fall", "play_spawn", "set_board"]), "once")
	assert_true(rig.session.state.equals(after), "the board's values are kept")
	_assert_shown_once("skin switch while waiting")


func test_a_skin_switch_while_a_new_run_waits_shows_the_run_before() -> void:
	_gated_rig(F.board_p(), 0)
	rig.session.start_new_run()
	var new_board: PackedInt64Array = rig.session.state.cells.duplicate()
	_deferred_check()
	rig.board.set_skin(SkinCatalog.get_skin(&"nova"))
	assert_eq(rig.view().boards, [F.board_p()] as Array[PackedInt64Array], "the run before, not the new board")
	_open = true
	rig.advance(FRAME)
	assert_eq((rig.view().spawns[0][0] as Array).size(), 40, "the new run spawns on the new view")
	assert_eq(rig.view().boards.back(), new_board, "and ends on the new board")
	_assert_shown_once("skin switch while a new run waits")


func test_a_skin_switch_before_the_first_board_shows_none() -> void:
	var board: StubBoardController = StubBoardController.new()
	var session: GameSession = GameSession.new()
	board.setup(session, SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID), null)
	board.set_show_gate(_gate)
	session.start_new_run()
	board.set_skin(SkinCatalog.get_skin(&"slate"))
	assert_eq(board.stub().boards.size(), 0, "no board before the first run has shown")
	_open = true
	board._check_gate()
	assert_eq(board.stub().effects, PackedStringArray(["play_spawn", "set_board"]), "then the spawn")
	assert_eq(board.stub().boards, [session.state.cells] as Array[PackedInt64Array], "and the new board")
	board.free()


func test_a_new_run_while_a_move_waits_replaces_it() -> void:
	_gated_rig(F.board_p(), 0)
	rig.play(PAIR)
	_deferred_check()
	rig.session.start_new_run()
	_deferred_check()
	_assert_held("the new run")
	_open = true
	rig.advance(FRAME)
	assert_eq(_effects(), PackedStringArray(["play_spawn", "set_board"]), "only the new run shows")
	_assert_shown_once("new run over a waiting move")


func test_a_second_setup_finishes_a_waiting_move_with_move_started_first() -> void:
	_gated_rig(F.board_p(), 0)
	rig.play(PAIR)
	_deferred_check()
	var old_session: GameSession = rig.session
	var new_session: GameSession = GameSession.new()
	rig.board.setup(new_session, rig.skin, rig.audio)
	rig.session = new_session
	assert_eq(rig.move_signals, PackedStringArray(["started", "finished"]), "move_started, then animation_finished, once each")
	assert_false(rig.board.is_waiting_for_save(), "nothing waits")
	assert_false(rig.board.is_animating(), "at rest")
	assert_false(old_session.is_waiting_for_view(), "the old session heard the move was shown")


# Gates that would freeze the game.

func test_a_gate_whose_object_is_gone_counts_as_open() -> void:
	rig = BF.rig(F.board_p(), 0)
	var node: Node = Node.new()
	# Outside the tree, so this gate says false.
	rig.board.set_show_gate(node.is_inside_tree)
	rig.play(PAIR)
	_deferred_check()
	_frames(2)
	_assert_held("the gate says false")
	node.free()
	rig.advance(FRAME)
	assert_false(rig.board.is_waiting_for_save(), "once its object is gone the move shows")
	_assert_shown_once("gate gone")


func test_a_gate_that_returns_no_bool_counts_as_open() -> void:
	rig = BF.rig(F.board_p(), 0)
	var not_a_bool: Callable = func() -> int: return 0
	rig.board.set_show_gate(not_a_bool)
	rig.play(PAIR)
	_deferred_check()
	_assert_shown_once("gate returns an int")

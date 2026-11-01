class_name PlayScreen
extends ScreenBase
## Play: board, tape, commands, and controls for one level.
##
## The simulation runs first and in one call (PlaySession.start). This screen then replays the
## resulting events with short animations. Animation length never changes the outcome, and with
## Reduce motion the tape and automaton jump instead of sliding.

## False in debug screenshots, which must not write progress.
var persist := true

var _entry: Dictionary
var _level: Dictionary
var _session: PlaySession
var _boards: BoardProgress
var _tab_row: BoardTabs  # null for a single board
var _tape: TapeModel
## Bumped whenever a run is stopped, so an animation that was waiting ends quietly.
var _run_id := 0
## True while one step is being animated.
var _busy := false

## The size the objective message should have inside its row.
var _message_box := Vector2.ZERO
var _back: TileButton
var _help: TileButton
var _menu: TileButton
var _coach: CoachBar
## The open pause or hint panel, if any.
var _overlay: Control
var _caption: Label
var _title: Label
var _badge: ResultBadge
var _message: Label
var _counter: Label
var _board: BoardView
var _program_caption: Label
var _tools: Array[TileButton] = []
var _tape_view: TapeView
var _commands_caption: Label
var _command_buttons: Array[TileButton] = []
## The palette tile of each group the level offers, by op (REPEAT, REPEAT_UNTIL, IF, PROC).
var _group_buttons := {}
## The CALL tile of each procedure name, shown for the names that are defined (PROC levels).
var _call_buttons: Array[TileButton] = []
## The Else tile, shown while an IF is open; null when the level does not offer IF.
var _else_button: TileButton
## The Else If and End Loop tiles by key ("ELSE_IF", "END_LOOP"); they show only while needed.
var _extra_buttons := {}
var _stats: Array[StatTile] = []
var _step: TileButton
var _run: TileButton
var _reset: TileButton
var _edit: TileButton
var _levels: TileButton
var _replay: TileButton
var _next: TileButton
var _share: TileButton
var _ranking: TileButton


func _build() -> void:
	_entry = (
		DailyPlay.entry(app.daily, str(args["daily"]))
		if args.has("daily")
		else app.campaign.entry_by_id(str(args.get("level_id", "")))
	)
	if _entry.is_empty():
		navigate.emit.call_deferred("daily" if args.has("daily") else "worlds", {})
		return
	_level = _entry["level"]
	_boards = BoardProgress.new(_level)
	_session = PlaySession.new(_boards.board_level())
	var available := LevelMechanics.available(_level)
	_tape = TapeModel.new(
		int(_level["constraints"]["maxCommands"]),
		available,
		LevelMechanics.nested_loops(_level),
		LevelMechanics.recursion(_level)
	)
	# A debug level starts with a program to fix.
	if _level.has("startProgram"):
		_tape.load_program(_level["startProgram"])
	if persist and not _entry.has("daily"):
		app.progress.set_last_level(_entry["id"])
		app.progress.save()

	PlayBuilder.build(self, available)
	_refresh()


func go_back() -> void:
	if _overlay != null:
		_close_overlay()
		return
	_run_id += 1
	if _entry.has("daily"):
		navigate.emit("daily", {})
		return
	navigate.emit("world", {"world": int(_entry["world"])})


func _notification(what: int) -> void:
	# Animation pauses when the app loses focus.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if _session != null and _session.state == PlaySession.State.RUNNING:
			_session.pause()
			_refresh()


func _layout() -> void:
	if _next == null:
		return
	PlayLayout.apply(self)


# ----- state to view --------------------------------------------------------------------------


## Brings every control in line with the session state. No animation.
func _refresh() -> void:
	PlayBoards.refresh(self)
	var state := _session.state
	var finished := _session.is_finished()
	var plan := PlayLayout.control_plan(self)
	for button: TileButton in [_step, _run, _reset, _edit, _levels, _replay, _next]:
		button.visible = false
	for item: Array in plan:
		(item[0] as TileButton).visible = true

	# A loop with no command in it, or an IF with an empty then, is not a program yet.
	var empty := _tape.is_empty() or _tape.is_incomplete()
	_step.set_disabled(state == PlaySession.State.RUNNING or empty)
	_reset.set_disabled(state == PlaySession.State.READY)
	match state:
		PlaySession.State.RUNNING:
			PlayTape.set_run_button(self, "PAUSE", "pause", false)
		PlaySession.State.PAUSED:
			PlayTape.set_run_button(self, "CONTINUE", "play", false)
		_:
			PlayTape.set_run_button(self, "RUN", "play", empty)

	var solved := state == PlaySession.State.SUCCEEDED
	var running := state == PlaySession.State.RUNNING
	PlayView.refresh_palette(self, solved, running)
	for stat in _stats:
		stat.visible = solved
	_share.visible = solved
	_ranking.visible = solved and app.has_social()
	if solved:
		PlayView.update_stats(self)
	_commands_caption.visible = not solved and size.y >= 760.0
	PlayView.update_coach(self, state)

	_badge.kind = "check" if solved else "x"
	_message.text = PlayView.message_text(self)
	_counter.text = PlayView.counter_text(self)
	_counter.visible = state != PlaySession.State.FAILED

	PlayView.refresh_tools(self)
	_program_caption.text = PlayView.program_caption(self)

	_tape_view.running = state != PlaySession.State.READY
	_tape_view.set_content(
		_tape.cells(), _tape.slots(), _tape.limit, _tape.selected, _tape.open_keys()
	)
	_tape_view.failed_index = _tape.cell_for_node(_session.failing_node())
	PlayTape.set_head(self, _session.current_entry())
	PlayTape.sync_scroll(self)
	PlayTape.show_board(self)
	_layout()
	queue_redraw()
	for node in [_badge, _tape_view]:
		node.queue_redraw()


# ----- player actions ---------------------------------------------------------------------------


func _stop_run() -> void:
	_run_id += 1
	_busy = false
	_session.reset()


## Editing from any state other than READY first returns the run to READY.
func _begin_edit() -> void:
	if _session.state == PlaySession.State.RUNNING:
		return
	if _session.state != PlaySession.State.READY:
		_stop_run()


func _on_command(op: String) -> void:
	if _session.state == PlaySession.State.RUNNING:
		return
	_begin_edit()
	PlayView.apply_command(_tape, op)
	app.sfx("tap")
	_refresh()


func _on_tile_tapped(index: int) -> void:
	if _session.state == PlaySession.State.RUNNING:
		return
	_begin_edit()
	if index >= 0 and index == _tape.selected and PlayView.can_cycle(_tape):
		_tape.cycle_condition()
	else:
		_tape.toggle_select(index)
	_refresh()


func _on_tool(kind: String) -> void:
	PlayTape.apply_tool(_tape, kind)
	_refresh()


## A CALL tile of the palette: adds a call of that procedure.
func _on_call(name: String) -> void:
	if _session.state == PlaySession.State.RUNNING:
		return
	_begin_edit()
	_tape.append_call(name)
	app.sfx("tap")
	_refresh()


func _on_reset() -> void:
	_stop_run()
	_tape.clear_selection()
	_refresh()


func _on_run() -> void:
	match _session.state:
		PlaySession.State.RUNNING:
			_session.pause()
			_refresh()
		PlaySession.State.PAUSED:
			if not _busy:
				_session.resume()
				_refresh()
				PlayAnimator.play_until_stopped(self)
		PlaySession.State.READY:
			if _start(PlaySession.State.RUNNING):
				PlayAnimator.play_until_stopped(self)


func _on_step() -> void:
	if _session.state == PlaySession.State.RUNNING or _busy or _session.is_finished():
		return
	if _session.state == PlaySession.State.READY and not _start(PlaySession.State.PAUSED):
		return
	PlayAnimator.play_one_step(self)


func _on_next() -> void:
	var next: Dictionary = app.campaign.next_after(_entry["id"])
	if not next.is_empty():
		navigate.emit("play", {"level_id": next["id"]})


func _start(next_state: PlaySession.State) -> bool:
	_tape.clear_selection()
	_boards.notice = ""
	if _tape.is_empty() or _tape.is_incomplete() or not _session.start(_tape.program(), next_state):
		return false
	_run_id += 1
	_refresh()
	return true


# ----- hint and pause ------------------------------------------------------------------------


func _open_hint() -> void:
	PlayOverlays.open_hint(self)


func _open_pause() -> void:
	PlayOverlays.open_pause(self)


func _show_overlay(overlay: Control) -> void:
	_overlay = overlay
	add_child(overlay)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


# ----- debug screenshots -----------------------------------------------------------------------


## Debug only (see main.gd): put a program on the tape and show the state after `steps` events.
func debug_show(program_text: String, steps: int) -> void:
	PlayDebug.show(self, program_text, steps)

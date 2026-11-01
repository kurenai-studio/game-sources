class_name BoardController extends Control
## The board on the play screen (docs/ARCHITECTURE.md section 8): input,
## chains, targeting taps and the order a move's effects play in. It holds
## no rules (GameSession and CoreRules decide everything) and no look (the
## skin's SkinBoardView draws everything). The root of scenes/board/board.tscn.
##
## Input. Touch and mouse go through one path. Mouse events that Godot makes
## up from a touch (device DEVICE_ID_EMULATION) are ignored, so a phone never
## sees a touch twice. Only the first finger counts until it lifts (D-08).
##
## Chains. A finger down outside targeting asks session.begin_drag(); when
## that refuses, the touch is ignored until it lifts. Every pointer move is
## hit tested with BoardGeometry.cell_at (D-07) at points along the path
## since the last event, so a fast swipe never skips a tile it crossed, and
## each tile entered goes through CoreRules.step_chain (D-04, D-05). Lifting
## commits a chain of 2 or more, anywhere on or off the board (D-06), and
## cancels a shorter one with no penalty.
##
## Targeting (D-43). A tap is a finger down and up inside the same tile's
## cell_rect, anywhere on the visible tile: D-07's smaller circle only keeps
## diagonal drags off side tiles, which a tap does not need. A finger down on
## a tile shows press feedback while the finger stays on that tile. Lifting
## on the same tile calls session.tap_cell(); lifting in a gap, on another
## tile or off the board does nothing.
##
## Moves. On run_started and move_resolved the board plays the move's
## effects in the order of DESIGN_SYSTEM.md 3.6 and waits for the lengths the
## view returns:
##   chain   merge travel, then the pop and the small tile clear together,
##           then the falls and the spawns together
##   Hammer  clear, then fall and spawn together
##   Double  value change, then, if small tiles cleared, the clear, then
##           fall and spawn together
##   Swap    swap. Shuffle and Undo: rearrange. New run: spawn. Resume: none
## Then it calls set_board(cells_after), session.move_shown() and emits
## animation_finished. No input is taken meanwhile (D-35). A move whose
## effects all take 0 seconds finishes inside the same call.
##
## The show gate (QA6-06, GDD D-33 and 15.1). With a gate set, the board
## stores each move and starts its effects only once gate.call() returns
## true. The first check is deferred, because the session emits
## save_requested after run_started and move_resolved, and the save is only
## queued then. After that it checks once a frame. Until the gate opens the
## view keeps the board as it was at the lift (the chain line and the click
## at the lift are input feedback, not the result) and input stays closed.
## move_started is emitted once for every move that is shown, gate or not,
## run_started included, right before its first effect and in the same frame,
## so always before that move's animation_finished. A gate that is open at
## the first check (a save that failed is idle too) starts the move then.
##
## Cancel paths while a move waits at the gate. cancel_drag() (pause, focus
## loss) leaves it waiting, and it shows once the gate opens. A skin switch
## keeps it waiting: the new view shows the board as it was at the lift and
## plays the move when the gate opens. A new move replaces it, as a new move
## replaces one still playing: the replaced move gets neither move_started
## nor animation_finished. setup() finishes it at once, as it does a move
## still playing, with move_started first. So a move is never lost from the
## session and never shown twice.
##
## Values. Every tile value the board passes on (boards, the preview, merge
## results, spawns, value changes) is the tile's exponent, as core gives it
## (docs/ARCHITECTURE.md section 17). The board never reads them.
##
## The drag path allocates nothing per pointer event: work that allocates
## (step_chain, the preview, the joinable highlight) runs only when the
## finger enters a new tile.

## Every tile added or removed, and every commit and cancel (empty chain, 0).
## preview_value is the merge result's exponent (section 17), 0 for none.
signal chain_changed(chain: Array[Vector2i], preview_value: int)
## After the last effect of a move.
signal animation_finished()
## The show gate opened and the move's effects begin, in this frame. Once per
## move shown, right before its first effect, so always before its
## animation_finished.
signal move_started()

const NO_CELL: Vector2i = Vector2i(-1, -1)
const NO_DRAG: Vector2 = Vector2(-1.0, -1.0)
const NO_POINTER: int = -1
## The pointer id the mouse uses. Touch indexes start at 0.
const MOUSE_POINTER: int = -2
## Hit test points along a pointer move are at most this share of the hit
## radius apart.
const SAMPLE_SPACING: float = 0.5
## The most hit test points one pointer event gets.
const MAX_SAMPLES: int = 64

enum Gesture { NONE, CHAIN, PRESS }

var _session: GameSession = null
var _skin: SkinData = null
var _audio: AudioService = null
var _view: SkinBoardView = null

# The gesture of the first finger, or of the mouse.
var _gesture: Gesture = Gesture.NONE
var _pointer: int = NO_POINTER
## The last pointer position in view pixels.
var _last_point: Vector2 = Vector2.ZERO
## The cell the finger is over now, (-1, -1) for none.
var _hover: Vector2i = NO_CELL
## The chain in drag order. Replaced, never changed in place, so a listener
## that keeps an array from chain_changed keeps what it was sent.
var _chain: Array[Vector2i] = []
## Always empty. Clears the joinable highlight.
var _no_cells: Array[Vector2i] = []
## Targeting: the tile the finger went down on, the booster active then, and
## the press feedback the view shows now.
var _pressed: Vector2i = NO_CELL
var _press_booster: StringName = &""
var _press_shown: Vector2i = NO_CELL

# The move being shown.
var _animating: bool = false
var _move: MoveResult = null
## The next effect step of the move.
var _stage: int = 0
## Seconds until the next step starts.
var _wait: float = 0.0
## The part of the merge's length that runs on after the travel (the pop).
var _merge_tail: float = 0.0
## A move's effects start only once this returns true. Empty for no gate.
var _gate: Callable = Callable()
## The move is stored and waits at the gate.
var _held: bool = false
## move_started was emitted for the move being shown.
var _began: bool = false
## The board the view was last told to show at rest. A view rebuilt while a
## move waits at the gate shows this: the board as it was at the lift.
var _shown: PackedInt64Array = PackedInt64Array()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


## Wires the board to a session, a skin and the audio service, builds the
## skin's board view and shows the session's board. Call it before
## session.start_new_run() or session.resume(), so the board sees run_started.
## audio may be null: then nothing is asked to click.
func setup(session: GameSession, skin: SkinData, audio: AudioService) -> void:
	if _animating:
		_finish_move()
	_drop_gesture()
	if _session != null and _session.run_started.is_connected(_on_run_started):
		_session.run_started.disconnect(_on_run_started)
		_session.move_resolved.disconnect(_on_move_resolved)
		_session.targeting_changed.disconnect(_on_targeting_changed)
	_session = session
	_skin = skin
	_audio = audio
	if _session != null:
		_session.run_started.connect(_on_run_started)
		_session.move_resolved.connect(_on_move_resolved)
		_session.targeting_changed.connect(_on_targeting_changed)
	_rebuild_view()


## Live skin switch: a new board view for the skin, showing the same board,
## targeting and chain. A move still playing finishes at once on the new view.
## A move waiting at the show gate keeps waiting: the new view shows the board
## as it was at the lift, and the move plays on it once the gate opens.
func set_skin(skin: SkinData) -> void:
	if skin == null:
		push_error("set_skin() needs a skin")
		return
	_skin = skin
	_rebuild_view()
	if _animating and not _held:
		_finish_move()


## Drops a chain or a targeting press in progress with no penalty and ends
## the session's drag. The App calls it when Pause opens and on focus loss.
func cancel_drag() -> void:
	_drop_gesture()
	if _session != null:
		_session.end_drag()


## The height the skin's board needs at this width.
func preferred_height(width: float) -> float:
	if _view == null:
		return 0.0
	return _view.preferred_height(width)


## True from a move's run_started or move_resolved, through any wait at the
## show gate and its effects, until animation_finished. Input is closed
## meanwhile (D-35).
func is_animating() -> bool:
	return _animating


## QA6-06. A move's effects start only once gate.call() returns true: checked
## deferred after the move arrives, then once a frame. An empty Callable shows
## every move at once. A gate whose object is gone, or that returns anything
## but a bool, counts as open, so the game never freezes. A new gate counts
## from the next check, also for a move already waiting.
func set_show_gate(gate: Callable) -> void:
	_gate = gate


## TH23: a move waits at the show gate.
func is_waiting_for_save() -> bool:
	return _held


## The skin board view for a skin. Tests override it to put in a stub.
func _make_view(skin: SkinData) -> SkinBoardView:
	return SkinCatalog.make_board_view(skin)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_fit_view()
		NOTIFICATION_READY:
			# Godot turns processing on for a script with _process; keep it on
			# only while a move plays.
			set_process(_animating)
		NOTIFICATION_EXIT_TREE:
			# A finger can never hold the session's drag lock from a board
			# that left the screen.
			_drop_gesture()


func _process(delta: float) -> void:
	if not _animating:
		set_process(false)
		return
	if _held:
		# Once a frame until the gate opens. The first step then starts now
		# and does not lose this frame's delta.
		_check_gate()
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = 0.0
		_run_stages()


# Input.

func _gui_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_pointer_down(touch.index, touch.position)
		elif touch.index == _pointer:
			_pointer_up(touch.position, touch.canceled)
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null:
		if drag.index == _pointer:
			_pointer_move(drag.position)
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_pointer_down(MOUSE_POINTER, button.position)
		elif _pointer == MOUSE_POINTER:
			_pointer_up(button.position, button.canceled)
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _pointer == MOUSE_POINTER:
		_pointer_move(motion.position)


func _pointer_down(pointer: int, point: Vector2) -> void:
	if pointer == _pointer:
		# This pointer's lift never arrived: drop that gesture with no penalty.
		_drop_gesture()
	if _pointer != NO_POINTER or _animating or _session == null or _view == null:
		return
	_fit_view()
	var local: Vector2 = _to_view(point)
	if _session.phase() == GameSession.Phase.TARGETING:
		_gesture = Gesture.PRESS
		_pointer = pointer
		_press_booster = _session.targeting_booster()
		_pressed = _tile_at(local)
		_show_press(_pressed)
	elif _session.begin_drag():
		_gesture = Gesture.CHAIN
		_pointer = pointer
		_last_point = local
		_hover = NO_CELL
		_visit(_cell_at(local), local)


func _pointer_move(point: Vector2) -> void:
	if _view == null:
		return
	var local: Vector2 = _to_view(point)
	match _gesture:
		Gesture.CHAIN:
			_drag_chain(local)
		Gesture.PRESS:
			_show_press(_pressed if _tile_at(local) == _pressed else NO_CELL)


func _pointer_up(point: Vector2, canceled: bool) -> void:
	match _gesture:
		Gesture.CHAIN:
			_end_chain(not canceled)
		Gesture.PRESS:
			var cell: Vector2i = _pressed
			_reset_gesture()
			_show_press(NO_CELL)
			if not canceled and cell != NO_CELL and _view != null and _tile_at(_to_view(point)) == cell:
				_session.tap_cell(cell)
		_:
			_reset_gesture()


# Chains.

## Hit tests the path from the last pointer position to local and steps the
## chain at every tile entered on the way.
func _drag_chain(local: Vector2) -> void:
	var from: Vector2 = _last_point
	_last_point = local
	var origin: Vector2 = _view.grid_origin()
	var pitch: Vector2 = _view.cell_pitch()
	var config: GameConfig = _session.config
	var spacing: float = config.join_radius * minf(pitch.x, pitch.y) * SAMPLE_SPACING
	var samples: int = 1
	if spacing > 0.0:
		samples = clampi(ceili(from.distance_to(local) / spacing), 1, MAX_SAMPLES)
	for i: int in samples:
		var sample: Vector2 = from.lerp(local, float(i + 1) / float(samples))
		_visit(BoardGeometry.cell_at(sample, origin, pitch, config.columns, config.rows, config.join_radius), sample)
	if not _chain.is_empty():
		_view.set_chain(_chain, local)


## The finger is over cell now (or over none). Entering a tile steps the
## chain: a joinable tile joins and clicks, the previous tile backtracks,
## anything else changes nothing.
func _visit(cell: Vector2i, local: Vector2) -> void:
	if cell == _hover:
		return
	_hover = cell
	if cell == NO_CELL:
		return
	# The run's real score: joining, the highlight and the commit all measure
	# the chain against it (docs/ARCHITECTURE.md section 17), so they agree.
	var stepped: Array[Vector2i] = CoreRules.step_chain(_session.state.cells, _session.state.score, _chain, cell, _session.config)
	if stepped.size() == _chain.size():
		return
	var added: bool = stepped.size() > _chain.size()
	_chain = stepped
	if added and _audio != null:
		_audio.play_click()
	var preview: int = _session.preview_value(_chain)
	_view.set_chain(_chain, local)
	_view.set_preview(preview)
	_view.set_joinable(_session.joinable_cells(_chain))
	chain_changed.emit(_chain, preview)


## The finger lifted (commit true) or the drag was dropped. Clears the chain
## from the view first, then commits a chain long enough, or ends the drag.
func _end_chain(commit: bool) -> void:
	var chain: Array[Vector2i] = _chain
	_reset_gesture()
	_chain = []
	if _view != null:
		_view.set_chain(_chain, NO_DRAG)
		_view.set_preview(0)
		_view.set_joinable(_no_cells)
	chain_changed.emit(_chain, 0)
	if commit and chain.size() >= maxi(2, _session.config.min_chain_length):
		var result: MoveResult = _session.commit_chain(chain)
		if result.accepted and _audio != null:
			_audio.play_click()
	else:
		_session.end_drag()


# Targeting.

func _show_press(cell: Vector2i) -> void:
	if cell == _press_shown:
		return
	_press_shown = cell
	if _view != null:
		_view.set_pressed_cell(cell)


func _on_targeting_changed(booster_id: StringName, swap_first: Vector2i) -> void:
	if _gesture == Gesture.PRESS and booster_id != _press_booster:
		# Targeting ended or switched under the finger: its lift picks nothing.
		_pressed = NO_CELL
		_show_press(NO_CELL)
	if _view != null:
		_view.set_targeting(booster_id)
		_view.set_swap_selected(swap_first)


# Gestures.

## Ends the gesture in progress with no penalty.
func _drop_gesture() -> void:
	match _gesture:
		Gesture.CHAIN:
			_end_chain(false)
		Gesture.PRESS:
			_reset_gesture()
			_show_press(NO_CELL)
		_:
			_reset_gesture()


func _reset_gesture() -> void:
	_gesture = Gesture.NONE
	_pointer = NO_POINTER
	_hover = NO_CELL
	_pressed = NO_CELL
	_press_booster = &""


# Moves.

func _on_run_started(result: MoveResult) -> void:
	_show_move(result)


func _on_move_resolved(result: MoveResult) -> void:
	_show_move(result)


## Stores the move, replacing one still waiting or playing, and starts it at
## once with no gate, or holds it for the gate.
func _show_move(result: MoveResult) -> void:
	if result == null:
		return
	_drop_gesture()
	_move = result
	_stage = 0
	_wait = 0.0
	_merge_tail = 0.0
	_animating = true
	_began = false
	if _gate.is_null():
		_held = false
		_start_move()
		return
	# The session emits save_requested right after this signal, so the first
	# check waits until those handlers have run and the save is queued.
	_held = true
	set_process(true)
	_check_gate.call_deferred()


## Starts the move waiting at the gate once the gate is open. Runs deferred
## after the move arrives, then once a frame from _process.
func _check_gate() -> void:
	if _held and _gate_open():
		_held = false
		_start_move()


func _gate_open() -> bool:
	if not _gate.is_valid():
		return true
	var open: Variant = _gate.call()
	if open is bool:
		return open
	push_error("BoardController: the show gate must return a bool")
	return true


## Tells listeners the move starts, then plays its effects. A move_started
## listener may replace or finish the move; then this move plays no further.
func _start_move() -> void:
	var move: MoveResult = _move
	_began = true
	move_started.emit()
	if _move == move and _animating and not _held:
		_run_stages()


## Runs effect steps until one needs time, or finishes the move when none is
## left. Steps that take no time run at once.
func _run_stages() -> void:
	while _animating and _wait <= 0.0:
		var wait: float = _run_stage(_move, _stage)
		if wait < 0.0:
			_finish_move()
			return
		_stage += 1
		_wait = wait
	if _animating:
		set_process(true)


## Plays step stage of the move and returns how long to wait before the next
## one, or -1 when the move has no more steps. Order per DESIGN_SYSTEM.md 3.6
## and GDD sections 8 and 13.
func _run_stage(move: MoveResult, stage: int) -> float:
	if _view == null:
		return -1.0
	match move.kind:
		MoveResult.Kind.CHAIN:
			match stage:
				0:
					# The pop runs on after the travel, together with the clear.
					var merge: float = _length(_view.play_merge(move.chain, move.result_cell, move.result_value))
					var travel: float = minf(_length(_skin.duration(&"merge_travel")), merge)
					_merge_tail = merge - travel
					return travel
				1:
					var wait: float = maxf(_merge_tail, _play_clear(move.cleared_small))
					_merge_tail = 0.0
					return wait
				2:
					return _play_fall_and_spawn(move)
		MoveResult.Kind.HAMMER:
			match stage:
				0:
					return _play_clear(move.emptied)
				1:
					return _play_fall_and_spawn(move)
		MoveResult.Kind.SWAP:
			if stage == 0 and move.targets.size() == 2:
				return _length(_view.play_swap(move.targets[0], move.targets[1]))
		MoveResult.Kind.SHUFFLE, MoveResult.Kind.UNDO:
			if stage == 0:
				return _length(_view.play_rearrange(move.cells_after))
		MoveResult.Kind.DOUBLE:
			match stage:
				0:
					return _length(_view.play_value_change(move.result_cell, move.result_value))
				1:
					return _play_clear(move.cleared_small)
				2:
					return _play_fall_and_spawn(move)
		MoveResult.Kind.NEW_RUN:
			# A resumed run has no spawn cells: the board just appears.
			if stage == 0:
				return _play_spawn(move)
	return -1.0


func _play_clear(cells: Array[Vector2i]) -> float:
	if cells.is_empty():
		return 0.0
	return _length(_view.play_clear(cells))


## Falls and spawns start at the same moment (DESIGN_SYSTEM.md 3.6); the
## view draws new tiles under falling ones and staggers them itself. Returns
## the longer of the two. play_fall moves the values inside the view, so it
## is always called first.
func _play_fall_and_spawn(move: MoveResult) -> float:
	var fall: float = 0.0
	if not move.fall_from.is_empty():
		fall = _length(_view.play_fall(move.fall_from, move.fall_to))
	return maxf(fall, _play_spawn(move))


func _play_spawn(move: MoveResult) -> float:
	if move.spawn_cells.is_empty():
		return 0.0
	return _length(_view.play_spawn(move.spawn_cells, move.spawn_values))


## The board shows the move's result, the session hears it was shown, and
## listeners hear the animation ended. State is reset before move_shown(),
## because the outcome it runs may start another move at once.
func _finish_move() -> void:
	if _move != null and not _began:
		# Only setup() finishes a move still waiting at the gate. Its
		# move_started still comes first, once.
		var waiting: MoveResult = _move
		_began = true
		move_started.emit()
		if _move != waiting:
			return
	var move: MoveResult = _move
	_move = null
	_animating = false
	_held = false
	_began = false
	_stage = 0
	_wait = 0.0
	_merge_tail = 0.0
	set_process(false)
	if move != null and _view != null and move.cells_after.size() == _cell_count():
		_view.set_board(move.cells_after)
		_shown = move.cells_after
	if _session != null:
		_session.move_shown()
	animation_finished.emit()


## An effect length the board can wait on: below 0, NaN or infinite counts as 0.
static func _length(seconds: float) -> float:
	if seconds > 0.0 and is_finite(seconds):
		return seconds
	return 0.0


# The view.

## Frees the old view and builds the skin's view, showing the session's
## board, targeting, and any chain or press in progress. While a move waits
## at the show gate it shows the board as it was at the lift instead, which
## is the board the old view showed at rest.
func _rebuild_view() -> void:
	if _view != null:
		remove_child(_view)
		_view.free()
		_view = null
	var press_shown: Vector2i = _press_shown
	_press_shown = NO_CELL
	var lift_board: PackedInt64Array = _shown
	_shown = PackedInt64Array()
	if _session == null or _skin == null:
		return
	_view = _make_view(_skin)
	if _view == null:
		return
	_view.name = &"SkinBoardView"
	_view.setup(_skin, _session.config.columns, _session.config.rows)
	add_child(_view)
	_fit_view()
	var board_cells: PackedInt64Array = lift_board if _held else _session.state.cells
	if board_cells.size() == _cell_count():
		_view.set_board(board_cells)
		_shown = board_cells
	_view.set_targeting(_session.targeting_booster())
	_view.set_swap_selected(_session.swap_first())
	if _gesture == Gesture.CHAIN and not _chain.is_empty():
		_view.set_chain(_chain, _last_point)
		_view.set_preview(_session.preview_value(_chain))
		_view.set_joinable(_session.joinable_cells(_chain))
	elif _gesture == Gesture.PRESS:
		_show_press(press_shown)


## The view fills the board's rect.
func _fit_view() -> void:
	if _view == null:
		return
	if _view.position != Vector2.ZERO:
		_view.position = Vector2.ZERO
	if _view.size != size:
		_view.size = size


func _to_view(point: Vector2) -> Vector2:
	return point - _view.position


## Chains: the tile within the D-07 join radius of local, else (-1, -1).
func _cell_at(local: Vector2) -> Vector2i:
	var config: GameConfig = _session.config
	return BoardGeometry.cell_at(local, _view.grid_origin(), _view.cell_pitch(), config.columns, config.rows, config.join_radius)


## Targeting taps: the tile whose cell_rect holds local, else (-1, -1). Gaps
## between tiles and points off the board hit no tile.
func _tile_at(local: Vector2) -> Vector2i:
	var config: GameConfig = _session.config
	var pitch: Vector2 = _view.cell_pitch()
	if not (pitch.x > 0.0 and pitch.y > 0.0) or not local.is_finite():
		return NO_CELL
	# Tiles sit inside their pitch boxes, so only the box's own tile can hold
	# the point.
	var box: Vector2 = (local - _view.grid_origin()) / pitch
	var cell: Vector2i = Vector2i(clampi(floori(box.x), 0, config.columns - 1), clampi(floori(box.y), 0, config.rows - 1))
	if _view.cell_rect(cell).has_point(local):
		return cell
	return NO_CELL


func _cell_count() -> int:
	if _session == null:
		return 0
	return _session.config.cell_count()

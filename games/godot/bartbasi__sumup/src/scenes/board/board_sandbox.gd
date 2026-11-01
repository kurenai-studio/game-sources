extends Control
## A manual play scene for the board, for Phase 4 checks before the screens
## exist: a real GameSession on the Gumdrop skin, an AudioService for the
## click, and the board filling the window. Play with the mouse.
##
## Keys, since there is no booster bar here: 1 to 5 press Hammer, Swap,
## Shuffle, Double and Undo; Escape cancels targeting; N starts a new run.
## The window title shows the score and the phase.

const BOARD_SCENE: PackedScene = preload("res://scenes/board/board.tscn")
const BOOSTER_KEYS: Dictionary[Key, StringName] = {
	KEY_1: &"hammer",
	KEY_2: &"swap",
	KEY_3: &"shuffle",
	KEY_4: &"double",
	KEY_5: &"undo",
}

var _session: GameSession = null
var _audio: AudioService = null
var _board: BoardController = null


func _ready() -> void:
	var skin: SkinData = SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = skin.color(&"bg")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_audio = AudioService.new()
	add_child(_audio)
	_session = GameSession.new()
	_session.status_changed.connect(_show_status)
	_board = BOARD_SCENE.instantiate() as BoardController
	add_child(_board)
	_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.setup(_session, skin, _audio)
	_session.start_new_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _board != null:
		_board.cancel_drag()
		_session.cancel_targeting()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if BOOSTER_KEYS.has(key.keycode):
		_session.press_booster(BOOSTER_KEYS[key.keycode])
	elif key.keycode == KEY_ESCAPE:
		_session.cancel_targeting()
	elif key.keycode == KEY_N:
		_board.cancel_drag()
		_session.start_new_run()


func _show_status() -> void:
	var phase: String = GameSession.Phase.keys()[_session.phase()]
	get_window().title = "Board sandbox: score %s, %s" % [NumberFormat.score(_session.state.score), phase.to_lower()]

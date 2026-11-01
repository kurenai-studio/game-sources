extends Control
## A pressable control drawn by a skin: the HUD pause buttons and the booster
## buttons. It presses with Motion.press while held and springs back with
## Motion.release, and emits tapped once when the finger lifts inside it. A
## disabled one takes the touch and does nothing. Taps are read by TapInput
## (QA6-01): a finger, a real mouse click or ui_accept, never the copies of
## Godot's mouse and touch emulation.

const TapInput: GDScript = preload("res://src/design/shared/tap_input.gd")

signal tapped()

## Whether a touch is down on it now.
var held: bool = false
## Whether it reacts to touch.
var enabled: bool = true

var _skin: SkinData = null
var _tap: TapInput = TapInput.new()


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


func _gui_input(event: InputEvent) -> void:
	if _skin == null:
		return
	var read: int = _tap.read(event, size)
	if read == TapInput.IGNORED:
		return
	accept_event()
	if not enabled:
		drop_hold()
		return
	match read:
		TapInput.PRESSED:
			_set_held(true)
			Motion.press(self, _skin)
			pivot_offset = _press_pivot()
		TapInput.TAPPED, TapInput.LIFTED:
			_set_held(false)
			Motion.release(self, _skin)
			pivot_offset = _press_pivot()
			if read == TapInput.TAPPED:
				tapped.emit()


## Ends a press with no tap and no motion, for a button hidden or disabled
## while held.
func drop_hold() -> void:
	_tap.reset()
	if held:
		_set_held(false)
		scale = Vector2.ONE


## The point the press scales around, local. The center of the control,
## unless the drawn face sits off center in a larger touch area.
func _press_pivot() -> Vector2:
	return size * 0.5


func _notification(what: int) -> void:
	# A button hidden while held would otherwise stay pressed.
	if what == NOTIFICATION_VISIBILITY_CHANGED and held and not is_visible_in_tree():
		drop_hold()


func _set_held(on: bool) -> void:
	held = on
	_held_changed()


## Called when held changes, for the skin to redraw its pressed look.
func _held_changed() -> void:
	queue_redraw()

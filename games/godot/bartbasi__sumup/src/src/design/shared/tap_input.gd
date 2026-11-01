extends RefCounted
## How every pressable control of the design area reads a tap (QA6-01), one
## rule for all: the icon buttons, the toggles, the HUD pause buttons and the
## booster buttons.
##
## A tap is a press, then a release on the same control, by one of:
##   a finger (InputEventScreenTouch, the first finger only),
##   a real mouse (InputEventMouseButton, left button),
##   ui_accept (Enter or Space, or whatever the input map adds) while the
##     control has focus.
## Godot copies each touch as an emulated mouse event and, when asked, each
## mouse click as an emulated touch (device DEVICE_ID_EMULATION). Those
## copies are never acted on, so a tap counts once whether the emulation is on
## or off, like the board (docs/ARCHITECTURE.md section 8).
##
## The control calls read() from _gui_input and accepts every event that does
## not come back IGNORED, so nothing else, BaseButton's own handling
## included, sees it a second time.

## Not a tap event: leave it alone (mouse motion, the wheel, other keys).
const IGNORED: int = 0
## A tap event with nothing to do: a copy made by the emulation, or a
## release that ends no press of this control. Accept it.
const SWALLOWED: int = 1
## A press: show the pressed look.
const PRESSED: int = 2
## A release inside the control: the tap. Do the action once.
const TAPPED: int = 3
## A release outside the control, or a cancelled touch: drop the pressed
## look, do nothing.
const LIFTED: int = 4

const _NO_POINTER: int = -3
const _MOUSE_POINTER: int = -2
const _KEY_POINTER: int = -1

## Whether a press is held now.
var held: bool = false

var _pointer: int = _NO_POINTER


## Reads one event that reached a control of size (local coordinates).
func read(event: InputEvent, size: Vector2) -> int:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.device == InputEvent.DEVICE_ID_EMULATION:
			return SWALLOWED
		return _pointer_event(touch.index, touch.pressed, touch.canceled, touch.position, size)
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index != MOUSE_BUTTON_LEFT:
			return IGNORED
		if button.device == InputEvent.DEVICE_ID_EMULATION:
			return SWALLOWED
		return _pointer_event(_MOUSE_POINTER, button.pressed, button.canceled, button.position, size)
	if event is InputEventMouse or event is InputEventScreenDrag:
		return IGNORED
	if not event.is_action(&"ui_accept", true) or event.is_echo():
		return IGNORED
	if event.is_pressed():
		_hold(_KEY_POINTER)
		return PRESSED
	if _pointer != _KEY_POINTER:
		return SWALLOWED
	reset()
	return TAPPED


## Drops a press in progress with no tap, for a control that is hidden or
## disabled while held.
func reset() -> void:
	held = false
	_pointer = _NO_POINTER


func _pointer_event(pointer: int, down: bool, canceled: bool, at: Vector2, size: Vector2) -> int:
	if down:
		# A new press while one is held takes over: the old one's lift was
		# lost, or a second finger came down. Either way one tap at most.
		_hold(pointer)
		return PRESSED
	if not held or pointer != _pointer:
		return SWALLOWED
	reset()
	if canceled or not Rect2(Vector2.ZERO, size).has_point(at):
		return LIFTED
	return TAPPED


func _hold(pointer: int) -> void:
	held = true
	_pointer = pointer

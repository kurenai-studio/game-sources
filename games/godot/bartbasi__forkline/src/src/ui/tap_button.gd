# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TapButton
extends Button
## The button every screen uses. It emits `tapped` only for a real tap: the
## finger went down and came up on the button, moved less than DEADZONE, and no
## scroll container above it moved in between. The end of a drag or a scroll
## never counts. Connect to `tapped`, not to `pressed`.
##
## A button also lets a list scroll under a finger that starts on it. A button takes the
## touch, so the scroll container above never sees the drag. Once the finger has moved
## DEADZONE up or down, this button scrolls the nearest scroll container above it by the
## finger's movement, lets go of the press, and the lift is no tap. A drag that stays inside
## the dead zone is still a tap. Every list in the app holds only TapButtons, so this is
## the one fix for all of them.

signal tapped()

## Finger travel allowed during a tap, in logical pixels (about 8 dp on the Fold5).
const DEADZONE: float = 24.0

var _down: bool = false
var _down_at: Vector2 = Vector2.ZERO
var _travel: float = 0.0
var _scroll_at: int = 0
var _tap_ok: bool = false
## Vertical finger movement since the press, and the list it scrolls once past the dead zone.
var _pulled: float = 0.0
var _scroller: ScrollContainer = null
var _scroll_pos: float = 0.0


func _init() -> void:
	# Touch only: no focus ring, no keyboard presses.
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(Layout.MIN_TOUCH, Layout.MIN_TOUCH)


func _gui_input(event: InputEvent) -> void:
	# A touch that starts on a button belongs to the button. Its mouse twin (Godot sends one
	# for every touch) does the work, and a list above is scrolled by _drag_list, so the
	# touch itself must not reach the scroll container too and scroll it twice.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		accept_event()
		return
	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event != null:
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if button_event.pressed:
			_down = true
			_down_at = button_event.position
			_travel = 0.0
			_pulled = 0.0
			_scroller = null
			_scroll_at = _scroll_now()
			_tap_ok = false
		else:
			_tap_ok = _down and _scroller == null and _travel < DEADZONE and _scroll_now() == _scroll_at
			_down = false
			_scroller = null
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _down:
		_travel = maxf(_travel, motion.position.distance_to(_down_at))
		_drag_list(motion.relative.y)


## Called by the button when a press ends on it. Only a clean tap goes on.
func _pressed() -> void:
	if _tap_ok:
		_tap_ok = false
		tapped.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_EXIT_TREE:
		_down = false
		_tap_ok = false
		_scroller = null
	elif what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_ENTER_TREE:
		_calm_hover()


## A touch has no hover, but Godot keeps the emulated mouse where the finger last was, so a
## button under that spot (after a panel closes and the screen comes back) would keep the
## lighter hover look (QA 2026-10-26, p3). Hover draws as normal on every TapButton. The
## pressed look still shows while a finger is down. The check below also stops the
## theme-changed call that adding the override raises.
func _calm_hover() -> void:
	var normal: StyleBox = get_theme_stylebox(&"normal")
	if get_theme_stylebox(&"hover") != normal:
		add_theme_stylebox_override(&"hover", normal)


## Follows the finger up or down. `dy` is how far it moved since the last event. Nothing
## happens until the finger has gone DEADZONE up or down in all; then the list jumps to
## where the finger is and goes along with it.
func _drag_list(dy: float) -> void:
	if _scroller == null:
		_pulled += dy
		if absf(_pulled) < DEADZONE:
			return
		_scroller = _list_above()
		if _scroller == null:
			# Nothing above scrolls. Keep the sum so a later check stays honest.
			_pulled = 0.0
			return
		_scroll_pos = float(_scroller.scroll_vertical)
		dy = _pulled
		_let_go()
	var bar: VScrollBar = _scroller.get_v_scroll_bar()
	var most: float = maxf(0.0, bar.max_value - bar.page)
	_scroll_pos = clampf(_scroll_pos - dy, 0.0, most)
	_scroller.scroll_vertical = roundi(_scroll_pos)


## Drops the press, so the button stops drawing as pressed and the lift is no tap.
func _let_go() -> void:
	if disabled:
		return
	disabled = true
	disabled = false


## The scroll container above that can scroll up and down, or null.
func _list_above() -> ScrollContainer:
	var node: Node = get_parent()
	while node != null:
		var scroll: ScrollContainer = node as ScrollContainer
		if scroll != null and scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			return scroll
		node = node.get_parent()
	return null


## The scroll position of the nearest scroll container above, or 0.
func _scroll_now() -> int:
	var node: Node = get_parent()
	while node != null:
		var scroll: ScrollContainer = node as ScrollContainer
		if scroll != null:
			return scroll.scroll_vertical + scroll.scroll_horizontal * 100000
		node = node.get_parent()
	return 0

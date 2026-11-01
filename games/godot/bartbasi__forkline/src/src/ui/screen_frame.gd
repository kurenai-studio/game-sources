# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name ScreenFrame
extends MarginContainer
## Base of every full screen. It fills the app, keeps its content inside the
## safe area, and knows which layout (portrait or landscape) is in use.

## The player asked to leave this screen (its back arrow).
signal back_requested()

var landscape: bool = false
var window_size: Vector2 = Vector2.ZERO
var safe: Rect2 = Rect2()
## The space kept free inside the safe area. The battle screen sets 0 and pads its own panels.
var pad: float = Layout.PAD


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Called by the App on start and on every resize. Margins are the safe insets
## plus `pad` (Layout.PAD unless a screen says otherwise).
func apply_layout(new_window_size: Vector2, new_safe: Rect2) -> void:
	window_size = new_window_size
	safe = new_safe
	landscape = Layout.is_landscape(new_window_size)
	var left: float = new_safe.position.x
	var top: float = new_safe.position.y
	var right: float = new_window_size.x - new_safe.end.x
	var bottom: float = new_window_size.y - new_safe.end.y
	add_theme_constant_override(&"margin_left", roundi(left + pad))
	add_theme_constant_override(&"margin_top", roundi(top + pad))
	add_theme_constant_override(&"margin_right", roundi(right + pad))
	add_theme_constant_override(&"margin_bottom", roundi(bottom + pad))
	_relayout()


## Override to move parts between the portrait and landscape arrangements.
func _relayout() -> void:
	pass



## The width inside the margins.
func inner_width() -> float:
	return maxf(Layout.MIN_TOUCH, safe.size.x - 2.0 * pad)

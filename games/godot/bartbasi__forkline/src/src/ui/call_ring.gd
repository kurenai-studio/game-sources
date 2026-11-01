# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name CallRing
extends Control
## The pulsing ring around the call button on a level whose highlight is that button
## (RULES 9.6, level 2-1). It is a shape, a thick honey outline that swells and relaxes,
## so it never relies on color alone. It sits on the button and draws a little outside it.

## How far the ring reaches outside the button at its widest, in logical px.
const REACH: float = 20.0
const PERIOD_MS: float = 1200.0
const WIDTH: float = 8.0

var _box: StyleBoxFlat = StyleBoxFlat.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = -REACH
	offset_top = -REACH
	offset_right = REACH
	offset_bottom = REACH
	_box.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_box.border_color = Palette.HONEY
	_box.set_border_width_all(int(WIDTH))
	_box.set_corner_radius_all(UiTheme.RADIUS + int(REACH))
	visible = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var phase: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / PERIOD_MS * TAU)
	# The ring is closest to the button at the low point and farthest at the high point.
	var inset: float = REACH * (1.0 - phase) + WIDTH * 0.5
	_box.border_color = Color(Palette.HONEY, 0.55 + 0.45 * phase)
	draw_style_box(_box, Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0))

# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name HealthBar
extends Control
## A plain bar for a creature's health. The numbers are always written beside it,
## so the bar is never the only signal.

var value: int = 0
var maximum: int = 1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 36.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func set_values(new_value: int, new_maximum: int) -> void:
	if new_value != value or new_maximum != maximum:
		value = new_value
		maximum = maxi(1, new_maximum)
		queue_redraw()


func _draw() -> void:
	var box: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(box, Palette.HP_BACK, true)
	var share: float = clampf(float(value) / float(maxi(1, maximum)), 0.0, 1.0)
	if share > 0.0:
		draw_rect(Rect2(box.position, Vector2(box.size.x * share, box.size.y)), Palette.HP_FILL, true)
	draw_rect(box, Palette.PANEL_EDGE, false, 3.0)

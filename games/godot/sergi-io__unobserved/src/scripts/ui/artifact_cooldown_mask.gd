extends Control

var cooldown_ratio: float = 0.0
var cooldown_seconds_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_cooldown(time_left: float, duration: float) -> void:
	cooldown_seconds_left = maxf(time_left, 0.0)
	if duration <= 0.0:
		cooldown_ratio = 0.0
	else:
		cooldown_ratio = clampf(cooldown_seconds_left / duration, 0.0, 1.0)

	visible = cooldown_ratio > 0.001
	queue_redraw()


func _draw() -> void:
	if cooldown_ratio <= 0.001:
		return

	var mask_rect := Rect2(Vector2.ZERO, size)
	draw_rect(mask_rect, Color(0.0, 0.0, 0.0, 0.20), true)

	var center := size * 0.5
	var radius := maxf(size.x, size.y) * 0.76
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU * cooldown_ratio
	var steps := maxi(int(ceil(48.0 * cooldown_ratio)), 2)
	var previous_point := center + Vector2.RIGHT.rotated(start_angle) * radius
	for index in range(1, steps + 1):
		var progress := float(index) / float(steps)
		var next_point := center + Vector2.RIGHT.rotated(lerpf(start_angle, end_angle, progress)) * radius
		draw_colored_polygon(PackedVector2Array([center, previous_point, next_point]), Color(0.0, 0.0, 0.0, 0.68))
		previous_point = next_point

	draw_arc(center, minf(size.x, size.y) * 0.42, start_angle, end_angle, 48, Color(1.0, 1.0, 1.0, 0.9), 2.0, true)

class_name ManaDisplay
extends Node2D

const WIDTH := 56.0
const PAD := 8.0

var _current: int = 10
var _max: int = 10
var _height: float = 200.0


func setup(current: int, max_mana: int, height: float) -> void:
	_current = current
	_max = max_mana
	_height = height
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), Palette.COLOR_WIDGET_BG, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), Palette.COLOR_WIDGET_BORDER, false, 1.0)

	if _max <= 0:
		return

	var radius := (WIDTH - PAD * 2.0) * 0.5
	var cx := WIDTH * 0.5
	var natural_step := radius * 2.0 + 4.0
	var min_step := maxf(radius * 0.4, 4.0)

	var step := natural_step
	if _max > 1:
		var ideal := (_height - PAD * 2.0 - radius * 2.0) / float(_max - 1)
		step = clampf(ideal, min_step, natural_step)

	# Draw bottom-to-top so index 0 (the next-to-grab) renders on top
	for i in range(_max - 1, -1, -1):
		var cy := PAD + radius + float(i) * step
		var filled := i < _current
		draw_circle(Vector2(cx, cy), radius, Palette.COLOR_MANA_DROPLET if filled else Palette.COLOR_MANA_EMPTY)
		draw_arc(Vector2(cx, cy), radius, 0.0, TAU, 24, Palette.COLOR_MANA_BORDER, 1.0)

class_name Explosion
extends Node2D
## Short-lived explosion: expanding ring + shrinking fireball + sparks.
## Pure _draw(), frees itself when the animation ends.

var _t := 0.0
var _life := 0.45
var _radius := 46.0
var _color := Color(1.0, 0.6, 0.2)
var _sparks: Array[Vector2] = []

func setup(pos: Vector2, radius: float, color: Color) -> void:
	position = pos
	_radius = radius
	_color = color
	for i in 10:
		_sparks.append(Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30.0, 95.0))

func _process(delta: float) -> void:
	_t += delta
	if _t >= _life:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := _t / _life
	var fade := 1.0 - k
	draw_circle(Vector2.ZERO, _radius * (0.4 + 0.6 * k), Color(_color, 0.35 * fade))
	draw_circle(Vector2.ZERO, _radius * 0.55 * fade + 4.0, Color(1.0, 0.85, 0.4, 0.8 * fade))
	draw_arc(Vector2.ZERO, _radius * k + 6.0, 0, TAU, 36, Color(_color, fade), 3.0)
	for s in _sparks:
		draw_circle(s * k, 3.0, Color(1.0, 0.8, 0.45, fade))

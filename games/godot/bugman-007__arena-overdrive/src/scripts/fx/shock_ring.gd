class_name ShockRing
extends Node2D
## Expanding, fading ring driven by `t` (0..1).

var color: Color = Color.WHITE
var max_radius: float = 100.0
var width: float = 6.0
var t: float = 0.0:
	set(v):
		t = v
		queue_redraw()


func _draw() -> void:
	var r := max_radius * t
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(color, 1.0 - t), width * (1.0 - t * 0.6), true)
	draw_circle(Vector2.ZERO, r, Color(color, 0.12 * (1.0 - t)))

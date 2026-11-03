extends Control

const BG_COLOR := Color(0.13, 0.15, 0.19)
const RING_COLOR := Color(0.35, 0.39, 0.47)
const GUIDE_COLOR := Color(0.25, 0.28, 0.34)
const KNOB_COLOR := Color(0.36, 0.72, 1.0)
const STEM_COLOR := Color(0.36, 0.72, 1.0, 0.35)

@export var axis_x: int = JOY_AXIS_LEFT_X
@export var axis_y: int = JOY_AXIS_LEFT_Y
@export var radius: float = 110.0
@export var deadzone: float = 0.2

var device: int = -1
var value: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * (radius * 2.0 + 8.0)


func _process(_delta: float) -> void:
	var current := Vector2.ZERO
	if device >= 0:
		current = Vector2(
			Input.get_joy_axis(device, axis_x),
			Input.get_joy_axis(device, axis_y)
		)
	if not current.is_equal_approx(value):
		value = current
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, BG_COLOR)
	draw_line(center - Vector2(radius, 0.0), center + Vector2(radius, 0.0), GUIDE_COLOR, 1.0)
	draw_line(center - Vector2(0.0, radius), center + Vector2(0.0, radius), GUIDE_COLOR, 1.0)
	draw_arc(center, radius * deadzone, 0.0, TAU, 32, GUIDE_COLOR, 1.0, true)
	draw_arc(center, radius, 0.0, TAU, 64, RING_COLOR, 2.0, true)

	var knob := center + value.limit_length(1.0) * radius
	draw_line(center, knob, STEM_COLOR, 3.0, true)
	draw_circle(knob, 12.0, KNOB_COLOR)

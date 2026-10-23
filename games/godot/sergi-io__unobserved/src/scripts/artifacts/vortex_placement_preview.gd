class_name VortexPlacementPreview
extends Node2D

@export var radius: float = 900.0
@export var line_width: float = 3.0
@export var bullet_radius: float = 6.0
@export var valid_color: Color = Color(0.12, 1.0, 0.28, 1.0)
@export var invalid_color: Color = Color(1.0, 0.0, 0.0, 1.0)

var _is_valid_placement: bool = true


func configure(preview_radius: float) -> void:
	radius = maxf(preview_radius, 1.0)
	queue_redraw()


func set_valid_placement(is_valid_placement: bool) -> void:
	if _is_valid_placement == is_valid_placement:
		return

	_is_valid_placement = is_valid_placement
	queue_redraw()


func _draw() -> void:
	var reticle_color := valid_color if _is_valid_placement else invalid_color
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, reticle_color, line_width, true)
	draw_circle(Vector2.ZERO, bullet_radius, reticle_color)

	if not _is_valid_placement:
		var cross_half_size := maxf(radius * 0.28, 24.0)
		var cross_width := maxf(line_width * 1.6, 3.0)
		draw_line(
			Vector2(-cross_half_size, -cross_half_size),
			Vector2(cross_half_size, cross_half_size),
			invalid_color,
			cross_width,
			true
		)
		draw_line(
			Vector2(-cross_half_size, cross_half_size),
			Vector2(cross_half_size, -cross_half_size),
			invalid_color,
			cross_width,
			true
		)

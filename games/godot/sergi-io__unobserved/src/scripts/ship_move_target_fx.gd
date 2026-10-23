extends Node2D
class_name ShipMoveTargetFx

@export_range(0.05, 2.0, 0.01) var duration: float = 0.48
@export_range(1.0, 128.0, 1.0) var start_radius: float = 18.0
@export_range(1.0, 128.0, 1.0) var end_radius: float = 44.0
@export_range(0.5, 12.0, 0.5) var ring_width: float = 3.0
@export var ring_color: Color = Color(0.42, 0.92, 1.0, 0.96)
@export var fill_color: Color = Color(0.42, 0.92, 1.0, 0.16)

var _elapsed: float = 0.0
var _tracked_world_position: Vector2 = Vector2.ZERO
var _tracks_canvas_overlay_position: bool = false


func configure(world_position: Vector2) -> void:
	_tracks_canvas_overlay_position = false
	scale = Vector2.ONE
	global_position = world_position
	_elapsed = 0.0
	queue_redraw()


func configure_canvas_overlay(world_position: Vector2) -> void:
	_tracked_world_position = world_position
	_tracks_canvas_overlay_position = true
	_elapsed = 0.0
	_sync_canvas_overlay_position()
	queue_redraw()


func _process(delta: float) -> void:
	if _tracks_canvas_overlay_position:
		_sync_canvas_overlay_position()

	_elapsed += maxf(delta, 0.0)
	if _elapsed >= maxf(duration, 0.001):
		queue_free()
		return

	queue_redraw()


func _sync_canvas_overlay_position() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var canvas_transform := viewport.get_canvas_transform()
	position = canvas_transform * _tracked_world_position
	scale = canvas_transform.get_scale()


func _draw() -> void:
	var progress := clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var eased_progress := 1.0 - pow(1.0 - progress, 3.0)
	var fade := 1.0 - progress
	var radius := lerpf(start_radius, end_radius, eased_progress)

	var current_fill_color := fill_color
	current_fill_color.a *= fade
	draw_circle(Vector2.ZERO, radius * 0.72, current_fill_color)

	var current_ring_color := ring_color
	current_ring_color.a *= fade
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, current_ring_color, ring_width, true)

	var tick_length := radius * 0.28
	var tick_gap := radius * 0.16
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(
			direction * (radius + tick_gap),
			direction * (radius + tick_gap + tick_length),
			current_ring_color,
			maxf(ring_width * 0.72, 1.0),
			true
		)

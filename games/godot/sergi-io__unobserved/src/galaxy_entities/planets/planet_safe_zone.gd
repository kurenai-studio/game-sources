class_name PlanetSafeZone
extends Node2D


@export_range(0.0, 50000.0, 1.0) var radius: float = 0.0:
	get:
		return _radius
	set(value):
		_radius = maxf(value, 0.0)

@export var fill_color: Color = Color(0.0, 1.0, 0.0, 0.1):
	get:
		return _fill_color
	set(value):
		_fill_color = value

@export_range(0.01, 1.0, 0.01) var reveal_start_scale: float = 0.04
@export_range(0.05, 2.0, 0.01) var reveal_duration: float = 0.56

var _radius: float = 0.0
var _fill_color: Color = Color(0.0, 1.0, 0.0, 0.3)
var _reveal_scale: float = 1.0:
	get:
		return _reveal_scale
	set(value):
		_reveal_scale = clampf(value, 0.01, 1.0)

var _reveal_alpha: float = 1.0:
	get:
		return _reveal_alpha
	set(value):
		_reveal_alpha = clampf(value, 0.0, 1.0)

var _reveal_tween: Tween


func _ready() -> void:
	visible = false


func reveal(delay: float = 0.0) -> void:
	if _radius <= 0.0:
		conceal()
		return

	_stop_reveal_tween()
	_reveal_scale = reveal_start_scale
	_reveal_alpha = 0.0

	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_QUAD)
	_reveal_tween.set_ease(Tween.EASE_OUT)
	var safe_delay := maxf(delay, 0.0)
	if safe_delay > 0.0:
		_reveal_tween.tween_interval(safe_delay)
	_reveal_tween.tween_property(self, "_reveal_scale", 1.0, reveal_duration)
	_reveal_tween.parallel().tween_property(self, "_reveal_alpha", 1.0, reveal_duration * 0.85)


func conceal() -> void:
	_stop_reveal_tween()
	_reveal_scale = 1.0
	_reveal_alpha = 1.0


func _stop_reveal_tween() -> void:
	if _reveal_tween != null and _reveal_tween.is_running():
		_reveal_tween.kill()

	_reveal_tween = null


func get_reveal_scale() -> float:
	return _reveal_scale


func get_effective_color() -> Color:
	return Color(_fill_color.r, _fill_color.g, _fill_color.b, _fill_color.a * _reveal_alpha)


func get_blocking_radius(margin: float = 0.0) -> float:
	return maxf(_radius + maxf(margin, 0.0), 0.0)


func contains_world_position(world_position: Vector2, margin: float = 0.0) -> bool:
	if _radius <= 0.0:
		return false

	return global_position.distance_to(world_position) <= get_blocking_radius(margin)

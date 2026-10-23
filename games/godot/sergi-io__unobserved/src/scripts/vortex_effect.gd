extends Node2D
class_name VortexEffect

const ENEMY_GROUP: StringName = &"enemies"
const PLAYER_GROUP: StringName = &"player_ships"
const PROCESS_PRIORITY_AFTER_ACTORS: int = 100
const VISUAL_FADE_IN_SECONDS: float = 0.12
const VISUAL_FADE_OUT_SECONDS: float = 0.55
const MIN_CAPTURE_SHADER_STRENGTH: float = 0.14
const EDGE_CAPTURE_ACCELERATION: float = 0.025
const GRAVITY_ACCELERATION_POWER: float = 1.45
const ORBIT_ACCELERATION_RESPONSE: float = 0.72
const ANGULAR_ACCELERATION_RESPONSE: float = 1.8
const ANGULAR_SPEED_MIN: float = 0.35
const ANGULAR_SPEED_MAX: float = 9.0
const RADIAL_SPEED_MIN_RATIO: float = 0.006
const RADIAL_SPEED_MAX_RATIO: float = 0.12
const ESCAPE_RELEASE_MARGIN: float = 2.0

@export_range(64.0, 5000.0, 1.0) var radius: float = 900.0
@export_range(0.1, 60.0, 0.1) var duration_seconds: float = 30.0
@export_range(0.0, 20000.0, 10.0) var pull_speed: float = 3600.0
@export_range(-12.0, 12.0, 0.1) var spin_speed: float = -2.8
@export var affects_bodies: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var _time_left: float = 0.0
var _age: float = 0.0
var _captured_nodes: Dictionary = {}
var _fog_alpha: float = 1.0
var _sprite_material: ShaderMaterial


func _ready() -> void:
	process_priority = PROCESS_PRIORITY_AFTER_ACTORS
	_time_left = maxf(duration_seconds, 0.1)
	_cache_sprite_material()
	_apply_sprite_scale()
	_apply_shader_parameters()


func configure(effect_radius: float, effect_duration_seconds: float, effect_pull_speed: float, should_affect_bodies: bool = true) -> void:
	radius = maxf(effect_radius, 1.0)
	duration_seconds = maxf(effect_duration_seconds, 0.1)
	pull_speed = maxf(effect_pull_speed, 0.0)
	affects_bodies = should_affect_bodies
	_time_left = duration_seconds
	_age = 0.0
	_apply_sprite_scale()
	_apply_shader_parameters()


func set_fog_presentation_alpha(alpha: float) -> void:
	_fog_alpha = clampf(alpha, 0.0, 1.0)
	_apply_visual_alpha()


func _process(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_age += safe_delta
	_time_left = maxf(_time_left - safe_delta, 0.0)
	rotation += spin_speed * safe_delta

	if affects_bodies:
		_capture_nearby_bodies()
		_pull_captured_bodies(safe_delta)

	_apply_visual_alpha()
	_apply_shader_parameters()

	if _time_left <= 0.0:
		queue_free()


func _capture_nearby_bodies() -> void:
	for node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		_capture_body_if_near(node as Node2D)
	for node in get_tree().get_nodes_in_group(PLAYER_GROUP):
		_capture_body_if_near(node as Node2D)


func _capture_body_if_near(body: Node2D) -> void:
	if not _is_body_valid(body):
		return
	if body.global_position.distance_to(global_position) > radius:
		return

	if not _captured_nodes.has(body):
		_captured_nodes[body] = _create_capture_state()


func _pull_captured_bodies(delta: float) -> void:
	if _captured_nodes.is_empty():
		return

	for body_key in _captured_nodes.keys():
		if not is_instance_valid(body_key):
			_captured_nodes.erase(body_key)
			continue

		var body := body_key as Node2D
		if not _is_body_valid(body):
			_captured_nodes.erase(body_key)
			continue

		_pull_body(body, body_key, delta)


func _pull_body(body: Node2D, body_key, delta: float) -> void:
	var from_center := body.global_position - global_position
	var distance_to_center := from_center.length()
	if distance_to_center <= 0.001:
		var centered_state := _get_capture_state(body_key)
		centered_state["acceleration"] = 1.0
		centered_state["angular_speed"] = 0.0
		_apply_body_vortex_capture(body, 1.0, delta)
		return

	if distance_to_center > radius + ESCAPE_RELEASE_MARGIN:
		_captured_nodes.erase(body_key)
		return

	var normalized_distance := clampf(distance_to_center / maxf(radius, 1.0), 0.0, 1.0)
	var proximity := 1.0 - normalized_distance
	var acceleration_target := clampf(EDGE_CAPTURE_ACCELERATION + pow(proximity, GRAVITY_ACCELERATION_POWER) * (1.0 - EDGE_CAPTURE_ACCELERATION), 0.0, 1.0)
	var capture_state := _get_capture_state(body_key)
	var capture_acceleration := float(capture_state.get("acceleration", 0.0))
	var acceleration_response := lerpf(0.28, ORBIT_ACCELERATION_RESPONSE, acceleration_target)
	capture_acceleration = move_toward(capture_acceleration, acceleration_target, acceleration_response * delta)
	var orbit_direction := -1.0 if spin_speed < 0.0 else 1.0
	var angular_speed := float(capture_state.get("angular_speed", 0.0))
	var angular_target := orbit_direction * lerpf(ANGULAR_SPEED_MIN, ANGULAR_SPEED_MAX, pow(capture_acceleration, 1.1))
	angular_speed = move_toward(angular_speed, angular_target, ANGULAR_ACCELERATION_RESPONSE * delta)
	capture_state["acceleration"] = capture_acceleration
	capture_state["angular_speed"] = angular_speed

	var radial_speed := pull_speed * lerpf(RADIAL_SPEED_MIN_RATIO, RADIAL_SPEED_MAX_RATIO, pow(capture_acceleration, 1.45))
	var next_radius := maxf(distance_to_center - radial_speed * delta, 0.0)
	var next_angle := from_center.angle() + angular_speed * delta
	body.global_position = global_position + Vector2.RIGHT.rotated(next_angle) * next_radius

	var capture_strength := clampf(lerpf(MIN_CAPTURE_SHADER_STRENGTH, 1.0, capture_acceleration), 0.0, 1.0)
	_apply_body_vortex_capture(body, capture_strength, delta)


func _apply_body_vortex_capture(body: Node2D, capture_strength: float, delta: float) -> void:
	if body.has_method("apply_vortex_capture"):
		body.call("apply_vortex_capture", global_position, clampf(capture_strength, 0.0, 1.0), delta)


func _create_capture_state() -> Dictionary:
	return {
		"acceleration": 0.0,
		"angular_speed": 0.0,
	}


func _get_capture_state(body_key) -> Dictionary:
	var state = _captured_nodes.get(body_key, {})
	if state is Dictionary:
		return state as Dictionary

	var migrated_state := _create_capture_state()
	migrated_state["acceleration"] = clampf(float(state), 0.0, 1.0)
	_captured_nodes[body_key] = migrated_state
	return migrated_state


func _is_body_valid(body: Node2D) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if body.has_method("is_destroyed") and bool(body.call("is_destroyed")):
		return false

	return true


func _apply_sprite_scale() -> void:
	if sprite == null or sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var diameter := radius * 2.0
	sprite.scale = Vector2(diameter / texture_size.x, diameter / texture_size.y)


func _cache_sprite_material() -> void:
	if sprite == null:
		_sprite_material = null
		return

	_sprite_material = sprite.material as ShaderMaterial


func _apply_shader_parameters() -> void:
	if _sprite_material == null:
		_cache_sprite_material()
	if _sprite_material == null:
		return

	var life_ratio := 0.0
	if duration_seconds > 0.0:
		life_ratio = clampf(_time_left / duration_seconds, 0.0, 1.0)

	_sprite_material.set_shader_parameter("life_ratio", life_ratio)


func _apply_visual_alpha() -> void:
	var fade_in := clampf(_age / VISUAL_FADE_IN_SECONDS, 0.0, 1.0)
	var fade_out := clampf(_time_left / VISUAL_FADE_OUT_SECONDS, 0.0, 1.0)
	var alpha := minf(fade_in, fade_out) * _fog_alpha
	modulate = Color(1.0, 1.0, 1.0, alpha)

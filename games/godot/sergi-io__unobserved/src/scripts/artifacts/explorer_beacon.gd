extends Node2D
class_name ExplorerBeacon

const DAMAGE_IMPACT_FX_SCRIPT: Script = preload("res://scripts/damage_impact_fx.gd")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const EXPLORER_BEACON_GROUP: StringName = &"explorer_beacons"
const FOG_PRESENTATION_VISIBLE_EPSILON: float = 0.01
const SPRITE_VISIBLE_ALPHA: float = 1.0
const OUT_OF_BOUNDS_MARGIN: float = 50.0
const THRUSTER_OFFSET: float = 30.0

@export_range(1, 999, 1) var hit_points: int = 4
@export_range(0.0, 3.0, 0.01) var deploy_duration: float = 0.55
@export_range(0.0, 12000.0, 10.0) var deploy_forward_speed: float = 150.0
@export_range(0.0, 1.0, 0.01) var deploy_settle_duration: float = 0.08
@export_range(0.0, 2.0, 0.01) var flight_z_index_delay: float = 1.0
@export_range(0.0, 12000.0, 10.0) var launch_speed: float = 120.0
@export_range(100.0, 24000.0, 50.0) var travel_speed: float = 200.0
@export_range(100.0, 24000.0, 10.0) var acceleration: float = 100.0
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var sprite_forward_rotation_offset: float = -PI * 0.5
@export_range(64.0, 20000.0, 10.0) var vision_radius: float = 1800.0
@export_range(1000.0, 200000.0, 100.0) var world_radius: float = 100000.0
@export var deploy_z_index: int = -100
@export var flight_z_index: int = 0
@export var owner_peer_id: int = 0
@export var network_id: int = 0
@export var broadcast_destroy_on_destroy: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var thruster: CPUParticles2D = get_node_or_null("FireTail") as CPUParticles2D

var _direction: Vector2 = Vector2.RIGHT
var _deploy_direction: Vector2 = Vector2.RIGHT
var _velocity: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var _deploy_time_left: float = 0.0
var _deploy_settle_time_left: float = 0.0
var _flight_z_index_delay_left: float = 0.0
var _has_ignited: bool = false
var _current_hit_points: int = 4
var _is_destroyed: bool = false
var _fog_alpha: float = 0.0


func _ready() -> void:
	add_to_group(EXPLORER_BEACON_GROUP)
	_current_hit_points = maxi(hit_points, 1)
	_set_thruster_emitting(false)
	_update_thruster_transform()
	_apply_presentation_state()
	GAME_SFX.play(self, GAME_SFX.CUE_SCANNER, -2.0, randf_range(0.97, 1.03))


func configure(
	launch_origin: Vector2,
	travel_direction: Vector2,
	speed_value: float,
	vision_radius_value: float,
	hit_points_value: int,
	world_radius_value: float,
	owner_peer_id_value: int,
	network_id_value: int = 0,
	should_broadcast_destroy: bool = false,
	deploy_direction_value: Vector2 = Vector2.ZERO
) -> void:
	global_position = launch_origin
	_direction = travel_direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_deploy_direction = deploy_direction_value.normalized()
	if _deploy_direction == Vector2.ZERO:
		_deploy_direction = _direction
	travel_speed = maxf(speed_value, 1.0)
	vision_radius = maxf(vision_radius_value, 1.0)
	hit_points = maxi(hit_points_value, 1)
	_current_hit_points = hit_points
	world_radius = maxf(world_radius_value, 1.0)
	owner_peer_id = owner_peer_id_value
	network_id = network_id_value
	broadcast_destroy_on_destroy = should_broadcast_destroy
	z_index = deploy_z_index
	rotation = 0.0
	_update_sprite_travel_rotation()
	_deploy_time_left = deploy_duration
	_deploy_settle_time_left = deploy_settle_duration
	_flight_z_index_delay_left = 0.0
	_has_ignited = false
	_current_speed = 0.0
	_velocity = Vector2.ZERO
	_is_destroyed = false
	_set_thruster_emitting(false)
	_update_thruster_transform()
	if is_zero_approx(_deploy_time_left):
		_ignite()
	_apply_presentation_state()


func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return

	var safe_delta := maxf(delta, 0.0)
	var movement_delta := safe_delta
	if _deploy_time_left > 0.0:
		var deploy_delta := minf(movement_delta, _deploy_time_left)
		_update_deploy_motion(deploy_delta)
		_deploy_time_left = maxf(_deploy_time_left - deploy_delta, 0.0)
		movement_delta = maxf(movement_delta - deploy_delta, 0.0)
		if _deploy_time_left > 0.0:
			return
		_velocity = Vector2.ZERO
		if _deploy_settle_time_left > 0.0 or is_zero_approx(movement_delta):
			return
		_ignite()

	if _deploy_settle_time_left > 0.0:
		var settle_delta := minf(movement_delta, _deploy_settle_time_left)
		_deploy_settle_time_left = maxf(_deploy_settle_time_left - settle_delta, 0.0)
		if _deploy_settle_time_left > 0.0:
			return
		_ignite()
		return

	_update_flight_velocity(movement_delta)
	_update_flight_z_index_delay(safe_delta)
	global_position += _velocity * movement_delta
	if _is_out_of_world_bounds():
		queue_free()


func set_fog_presentation_alpha(alpha: float) -> void:
	_fog_alpha = clampf(alpha, 0.0, 1.0)
	_apply_presentation_state()


func set_fog_presentation_visible(is_visible: bool) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0)


func get_vision_radius() -> float:
	return maxf(vision_radius, 1.0)


func get_owner_peer_id() -> int:
	return owner_peer_id


func is_destroyed() -> bool:
	return _is_destroyed


func is_invisible() -> bool:
	return false


func is_attack_targetable() -> bool:
	return not _is_destroyed


func get_touch_radius() -> float:
	if sprite == null or sprite.texture == null:
		return 32.0

	var texture_size := sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return 32.0

	var scaled_size := texture_size * sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func get_damage_impact_radius() -> float:
	return get_touch_radius()


func get_damage_impact_position(source_world_position: Vector2 = Vector2.INF) -> Vector2:
	if sprite != null and sprite.texture != null:
		return DAMAGE_IMPACT_FX_SCRIPT.get_sprite_impact_position(sprite, source_world_position, global_position)

	var to_source := global_position - source_world_position
	if to_source.length_squared() <= 0.001:
		return global_position

	return global_position - to_source.normalized() * get_touch_radius()


func take_damage(amount: int, impact_world_position: Vector2 = Vector2.INF, should_spawn_hit_fx: bool = true) -> int:
	if _is_destroyed or amount <= 0:
		return 0

	var applied_damage := mini(amount, _current_hit_points)
	if applied_damage <= 0:
		return 0

	var resolved_impact := impact_world_position
	if should_spawn_hit_fx and not resolved_impact.is_finite():
		resolved_impact = get_damage_impact_position(global_position - _direction * get_touch_radius())

	_current_hit_points = maxi(_current_hit_points - applied_damage, 0)
	if should_spawn_hit_fx:
		_spawn_damage_sparks(resolved_impact)
	if _current_hit_points <= 0:
		_destroy_beacon()

	return applied_damage


func _destroy_beacon() -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	visible = false
	_set_thruster_emitting(false)
	if broadcast_destroy_on_destroy and network_id > 0:
		_broadcast_destroyed()
	queue_free()


func _broadcast_destroyed() -> void:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null or not scene_root.has_method("client_explorer_beacon_destroyed"):
		return
	if multiplayer.multiplayer_peer == null:
		return

	scene_root.rpc("client_explorer_beacon_destroyed", network_id)


func _spawn_damage_sparks(impact_world_position: Vector2) -> void:
	if not impact_world_position.is_finite():
		return

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	DAMAGE_IMPACT_FX_SCRIPT.spawn_sparks(
		fx_layer,
		impact_world_position,
		_get_damage_spark_direction(impact_world_position),
		_fog_alpha > FOG_PRESENTATION_VISIBLE_EPSILON,
		18,
		0.32,
		0.9,
		0.66,
		92.0,
		70.0,
		280.0,
		620.0,
		Color(0.42, 0.92, 1.0, 0.86)
	)


func _get_damage_spark_direction(impact_world_position: Vector2) -> Vector2:
	var impact_direction := impact_world_position - global_position
	if impact_direction.length_squared() > 0.001:
		return impact_direction.normalized()

	return -_direction


func _get_fx_layer() -> Node2D:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root != null:
		var root_fx_layer := scene_root.find_child("FXLayer", true, false) as Node2D
		if root_fx_layer != null:
			return root_fx_layer

	return get_parent() as Node2D


func _ignite() -> void:
	if _has_ignited:
		return

	_has_ignited = true
	_flight_z_index_delay_left = maxf(flight_z_index_delay, 0.0)
	if is_zero_approx(_flight_z_index_delay_left):
		z_index = flight_z_index
	_current_speed = minf(maxf(launch_speed, 0.0), travel_speed)
	_velocity = _direction * _current_speed
	_set_thruster_emitting(true)
	_update_thruster_transform()


func _update_deploy_motion(delta: float) -> void:
	if deploy_forward_speed <= 0.0:
		return

	global_position += _deploy_direction * deploy_forward_speed * delta
	_update_thruster_transform()


func _update_flight_velocity(delta: float) -> void:
	_current_speed = move_toward(_current_speed, travel_speed, maxf(acceleration, 0.0) * delta)
	_velocity = _direction * _current_speed
	_update_thruster_transform()


func _update_sprite_travel_rotation() -> void:
	if sprite == null:
		return

	sprite.rotation = _direction.angle() + sprite_forward_rotation_offset


func _update_flight_z_index_delay(delta: float) -> void:
	if not _has_ignited or _flight_z_index_delay_left <= 0.0:
		return

	_flight_z_index_delay_left = maxf(_flight_z_index_delay_left - delta, 0.0)
	if is_zero_approx(_flight_z_index_delay_left):
		z_index = flight_z_index


func _set_thruster_emitting(is_emitting: bool) -> void:
	if thruster == null:
		return

	thruster.emitting = is_emitting


func _update_thruster_transform() -> void:
	if thruster == null:
		return

	thruster.position = -_direction * THRUSTER_OFFSET
	thruster.rotation = _direction.angle() + PI


func _is_out_of_world_bounds() -> bool:
	var bound := maxf(world_radius, 1.0) + OUT_OF_BOUNDS_MARGIN
	return absf(global_position.x) > bound or absf(global_position.y) > bound


func _apply_presentation_state() -> void:
	visible = not _is_destroyed
	if sprite == null:
		return

	var sprite_color := sprite.modulate
	sprite_color.a = SPRITE_VISIBLE_ALPHA
	sprite.modulate = sprite_color

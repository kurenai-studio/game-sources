extends Node2D
class_name HomingMissile

const ENEMY_GROUP: StringName = &"enemies"
const PLAYER_GROUP: StringName = &"player_ships"
const EXPLORER_BEACON_GROUP: StringName = &"explorer_beacons"
const SHIP_EXPLOSION_SCENE: PackedScene = preload("res://scenes/ship_explosion_fx.tscn")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const MIN_DETONATION_DISTANCE: float = 20.0
const SPRITE_FORWARD_ROTATION_OFFSET: float = PI * 0.5

@export var ship_path: NodePath = NodePath("../Ship")

@export_group("Homing")
@export_range(0.0, 3.0, 0.01) var deploy_duration: float = 0.4
@export_range(0.0, 1000.0, 5.0) var deploy_forward_speed: float = 120.0
@export_range(0.0, 1000.0, 5.0) var deploy_lateral_speed: float = 70.0
@export_range(0.0, 1.0, 0.01) var deploy_settle_duration: float = 0.08
@export_range(0.0, 12000.0, 10.0) var launch_speed: float = 140.0
@export_range(100.0, 12000.0, 10.0) var speed: float = 1550.0
@export_range(100.0, 24000.0, 10.0) var acceleration: float = 2600.0
@export_range(1.0, 90.0, 1.0) var turn_speed: float = 10.0
@export_range(100.0, 12000.0, 10.0) var target_search_radius: float = 3400.0
@export_range(30.0, 2000.0, 5.0) var cluster_radius: float = 260.0

@export_group("Firing")
@export_range(0.1, 10.0, 0.05) var fire_interval: float = 1.2
@export_range(0.0, 2.0, 0.01) var volley_delay: float = 0.2

@export_group("Impact")
@export_range(1, 999, 1) var damage_per_enemy: int = 2
@export_range(30.0, 1000.0, 5.0) var impact_radius: float = 180.0
@export_range(0.5, 12.0, 0.1) var lifetime: float = 4.0
@export_range(0.05, 0.5, 0.01) var impact_fx_duration: float = 0.12

@export_group("Layering")
@export var deploy_z_index: int = -520
@export var flight_z_index: int = 0
@export var owner_peer_id: int = 0
@export var deals_damage: bool = true

@onready var missile_sprite: Sprite2D = $Sprite2D
@onready var fire_tail: CPUParticles2D = get_node_or_null("FireTail") as CPUParticles2D

var _ship: Node2D
var _target: Node2D
var _fallback_target_position: Vector2 = Vector2.ZERO
var _fallback_target_position_valid: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _launch_direction: Vector2 = Vector2.ZERO
var _deploy_lateral_sign: float = 1.0
var _current_speed: float = 0.0
var _time_left: float = 0.0
var _deploy_time_left: float = 0.0
var _deploy_settle_time_left: float = 0.0
var _has_ignited: bool = false
var _is_exploding: bool = false
var _impact_tween: Tween
var _is_fog_presentation_visible: bool = true


func _ready() -> void:
	_time_left = lifetime
	_resolve_ship()
	_set_fire_tail_emitting(false)
	_apply_presentation_state()


func initialize(
	initial_target: Node2D,
	launch_direction_value: Vector2 = Vector2.ZERO,
	deploy_lateral_sign_value: float = 1.0,
	fallback_target_position_value: Vector2 = Vector2.ZERO,
	fallback_target_position_valid_value: bool = false
) -> void:
	_target = initial_target
	_fallback_target_position = fallback_target_position_value
	_fallback_target_position_valid = fallback_target_position_valid_value
	_launch_direction = launch_direction_value.normalized() if launch_direction_value != Vector2.ZERO else Vector2.ZERO
	_deploy_lateral_sign = -1.0 if deploy_lateral_sign_value < 0.0 else 1.0
	_time_left = lifetime
	_deploy_time_left = deploy_duration
	_deploy_settle_time_left = deploy_settle_duration
	_has_ignited = false
	_current_speed = 0.0
	_velocity = Vector2.ZERO
	_resolve_ship()
	_set_deploy_rotation()
	z_index = deploy_z_index
	_set_fire_tail_emitting(false)
	if is_zero_approx(_deploy_time_left):
		_ignite()


func set_fog_presentation_visible(is_visible: bool) -> void:
	_is_fog_presentation_visible = is_visible
	_apply_presentation_state()


func _apply_presentation_state() -> void:
	visible = _is_fog_presentation_visible


func _physics_process(delta: float) -> void:
	if _is_exploding:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	if _time_left <= 0.0:
		_explode()
		return

	if not _is_target_valid():
		_acquire_target()

	var movement_delta := delta
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

	_update_velocity(movement_delta)
	global_position += _velocity * movement_delta

	if _velocity != Vector2.ZERO:
		rotation = _velocity.angle() + SPRITE_FORWARD_ROTATION_OFFSET

	if _target != null and is_instance_valid(_target):
		var detonation_distance := maxf(MIN_DETONATION_DISTANCE, minf(impact_radius * 0.25, 60.0))
		if global_position.distance_to(_target.global_position) <= detonation_distance:
			_explode()
	elif _fallback_target_position_valid:
		var detonation_distance := maxf(MIN_DETONATION_DISTANCE, minf(impact_radius * 0.25, 60.0))
		if global_position.distance_to(_fallback_target_position) <= detonation_distance:
			_explode()


func _resolve_ship() -> void:
	_ship = get_node_or_null(ship_path) as Node2D


func _prime_velocity() -> void:
	var launch_direction := _launch_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()

	_current_speed = minf(maxf(launch_speed, 0.0), speed)
	_velocity = launch_direction * _current_speed
	if _velocity != Vector2.ZERO:
		rotation = _velocity.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _set_deploy_rotation() -> void:
	var launch_direction := _launch_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()
	rotation = launch_direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _ignite() -> void:
	if _has_ignited:
		return

	_has_ignited = true
	z_index = flight_z_index
	_prime_velocity()
	_set_fire_tail_emitting(true)
	GAME_SFX.play(self, GAME_SFX.CUE_MISSILE_LAUNCH)


func _update_deploy_motion(delta: float) -> void:
	if deploy_forward_speed <= 0.0 and deploy_lateral_speed <= 0.0:
		return

	var launch_direction := _launch_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()
	var lateral_direction := launch_direction.rotated(PI * 0.5 * _deploy_lateral_sign)
	var deploy_velocity := launch_direction * deploy_forward_speed + lateral_direction * deploy_lateral_speed
	global_position += deploy_velocity * delta
	rotation = launch_direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _update_velocity(delta: float) -> void:
	var travel_direction := _get_travel_direction()
	if _target != null and is_instance_valid(_target):
		var desired_direction := (_target.global_position - global_position).normalized()
		if desired_direction != Vector2.ZERO:
			var max_turn_step := maxf(turn_speed, 0.0) * delta
			travel_direction = travel_direction.rotated(clampf(travel_direction.angle_to(desired_direction), -max_turn_step, max_turn_step))
	elif _fallback_target_position_valid:
		var desired_direction := (_fallback_target_position - global_position).normalized()
		if desired_direction != Vector2.ZERO:
			var max_turn_step := maxf(turn_speed, 0.0) * delta
			travel_direction = travel_direction.rotated(clampf(travel_direction.angle_to(desired_direction), -max_turn_step, max_turn_step))

	_current_speed = minf(_current_speed + acceleration * delta, speed)
	_velocity = travel_direction * _current_speed


func _get_travel_direction() -> Vector2:
	if _velocity != Vector2.ZERO:
		return _velocity.normalized()

	return _get_forward_direction()


func _get_forward_direction() -> Vector2:
	var forward := Vector2.UP.rotated(rotation)
	if forward == Vector2.ZERO:
		return Vector2.UP

	return forward.normalized()


func _is_target_valid() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false

	if _target.has_method("is_destroyed") and bool(_target.call("is_destroyed")):
		return false
	if _target.has_method("is_invisible") and bool(_target.call("is_invisible")):
		return false

	return true


func _acquire_target() -> void:
	_resolve_ship()
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("get_homing_missile_target"):
		_target = _ship.call("get_homing_missile_target", global_position, target_search_radius, cluster_radius) as Node2D
		if _target != null and is_instance_valid(_target):
			return

	_target = _find_best_local_target()


func _find_best_local_target() -> Node2D:
	var enemy_candidates: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := candidate as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to(enemy.global_position) > target_search_radius:
			continue

		enemy_candidates.append(enemy)

	for candidate in get_tree().get_nodes_in_group(PLAYER_GROUP):
		var player_ship := candidate as Node2D
		if not _is_player_ship_targetable(player_ship):
			continue
		if global_position.distance_to(player_ship.global_position) > target_search_radius:
			continue

		enemy_candidates.append(player_ship)

	for candidate in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
		var beacon := candidate as Node2D
		if not _is_explorer_beacon_targetable(beacon):
			continue
		if global_position.distance_to(beacon.global_position) > target_search_radius:
			continue

		enemy_candidates.append(beacon)

	if enemy_candidates.is_empty():
		return null

	var best_enemy: Node2D
	var best_cluster_size := -1
	var best_distance := INF
	for enemy in enemy_candidates:
		var cluster_size := 1
		for other_enemy in enemy_candidates:
			if enemy == other_enemy:
				continue
			if enemy.global_position.distance_to(other_enemy.global_position) <= cluster_radius:
				cluster_size += 1

		var distance_to_origin := global_position.distance_to(enemy.global_position)
		if cluster_size > best_cluster_size or (cluster_size == best_cluster_size and distance_to_origin < best_distance):
			best_cluster_size = cluster_size
			best_distance = distance_to_origin
			best_enemy = enemy

	return best_enemy


func _is_player_ship_targetable(player_ship: Node2D) -> bool:
	if player_ship == null or not is_instance_valid(player_ship):
		return false
	if not player_ship.has_method("take_damage"):
		return false
	if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
		return false
	if player_ship.has_method("is_invisible") and bool(player_ship.call("is_invisible")):
		return false
	if player_ship.has_method("get_owner_peer_id") and int(player_ship.call("get_owner_peer_id")) == owner_peer_id:
		return false

	return true


func _is_explorer_beacon_targetable(beacon: Node2D) -> bool:
	if beacon == null or not is_instance_valid(beacon):
		return false
	if not beacon.has_method("take_damage"):
		return false
	if beacon.has_method("is_destroyed") and bool(beacon.call("is_destroyed")):
		return false
	if beacon.has_method("is_attack_targetable") and not bool(beacon.call("is_attack_targetable")):
		return false
	if beacon.has_method("get_owner_peer_id") and int(beacon.call("get_owner_peer_id")) == owner_peer_id:
		return false

	return true


func _explode() -> void:
	if _is_exploding:
		return

	_is_exploding = true
	_apply_area_damage()
	_play_explosion_effect()


func _apply_area_damage() -> void:
	if not deals_damage:
		return

	if damage_per_enemy <= 0:
		return

	var damage_multiplier := 1.0
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("get_safe_zone_attack_multiplier"):
		damage_multiplier = maxf(float(_ship.call("get_safe_zone_attack_multiplier")), 1.0)

	var applied_damage := maxi(1, int(round(float(damage_per_enemy) * damage_multiplier)))
	var impact_radius_squared := impact_radius * impact_radius
	for candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := candidate as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if global_position.distance_squared_to(enemy.global_position) > impact_radius_squared:
			continue

		enemy.call("take_damage", applied_damage)

	for candidate in get_tree().get_nodes_in_group(PLAYER_GROUP):
		var player_ship := candidate as Node2D
		if player_ship == null or not is_instance_valid(player_ship):
			continue
		if not player_ship.has_method("take_damage"):
			continue
		if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
			continue
		if player_ship.has_method("get_owner_peer_id") and int(player_ship.call("get_owner_peer_id")) == owner_peer_id:
			continue
		if global_position.distance_squared_to(player_ship.global_position) > impact_radius_squared:
			continue

		player_ship.call("take_damage", applied_damage)

	for candidate in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
		var beacon := candidate as Node2D
		if not _is_explorer_beacon_targetable(beacon):
			continue
		if global_position.distance_squared_to(beacon.global_position) > impact_radius_squared:
			continue

		beacon.call("take_damage", applied_damage)


func _play_explosion_effect() -> void:
	_velocity = Vector2.ZERO
	_set_fire_tail_emitting(false)
	_request_camera_shake()
	_spawn_explosion_fx()
	if missile_sprite != null:
		missile_sprite.visible = false

	if _impact_tween != null:
		_impact_tween.kill()

	_impact_tween = create_tween()
	_impact_tween.tween_interval(maxf(impact_fx_duration, 0.02))
	_impact_tween.tween_callback(Callable(self, "queue_free"))


func _request_camera_shake() -> void:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null or not scene_root.has_method("request_camera_shake"):
		return

	var intensity := 0.42
	for property in scene_root.get_property_list():
		if StringName(property.get("name", "")) == &"homing_missile_camera_shake_intensity":
			intensity = float(scene_root.get(&"homing_missile_camera_shake_intensity"))
			break

	scene_root.call("request_camera_shake", intensity, global_position)


func _spawn_explosion_fx() -> void:
	if not _is_fog_presentation_visible:
		return

	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null:
		return

	var fx_layer := scene_root.get_node_or_null("FXLayer") as Node2D
	if fx_layer == null:
		return
	if not ShipExplosionFx.can_spawn_active_explosion(get_tree()):
		return

	var explosion := SHIP_EXPLOSION_SCENE.instantiate() as Node2D
	if explosion == null:
		return

	fx_layer.add_child(explosion)
	if explosion.has_method("configure_from_source"):
		var explosion_scale := maxf(impact_radius / 180.0, 0.5)
		explosion.call("configure_from_source", self, NodePath("Sprite2D"), 0.0, explosion_scale)
	if explosion.has_method("set_fog_presentation_visible"):
		explosion.call("set_fog_presentation_visible", _is_fog_presentation_visible)


func _set_fire_tail_emitting(is_emitting: bool) -> void:
	if fire_tail == null:
		return

	fire_tail.emitting = is_emitting

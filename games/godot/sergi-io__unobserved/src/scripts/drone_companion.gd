extends Node2D
class_name DroneCompanion

const ENEMY_GROUP: StringName = &"enemies"
const FIRE_LINE_COLOR: Color = Color(0.42, 0.95, 1.0, 0.9)
const SPRITE_FORWARD_ROTATION_OFFSET: float = -PI * 0.5

@export var ship_path: NodePath = NodePath("../Ship")

@export_group("Formation")
@export_range(24.0, 240.0, 1.0) var follow_distance: float = 124.0
@export_range(16.0, 240.0, 1.0) var formation_side_spacing: float = 38.0
@export_range(16.0, 240.0, 1.0) var formation_row_spacing: float = 36.0
@export_range(-240.0, 240.0, 1.0) var formation_back_offset: float = 118.0
@export_range(1, 8, 1) var formation_side_lanes: int = 5
@export_range(1, 16, 1) var formation_side_columns: int = 8
@export_range(0.0, 24.0, 0.01) var follow_speed: float = 10.0
@export_range(0.0, 1.5, 0.01) var follow_delay_seconds: float = 0.22
@export_range(0.0, 16.0, 0.01) var snap_distance_multiplier: float = 8.0
@export_range(0.0, 1.0, 0.01) var formation_bob_amount: float = 0.04
@export_range(0.0, 8.0, 0.01) var formation_bob_speed: float = 1.1
@export_range(0.0, 48.0, 0.5) var formation_wander_amount: float = 14.0
@export_range(0.0, 8.0, 0.01) var formation_wander_speed: float = 1.55

@export_group("Interceptor")
@export_range(100.0, 2400.0, 10.0) var intercept_speed: float = 820.0
@export_range(100.0, 8000.0, 10.0) var intercept_acceleration: float = 1400.0
@export_range(100.0, 8000.0, 10.0) var intercept_deceleration: float = 1800.0
@export_range(100.0, 3600.0, 10.0) var return_speed: float = 1250.0
@export_range(100.0, 8000.0, 10.0) var return_acceleration: float = 4200.0
@export_range(100.0, 8000.0, 10.0) var return_deceleration: float = 5200.0
@export_range(24.0, 240.0, 1.0) var intercept_attack_radius: float = 92.0
@export_range(4.0, 120.0, 1.0) var intercept_attack_tolerance: float = 24.0
@export_range(0.1, 3.0, 0.01) var intercept_orbit_speed: float = 0.65
@export_range(1.0, 4.0, 0.05) var intercept_leash_multiplier: float = 1.35

@export_group("Combat")
@export_range(100.0, 4000.0, 10.0) var attack_range: float = 1600.0
@export_range(0.05, 5.0, 0.05) var fire_interval: float = 1.15
@export_range(1, 999, 1) var damage_per_shot: int = 1
@export_range(0.02, 0.4, 0.01) var beam_duration: float = 0.08
@export_range(1.0, 20.0, 0.5) var beam_width: float = 4.5
@export_range(0.0, 1000.0, 1.0) var target_switch_distance: float = 96.0

@onready var drone_sprite: Sprite2D = $Sprite2D

var _ship: Node2D
var _fire_line: Line2D
var _elapsed: float = 0.0
var _fire_cooldown: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _base_rotation: float = 0.0
var _flight_velocity: Vector2 = Vector2.ZERO
var _beam_time_left: float = 0.0
var _target_enemy: Node2D
var _beam_target_world_position: Vector2 = Vector2.ZERO
var _beam_target_world_position_valid: bool = false
var _ship_transform_history: Array[Dictionary] = []
var owner_peer_id: int = 0
var drone_index: int = 0
var drone_count: int = 1
var is_server_authority: bool = false
var _is_network_presentation: bool = false
var _is_fog_presentation_visible: bool = true
var _owner_invisibility_alpha: float = 1.0


func _ready() -> void:
	_base_scale = scale
	_base_rotation = rotation
	_resolve_ship()
	_record_ship_transform_sample()
	_ensure_fire_line()
	_apply_presentation_state()


func _process(delta: float) -> void:
	_elapsed += delta
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_record_ship_transform_sample()
	_update_interceptor(delta)
	_update_beam(delta)


func set_network_identity(peer_id: int, network_drone_index: int, server_authority: bool) -> void:
	owner_peer_id = peer_id
	drone_index = network_drone_index
	is_server_authority = server_authority
	_is_network_presentation = true


func set_formation_slot(formation_index: int, formation_count: int) -> void:
	drone_index = formation_index
	drone_count = maxi(formation_count, 1)


func snap_to_formation() -> void:
	if _ship == null or not is_instance_valid(_ship):
		_resolve_ship()
	if _ship == null or not is_instance_valid(_ship):
		return

	var desired_position := _get_formation_world_position()
	global_position = desired_position
	_flight_velocity = Vector2.ZERO
	rotation = _base_rotation + _get_ship_forward_direction().angle() + SPRITE_FORWARD_ROTATION_OFFSET


func play_network_beam(target_world_position: Vector2) -> void:
	if _ship == null or not is_instance_valid(_ship):
		_resolve_ship()

	_target_enemy = null
	_show_beam(target_world_position)


func set_fog_presentation_visible(is_visible: bool) -> void:
	_is_fog_presentation_visible = is_visible
	_apply_presentation_state()
	if not _is_fog_presentation_visible:
		_hide_beam()


func set_owner_invisibility_alpha(alpha: float) -> void:
	_owner_invisibility_alpha = clampf(alpha, 0.0, 1.0)
	_apply_presentation_state()


func _apply_presentation_state() -> void:
	visible = _is_fog_presentation_visible
	var root_modulate := modulate
	root_modulate.a = 1.0
	modulate = root_modulate
	if drone_sprite != null:
		var sprite_modulate := drone_sprite.modulate
		sprite_modulate.a = _owner_invisibility_alpha
		drone_sprite.modulate = sprite_modulate
	_apply_fire_line_alpha()


func _resolve_ship() -> void:
	_ship = get_node_or_null(ship_path) as Node2D


func get_touch_radius() -> float:
	if drone_sprite == null or drone_sprite.texture == null:
		return 0.0

	var texture_size := drone_sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return 0.0

	var scaled_size := texture_size * drone_sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func _update_interceptor(delta: float) -> void:
	if _ship == null or not is_instance_valid(_ship):
		_resolve_ship()
		if _ship == null or not is_instance_valid(_ship):
			return

	if _is_owner_ship_vortex_captured():
		_target_enemy = null
		_fire_cooldown = maxf(_fire_cooldown, fire_interval)
		_hide_beam()
		_update_formation(delta)
		return

	var nearest_enemy := _find_nearest_enemy()
	if not _is_valid_enemy_target(_target_enemy) or not _is_enemy_inside_leash(_target_enemy):
		_target_enemy = nearest_enemy
	elif _should_switch_target(_target_enemy, nearest_enemy):
		_target_enemy = nearest_enemy

	if _target_enemy == null:
		_update_formation(delta)
		return

	_update_intercept_target(delta)


func _update_formation(delta: float, allow_snap: bool = false) -> void:
	if _ship == null or not is_instance_valid(_ship):
		_resolve_ship()
		if _ship == null or not is_instance_valid(_ship):
			return

	var desired_position := _get_formation_world_position()
	var snap_distance := maxf(follow_distance, formation_side_spacing) * snap_distance_multiplier
	if allow_snap and snap_distance > 0.0 and global_position.distance_squared_to(desired_position) > snap_distance * snap_distance:
		global_position = desired_position
		_flight_velocity = Vector2.ZERO
	else:
		_move_toward_world_position(
			desired_position,
			return_speed,
			return_acceleration,
			return_deceleration,
			delta,
			6.0
		)

	var target_rotation := _get_delayed_ship_forward_direction().angle() + SPRITE_FORWARD_ROTATION_OFFSET
	var rotation_weight := clampf(delta * follow_speed, 0.0, 1.0)
	rotation = lerp_angle(rotation, _base_rotation + target_rotation, rotation_weight)

	var bob_phase := _elapsed * formation_bob_speed + float(drone_index) * 0.73
	scale = _base_scale * (1.0 + sin(_elapsed * 2.4 + bob_phase) * 0.02)


func _update_intercept_target(delta: float) -> void:
	var target_enemy := _get_valid_enemy_target(_target_enemy)
	if target_enemy == null:
		_target_enemy = null
		_update_formation(delta)
		return

	var attack_position := _get_intercept_world_position(target_enemy)
	_move_toward_world_position(
		attack_position,
		intercept_speed,
		intercept_acceleration,
		intercept_deceleration,
		delta,
		intercept_attack_tolerance * 0.5
	)

	var target_direction := target_enemy.global_position - global_position
	if target_direction.length_squared() > 0.001:
		var rotation_weight := clampf(delta * follow_speed, 0.0, 1.0)
		rotation = lerp_angle(rotation, _base_rotation + target_direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET, rotation_weight)

	var bob_phase := _elapsed * formation_bob_speed + float(drone_index) * 0.73
	scale = _base_scale * (1.0 + sin(_elapsed * 3.2 + bob_phase) * 0.025)

	if global_position.distance_to(target_enemy.global_position) > intercept_attack_radius + intercept_attack_tolerance:
		return
	if _fire_cooldown > 0.0:
		return
	if _is_network_presentation and not is_server_authority:
		return

	_fire_at(target_enemy)
	_fire_cooldown = fire_interval


func _move_toward_world_position(
	target_world_position: Vector2,
	max_speed: float,
	acceleration_value: float,
	deceleration_value: float,
	delta: float,
	stop_distance: float = 0.0
) -> bool:
	var travel_vector := target_world_position - global_position
	var travel_distance := travel_vector.length()
	var safe_deceleration := maxf(deceleration_value, 1.0)
	var safe_delta := maxf(delta, 0.001)
	if travel_distance <= 0.001:
		_flight_velocity = _flight_velocity.move_toward(Vector2.ZERO, safe_deceleration * delta)
		return _flight_velocity.length_squared() <= 0.001

	var travel_direction := travel_vector / travel_distance
	var desired_velocity := Vector2.ZERO
	if travel_distance > stop_distance:
		var current_speed_toward_target := maxf(_flight_velocity.dot(travel_direction), 0.0)
		var stopping_distance := (current_speed_toward_target * current_speed_toward_target) / (2.0 * safe_deceleration)
		var distance_to_stop := maxf(travel_distance - stop_distance, 0.0)
		var desired_speed := maxf(max_speed, 0.0)
		if stopping_distance >= distance_to_stop:
			desired_speed = sqrt(maxf(0.0, 2.0 * safe_deceleration * distance_to_stop))

		desired_velocity = travel_direction * desired_speed

	var acceleration_rate := acceleration_value if desired_velocity.length() > _flight_velocity.length() else deceleration_value
	_flight_velocity = _flight_velocity.move_toward(desired_velocity, maxf(acceleration_rate, 1.0) * delta)

	var move_vector := _flight_velocity * delta
	if travel_distance > stop_distance and move_vector.length() > travel_distance:
		move_vector = travel_vector.normalized() * travel_distance
		_flight_velocity = move_vector / safe_delta

	var next_position := global_position + move_vector
	global_position = next_position
	return travel_distance <= stop_distance and _flight_velocity.length() <= 4.0


func _get_intercept_world_position(enemy_candidate: Variant) -> Vector2:
	var enemy := _get_valid_enemy_target(enemy_candidate)
	if enemy == null:
		return global_position

	var slot_count := maxi(drone_count, 1)
	var slot_angle := (TAU * float(drone_index) / float(slot_count)) + (_elapsed * intercept_orbit_speed)
	return enemy.global_position + Vector2.RIGHT.rotated(slot_angle) * intercept_attack_radius


func _get_formation_world_position() -> Vector2:
	if _ship == null or not is_instance_valid(_ship):
		return global_position

	var forward := _get_delayed_ship_forward_direction()
	var lateral := forward.orthogonal()
	var local_offset := _get_formation_local_offset()
	local_offset += _get_formation_wander_local_offset()
	var bob_offset := sin(_elapsed * formation_bob_speed + float(drone_index) * 0.73) * follow_distance * formation_bob_amount
	return _get_delayed_ship_world_position() + forward * local_offset.x + lateral * (local_offset.y + bob_offset)


func _get_formation_local_offset() -> Vector2:
	if drone_count <= 1:
		return Vector2(-formation_back_offset, -follow_distance)

	var side_sign := -1.0 if drone_index % 2 == 0 else 1.0
	var side_index := int(drone_index / 2)
	var side_count := int((drone_count + 1) / 2) if side_sign < 0.0 else int(drone_count / 2)
	var max_lanes := maxi(formation_side_lanes, 1)
	var max_columns := maxi(formation_side_columns, 1)
	var columns := mini(maxi(int(ceil(sqrt(float(side_count) * 1.6))), 1), max_columns)
	var lanes := maxi(int(ceil(float(side_count) / float(columns))), 1)
	if lanes > max_lanes:
		lanes = max_lanes
		columns = maxi(int(ceil(float(side_count) / float(lanes))), 1)

	var lane_index := int(side_index / columns)
	var column_index := side_index % columns
	var remaining_in_lane := side_count - lane_index * columns
	var lane_columns := mini(columns, remaining_in_lane)
	var centered_column := float(column_index) - (float(lane_columns) - 1.0) * 0.5
	var lane_shift := formation_row_spacing * 0.35 if lane_index % 2 == 1 else 0.0
	return Vector2(
		-formation_back_offset + centered_column * formation_row_spacing + lane_shift,
		side_sign * (follow_distance + float(lane_index) * formation_side_spacing)
	)


func _get_formation_wander_local_offset() -> Vector2:
	if formation_wander_amount <= 0.0 or formation_wander_speed <= 0.0:
		return Vector2.ZERO

	var seed := float(drone_index + 1)
	var phase_a := _elapsed * formation_wander_speed + seed * 1.819
	var phase_b := _elapsed * formation_wander_speed * 0.73 + seed * 2.447
	var phase_c := _elapsed * formation_wander_speed * 1.31 + seed * 0.991
	return Vector2(
		sin(phase_a) * formation_wander_amount * 0.55 + sin(phase_b) * formation_wander_amount * 0.25,
		cos(phase_b) * formation_wander_amount + sin(phase_c) * formation_wander_amount * 0.35
	)


func _get_ship_forward_direction() -> Vector2:
	if _ship == null or not is_instance_valid(_ship):
		return Vector2.RIGHT

	return _get_ship_forward_direction_for_rotation(_ship.global_rotation)


func _get_delayed_ship_world_position() -> Vector2:
	var delayed_transform := _get_delayed_ship_transform()
	if delayed_transform.has("position"):
		return delayed_transform["position"] as Vector2
	if _ship == null or not is_instance_valid(_ship):
		return global_position
	return _ship.global_position


func _get_delayed_ship_forward_direction() -> Vector2:
	var delayed_transform := _get_delayed_ship_transform()
	if delayed_transform.has("rotation"):
		return _get_ship_forward_direction_for_rotation(float(delayed_transform["rotation"]))
	return _get_ship_forward_direction()


func _get_ship_forward_direction_for_rotation(ship_rotation: float) -> Vector2:
	var forward_rotation_offset := 0.0
	var offset_variant: Variant = _ship.get("sprite_forward_rotation_offset")
	if offset_variant is float:
		forward_rotation_offset = offset_variant

	return Vector2.RIGHT.rotated(ship_rotation - forward_rotation_offset)


func _record_ship_transform_sample() -> void:
	if _ship == null or not is_instance_valid(_ship):
		_resolve_ship()
		if _ship == null or not is_instance_valid(_ship):
			_ship_transform_history.clear()
			return

	_ship_transform_history.append({
		"time": _elapsed,
		"position": _ship.global_position,
		"rotation": _ship.global_rotation,
	})

	var keep_seconds := maxf(follow_delay_seconds + 0.5, 0.75)
	var oldest_time := _elapsed - keep_seconds
	while _ship_transform_history.size() > 2 and float(_ship_transform_history[1]["time"]) < oldest_time:
		_ship_transform_history.remove_at(0)


func _get_delayed_ship_transform() -> Dictionary:
	if _ship_transform_history.is_empty():
		return {}

	var delay := maxf(follow_delay_seconds, 0.0)
	if delay <= 0.0 or _ship_transform_history.size() == 1:
		return _ship_transform_history[_ship_transform_history.size() - 1]

	var target_time := _elapsed - delay
	if target_time <= float(_ship_transform_history[0]["time"]):
		return _ship_transform_history[0]

	for index in range(1, _ship_transform_history.size()):
		var next_sample := _ship_transform_history[index]
		var next_time := float(next_sample["time"])
		if next_time < target_time:
			continue

		var previous_sample := _ship_transform_history[index - 1]
		var previous_time := float(previous_sample["time"])
		var sample_span := maxf(next_time - previous_time, 0.001)
		var weight := clampf((target_time - previous_time) / sample_span, 0.0, 1.0)
		return {
			"time": target_time,
			"position": (previous_sample["position"] as Vector2).lerp(next_sample["position"] as Vector2, weight),
			"rotation": lerp_angle(float(previous_sample["rotation"]), float(next_sample["rotation"]), weight),
		}

	return _ship_transform_history[_ship_transform_history.size() - 1]


func _find_nearest_enemy() -> Node2D:
	if _ship == null or not is_instance_valid(_ship):
		return null

	var effective_attack_range := _get_effective_attack_range()
	var best_enemy: Node2D
	var best_distance := INF
	for enemy_candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := enemy_candidate as Node2D
		if not _is_valid_enemy_target(enemy):
			continue

		if _ship.global_position.distance_to(enemy.global_position) > effective_attack_range:
			continue

		var distance_to_enemy := global_position.distance_to(enemy.global_position)
		if distance_to_enemy > best_distance:
			continue

		best_distance = distance_to_enemy
		best_enemy = enemy

	return best_enemy


func _should_switch_target(current_enemy_candidate: Variant, next_enemy_candidate: Variant) -> bool:
	var next_enemy := _get_valid_enemy_target(next_enemy_candidate)
	if next_enemy == null:
		return false

	var current_enemy := _get_valid_enemy_target(current_enemy_candidate)
	if current_enemy == null:
		return true
	if not _is_enemy_inside_leash(current_enemy):
		return true
	if current_enemy == next_enemy:
		return false

	var current_distance := global_position.distance_to(current_enemy.global_position)
	var next_distance := global_position.distance_to(next_enemy.global_position)
	return current_distance - next_distance > maxf(target_switch_distance, 0.0)


func _get_valid_enemy_target(enemy_candidate: Variant) -> Node2D:
	if enemy_candidate == null or not is_instance_valid(enemy_candidate):
		return null

	var enemy := enemy_candidate as Node2D
	if enemy == null or enemy.is_queued_for_deletion():
		return null
	if not enemy.has_method("take_damage"):
		return null

	return enemy


func _is_valid_enemy_target(enemy_candidate: Variant) -> bool:
	return _get_valid_enemy_target(enemy_candidate) != null


func _is_owner_ship_vortex_captured() -> bool:
	if _ship == null or not is_instance_valid(_ship):
		return false
	if not _ship.has_method("is_vortex_captured"):
		return false

	return bool(_ship.call("is_vortex_captured"))


func _is_enemy_inside_leash(enemy_candidate: Variant) -> bool:
	if _ship == null or not is_instance_valid(_ship):
		return false
	var enemy := _get_valid_enemy_target(enemy_candidate)
	if enemy == null:
		return false

	var leash_range := _get_effective_attack_range() * intercept_leash_multiplier
	return _ship.global_position.distance_to(enemy.global_position) <= leash_range


func _get_effective_attack_range() -> float:
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("get_weapon_range"):
		return maxf(float(_ship.call("get_weapon_range")), 1.0)

	return maxf(attack_range, 1.0)


func _fire_at(enemy_candidate: Variant) -> void:
	var enemy := _get_valid_enemy_target(enemy_candidate)
	if enemy == null:
		return

	_show_beam(enemy.global_position)
	_broadcast_network_beam(enemy.global_position)

	if (not _is_network_presentation or is_server_authority) and enemy.has_method("take_damage"):
		var damage_multiplier := 1.0
		if _ship != null and is_instance_valid(_ship) and _ship.has_method("get_safe_zone_attack_multiplier"):
			damage_multiplier = maxf(float(_ship.call("get_safe_zone_attack_multiplier")), 1.0)

		enemy.call("take_damage", maxi(1, int(round(float(damage_per_shot) * damage_multiplier))))


func _show_beam(target_world_position: Vector2) -> void:
	_beam_target_world_position = target_world_position
	_beam_target_world_position_valid = true
	_beam_time_left = beam_duration
	if _fire_line != null:
		_fire_line.visible = _is_fog_presentation_visible
		_fire_line.points = PackedVector2Array([Vector2.ZERO, to_local(target_world_position)])
		_fire_line.width = beam_width
		_apply_fire_line_alpha()


func _update_beam(delta: float) -> void:
	if _fire_line == null:
		return

	if _beam_time_left <= 0.0:
		_hide_beam()
		return

	_beam_time_left = maxf(_beam_time_left - delta, 0.0)
	var target_world_position := _beam_target_world_position
	var target_enemy := _get_valid_enemy_target(_target_enemy)
	if target_enemy != null:
		target_world_position = target_enemy.global_position
		_beam_target_world_position = target_world_position
		_beam_target_world_position_valid = true
	elif not _beam_target_world_position_valid:
		_hide_beam()
		return

	_fire_line.points = PackedVector2Array([Vector2.ZERO, to_local(target_world_position)])
	_fire_line.visible = _is_fog_presentation_visible
	_apply_fire_line_alpha()

	if _beam_time_left <= 0.0:
		_hide_beam()


func _ensure_fire_line() -> void:
	_fire_line = get_node_or_null("FireLine") as Line2D
	if _fire_line == null:
		_fire_line = Line2D.new()
		_fire_line.name = "FireLine"
		add_child(_fire_line)

	_fire_line.visible = false
	_fire_line.z_index = 10
	_fire_line.antialiased = true
	_fire_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_fire_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_fire_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_fire_line.default_color = FIRE_LINE_COLOR
	_fire_line.width = beam_width
	_apply_fire_line_alpha()


func _hide_beam() -> void:
	_beam_time_left = 0.0
	_target_enemy = null
	_beam_target_world_position = Vector2.ZERO
	_beam_target_world_position_valid = false
	if _fire_line != null:
		_fire_line.visible = false


func _apply_fire_line_alpha() -> void:
	if _fire_line == null:
		return

	var fire_line_color := FIRE_LINE_COLOR
	_fire_line.default_color = fire_line_color


func _broadcast_network_beam(target_world_position: Vector2) -> void:
	if not _is_network_presentation or not is_server_authority:
		return

	if multiplayer.multiplayer_peer == null:
		return

	var galaxy := get_tree().current_scene
	if galaxy != null and galaxy.has_method("client_ship_drone_weapon_fired"):
		galaxy.rpc("client_ship_drone_weapon_fired", owner_peer_id, drone_index, target_world_position)

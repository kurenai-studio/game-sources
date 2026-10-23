extends Node2D
class_name Enemy

const SHIP_DISTORTION_SHADER: Shader = preload("res://shaders/ship_distortion.gdshader")
const DAMAGE_IMPACT_FX_SCRIPT: Script = preload("res://scripts/damage_impact_fx.gd")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const PLAYER_GROUP: StringName = &"player_ships"
const ENEMY_GROUP: StringName = &"enemies"
const EXPLORER_BEACON_GROUP: StringName = &"explorer_beacons"
const SAFE_ZONE_AVOIDANCE_LOOKAHEAD: float = 520.0
const SAFE_ZONE_AVOIDANCE_PADDING: float = 64.0
const SAFE_ZONE_AVOIDANCE_CENTER_EPSILON: float = 8.0
const SAFE_ZONE_STEERING_RESPONSE: float = 7.0
const VORTEX_CAPTURE_LOCK_SECONDS: float = 0.22
const FOG_PRESENTATION_VISIBLE_EPSILON: float = 0.01
const ENEMY_BLOCK_TRAVEL_PADDING: float = 0.5

signal destroyed(xp_amount: int, world_position: Vector2, enemy: Node2D)
signal damage_taken(amount: int, world_position: Vector2, enemy: Node2D)

## Maximum world radius the enemy can patrol within.
@export_range(100.0, 20000.0, 10.0) var world_radius: float = 10000.0
## Distance from a patrol target before the enemy picks a new one.
@export_range(8.0, 120.0, 1.0) var movement_tolerance: float = 24.0
## Rotation offset that makes the sprite face forward while moving.
@export var sprite_forward_rotation_offset: float = PI * 0.5
## Starting health the enemy receives when it spawns.
@export_range(1, 999, 1) var hit_points: int = 3
## XP awarded when the enemy is destroyed.
@export_range(0, 999, 1) var xp_reward: int = 1
## Multiplier applied to the enemy explosion effect size.
@export_range(0.1, 10.0, 0.05) var explosion_size: float = 1.0
@export_group("Combat")
## Range at which the enemy notices and starts chasing the ship.
@export_range(150.0, 30000.0, 10.0) var detection_radius: float = 2200.0
## Range at which the enemy will keep chasing if the ship is inside a safe zone.
@export_range(1000.0, 40000.0, 10.0) var safe_zone_chase_radius: float = 20000.0
## Range at which the enemy is allowed to fire.
@export_range(50.0, 12000.0, 10.0) var attack_radius: float = 520.0
## Time between beam attacks.
@export_range(0.05, 10.0, 0.05) var attack_cooldown: float = 0.9
## Damage dealt by each beam shot.
@export_range(0, 100, 1) var damage_per_shot: int = 1
## How long the beam stays visible after firing.
@export_range(0.02, 0.4, 0.01) var beam_duration: float = 0.08
## Thickness of the beam line.
@export_range(1.0, 20.0, 0.5) var beam_width: float = 6.0
## Tint used for the beam effect.
@export var beam_color: Color = Color(1.0, 0.28, 0.22, 0.95)
## Fraction of patrol speed kept while the enemy is in attack range.
@export_range(0.0, 1.0, 0.01) var attack_drift_speed_ratio: float = 0.22
@export var network_id: int = 0
@export var network_scene_key: StringName = &"enemy"
var is_defender: bool = false

@export_group("Damage FX")
@export_range(1, 160, 1) var damage_spark_amount: int = 28
@export_range(0.05, 1.5, 0.01) var damage_spark_lifetime: float = 0.4
@export_range(0.0, 1.0, 0.01) var damage_spark_explosiveness: float = 0.92
@export_range(0.0, 1.0, 0.01) var damage_spark_randomness: float = 0.68
@export_range(0.0, 360.0, 1.0) var damage_spark_spread_degrees: float = 96.0
@export_range(0.0, 1200.0, 1.0) var damage_spark_velocity_min: float = 55.0
@export_range(0.0, 2400.0, 1.0) var damage_spark_velocity_max: float = 300.0
@export_range(0.0, 2400.0, 1.0) var damage_spark_damping: float = 650.0
@export var damage_spark_color: Color = Color(1.0, 0.78, 0.36, 0.82)

@onready var enemy_sprite: Sprite2D = $EnemySprite

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _hit_points: int = 3
var _is_destroyed: bool = false
var _patrol_center: Vector2 = Vector2.ZERO
var _patrol_radius: float = 600.0
var _move_speed: float = 180.0
var _turn_speed: float = PI * 1.5
var _retarget_delay_min: float = 1.5
var _retarget_delay_max: float = 4.5
var _retarget_timer: float = 0.0
var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _target_ship: Node2D
var _is_network_presentation: bool = false
var is_server_authority: bool = true
var _beam_line: Line2D
var _beam_time_left: float = 0.0
var _beam_target_world_position: Vector2 = Vector2.ZERO
var _beam_target_world_position_valid: bool = false
var _attack_cooldown_timer: float = 0.0
var _safe_zone_damage_remainder: float = 0.0
var _enemy_material: ShaderMaterial
var _damage_flash_tween: Tween
var _fog_presentation_alpha: float = 1.0
var _is_fog_presentation_visible: bool = true
var _current_move_direction: Vector2 = Vector2.ZERO
var _has_current_move_direction: bool = false
var _safe_zone_avoidance_center: Vector2 = Vector2.ZERO
var _safe_zone_avoidance_side: int = 0
var _attack_drift_side: int = 1
var _shader_time: float = 0.0
var _vortex_capture_time_left: float = 0.0
var _vortex_capture_strength: float = 0.0
var _vortex_capture_center: Vector2 = Vector2.ZERO
var _vortex_local_direction: Vector2 = Vector2(0.0, -1.0)
var _has_defense_area: bool = false
var _defense_center: Vector2 = Vector2.ZERO
var _defense_radius: float = 0.0
var _holds_patrol_position: bool = false


func _ready() -> void:
	_hit_points = maxi(hit_points, 1)
	_is_destroyed = false
	add_to_group(ENEMY_GROUP)
	_ensure_enemy_material()
	_ensure_beam_line()
	if not _has_target:
		_pick_new_target()


func configure_patrol(
	patrol_center: Vector2,
	patrol_radius_value: float,
	move_speed: float,
	turn_speed: float,
	world_radius_value: float,
	retarget_delay_min: float,
	retarget_delay_max: float,
	seed: int = 0,
	target_ship: Node2D = null
) -> void:
	_patrol_center = patrol_center
	_patrol_radius = maxf(patrol_radius_value, movement_tolerance * 2.0)
	_move_speed = move_speed
	_turn_speed = maxf(turn_speed, 0.01)
	world_radius = maxf(world_radius_value, _patrol_radius + movement_tolerance)
	_retarget_delay_min = minf(retarget_delay_min, retarget_delay_max)
	_retarget_delay_max = maxf(retarget_delay_min, retarget_delay_max)
	_target_ship = target_ship
	_attack_cooldown_timer = 0.0
	_beam_time_left = 0.0
	_current_move_direction = Vector2.ZERO
	_has_current_move_direction = false
	_clear_safe_zone_avoidance()

	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	_attack_drift_side = 1 if _rng.randf() >= 0.5 else -1

	_has_target = false
	if is_inside_tree():
		_pick_new_target()


func configure_defense_area(defense_center: Vector2, defense_radius: float, hold_patrol_position: bool = true) -> void:
	_has_defense_area = defense_radius > 0.0
	_defense_center = defense_center
	_defense_radius = maxf(defense_radius, attack_radius)
	_holds_patrol_position = hold_patrol_position
	_attack_cooldown_timer = 0.0

	if _holds_patrol_position:
		_has_target = true
		_target_position = _patrol_center
		_retarget_timer = INF


func set_network_identity(server_authority: bool) -> void:
	is_server_authority = server_authority
	_is_network_presentation = true


func set_fog_presentation_alpha(alpha: float) -> void:
	var resolved_alpha := clampf(alpha, 0.0, 1.0)
	var is_visible_for_fog := resolved_alpha > FOG_PRESENTATION_VISIBLE_EPSILON
	if is_equal_approx(resolved_alpha, _fog_presentation_alpha) and is_visible_for_fog == _is_fog_presentation_visible:
		return

	_fog_presentation_alpha = resolved_alpha
	_is_fog_presentation_visible = is_visible_for_fog
	visible = _is_fog_presentation_visible and not _is_destroyed
	if _enemy_material != null:
		_enemy_material.set_shader_parameter("global_fade", _fog_presentation_alpha)
	if _beam_line != null:
		if not _is_fog_presentation_visible:
			_hide_beam()
		else:
			_apply_beam_fog_alpha()


func apply_vortex_capture(vortex_center: Vector2, strength: float, delta: float) -> void:
	if _is_destroyed:
		return

	var capture_strength := clampf(strength, 0.0, 1.0)
	_vortex_capture_time_left = VORTEX_CAPTURE_LOCK_SECONDS
	_vortex_capture_strength = move_toward(
		_vortex_capture_strength,
		capture_strength,
		maxf(delta, 0.0) * lerpf(0.9, 3.8, capture_strength)
	)
	_vortex_capture_center = vortex_center
	_target_ship = null
	_has_target = false
	_attack_cooldown_timer = attack_cooldown
	_clear_current_move_direction()
	_hide_beam()

	var to_center := vortex_center - global_position
	if to_center.length_squared() > 0.001:
		var world_direction := to_center.normalized()
		_vortex_local_direction = world_direction.rotated(-enemy_sprite.global_rotation).normalized()
		var desired_rotation := world_direction.angle() + sprite_forward_rotation_offset
		var turn_response := lerpf(0.45, 3.1, _vortex_capture_strength * _vortex_capture_strength)
		rotation = lerp_angle(rotation, desired_rotation, clampf(turn_response * maxf(delta, 0.0), 0.0, 1.0))


func is_vortex_captured() -> bool:
	return _is_vortex_captured()


func _process(delta: float) -> void:
	if _is_destroyed:
		return

	_shader_time += maxf(delta, 0.0)
	_update_vortex_capture_state(delta)
	if _is_fog_presentation_visible:
		_apply_enemy_shader_runtime_parameters()
		_update_beam(delta)
	else:
		_hide_beam()
	if _is_vortex_captured():
		_hide_beam()
		return
	if _is_network_presentation and not is_server_authority:
		return

	if not _is_target_ship_alive():
		_target_ship = _find_nearest_player_ship()

	if _can_chase_ship():
		_update_chase(delta)
		return

	if _has_defense_area and not _is_target_inside_defense_area():
		_target_ship = null
	_target_ship = null if not _is_target_ship_alive() else _target_ship
	_update_patrol(delta)


func _update_patrol(delta: float) -> void:
	if _holds_patrol_position:
		_update_hold_position(delta)
		return

	if not _has_target:
		_pick_new_target()
		return

	_retarget_timer -= delta
	var to_target := _target_position - global_position
	if to_target.length() <= movement_tolerance or _retarget_timer <= 0.0 or _is_in_safe_zone(_target_position, get_touch_radius()):
		_pick_new_target()
		to_target = _target_position - global_position

	if to_target == Vector2.ZERO:
		return

	_move_toward_target(delta)


func _update_hold_position(delta: float) -> void:
	_target_position = _patrol_center
	_retarget_timer = INF
	_has_target = true

	var to_home := _target_position - global_position
	if to_home.length() <= movement_tolerance:
		_clear_current_move_direction()
		return

	_move_toward_target(delta)


func _update_chase(delta: float) -> void:
	if not _is_target_ship_alive():
		_target_ship = null
		return

	_has_target = true
	_target_position = _target_ship.global_position
	_retarget_timer = 0.0

	var ship_distance := global_position.distance_to(_target_ship.global_position)
	if ship_distance > _get_attack_radius():
		_move_toward_target(delta)
		_attack_cooldown_timer = 0.0
		return

	_apply_attack_drift(delta, ship_distance)
	_face_target_ship(delta)
	_attack_cooldown_timer = maxf(_attack_cooldown_timer - delta, 0.0)
	if _attack_cooldown_timer > 0.0:
		return

	_fire_beam(_get_target_ship_damage_impact_position())
	_attack_cooldown_timer = attack_cooldown


func _move_toward_target(delta: float) -> void:
	var to_target := _target_position - global_position
	if to_target == Vector2.ZERO:
		return

	var move_distance := minf(_move_speed * delta, to_target.length())
	var move_margin := get_touch_radius()
	var desired_move_direction := to_target.normalized()
	var target_ship_in_safe_zone := _is_target_ship_in_safe_zone()
	if not target_ship_in_safe_zone:
		desired_move_direction = _get_safe_steering_direction(to_target, move_distance, move_margin)
	if desired_move_direction == Vector2.ZERO:
		return

	var move_direction := _smooth_move_direction(desired_move_direction, delta)
	var desired_rotation := move_direction.angle() + sprite_forward_rotation_offset
	rotation = lerp_angle(rotation, desired_rotation, clampf(_turn_speed * delta, 0.0, 1.0))

	var safe_move_distance := move_distance
	if not target_ship_in_safe_zone:
		safe_move_distance = _get_safe_travel_distance(move_direction, move_distance, move_margin)
		if safe_move_distance <= 0.0 and not move_direction.is_equal_approx(desired_move_direction):
			move_direction = desired_move_direction
			_current_move_direction = move_direction
			safe_move_distance = _get_safe_travel_distance(move_direction, move_distance, move_margin)
	safe_move_distance = _get_enemy_blocked_travel_distance(move_direction, safe_move_distance)
	if safe_move_distance <= 0.0:
		return

	global_position += move_direction * safe_move_distance


func _apply_attack_drift(delta: float, ship_distance: float) -> void:
	if attack_drift_speed_ratio <= 0.0 or delta <= 0.0:
		_clear_current_move_direction()
		return
	if not _is_target_ship_alive():
		_clear_current_move_direction()
		return

	var to_ship := _target_ship.global_position - global_position
	if to_ship == Vector2.ZERO:
		return

	var toward_ship := to_ship.normalized()
	var drift_direction := toward_ship.rotated(float(_attack_drift_side) * PI * 0.5)
	var preferred_distance := _get_attack_radius() * 0.82
	if ship_distance < preferred_distance - movement_tolerance:
		drift_direction = (drift_direction - toward_ship * 0.85).normalized()
	elif ship_distance > preferred_distance + movement_tolerance:
		drift_direction = (drift_direction + toward_ship * 0.65).normalized()

	if drift_direction == Vector2.ZERO:
		return

	var move_direction := _smooth_move_direction(drift_direction, delta)
	var move_distance := _move_speed * attack_drift_speed_ratio * delta
	if move_distance <= 0.0:
		return

	var safe_move_distance := move_distance
	if not _is_target_ship_in_safe_zone():
		safe_move_distance = _get_safe_travel_distance(move_direction, move_distance, get_touch_radius())
	safe_move_distance = _get_enemy_blocked_travel_distance(move_direction, safe_move_distance)
	if safe_move_distance <= 0.0:
		return

	global_position += move_direction * safe_move_distance


func _face_target_ship(delta: float) -> void:
	if not _is_target_ship_alive():
		return

	var to_ship := _target_ship.global_position - global_position
	if to_ship == Vector2.ZERO:
		return

	var desired_rotation := to_ship.angle() + sprite_forward_rotation_offset
	rotation = lerp_angle(rotation, desired_rotation, clampf(_turn_speed * delta, 0.0, 1.0))


func _clear_current_move_direction() -> void:
	_current_move_direction = Vector2.ZERO
	_has_current_move_direction = false
	_clear_safe_zone_avoidance()


func _is_vortex_captured() -> bool:
	return _vortex_capture_time_left > 0.0 and _vortex_capture_strength > 0.01


func _update_vortex_capture_state(delta: float) -> void:
	if _vortex_capture_time_left > 0.0:
		_vortex_capture_time_left = maxf(_vortex_capture_time_left - maxf(delta, 0.0), 0.0)
		return

	_vortex_capture_strength = move_toward(_vortex_capture_strength, 0.0, maxf(delta, 0.0) * 7.0)


func _can_chase_ship() -> bool:
	if not _is_target_ship_alive():
		return false
	if _has_defense_area:
		return _is_target_inside_defense_area()

	return global_position.distance_to(_target_ship.global_position) <= _get_chase_radius()


func _is_target_inside_defense_area() -> bool:
	if not _has_defense_area or not _is_target_ship_alive():
		return false

	return _defense_center.distance_to(_target_ship.global_position) <= _defense_radius


func _find_nearest_player_ship() -> Node2D:
	var nearest_ship: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group(PLAYER_GROUP):
		var player_ship := candidate as Node2D
		if not _is_player_ship_targetable(player_ship):
			continue

		var distance_to_ship := global_position.distance_to(player_ship.global_position)
		if distance_to_ship > nearest_distance:
			continue

		nearest_distance = distance_to_ship
		nearest_ship = player_ship

	for candidate in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
		var beacon := candidate as Node2D
		if not _is_explorer_beacon_targetable(beacon):
			continue

		var distance_to_beacon := global_position.distance_to(beacon.global_position)
		if distance_to_beacon > nearest_distance:
			continue

		nearest_distance = distance_to_beacon
		nearest_ship = beacon

	return nearest_ship


func _is_target_ship_alive() -> bool:
	return _is_player_ship_targetable(_target_ship)


func _is_player_ship_targetable(player_ship_candidate: Variant) -> bool:
	if player_ship_candidate == null or not is_instance_valid(player_ship_candidate):
		return false

	var player_ship := player_ship_candidate as Node2D
	if player_ship == null:
		return false
	if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
		return false
	if player_ship.has_method("is_invisible") and bool(player_ship.call("is_invisible")):
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

	return true


func _is_target_ship_in_safe_zone() -> bool:
	if _target_ship == null or not is_instance_valid(_target_ship):
		return false

	var ship_margin := _get_target_ship_touch_radius()
	return _is_in_safe_zone(_target_ship.global_position, ship_margin)


func _get_chase_radius() -> float:
	if _is_target_ship_in_safe_zone():
		return maxf(safe_zone_chase_radius, attack_radius)

	return _get_detection_radius()


func _get_detection_radius() -> float:
	return maxf(detection_radius, attack_radius)


func _get_attack_radius() -> float:
	return minf(attack_radius, _get_detection_radius())


func _get_damage_to_target_ship() -> int:
	if _target_ship == null or not is_instance_valid(_target_ship) or damage_per_shot <= 0:
		_safe_zone_damage_remainder = 0.0
		return 0
	if _target_ship.has_method("is_invisible") and bool(_target_ship.call("is_invisible")):
		_safe_zone_damage_remainder = 0.0
		return 0

	if _is_target_ship_in_safe_zone():
		_safe_zone_damage_remainder += float(damage_per_shot) * 0.5
		var safe_zone_damage := int(floor(_safe_zone_damage_remainder))
		if safe_zone_damage > 0:
			_safe_zone_damage_remainder -= float(safe_zone_damage)
		return safe_zone_damage

	_safe_zone_damage_remainder = 0.0
	return damage_per_shot


func get_touch_radius() -> float:
	if enemy_sprite == null or enemy_sprite.texture == null:
		return 0.0

	var texture_size := enemy_sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return 0.0

	var scaled_size := texture_size * enemy_sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func get_damage_impact_radius() -> float:
	return get_touch_radius()


func get_damage_impact_position(source_world_position: Vector2 = Vector2.INF) -> Vector2:
	return DAMAGE_IMPACT_FX_SCRIPT.get_sprite_impact_position(enemy_sprite, source_world_position, global_position)


func _get_target_ship_touch_radius() -> float:
	if _target_ship == null or not is_instance_valid(_target_ship):
		return 0.0

	if _target_ship.has_method("get_touch_radius"):
		return maxf(float(_target_ship.call("get_touch_radius")), 0.0)

	return 0.0


func _get_target_ship_damage_impact_position() -> Vector2:
	if _target_ship == null or not is_instance_valid(_target_ship):
		return global_position

	if _target_ship.has_method("get_damage_impact_position"):
		return _target_ship.call("get_damage_impact_position", global_position) as Vector2

	return _target_ship.global_position


func _get_planet_field() -> Node2D:
	if not is_inside_tree():
		return null

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null

	return scene_root.get_node_or_null("PlanetField") as Node2D


func _is_in_safe_zone(world_position: Vector2, margin: float = 0.0) -> bool:
	var planet_field := _get_planet_field()
	if planet_field == null:
		return false

	for child in planet_field.get_children():
		var planet: Planet = child as Planet
		if planet == null or not planet.is_conquered():
			continue

		var safe_zone: PlanetSafeZone = planet.planet_safe_zone
		if safe_zone != null and safe_zone.contains_world_position(world_position, margin):
			return true

	return false


func _get_safe_travel_distance(travel_direction: Vector2, desired_distance: float, margin: float = 0.0) -> float:
	if desired_distance <= 0.0 or travel_direction == Vector2.ZERO:
		return maxf(desired_distance, 0.0)

	var planet_field := _get_planet_field()
	if planet_field == null:
		return desired_distance

	var direction: Vector2 = travel_direction.normalized()
	var max_distance: float = desired_distance

	for child in planet_field.get_children():
		var planet: Planet = child as Planet
		if planet == null or not planet.is_conquered():
			continue

		var safe_zone: PlanetSafeZone = planet.planet_safe_zone
		if safe_zone == null:
			continue
		if safe_zone.radius <= 0.0:
			continue

		var zone_radius: float = safe_zone.get_blocking_radius(margin)
		if zone_radius <= 0.0:
			continue

		var offset: Vector2 = global_position - planet.global_position
		if offset.length_squared() <= zone_radius * zone_radius:
			continue

		var a: float = 1.0
		var b: float = 2.0 * direction.dot(offset)
		var c: float = offset.length_squared() - zone_radius * zone_radius
		var discriminant: float = b * b - 4.0 * a * c
		if discriminant < 0.0:
			continue

		var enter_distance: float = (-b - sqrt(discriminant)) / (2.0 * a)
		if enter_distance < 0.0 or enter_distance > max_distance:
			continue

		max_distance = maxf(0.0, enter_distance - 0.5)

	return max_distance


func _get_enemy_blocked_travel_distance(travel_direction: Vector2, desired_distance: float) -> float:
	if desired_distance <= 0.0 or travel_direction == Vector2.ZERO:
		return maxf(desired_distance, 0.0)
	if not is_inside_tree():
		return desired_distance

	var enemy_radius := get_touch_radius()
	if enemy_radius <= 0.0:
		return desired_distance

	var direction := travel_direction.normalized()
	var max_distance := desired_distance
	for candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var other_enemy := candidate as Node2D
		if other_enemy == null or other_enemy == self:
			continue
		if not is_instance_valid(other_enemy) or other_enemy.is_queued_for_deletion():
			continue
		if not other_enemy.has_method("get_touch_radius"):
			continue

		var other_radius := maxf(float(other_enemy.call("get_touch_radius")), 0.0)
		if other_radius <= 0.0:
			continue

		var block_radius := enemy_radius + other_radius
		var offset := global_position - other_enemy.global_position
		var offset_distance_squared := offset.length_squared()
		if offset_distance_squared <= block_radius * block_radius:
			continue

		var b := 2.0 * direction.dot(offset)
		var c := offset_distance_squared - block_radius * block_radius
		var discriminant := b * b - 4.0 * c
		if discriminant < 0.0:
			continue

		var enter_distance := (-b - sqrt(discriminant)) * 0.5
		if enter_distance < 0.0 or enter_distance > max_distance:
			continue

		max_distance = maxf(0.0, enter_distance - ENEMY_BLOCK_TRAVEL_PADDING)

	return max_distance


func _get_safe_steering_direction(to_target: Vector2, desired_distance: float, margin: float = 0.0) -> Vector2:
	if to_target == Vector2.ZERO:
		return Vector2.ZERO

	var direct_direction := to_target.normalized()
	var blocker := _get_nearest_safe_zone_blocker(to_target, desired_distance, margin + SAFE_ZONE_AVOIDANCE_PADDING)
	if blocker.is_empty():
		_clear_safe_zone_avoidance()
		return direct_direction

	var center := blocker.get("center", global_position) as Vector2
	var radius := maxf(float(blocker.get("radius", 0.0)), 0.0)
	var from_center := global_position - center
	var distance_from_center := from_center.length()
	if distance_from_center <= 0.001:
		return -direct_direction
	var side := _get_safe_zone_avoidance_side(center, direct_direction)
	if distance_from_center <= radius + 0.5:
		var outward_direction := from_center.normalized()
		var border_slide_direction := outward_direction.rotated(float(side) * PI * 0.5)
		return ((outward_direction * 0.35) + (border_slide_direction * 0.65)).normalized()

	var to_center_direction := (center - global_position).normalized()
	var tangent_angle := asin(clampf(radius / distance_from_center, -1.0, 1.0))
	return to_center_direction.rotated(tangent_angle * float(side)).normalized()


func _smooth_move_direction(desired_direction: Vector2, delta: float) -> Vector2:
	if desired_direction == Vector2.ZERO:
		return Vector2.ZERO
	if not _has_current_move_direction or _current_move_direction == Vector2.ZERO:
		_current_move_direction = desired_direction.normalized()
		_has_current_move_direction = true
		return _current_move_direction

	var blend := clampf(SAFE_ZONE_STEERING_RESPONSE * delta, 0.0, 1.0)
	var smoothed_angle := lerp_angle(_current_move_direction.angle(), desired_direction.angle(), blend)
	_current_move_direction = Vector2.RIGHT.rotated(smoothed_angle)
	return _current_move_direction


func _get_safe_zone_avoidance_side(center: Vector2, direct_direction: Vector2) -> int:
	if _safe_zone_avoidance_side != 0 and _safe_zone_avoidance_center.distance_to(center) <= SAFE_ZONE_AVOIDANCE_CENTER_EPSILON:
		return _safe_zone_avoidance_side

	_safe_zone_avoidance_center = center
	_safe_zone_avoidance_side = 1
	var to_center := center - global_position
	if direct_direction.cross(to_center) < 0.0:
		_safe_zone_avoidance_side = -1

	return _safe_zone_avoidance_side


func _clear_safe_zone_avoidance() -> void:
	_safe_zone_avoidance_center = Vector2.ZERO
	_safe_zone_avoidance_side = 0


func _get_nearest_safe_zone_blocker(to_target: Vector2, desired_distance: float, margin: float = 0.0) -> Dictionary:
	var result: Dictionary = {}
	if to_target == Vector2.ZERO:
		return result

	var planet_field := _get_planet_field()
	if planet_field == null:
		return result

	var direction := to_target.normalized()
	var target_distance := to_target.length()
	var nearest_enter_distance := INF

	for child in planet_field.get_children():
		var planet: Planet = child as Planet
		if planet == null or not planet.is_conquered():
			continue

		var safe_zone: PlanetSafeZone = planet.planet_safe_zone
		if safe_zone == null:
			continue
		if safe_zone.radius <= 0.0:
			continue

		var zone_radius := safe_zone.get_blocking_radius(margin)
		if zone_radius <= 0.0:
			continue

		var offset := global_position - planet.global_position
		var offset_distance_squared := offset.length_squared()
		if offset_distance_squared <= zone_radius * zone_radius:
			return {
				"center": planet.global_position,
				"radius": zone_radius,
				"enter_distance": 0.0,
			}

		var b := 2.0 * direction.dot(offset)
		var c := offset_distance_squared - zone_radius * zone_radius
		var discriminant := b * b - 4.0 * c
		if discriminant < 0.0:
			continue

		var enter_distance := (-b - sqrt(discriminant)) * 0.5
		if enter_distance < 0.0:
			continue

		var lookahead_distance := maxf(desired_distance, zone_radius + SAFE_ZONE_AVOIDANCE_LOOKAHEAD)
		var scan_distance := minf(target_distance, lookahead_distance)
		if enter_distance > scan_distance:
			continue
		if enter_distance >= nearest_enter_distance:
			continue

		nearest_enter_distance = enter_distance
		result = {
			"center": planet.global_position,
			"radius": zone_radius,
			"enter_distance": enter_distance,
		}

	return result


func _fire_beam(target_world_position: Vector2) -> void:
	if _is_destroyed:
		return

	_show_beam(target_world_position)
	_broadcast_network_beam(target_world_position)

	if is_server_authority and _target_ship != null and is_instance_valid(_target_ship) and _target_ship.has_method("take_damage"):
		var applied_damage := _get_damage_to_target_ship()
		if _target_ship.has_method("get_damage_impact_position"):
			_target_ship.call("take_damage", applied_damage, target_world_position)
		else:
			_target_ship.call("take_damage", applied_damage)


func play_network_beam(target_world_position: Vector2) -> void:
	if _is_destroyed:
		return

	_target_ship = null
	_show_beam(target_world_position)


func _show_beam(target_world_position: Vector2) -> void:
	_beam_target_world_position = target_world_position
	_beam_target_world_position_valid = true
	_beam_time_left = beam_duration
	if _beam_line == null:
		return

	_beam_line.visible = _is_fog_presentation_visible
	_apply_beam_fog_alpha()
	_beam_line.width = beam_width
	_beam_line.points = PackedVector2Array([Vector2.ZERO, to_local(target_world_position)])
	GAME_SFX.play(self, GAME_SFX.CUE_LASER)


func _update_beam(delta: float) -> void:
	if _beam_line == null:
		return

	if _beam_time_left <= 0.0:
		_hide_beam()
		return

	_beam_time_left = maxf(_beam_time_left - delta, 0.0)
	var target_world_position := _beam_target_world_position
	if _target_ship != null and is_instance_valid(_target_ship):
		target_world_position = _get_target_ship_damage_impact_position()
		_beam_target_world_position = target_world_position
		_beam_target_world_position_valid = true
	elif not _beam_target_world_position_valid:
		_hide_beam()
		return

	_beam_line.points = PackedVector2Array([Vector2.ZERO, to_local(target_world_position)])
	_beam_line.visible = _is_fog_presentation_visible
	_apply_beam_fog_alpha()

	if _beam_time_left <= 0.0:
		_hide_beam()


func take_damage(amount: int, impact_world_position: Vector2 = Vector2.INF, should_spawn_hit_fx: bool = true) -> int:
	if _is_destroyed or amount <= 0:
		return 0

	var applied_damage := mini(amount, _hit_points)
	if applied_damage <= 0:
		return 0

	var resolved_impact := Vector2.INF
	if should_spawn_hit_fx:
		resolved_impact = _resolve_damage_impact_position(impact_world_position)
	_hit_points = maxi(_hit_points - applied_damage, 0)
	if should_spawn_hit_fx:
		_trigger_damage_flash()
		_spawn_damage_sparks(resolved_impact)
	damage_taken.emit(applied_damage, global_position, self)
	if _hit_points <= 0:
		_destroy_enemy()

	return applied_damage


func _ensure_beam_line() -> void:
	_beam_line = get_node_or_null("BeamLine") as Line2D
	if _beam_line == null:
		_beam_line = Line2D.new()
		_beam_line.name = "BeamLine"
		add_child(_beam_line)

	_beam_line.visible = false
	_beam_line.z_index = 20
	_beam_line.antialiased = true
	_beam_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_beam_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_beam_line.default_color = beam_color
	_beam_line.width = beam_width


func _apply_beam_fog_alpha() -> void:
	if _beam_line == null:
		return

	var faded_color := beam_color
	faded_color.a *= _fog_presentation_alpha
	_beam_line.default_color = faded_color


func _hide_beam() -> void:
	_beam_time_left = 0.0
	_beam_target_world_position = Vector2.ZERO
	_beam_target_world_position_valid = false
	if _beam_line != null:
		_beam_line.visible = false


func _broadcast_network_beam(target_world_position: Vector2) -> void:
	if not is_server_authority:
		return

	if multiplayer.multiplayer_peer == null:
		return

	var galaxy := get_tree().current_scene
	if galaxy != null and galaxy.has_method("client_enemy_beam_fired"):
		galaxy.rpc("client_enemy_beam_fired", network_id, target_world_position)


func _destroy_enemy() -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	_hide_beam()

	destroyed.emit(maxi(xp_reward, 0), global_position, self)
	queue_free()


func _ensure_enemy_material() -> void:
	if enemy_sprite == null:
		return

	if enemy_sprite.material == null or not (enemy_sprite.material is ShaderMaterial):
		_enemy_material = ShaderMaterial.new()
		_enemy_material.shader = SHIP_DISTORTION_SHADER
		enemy_sprite.material = _enemy_material
	else:
		_enemy_material = enemy_sprite.material as ShaderMaterial
		if _enemy_material.shader == null:
			_enemy_material.shader = SHIP_DISTORTION_SHADER

	if _enemy_material == null:
		return

	_enemy_material.set_shader_parameter("time", 0.0)
	_enemy_material.set_shader_parameter("thrust_strength", 0.0)
	_enemy_material.set_shader_parameter("distortion_strength", 0.0)
	_enemy_material.set_shader_parameter("engine_focus", 0.58)
	_enemy_material.set_shader_parameter("alpha", 1.0)
	_enemy_material.set_shader_parameter("global_fade", 1.0)
	_enemy_material.set_shader_parameter("pickup_flash_strength", 0.0)
	_enemy_material.set_shader_parameter("pickup_flash_color", Color(0.95, 1.0, 1.0, 1.0))
	_enemy_material.set_shader_parameter("pickup_flash_hotness", 1.9)
	_enemy_material.set_shader_parameter("pickup_flash_glow", 0.52)
	_enemy_material.set_shader_parameter("damage_flash_strength", 0.0)
	_enemy_material.set_shader_parameter("damage_flash_color", Color(1.0, 0.25, 0.2, 1.0))
	_enemy_material.set_shader_parameter("damage_flash_hotness", 1.8)
	_enemy_material.set_shader_parameter("damage_flash_glow", 0.64)
	_enemy_material.set_shader_parameter("vortex_strength", 0.0)
	_enemy_material.set_shader_parameter("vortex_direction", _vortex_local_direction)


func _apply_enemy_shader_runtime_parameters() -> void:
	if _enemy_material == null:
		return

	_enemy_material.set_shader_parameter("time", _shader_time)
	_enemy_material.set_shader_parameter("vortex_strength", _vortex_capture_strength)
	_enemy_material.set_shader_parameter("vortex_direction", _vortex_local_direction)


func _trigger_damage_flash() -> void:
	if _enemy_material == null or not _is_fog_presentation_visible:
		return

	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	_enemy_material.set_shader_parameter("damage_flash_strength", 0.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.set_trans(Tween.TRANS_SINE)
	_damage_flash_tween.set_ease(Tween.EASE_OUT)
	_damage_flash_tween.tween_property(_enemy_material, "shader_parameter/damage_flash_strength", 1.0, 0.055)
	_damage_flash_tween.tween_property(_enemy_material, "shader_parameter/damage_flash_strength", 0.0, 0.22)


func _resolve_damage_impact_position(impact_world_position: Vector2) -> Vector2:
	if impact_world_position.is_finite():
		return impact_world_position

	return get_damage_impact_position(global_position + Vector2.RIGHT.rotated(global_rotation) * get_damage_impact_radius())


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
		_fog_presentation_alpha > 0.01,
		damage_spark_amount,
		damage_spark_lifetime,
		damage_spark_explosiveness,
		damage_spark_randomness,
		damage_spark_spread_degrees,
		damage_spark_velocity_min,
		damage_spark_velocity_max,
		damage_spark_damping,
		damage_spark_color
	)


func _get_damage_spark_direction(impact_world_position: Vector2) -> Vector2:
	var impact_direction := impact_world_position - global_position
	if impact_direction.length_squared() > 0.001:
		return impact_direction.normalized()

	if _has_current_move_direction and _current_move_direction != Vector2.ZERO:
		return _current_move_direction.normalized()

	return Vector2.RIGHT.rotated(global_rotation)


func _get_fx_layer() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return self

	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root != null:
		var root_fx_layer := scene_root.find_child("FXLayer", true, false) as Node2D
		if root_fx_layer != null:
			return root_fx_layer

	var fx_layer := parent.find_child("FXLayer", true, false) as Node2D
	if fx_layer != null:
		return fx_layer

	var node_parent := parent as Node2D
	if node_parent != null:
		return node_parent

	return self


func _pick_new_target() -> void:
	var candidate := _patrol_center
	for _attempt in range(12):
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(_patrol_radius * 0.25, _patrol_radius)
		candidate = _patrol_center + Vector2.RIGHT.rotated(angle) * radius
		if candidate.length() > world_radius:
			candidate = candidate.normalized() * world_radius
		if candidate.distance_to(global_position) > movement_tolerance and not _is_in_safe_zone(candidate, get_touch_radius()):
			break

	if candidate.distance_to(global_position) <= movement_tolerance:
		candidate = _patrol_center + Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _patrol_radius
		if candidate.length() > world_radius:
			candidate = candidate.normalized() * world_radius

	_target_position = candidate
	_has_target = true
	_retarget_timer = _rng.randf_range(_retarget_delay_min, _retarget_delay_max)

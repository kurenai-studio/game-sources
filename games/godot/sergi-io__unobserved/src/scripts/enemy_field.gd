extends Node2D
class_name EnemyField

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")
const ENEMY_2_SCENE: PackedScene = preload("res://scenes/enemy_2.tscn")
const ENEMY_2_SPAWN_CHANCE: float = 0.3
const UNLIMITED_ENEMY_SPAWN_SLOTS: int = 1000000
const HIDDEN_SPAWN_ATTEMPTS_PER_PASS: int = 32
const HIDDEN_SPAWN_EXPANSION_PASSES: int = 6
const DEFENDER_GROUP_CENTER_ATTEMPTS: int = 48
const DEFENDER_GOLDEN_ANGLE: float = 2.399963229728653
const DEFENDER_GROUP_ACTIVATION_CHECK_INTERVAL: float = 0.25

signal enemy_spawned(enemy: Enemy)
signal enemy_destroyed(xp_amount: int, world_position: Vector2, enemy: Node2D)
signal enemy_damage_taken(amount: int, world_position: Vector2, enemy: Node2D)
signal wave_state_changed(time_left: float, next_wave_size: int)

const WAVE_STATE_EMIT_INTERVAL: float = 0.1

@export_group("Waves")
@export_range(1, 128, 1) var base_wave_size: int = 10
@export_range(0.0, 2.0, 0.01) var wave_growth_factor: float = 0.2
@export_range(0.1, 120.0, 0.1) var wave_interval: float = 30.0
@export var use_wave_timeline: bool = true
@export var wave_timeline: Resource
@export_range(0, 10000, 1) var max_active_enemies: int = 0

@export_range(500.0, 20000.0, 10.0) var spawn_radius: float = 8600.0
@export_range(0.0, 1.0, 0.01) var inner_clear_radius_ratio: float = 0.2
@export_range(0.0, 4000.0, 1.0) var min_separation: float = 520.0
@export_range(200.0, 4000.0, 10.0) var patrol_radius_min: float = 420.0
@export_range(200.0, 5000.0, 10.0) var patrol_radius_max: float = 1600.0
@export_range(60.0, 520.0, 1.0) var move_speed_min: float = 110.0
@export_range(60.0, 520.0, 1.0) var move_speed_max: float = 240.0
@export_range(0.5, 10.0, 0.1) var turn_speed_min: float = PI
@export_range(0.5, 10.0, 0.1) var turn_speed_max: float = PI * 2.5
@export_range(0.5, 10.0, 0.1) var retarget_delay_min: float = 1.5
@export_range(0.5, 10.0, 0.1) var retarget_delay_max: float = 4.0
@export_range(1000.0, 40000.0, 10.0) var safe_zone_chase_radius: float = 20000.0
@export_group("Spawn Around Ship")
@export_range(100.0, 5000.0, 10.0) var debug_spawn_min_distance: float = 650.0
@export_range(100.0, 8000.0, 10.0) var debug_spawn_max_distance: float = 2200.0
@export_range(0.0, 2000.0, 1.0) var hidden_spawn_fog_padding: float = 96.0
@export_range(0.0, 1.0, 0.01) var hidden_spawn_active_vision_alpha_limit: float = 0.01
@export_range(0.0, 2000.0, 1.0) var debug_spawn_world_margin: float = 192.0
@export var world_seed: int = 0
@export var clear_existing_children: bool = true
@export var ship_path: NodePath = NodePath("../Ship")
@export var fog_of_war_path: NodePath = NodePath("../FogOfWarLayer/FogOfWar")
@export_group("Defending Groups")
@export var spawn_defending_groups: bool = true
@export_range(0, 100, 1) var defending_group_count: int = 20
@export_range(1, 64, 1) var defending_group_size_min: int = 4
@export_range(1, 64, 1) var defending_group_size_max: int = 20
@export_range(0.0, 1.0, 0.01) var defending_group_inner_radius_ratio: float = 0.18
@export_range(0.0, 1.0, 0.01) var defending_group_outer_radius_ratio: float = 0.92
@export_range(100.0, 20000.0, 10.0) var defending_group_min_separation: float = 4200.0
@export_range(100.0, 12000.0, 10.0) var defending_group_detection_radius: float = 2800.0
@export_range(500.0, 30000.0, 10.0) var defending_group_activation_radius: float = 6500.0
@export_range(40.0, 3000.0, 10.0) var defending_group_formation_radius_min: float = 260.0
@export_range(40.0, 4000.0, 10.0) var defending_group_formation_radius_max: float = 920.0

var _world_radius: float = 10000.0
var _ship: Node2D
var _fog_of_war: Node
var _wave_timer: float = 0.0
var _wave_count: int = 0
var _next_enemy_network_id: int = 1
var _wave_state_emit_accumulator: float = 0.0
var _timeline_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _timeline_wave_index: int = 0
var _timeline_wave_elapsed: float = 0.0
var _timeline_spawn_budget_left: int = 0
var _timeline_spawn_timer: float = 0.0
var _timeline_fired_event_indices: Dictionary = {}
var _defender_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pending_defending_groups: Array[Dictionary] = []
var _defender_activation_check_timer: float = 0.0


func _ready() -> void:
	_apply_galaxy_configuration()
	_resolve_ship()
	_resolve_fog_of_war()
	_clear_existing_children()
	_reset_timeline_rng()
	_reset_defender_rng()
	_queue_defending_groups()
	_wave_count = 0
	if _uses_wave_timeline():
		_reset_timeline()
	else:
		_reset_wave_timer()
	_emit_wave_state_changed()


func regenerate() -> void:
	_apply_galaxy_configuration()
	_resolve_ship()
	_resolve_fog_of_war()
	_clear_existing_children()
	_reset_timeline_rng()
	_reset_defender_rng()
	_queue_defending_groups()
	_wave_count = 0
	if _uses_wave_timeline():
		_reset_timeline()
	else:
		_reset_wave_timer()
	_emit_wave_state_changed()


func spawn_enemies(enemy_count: int) -> void:
	_spawn_enemies(maxi(enemy_count, 0))


func spawn_enemies_near_ship(enemy_count: int) -> void:
	_spawn_enemies(maxi(enemy_count, 0))


func can_spawn_enemy() -> bool:
	return get_available_enemy_spawn_slots() > 0


func get_available_enemy_spawn_slots() -> int:
	if max_active_enemies <= 0:
		return UNLIMITED_ENEMY_SPAWN_SLOTS

	return maxi(max_active_enemies - get_active_enemy_count(), 0)


func get_active_enemy_count() -> int:
	var active_enemy_count := 0
	for child in get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		active_enemy_count += 1

	return active_enemy_count


func _process(delta: float) -> void:
	_process_pending_defending_groups(delta)

	if _uses_wave_timeline():
		_process_timeline(delta)
		return

	_wave_timer = maxf(_wave_timer - delta, 0.0)
	if _wave_timer > 0.0:
		_process_wave_state_emit(delta)
		return

	_spawn_wave()
	_reset_wave_timer()
	_emit_wave_state_changed()


func _reset_wave_timer() -> void:
	_wave_timer = maxf(wave_interval, 0.1)


func _uses_wave_timeline() -> bool:
	return use_wave_timeline and wave_timeline != null and not wave_timeline.is_empty()


func _reset_timeline_rng() -> void:
	if world_seed == 0:
		_timeline_rng.randomize()
	else:
		_timeline_rng.seed = world_seed


func _reset_defender_rng() -> void:
	if world_seed == 0:
		_defender_rng.randomize()
	else:
		_defender_rng.seed = maxi(world_seed, 1) + 109729


func _reset_timeline() -> void:
	_timeline_wave_index = 0
	_start_timeline_wave(_timeline_wave_index)


func _start_timeline_wave(wave_index: int) -> void:
	var wave := _get_timeline_wave(wave_index)
	if wave == null:
		_wave_timer = 0.0
		_timeline_spawn_budget_left = 0
		_timeline_spawn_timer = 0.0
		_timeline_fired_event_indices.clear()
		return

	_timeline_wave_elapsed = 0.0
	_timeline_spawn_budget_left = wave.get_safe_spawn_budget()
	_timeline_spawn_timer = 0.0
	_timeline_fired_event_indices.clear()
	_wave_timer = wave.get_safe_duration()


func _get_timeline_wave(wave_index: int) -> Resource:
	if wave_timeline == null:
		return null

	return wave_timeline.get_wave(wave_index)


func _process_timeline(delta: float) -> void:
	var wave := _get_timeline_wave(_timeline_wave_index)
	if wave == null:
		_wave_timer = 0.0
		_timeline_spawn_budget_left = 0
		_process_wave_state_emit(delta)
		return

	var safe_delta := maxf(delta, 0.0)
	_timeline_wave_elapsed += safe_delta
	_wave_timer = maxf(wave.get_safe_duration() - _timeline_wave_elapsed, 0.0)
	_process_timeline_events(wave)
	_process_timeline_spawn_tick(wave, safe_delta)

	if _wave_timer <= 0.0:
		_timeline_wave_index += 1
		_start_timeline_wave(_timeline_wave_index)
		_emit_wave_state_changed()
		return

	_process_wave_state_emit(delta)


func _process_timeline_events(wave: Resource) -> void:
	for event_index in range(wave.events.size()):
		if _timeline_fired_event_indices.has(event_index):
			continue

		var event: Resource = wave.events[event_index]
		if event == null:
			_timeline_fired_event_indices[event_index] = true
			continue
		if not (event is WaveEvent):
			push_warning("Ignoring invalid wave event resource in %s at index %d: expected WaveEvent, got %s." % [_get_wave_debug_name(wave), event_index, event.get_class()])
			_timeline_fired_event_indices[event_index] = true
			continue
		if _timeline_wave_elapsed < maxf(event.time, 0.0):
			continue

		var rule: Resource = event.enemy_rule
		if rule != null and not (rule is WaveEnemyRule):
			push_warning("Ignoring invalid enemy rule in %s event %d: expected WaveEnemyRule, got %s." % [_get_wave_debug_name(wave), event_index, rule.get_class()])
			rule = null
		if rule == null:
			rule = wave.pick_enemy_rule(_timeline_rng)
		_spawn_enemy_batch(event.get_safe_count(), _timeline_rng, rule, wave)
		_timeline_fired_event_indices[event_index] = true
		_emit_wave_state_changed()


func _process_timeline_spawn_tick(wave: Resource, delta: float) -> void:
	_timeline_spawn_timer -= delta
	if _timeline_spawn_timer > 0.0:
		return

	_timeline_spawn_timer = wave.get_spawn_interval_at(_timeline_wave_elapsed)
	if _timeline_spawn_budget_left <= 0:
		return

	for rule in wave.enemy_pools:
		if rule == null:
			continue
		if not (rule is WaveEnemyRule):
			push_warning("Ignoring invalid enemy pool resource in %s: expected WaveEnemyRule, got %s." % [_get_wave_debug_name(wave), rule.get_class()])
			continue
		if rule.min_alive <= 0:
			continue
		var deficit := maxi(rule.min_alive - _get_active_enemy_count_for_key(rule.id), 0)
		if deficit <= 0:
			continue
		_spawn_timeline_rule(rule, mini(deficit, _timeline_spawn_budget_left), wave)
		if _timeline_spawn_budget_left <= 0:
			return

	var weighted_rule: Resource = wave.pick_enemy_rule(_timeline_rng)
	if weighted_rule == null:
		return

	var group_size := _timeline_rng.randi_range(weighted_rule.get_safe_group_size_min(), weighted_rule.get_safe_group_size_max())
	_spawn_timeline_rule(weighted_rule, group_size, wave)


func _spawn_timeline_rule(rule: Resource, requested_count: int, wave: Resource) -> void:
	if requested_count <= 0 or _timeline_spawn_budget_left <= 0:
		return

	var wave_slots: int = _get_effective_wave_max_alive(wave) - _get_active_wave_enemy_count()
	var spawn_count := mini(mini(requested_count, _timeline_spawn_budget_left), maxi(wave_slots, 0))
	if spawn_count <= 0:
		return

	var spawned_count := _spawn_enemy_batch(spawn_count, _timeline_rng, rule, wave)
	_timeline_spawn_budget_left = maxi(_timeline_spawn_budget_left - spawned_count, 0)
	if spawned_count > 0:
		_emit_wave_state_changed()


func _process_wave_state_emit(delta: float) -> void:
	_wave_state_emit_accumulator += maxf(delta, 0.0)
	if _wave_state_emit_accumulator < WAVE_STATE_EMIT_INTERVAL:
		return

	_wave_state_emit_accumulator = 0.0
	_emit_wave_state_changed()


func _spawn_wave() -> void:
	var wave_size := _get_wave_size(_wave_count)
	_spawn_enemies(wave_size)
	_wave_count += 1


func _get_wave_size(wave_index: int) -> int:
	var safe_wave_index := maxi(wave_index, 0)
	var wave_multiplier := pow(1.0 + clampf(wave_growth_factor, 0.0, 2.0), float(safe_wave_index))
	return maxi(int(round(float(base_wave_size) * wave_multiplier)), 1)


func _get_effective_wave_max_alive(wave: Resource) -> int:
	if wave == null:
		return 0

	var max_alive: int = wave.get_safe_max_alive()
	var loop_count: int = _get_repeated_final_wave_count()
	if loop_count <= 0:
		return max_alive

	return max_alive + loop_count * maxi(wave.get_safe_spawn_budget(), 1)


func _get_repeated_final_wave_count() -> int:
	if wave_timeline == null or not (wave_timeline is WaveTimeline):
		return 0
	if not bool(wave_timeline.get("loop_last_wave")):
		return 0

	var timeline := wave_timeline as WaveTimeline
	var wave_count: int = timeline.get_wave_count()
	if wave_count <= 0 or _timeline_wave_index < wave_count:
		return 0

	return _timeline_wave_index - wave_count + 1


func _clear_existing_children() -> void:
	if not clear_existing_children:
		return

	for child in get_children():
		child.queue_free()


func _apply_galaxy_configuration() -> void:
	var galaxy := get_parent()
	if galaxy != null and galaxy.has_method("get_world_radius"):
		_world_radius = float(galaxy.call("get_world_radius"))
	else:
		_world_radius = 10000.0

	spawn_radius = maxf(spawn_radius, 100.0)
	min_separation = maxf(min_separation, 360.0)


func _resolve_ship() -> void:
	_ship = get_node_or_null(ship_path) as Node2D


func _resolve_fog_of_war() -> void:
	_fog_of_war = get_node_or_null(fog_of_war_path)
	if _fog_of_war != null:
		return

	var parent_node := get_parent()
	if parent_node != null:
		_fog_of_war = parent_node.find_child("FogOfWar", true, false)


func _spawn_enemies(enemy_count: int) -> void:
	_spawn_enemy_batch(enemy_count, _create_spawn_rng(), null, null)


func _create_spawn_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if world_seed == 0:
		rng.randomize()
	else:
		rng.seed = world_seed

	return rng


func _spawn_enemy_batch(enemy_count: int, rng: RandomNumberGenerator, rule: Resource, wave: Resource) -> int:
	var spawn_count := mini(maxi(enemy_count, 0), get_available_enemy_spawn_slots())
	if spawn_count <= 0:
		return 0

	_resolve_ship()
	_resolve_fog_of_war()

	var spawned_positions: Array[Vector2] = []
	var spawned_count := 0
	for _index in range(spawn_count):
		var enemy := _create_enemy_for_rule(rng, rule)
		if enemy == null:
			continue
		enemy.network_id = _next_enemy_network_id
		_next_enemy_network_id += 1
		_apply_rule_modifiers(enemy, rule)

		var spawn_position := _pick_hidden_spawn_position_near_ship(rng, spawned_positions, enemy)
		enemy.position = spawn_position
		enemy.z_index = -20
		var speed_multiplier := _get_rule_speed_multiplier(rule)
		enemy.configure_patrol(
			spawn_position,
			rng.randf_range(patrol_radius_min, patrol_radius_max),
			rng.randf_range(move_speed_min, move_speed_max) * speed_multiplier,
			rng.randf_range(turn_speed_min, turn_speed_max),
			_world_radius,
			rng.randf_range(retarget_delay_min, retarget_delay_max),
			rng.randf_range(retarget_delay_min, retarget_delay_max),
			rng.randi(),
			_ship
		)
		enemy.detection_radius = maxf(_world_radius * 2.0, enemy.attack_radius)
		enemy.safe_zone_chase_radius = maxf(safe_zone_chase_radius, enemy.attack_radius)
		_register_spawned_enemy(enemy)
		spawned_positions.append(spawn_position)
		spawned_count += 1

	return spawned_count


func _create_enemy(rng: RandomNumberGenerator) -> Enemy:
	var enemy_scene := ENEMY_SCENE
	if rng.randf() < ENEMY_2_SPAWN_CHANCE:
		enemy_scene = ENEMY_2_SCENE

	return enemy_scene.instantiate() as Enemy


func _create_enemy_for_rule(rng: RandomNumberGenerator, rule: Resource) -> Enemy:
	if rule == null:
		return _create_enemy(rng)
	if not (rule is WaveEnemyRule):
		return _create_enemy(rng)

	var enemy_scene: PackedScene = rule.enemy_scene as PackedScene
	if enemy_scene == null:
		enemy_scene = _get_enemy_scene_for_key(rule.id)
	if enemy_scene == null:
		return null

	var enemy := enemy_scene.instantiate() as Enemy
	if enemy != null:
		enemy.network_scene_key = rule.id

	return enemy


func _apply_rule_modifiers(enemy: Enemy, rule: Resource) -> void:
	if enemy == null or rule == null:
		return
	if not (rule is WaveEnemyRule):
		return

	enemy.hit_points = maxi(int(round(float(enemy.hit_points) * maxf(rule.hp_multiplier, 0.1))), 1)
	enemy.damage_per_shot = maxi(int(round(float(enemy.damage_per_shot) * maxf(rule.damage_multiplier, 0.1))), 0)


func _get_rule_speed_multiplier(rule: Resource) -> float:
	if rule == null:
		return 1.0
	if not (rule is WaveEnemyRule):
		return 1.0

	return maxf(rule.speed_multiplier, 0.1)


func _get_enemy_scene_for_key(scene_key: StringName) -> PackedScene:
	if scene_key == &"enemy_2":
		return ENEMY_2_SCENE
	if scene_key == &"enemy":
		return ENEMY_SCENE

	var timeline_scene := _find_enemy_scene_in_timeline(scene_key)
	return timeline_scene if timeline_scene != null else ENEMY_SCENE


func _find_enemy_scene_in_timeline(scene_key: StringName) -> PackedScene:
	if wave_timeline == null:
		return null

	for wave in wave_timeline.waves:
		if wave == null:
			continue
		for rule in wave.enemy_pools:
			if rule != null and rule is WaveEnemyRule and rule.id == scene_key and rule.enemy_scene != null:
				return rule.enemy_scene
		for event in wave.events:
			if event == null or not (event is WaveEvent) or event.enemy_rule == null:
				continue
			if not (event.enemy_rule is WaveEnemyRule):
				continue
			if event.enemy_rule.id == scene_key and event.enemy_rule.enemy_scene != null:
				return event.enemy_rule.enemy_scene

	return null


func _get_wave_debug_name(wave: Resource) -> String:
	if wave == null:
		return "<null wave>"
	var wave_id := String(wave.get("id"))
	if not wave_id.is_empty():
		return wave_id
	return wave.resource_path if not wave.resource_path.is_empty() else wave.get_class()


func _get_active_enemy_count_for_key(scene_key: StringName) -> int:
	var active_enemy_count := 0
	for child in get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if enemy.is_defender:
			continue
		if enemy.network_scene_key == scene_key:
			active_enemy_count += 1

	return active_enemy_count


func create_enemy_for_network(scene_key: StringName, enemy_network_id: int) -> Enemy:
	if not can_spawn_enemy():
		return null

	var enemy_scene := _get_enemy_scene_for_key(scene_key)
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return null

	enemy.network_id = enemy_network_id
	enemy.network_scene_key = scene_key
	add_child(enemy)
	if enemy.has_method("set_network_identity"):
		enemy.call("set_network_identity", false)
	enemy.set_process(true)
	return enemy


func _queue_defending_groups() -> void:
	_pending_defending_groups.clear()
	_defender_activation_check_timer = 0.0

	if not spawn_defending_groups or defending_group_count <= 0 or _is_network_client():
		return

	var group_centers: Array[Vector2] = []
	var safe_group_count: int = maxi(defending_group_count, 0)
	for group_index in range(safe_group_count):
		var group_center: Vector2 = _pick_defending_group_center(_defender_rng, group_centers, group_index, safe_group_count)
		group_centers.append(group_center)
		var group_size: int = _defender_rng.randi_range(
			mini(defending_group_size_min, defending_group_size_max),
			maxi(defending_group_size_min, defending_group_size_max)
		)
		_pending_defending_groups.append({
			"center": group_center,
			"size": group_size,
			"seed": _defender_rng.randi(),
		})


func _process_pending_defending_groups(delta: float) -> void:
	if _pending_defending_groups.is_empty() or _is_network_client():
		return

	_defender_activation_check_timer -= maxf(delta, 0.0)
	if _defender_activation_check_timer > 0.0:
		return

	_defender_activation_check_timer = DEFENDER_GROUP_ACTIVATION_CHECK_INTERVAL
	_resolve_ship()
	if _ship == null or not is_instance_valid(_ship):
		return

	var ship_position: Vector2 = to_local(_ship.global_position)
	var activation_radius: float = maxf(defending_group_activation_radius, defending_group_detection_radius)
	var activation_radius_squared: float = activation_radius * activation_radius
	for index in range(_pending_defending_groups.size() - 1, -1, -1):
		if get_available_enemy_spawn_slots() <= 0:
			return

		var group: Dictionary = _pending_defending_groups[index]
		var group_center: Vector2 = group.get("center", Vector2.ZERO) as Vector2
		if ship_position.distance_squared_to(group_center) > activation_radius_squared:
			continue

		var group_rng: RandomNumberGenerator = RandomNumberGenerator.new()
		group_rng.seed = int(group.get("seed", 0))
		_spawn_defending_group(group_center, int(group.get("size", 0)), group_rng)
		_pending_defending_groups.remove_at(index)


func _spawn_defending_group(group_center: Vector2, group_size: int, rng: RandomNumberGenerator) -> void:
	var spawn_count := mini(maxi(group_size, 0), get_available_enemy_spawn_slots())
	if spawn_count <= 0:
		return

	var formation_radius := rng.randf_range(
		minf(defending_group_formation_radius_min, defending_group_formation_radius_max),
		maxf(defending_group_formation_radius_min, defending_group_formation_radius_max)
	)
	for enemy_index in range(spawn_count):
		var enemy := _create_enemy(rng)
		if enemy == null:
			continue

		var home_position := _get_defending_enemy_home_position(group_center, formation_radius, enemy_index, spawn_count, rng)
		enemy.network_id = _next_enemy_network_id
		_next_enemy_network_id += 1
		enemy.is_defender = true
		enemy.position = home_position
		enemy.z_index = -20
		enemy.configure_patrol(
			home_position,
			maxf(enemy.movement_tolerance * 2.0, 64.0),
			rng.randf_range(move_speed_min, move_speed_max),
			rng.randf_range(turn_speed_min, turn_speed_max),
			_world_radius,
			retarget_delay_max,
			retarget_delay_max,
			rng.randi(),
			_ship
		)
		enemy.detection_radius = maxf(defending_group_detection_radius, enemy.attack_radius)
		enemy.safe_zone_chase_radius = maxf(safe_zone_chase_radius, enemy.attack_radius)
		enemy.configure_defense_area(group_center, defending_group_detection_radius, true)
		_register_spawned_enemy(enemy)


func _pick_defending_group_center(
	rng: RandomNumberGenerator,
	existing_centers: Array[Vector2],
	group_index: int,
	group_count: int
) -> Vector2:
	var inner_radius := _world_radius * clampf(defending_group_inner_radius_ratio, 0.0, 1.0)
	var outer_radius := _world_radius * clampf(defending_group_outer_radius_ratio, 0.0, 1.0)
	if outer_radius < inner_radius:
		var swap_radius := inner_radius
		inner_radius = outer_radius
		outer_radius = swap_radius
	outer_radius = maxf(outer_radius, inner_radius + defending_group_min_separation)

	var base_angle := TAU * float(group_index) / maxf(float(group_count), 1.0)
	var fallback_position := Vector2.RIGHT.rotated(base_angle) * rng.randf_range(inner_radius, outer_radius)
	for _attempt in range(DEFENDER_GROUP_CENTER_ATTEMPTS):
		var angle := base_angle + rng.randf_range(-TAU * 0.18, TAU * 0.18)
		var radius := rng.randf_range(inner_radius, outer_radius)
		var candidate := Vector2.RIGHT.rotated(angle) * radius
		if _ship != null and is_instance_valid(_ship):
			var ship_clearance := maxf(defending_group_detection_radius * 1.2, defending_group_min_separation)
			if candidate.distance_to(_ship.global_position) < ship_clearance:
				continue
		if _is_far_enough_from_positions(candidate, existing_centers, defending_group_min_separation):
			return candidate

	return fallback_position


func _get_defending_enemy_home_position(
	group_center: Vector2,
	formation_radius: float,
	enemy_index: int,
	group_size: int,
	rng: RandomNumberGenerator
) -> Vector2:
	if group_size <= 1:
		return group_center

	var normalized_index := float(enemy_index) / maxf(float(group_size - 1), 1.0)
	var radius := formation_radius * sqrt(normalized_index)
	var angle := float(enemy_index) * DEFENDER_GOLDEN_ANGLE + rng.randf_range(-0.16, 0.16)
	var jitter := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(0.0, 48.0)
	return group_center + Vector2.RIGHT.rotated(angle) * radius + jitter


func _register_spawned_enemy(enemy: Enemy) -> void:
	var destroyed_callable := Callable(self, "_on_enemy_destroyed")
	if not enemy.is_connected("destroyed", destroyed_callable):
		enemy.connect("destroyed", destroyed_callable)
	var damage_taken_callable := Callable(self, "_on_enemy_damage_taken")
	if enemy.has_signal("damage_taken") and not enemy.is_connected("damage_taken", damage_taken_callable):
		enemy.connect("damage_taken", damage_taken_callable)
	add_child(enemy)
	enemy_spawned.emit(enemy)


func _get_active_wave_enemy_count() -> int:
	var active_enemy_count := 0
	for child in get_children():
		var enemy := child as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or enemy.is_defender:
			continue
		active_enemy_count += 1

	return active_enemy_count


func _is_network_client() -> bool:
	var network_session := get_node_or_null("/root/NetworkSession")
	if network_session == null:
		return false
	if not bool(network_session.call("is_multiplayer_enabled")):
		return false

	return bool(network_session.call("is_client"))


func _is_far_enough_from_positions(candidate: Vector2, existing_positions: Array[Vector2], required_separation: float) -> bool:
	for existing_position in existing_positions:
		if candidate.distance_to(existing_position) < required_separation:
			return false

	return true


func _emit_wave_state_changed() -> void:
	wave_state_changed.emit(get_wave_time_left(), get_next_wave_size())


func get_wave_time_left() -> float:
	return maxf(_wave_timer, 0.0)


func get_next_wave_size() -> int:
	if _uses_wave_timeline():
		var wave := _get_timeline_wave(_timeline_wave_index)
		if wave == null:
			return 0
		return maxi(_timeline_spawn_budget_left, 0)

	return _get_wave_size(_wave_count)


func _pick_spawn_position(rng: RandomNumberGenerator, spawned_positions: Array[Vector2]) -> Vector2:
	var inner_radius := _get_spawn_inner_radius()
	var outer_radius := _get_spawn_outer_radius()
	var fallback_position := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(inner_radius, outer_radius)

	for _attempt in range(16):
		var angle := rng.randf_range(0.0, TAU)
		var radius := lerpf(inner_radius, outer_radius, pow(rng.randf(), 0.72))
		var candidate := Vector2.RIGHT.rotated(angle) * radius
		if _is_far_enough(candidate, spawned_positions):
			return candidate

	return fallback_position


func _pick_debug_spawn_position(rng: RandomNumberGenerator, spawned_positions: Array[Vector2], enemy: Enemy) -> Vector2:
	return _pick_hidden_spawn_position_near_ship(rng, spawned_positions, enemy)


func _pick_hidden_spawn_position_near_ship(rng: RandomNumberGenerator, spawned_positions: Array[Vector2], enemy: Enemy) -> Vector2:
	if _ship == null or not is_instance_valid(_ship):
		return _pick_spawn_position(rng, spawned_positions)

	var ship_position := _ship.position
	var min_distance := _get_hidden_spawn_min_distance(enemy)
	var max_distance := maxf(debug_spawn_max_distance, min_distance + maxf(min_separation, 600.0))
	var world_limit := maxf(_world_radius - debug_spawn_world_margin, min_distance)
	var ship_position_length := ship_position.length()
	var hidden_candidate := Vector2.ZERO
	var has_hidden_candidate := false

	for pass_index in range(HIDDEN_SPAWN_EXPANSION_PASSES):
		var pass_max_distance := minf(max_distance + float(pass_index) * maxf(min_separation, 600.0), world_limit)
		for _attempt in range(HIDDEN_SPAWN_ATTEMPTS_PER_PASS):
			var direction := _pick_spawn_direction_near_ship(rng, ship_position)
			var candidate := ship_position + direction * rng.randf_range(min_distance, pass_max_distance)
			if candidate.length() > world_limit:
				continue
			if candidate.distance_to(ship_position) < min_distance:
				continue
			if candidate.distance_to(ship_position) > pass_max_distance:
				continue
			if not _is_spawn_position_hidden(candidate):
				continue
			if not has_hidden_candidate:
				hidden_candidate = candidate
				has_hidden_candidate = true
			if not _is_far_enough(candidate, spawned_positions):
				continue

			return candidate

	if has_hidden_candidate:
		return hidden_candidate

	for _attempt in range(HIDDEN_SPAWN_ATTEMPTS_PER_PASS):
		var direction := _pick_spawn_direction_near_ship(rng, ship_position)
		var candidate := ship_position + direction * rng.randf_range(min_distance, max_distance)
		if candidate.length() > world_limit:
			continue
		if not _is_far_enough(candidate, spawned_positions):
			continue

		return candidate

	var fallback_direction := _pick_spawn_direction_near_ship(rng, ship_position)
	var fallback_distance := minf(max_distance, ship_position_length + world_limit)
	fallback_distance = maxf(fallback_distance, min_distance)
	return ship_position + fallback_direction * fallback_distance


func _pick_spawn_direction_near_ship(rng: RandomNumberGenerator, ship_position: Vector2) -> Vector2:
	if ship_position == Vector2.ZERO:
		return Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))

	var inward_bias := (-ship_position).normalized()
	return Vector2.RIGHT.rotated(inward_bias.angle() + rng.randf_range(-PI * 0.7, PI * 0.7))


func _get_hidden_spawn_min_distance(enemy: Enemy) -> float:
	var touch_radius := 0.0
	if enemy != null and enemy.has_method("get_touch_radius"):
		touch_radius = maxf(float(enemy.call("get_touch_radius")), 0.0)

	return maxf(maxf(debug_spawn_min_distance, touch_radius * 2.0), _get_ship_active_vision_outer_radius() + hidden_spawn_fog_padding)


func _get_ship_active_vision_outer_radius() -> float:
	var vision_radius := 900.0
	var edge_softness_ratio := 0.0
	if _fog_of_war != null:
		vision_radius = maxf(float(_fog_of_war.get("visible_radius")), 1.0)
		edge_softness_ratio = clampf(float(_fog_of_war.get("visible_edge_softness_ratio")), 0.0, 1.0)
	if _ship != null and is_instance_valid(_ship) and _ship.has_method("get_vision_radius"):
		vision_radius = maxf(float(_ship.call("get_vision_radius", vision_radius)), 1.0)

	return vision_radius * (1.0 + edge_softness_ratio)


func _is_spawn_position_hidden(candidate: Vector2) -> bool:
	if _fog_of_war == null or not is_instance_valid(_fog_of_war):
		return true
	var fog_canvas_item := _fog_of_war as CanvasItem
	if fog_canvas_item != null and not fog_canvas_item.visible:
		return true
	if _fog_of_war.has_method("get_world_position_active_vision_alpha"):
		return float(_fog_of_war.call("get_world_position_active_vision_alpha", candidate)) <= hidden_spawn_active_vision_alpha_limit
	if _fog_of_war.has_method("is_world_position_in_active_vision"):
		return not bool(_fog_of_war.call("is_world_position_in_active_vision", candidate))

	return true


func _get_spawn_inner_radius() -> float:
	var safe_world_radius := maxf(_world_radius, 1.0)
	var outside_gap := maxf(spawn_radius * clampf(inner_clear_radius_ratio, 0.0, 1.0), 1.0)
	return safe_world_radius + outside_gap


func _get_spawn_outer_radius() -> float:
	var safe_world_radius := maxf(_world_radius, 1.0)
	return safe_world_radius + maxf(spawn_radius, 1.0)


func _is_far_enough(candidate: Vector2, spawned_positions: Array[Vector2]) -> bool:
	for existing_position in spawned_positions:
		if candidate.distance_to(existing_position) < min_separation:
			return false

	return true


func _on_enemy_destroyed(xp_amount: int, world_position: Vector2, enemy: Node2D) -> void:
	enemy_destroyed.emit(maxi(xp_amount, 0), world_position, enemy)


func _on_enemy_damage_taken(amount: int, world_position: Vector2, enemy: Node2D) -> void:
	enemy_damage_taken.emit(maxi(amount, 0), world_position, enemy)

extends Node2D

const SHIP_DISTORTION_SHADER: Shader = preload("res://shaders/ship_distortion.gdshader")
const SHIP_CAMOUFLAGE_MIRROR_SHADER: Shader = preload("res://shaders/ship_camouflage_mirror.gdshader")
const DAMAGE_IMPACT_FX_SCRIPT: Script = preload("res://scripts/damage_impact_fx.gd")
const DRONE_COMPANION_MANAGER_SCRIPT: Script = preload("res://scripts/drone_companion_manager.gd")
const HOMING_MISSILE_SCENE: PackedScene = preload("res://scenes/homing_missile.tscn")
const SHIP_EXPLOSION_SCENE: PackedScene = preload("res://scenes/ship_explosion_fx.tscn")
const LASER_PROJECTILE_SCRIPT: Script = preload("res://scripts/laser_projectile.gd")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const ENEMY_GROUP: StringName = &"enemies"
const PLAYER_GROUP: StringName = &"player_ships"
const EXPLORER_BEACON_GROUP: StringName = &"explorer_beacons"
const XP_BOX_REWARD_MULTIPLIER: int = 3
const DEFAULT_BASE_VISION_RADIUS: float = 900.0
const NETWORK_INTERPOLATION_DELAY: float = 0.12
const NETWORK_MAX_EXTRAPOLATION: float = 0.10
const NETWORK_CORRECTION_MIN_DISTANCE: float = 12.0
const NETWORK_CORRECTION_SNAP_DISTANCE: float = 1200.0
const NETWORK_CORRECTION_BLEND: float = 0.18
const NETWORK_MAX_SNAPSHOT_BUFFER_SIZE: int = 12
const SHIELD_HIT_POINTS_PER_LEVEL: int = 10
const VORTEX_CAPTURE_LOCK_SECONDS: float = 0.22
const FOG_PRESENTATION_VISIBLE_EPSILON: float = 0.01
const MIN_DECELERATION_ADVANTAGE: float = 1.0

signal hp_changed(current_hp: int, max_hp: int)
signal died
signal loadout_changed(laser_level: int, battery_level: int, drone_level: int)
signal inventory_changed(inventory: Dictionary)
signal shield_changed(current_shield_hp: int, max_shield_hp: int, shield_level: int)
signal experience_collected(amount: int, world_position: Vector2)

@export_group("Movement")
@export var move_speed: float = 650.0
@export var target_tolerance: float = 4.0
@export var acceleration: float = 420.0
@export var deceleration: float = 1200.0
@export_range(0.0, 720.0, 1.0, "radians_as_degrees") var turn_speed: float = PI
@export_range(-180.0, 180.0, 1.0, "radians_as_degrees") var sprite_forward_rotation_offset: float = PI * 0.5

@export_group("Easing")
@export_range(0.0, 1.0, 0.01) var minimum_turn_speed_factor: float = 0.35

@export_group("Idle Float")
@export_range(0.0, 8.0, 0.01) var idle_float_amount: float = 3.8
@export_range(0.0, 3.0, 0.01) var idle_float_speed: float = 0.52
@export_range(0.0, 0.08, 0.001) var idle_rotation_amount: float = 0.035
@export_range(0.0, 0.05, 0.001) var idle_scale_amount: float = 0.018
@export_range(0.0, 1.0, 0.01) var idle_internal_wobble_amount: float = 0.72
@export_range(0.0, 3.0, 0.01) var idle_internal_wobble_speed: float = 1.12

@export_group("Launch")
@export_range(0.0, 12.0, 0.01) var launch_shake_amount: float = 4.2
@export_range(0.0, 0.12, 0.001) var launch_rotation_amount: float = 0.045
@export_range(0.0, 8.0, 0.01) var launch_pulse_decay: float = 2.4
@export_range(0.0, 24.0, 0.1) var launch_vibration_speed: float = 12.0

@export_group("Jets")
@export var min_jet_amount_ratio: float = 3.0
@export var jet_warmup_speed: float = 8.0
@export var jet_length_scale_min: float = 1.25
@export var jet_length_scale_max: float = 4.8
@export var jet_turn_power_boost: float = 0.9

@export_group("Upgrades")
@export_range(0.0, 1.0, 0.01) var battery_move_speed_bonus_per_level: float = 0.5
@export_range(0.0, 1.0, 0.01) var battery_acceleration_bonus_per_level: float = 0.5
@export_range(0.0, 1.0, 0.01) var battery_jet_power_bonus_per_level: float = 0.15
@export_range(0.0, 1.0, 0.01) var battery_thrust_response_bonus_per_level: float = 0.08
@export_range(1, 999, 1) var laser_base_damage: int = 1
@export_range(0.1, 10.0, 0.05) var laser_fire_interval: float = 0.75
@export_range(0.0, 1.0, 0.01) var laser_fire_rate_bonus_per_level: float = 0.15
@export_range(100.0, 6000.0, 10.0) var laser_fire_range: float = 1600.0
@export_range(1.0, 180.0, 1.0) var laser_fire_cone_degrees: float = 90.0
@export_range(500.0, 24000.0, 50.0) var laser_projectile_speed: float = 4200.0
@export_range(0.05, 4.0, 0.01) var laser_projectile_base_scale: float = 0.4
@export_range(0.0, 1.0, 0.01) var laser_projectile_scale_per_level: float = 0.08
@export_range(0.0, 240.0, 1.0) var combat_drift_speed: float = 34.0
@export_range(0.0, 4.0, 0.01) var combat_drift_duration: float = 0.65

@export_group("Distortion")
@export_range(0.0, 24.0, 0.1) var thrust_visual_response: float = 9.0
@export_range(0.0, 0.05, 0.001) var thrust_distortion_amount: float = 0.018
@export_range(0.0, 1.0, 0.01) var thrust_distortion_focus: float = 0.58
@export_range(0.0, 1.0, 0.01) var thrust_scale_boost: float = 0.018
@export_range(0.0, 1.0, 0.01) var launch_scale_boost: float = 0.028

@export_group("Selection")
@export var selection_ring_color: Color = Color(1.0, 0.86, 0.1, 0.2)
@export var selection_ring_width: float = 4.0
@export var selection_ring_padding: float = 28.0
@export var selection_ring_fade_duration: float = 0.18

@export_group("Health")
@export_range(1, 999, 1) var max_hit_points: int = 10
@export var owner_peer_id: int = 0
@export var is_local_player: bool = false
@export var is_server_authority: bool = false

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

@export_group("Shield")
@export_range(0.0, 30.0, 0.1) var shield_regen_delay: float = 3.0
@export_range(0.0, 100.0, 0.1) var shield_regen_hit_points_per_second: float = 1.0

@export_group("Pickup Magnet")
@export_range(0.0, 1000.0, 1.0) var vacuum_pickup_radius_bonus_per_level: float = 220.0

@export_group("Vision")
@export_range(0.0, 5000.0, 1.0) var radar_vision_radius_bonus_per_level: float = 100.0

@export_group("Invisibility")
@export_range(1.0, 600.0, 0.5) var invisibility_duration_per_pickup: float = 12.0
@export_range(0.0, 1.0, 0.01) var invisibility_visual_alpha: float = 0.18
@export_range(0.0, 0.05, 0.001) var invisibility_distortion_bonus: float = 0.012
@export_range(0.0, 1.0, 0.01) var remote_invisibility_visual_alpha: float = 0.38
@export var remote_invisibility_tint_color: Color = Color(0.16, 0.72, 1.0, 1.0)
@export_range(0.0, 0.05, 0.001) var remote_invisibility_refraction_strength: float = 0.018
@export_range(1.0, 24.0, 0.5) var remote_invisibility_wave_frequency: float = 7.0
@export_range(0.0, 12.0, 0.1) var remote_invisibility_wave_speed: float = 1.7
@export_range(0.0, 1.0, 0.01) var remote_invisibility_mirror_mix: float = 0.72
@export_range(0.0, 2.0, 0.01) var remote_invisibility_edge_strength: float = 1.25
@export_range(0.0, 1.0, 0.01) var remote_invisibility_shimmer_strength: float = 0.38

@onready var visuals_root: Node2D = $Visuals
@onready var ship_sprite: Sprite2D = $Visuals/shipSprite
@onready var shield_visual: Sprite2D = $Visuals/shipSprite/Shield
@onready var jets_root: Node2D = $Visuals/Jets
@onready var left_jet: CPUParticles2D = $Visuals/Jets/LeftJet
@onready var right_jet: CPUParticles2D = $Visuals/Jets/RightJet
@onready var artifacts_root: Node = $Artifacts

var _target_position: Vector2
var _is_moving: bool = false
var _is_selected: bool = false
var _selection_ring_alpha: float = 0.0
var _selection_ring_tween: Tween
var _pickup_flash_tween: Tween
var _damage_flash_tween: Tween
var _current_speed: float = 0.0
var _jet_strength: float = 0.0
var _turn_bias: float = 0.0
var _left_jet_lifetime: float = 0.0
var _right_jet_lifetime: float = 0.0
var _left_jet_speed_scale: float = 0.0
var _right_jet_speed_scale: float = 0.0
var _left_jet_scale_amount_max: float = 0.0
var _right_jet_scale_amount_max: float = 0.0
var _hit_points: int = 10
var _is_destroyed: bool = false
var _death_fx_played: bool = false
var _sprite_base_position: Vector2 = Vector2.ZERO
var _sprite_base_rotation: float = 0.0
var _sprite_base_scale: Vector2 = Vector2.ONE
var _visuals_base_position: Vector2 = Vector2.ZERO
var _visuals_base_rotation: float = 0.0
var _visuals_base_scale: Vector2 = Vector2.ONE
var _jets_base_position: Vector2 = Vector2.ZERO
var _jets_base_rotation: float = 0.0
var _jets_base_scale: Vector2 = Vector2.ONE
var _ship_material: ShaderMaterial
var _remote_invisibility_material: ShaderMaterial
var _idle_elapsed: float = 0.0
var _launch_pulse: float = 0.0
var _thrust_visual_strength: float = 0.0
var _idle_seed_a: float = 0.0
var _idle_seed_b: float = 0.0
var _idle_seed_c: float = 0.0
var _laser_level: int = 1
var _laser_rate_level: int = 0
var _battery_level: int = 0
var _drone_level: int = 0
var _homing_missile_level: int = 0
var _shield_level: int = 0
var _shield_level_damage: int = 0
var _shield_regen_delay_left: float = 0.0
var _shield_regen_remainder: float = 0.0
var _vacuum_level: int = 0
var _radar_level: int = 0
var _invisibility_time_left: float = 0.0
var _invisibility_last_inventory_seconds: int = 0
var _is_god_mode_enabled: bool = false
var _debug_show_vacuum_radius: bool = false
var _debug_no_artifact_cooldowns: bool = false
var _inventory_levels: Dictionary = {&"laser": 1}
var _artifact_by_item_kind: Dictionary = {}
var _weapon_fire_cooldown: float = 0.0
var _homing_missile_fire_cooldown: float = 0.0
var _homing_missile_volley_delay_left: float = 0.0
var _homing_missile_volley_index: int = 0
var _homing_missile_volley_total: int = 0
var _homing_missile_config: HomingMissile
var _combat_drift_time_left: float = 0.0
var _combat_drift_direction: Vector2 = Vector2.ZERO
var _drone_companion_manager: DroneCompanionManager
var _is_network_presentation: bool = false
var _network_snapshot_buffer: Array[Dictionary] = []
var _last_interpolated_position: Vector2 = Vector2.ZERO
var _is_fog_presentation_visible: bool = true
var _fog_presentation_alpha: float = 1.0
var _fog_active_vision_query: Callable = Callable()
var _vortex_capture_time_left: float = 0.0
var _vortex_capture_strength: float = 0.0
var _vortex_capture_center: Vector2 = Vector2.ZERO
var _vortex_local_direction: Vector2 = Vector2(0.0, -1.0)
var _artifact_warp_distortion_time_left: float = 0.0
var _artifact_warp_distortion_duration: float = 0.0
var _artifact_warp_vortex_strength: float = 0.0
var _artifact_warp_vortex_target_strength: float = 0.0
var _artifact_warp_vortex_direction: Vector2 = Vector2(0.0, -1.0)
var _artifact_warp_holo_time_left: float = 0.0
var _artifact_warp_holo_duration: float = 0.0
var _artifact_warp_holo_fade_out_duration: float = 0.0
var _artifact_warp_holo_strength: float = 0.0
var _artifact_warp_holo_target_strength: float = 0.0
var _are_jets_emitting: bool = false
var _propulsion_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	global_position = _clamp_to_galaxy_bounds(global_position)
	_target_position = global_position
	_visuals_base_position = visuals_root.position
	_visuals_base_rotation = visuals_root.rotation
	_visuals_base_scale = visuals_root.scale
	_sprite_base_position = ship_sprite.position
	_sprite_base_rotation = ship_sprite.rotation
	_sprite_base_scale = ship_sprite.scale
	_jets_base_position = jets_root.position
	_jets_base_rotation = jets_root.rotation
	_jets_base_scale = jets_root.scale
	_left_jet_lifetime = left_jet.lifetime
	_right_jet_lifetime = right_jet.lifetime
	_left_jet_speed_scale = left_jet.speed_scale
	_right_jet_speed_scale = right_jet.speed_scale
	_left_jet_scale_amount_max = left_jet.scale_amount_max
	_right_jet_scale_amount_max = right_jet.scale_amount_max
	_hit_points = max_hit_points
	_is_destroyed = false
	_death_fx_played = false
	_laser_level = 1
	_laser_rate_level = 0
	_battery_level = 0
	_drone_level = 0
	_homing_missile_level = 0
	_shield_level = 0
	_shield_level_damage = 0
	_shield_regen_delay_left = 0.0
	_shield_regen_remainder = 0.0
	_vacuum_level = 0
	_radar_level = 0
	_invisibility_time_left = 0.0
	_invisibility_last_inventory_seconds = 0
	_setup_artifacts()
	_sync_inventory_from_loadout()

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_idle_seed_a = rng.randf_range(0.0, TAU)
	_idle_seed_b = rng.randf_range(0.0, TAU)
	_idle_seed_c = rng.randf_range(0.0, TAU)

	_ship_material = ShaderMaterial.new()
	_ship_material.shader = SHIP_DISTORTION_SHADER
	ship_sprite.material = _ship_material
	_ship_material.set_shader_parameter("pickup_flash_strength", 0.0)
	_ship_material.set_shader_parameter("pickup_flash_color", Color(0.95, 1.0, 1.0, 1.0))
	_ship_material.set_shader_parameter("pickup_flash_hotness", 1.9)
	_ship_material.set_shader_parameter("pickup_flash_glow", 0.52)
	_ship_material.set_shader_parameter("damage_flash_strength", 0.0)
	_ship_material.set_shader_parameter("damage_flash_color", Color(1.0, 0.25, 0.2, 1.0))
	_ship_material.set_shader_parameter("damage_flash_hotness", 1.8)
	_ship_material.set_shader_parameter("damage_flash_glow", 0.64)
	_ship_material.set_shader_parameter("vortex_strength", 0.0)
	_ship_material.set_shader_parameter("vortex_direction", _vortex_local_direction)
	_ship_material.set_shader_parameter("holo_effect_strength", 0.0)
	_ship_material.set_shader_parameter("global_fade", _fog_presentation_alpha)
	_remote_invisibility_material = ShaderMaterial.new()
	_remote_invisibility_material.shader = SHIP_CAMOUFLAGE_MIRROR_SHADER
	_apply_remote_invisibility_shader_parameters()
	if shield_visual != null and shield_visual.has_method("setup"):
		shield_visual.call("setup")

	_ensure_propulsion_player()
	_set_jets_emitting(false)
	_apply_ship_visuals()
	hp_changed.emit(_hit_points, _get_max_hit_points())
	loadout_changed.emit(_laser_level, _battery_level, _drone_level)
	inventory_changed.emit(get_inventory_levels())
	_emit_shield_changed()
	_sync_drone_companions()


func _exit_tree() -> void:
	_stop_propulsion_sfx()
	if _homing_missile_config != null and is_instance_valid(_homing_missile_config):
		_homing_missile_config.free()
	_homing_missile_config = null


func _get_homing_missile_config() -> HomingMissile:
	if _homing_missile_config == null or not is_instance_valid(_homing_missile_config):
		_homing_missile_config = HOMING_MISSILE_SCENE.instantiate() as HomingMissile
	return _homing_missile_config


func _physics_process(delta: float) -> void:
	if _is_destroyed:
		return

	if _is_vortex_captured():
		_stop_movement()
	elif _should_simulate_movement():
		_update_movement(delta)
		_update_combat_drift(delta)


func _process(delta: float) -> void:
	if _is_destroyed:
		return

	if _should_interpolate_network_snapshots():
		_update_network_interpolation(delta)

	_update_vortex_capture_state(delta)
	_update_artifact_warp_distortion(delta)
	_update_artifact_warp_holo(delta)
	_update_invisibility(delta)
	_update_artifacts(delta)
	if _should_update_visual_presentation():
		_update_jets(delta)
		_update_ship_visuals(delta)
	else:
		_sleep_visual_presentation()
	if _should_run_authoritative_gameplay():
		_update_shield_regen(delta)
		if _is_vortex_captured():
			_suppress_attacks_while_vortex_captured()
			return
		_update_combat(delta)
		_update_homing_missiles(delta)


func _draw() -> void:
	if _debug_show_vacuum_radius and _vacuum_level > 0:
		var vacuum_radius := get_pickup_attraction_radius()
		if vacuum_radius > 0.0:
			var vacuum_color := Color(0.10, 0.86, 1.0, 0.14)
			draw_arc(visuals_root.position, vacuum_radius, 0.0, TAU, 96, vacuum_color, 3.0, true)

	if not _is_selected or is_zero_approx(_selection_ring_alpha):
		return

	var ring_color := selection_ring_color
	ring_color.a *= _selection_ring_alpha
	draw_arc(visuals_root.position, _get_selection_ring_radius(), 0.0, TAU, 96, ring_color, selection_ring_width, true)


func move_to(world_position: Vector2) -> void:
	if _is_destroyed:
		return
	if _is_vortex_captured():
		return

	var clamped_target := _clamp_to_galaxy_bounds(world_position)
	var travel_distance := global_position.distance_to(clamped_target)
	if travel_distance <= target_tolerance:
		_stop_movement()
		return

	if not _is_moving:
		_launch_pulse = 1.0

	_target_position = clamped_target
	_is_moving = true


func contains_world_position(world_position: Vector2) -> bool:
	if ship_sprite.texture == null:
		return false

	var local_position := ship_sprite.to_local(world_position)
	return ship_sprite.get_rect().has_point(local_position)


func get_touch_radius() -> float:
	if ship_sprite == null:
		return 0.0

	if ship_sprite.texture == null:
		return 0.0

	var texture_size: Vector2 = ship_sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return 0.0

	var scaled_size: Vector2 = texture_size * ship_sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func get_damage_impact_radius() -> float:
	if _get_current_shield_hit_points() <= 0:
		return get_touch_radius()

	return maxf(_get_shield_touch_radius(), get_touch_radius())


func get_damage_impact_position(source_world_position: Vector2 = Vector2.INF) -> Vector2:
	if _get_current_shield_hit_points() <= 0:
		return _get_ship_body_damage_impact_position(source_world_position)

	var shield_radius := _get_shield_touch_radius()
	if shield_radius <= 0.0 or not source_world_position.is_finite():
		return global_position

	var source_to_ship := global_position - source_world_position
	if source_to_ship.length_squared() <= 0.001:
		return global_position

	return global_position - source_to_ship.normalized() * shield_radius


func _get_ship_body_damage_impact_position(source_world_position: Vector2) -> Vector2:
	return DAMAGE_IMPACT_FX_SCRIPT.get_sprite_impact_position(ship_sprite, source_world_position, global_position)


func get_pickup_attraction_radius() -> float:
	if _vacuum_level <= 0:
		return 0.0

	var base_radius := get_touch_radius()
	if base_radius <= 0.0:
		return 0.0

	return base_radius + maxf(float(_vacuum_level), 0.0) * vacuum_pickup_radius_bonus_per_level


func get_vision_radius(base_radius: float) -> float:
	return _get_vision_radius_for_level(_radar_level, base_radius)


func get_weapon_range() -> float:
	return _get_effective_weapon_range()


func set_debug_vacuum_radius_visible(visible: bool) -> void:
	if _debug_show_vacuum_radius == visible:
		return

	_debug_show_vacuum_radius = visible
	queue_redraw()


func set_god_mode_enabled(enabled: bool) -> void:
	_is_god_mode_enabled = enabled


func is_god_mode_enabled() -> bool:
	return _is_god_mode_enabled


func set_debug_no_artifact_cooldowns(enabled: bool) -> void:
	_debug_no_artifact_cooldowns = enabled
	if _debug_no_artifact_cooldowns:
		_clear_artifact_cooldowns()


func set_selected(is_selected: bool) -> void:
	if _is_selected == is_selected:
		return

	if _selection_ring_tween != null:
		_selection_ring_tween.kill()

	if is_selected:
		_is_selected = true

	var fade_duration := maxf(selection_ring_fade_duration, 0.0)
	_selection_ring_tween = create_tween()
	_selection_ring_tween.tween_method(_set_selection_ring_alpha, _selection_ring_alpha, 1.0 if is_selected else 0.0, fade_duration)
	if not is_selected:
		_selection_ring_tween.tween_callback(func() -> void: _is_selected = false)


func take_damage(amount: int, impact_world_position: Vector2 = Vector2.INF) -> int:
	if _is_destroyed or _is_god_mode_enabled or amount <= 0:
		return 0

	var resolved_impact := _resolve_damage_impact_position(impact_world_position)
	var should_spawn_damage_sparks := false

	if _shield_level > 0:
		_reset_shield_regen_delay()

	var previous_shield_level := _shield_level
	var shield_absorbed := _absorb_shield_damage(amount)
	if shield_absorbed > 0:
		if _shield_level != previous_shield_level and _shield_level > 0:
			_update_shield_visuals()
		_trigger_shield_hit(resolved_impact, shield_absorbed)
		should_spawn_damage_sparks = true
		_emit_shield_changed()
		if _shield_level != previous_shield_level:
			inventory_changed.emit(get_inventory_levels())
		amount -= shield_absorbed

	if amount <= 0:
		if should_spawn_damage_sparks:
			_spawn_damage_sparks(resolved_impact)
		return 0

	var applied_damage := mini(amount, _hit_points)
	if applied_damage <= 0:
		return 0

	should_spawn_damage_sparks = true
	_hit_points = maxi(_hit_points - applied_damage, 0)
	hp_changed.emit(_hit_points, _get_max_hit_points())
	if _should_play_damage_flash_on_damage_apply():
		_trigger_damage_flash()
	if should_spawn_damage_sparks:
		_spawn_damage_sparks(resolved_impact)
	if _hit_points <= 0:
		_destroy_ship()

	return applied_damage


func heal_hit_points(amount: int) -> int:
	if _is_destroyed or amount <= 0:
		return 0

	var missing_hit_points: int = maxi(_get_max_hit_points() - _hit_points, 0)
	if missing_hit_points <= 0:
		return 0

	var applied_heal: int = mini(amount, missing_hit_points)
	if applied_heal <= 0:
		return 0

	_hit_points = mini(_hit_points + applied_heal, _get_max_hit_points())
	hp_changed.emit(_hit_points, _get_max_hit_points())
	return applied_heal


func heal_half_max_hit_points() -> int:
	return heal_hit_points(ceili(float(_get_max_hit_points()) * 0.5))


func collect_item(item_kind: StringName, item_level: int = 1, repair_amount: int = 4, source_world_position: Vector2 = Vector2.ZERO) -> void:
	_trigger_pickup_flash()
	var applied_level := maxi(item_level, 1)
	var should_refresh_drones := false
	var should_refresh_shield := false
	var should_emit_inventory := false
	if item_kind == ItemPickup.ITEM_LASER:
		_laser_level += applied_level
		_set_inventory_level(item_kind, _laser_level)
		should_emit_inventory = true
		should_refresh_drones = true
	elif item_kind == ItemPickup.ITEM_LASER_RATE:
		_laser_rate_level += applied_level
		_set_inventory_level(item_kind, _laser_rate_level)
		_weapon_fire_cooldown = minf(_weapon_fire_cooldown, _get_effective_laser_fire_interval())
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_BATTERY:
		_battery_level += applied_level
		_set_inventory_level(item_kind, _battery_level)
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_DRONE:
		_drone_level += applied_level
		_set_inventory_level(item_kind, _drone_level)
		should_emit_inventory = true
		should_refresh_drones = true
	elif item_kind == ItemPickup.ITEM_HOMING_MISSILE:
		_homing_missile_level += applied_level
		_set_inventory_level(item_kind, _homing_missile_level)
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_SHIELD:
		_shield_level += applied_level
		_set_inventory_level(item_kind, _shield_level)
		should_emit_inventory = true
		should_refresh_shield = true
	elif item_kind == ItemPickup.ITEM_VACUUM:
		_vacuum_level += applied_level
		_set_inventory_level(item_kind, _vacuum_level)
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_RADAR:
		_radar_level += applied_level
		_set_inventory_level(item_kind, _radar_level)
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_INVISIBILITY:
		_add_invisibility_time(applied_level)
		should_emit_inventory = true
	elif item_kind == ItemPickup.ITEM_REPAIRSET:
		heal_half_max_hit_points()
		return
	elif item_kind == ItemPickup.ITEM_XP_BOX:
		experience_collected.emit(applied_level * XP_BOX_REWARD_MULTIPLIER, source_world_position)
		return
	else:
		var artifact := _get_artifact(item_kind)
		if artifact != null:
			if artifact.unlock(applied_level):
				_set_inventory_level(item_kind, artifact.get_level())
				should_emit_inventory = true
		else:
			_increment_inventory_level(item_kind, applied_level)
			should_emit_inventory = true

	if should_refresh_drones and _drone_level > 0:
		_sync_drone_companions()
	if should_refresh_shield:
		_update_shield_visuals()
		_emit_shield_changed()

	loadout_changed.emit(_laser_level, _battery_level, _drone_level)
	if should_emit_inventory:
		inventory_changed.emit(get_inventory_levels())


func get_upgrade_preview(item_kind: StringName, item_level: int = 1, repair_amount: int = 4) -> Dictionary:
	var applied_level := maxi(item_level, 1)
	if item_kind == ItemPickup.ITEM_LASER:
		return _build_laser_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_LASER_RATE:
		return _build_laser_rate_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_BATTERY:
		return _build_battery_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_DRONE:
		return _build_drone_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_HOMING_MISSILE:
		return _build_homing_missile_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_SHIELD:
		return _build_shield_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_VACUUM:
		return _build_vacuum_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_RADAR:
		return _build_radar_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_INVISIBILITY:
		return _build_invisibility_upgrade_preview(applied_level)
	elif item_kind == ItemPickup.ITEM_REPAIRSET:
		return _build_repairset_upgrade_preview(applied_level, repair_amount)
	elif item_kind == ItemPickup.ITEM_COLONY_BEACON:
		return _build_colony_beacon_upgrade_preview(applied_level)
	else:
		var artifact := _get_artifact(item_kind)
		if artifact != null:
			return artifact.get_upgrade_preview()

		var preview := {}
		preview["title"] = "Upgrade"
		preview["summary"] = "Applies an upgrade to the ship."
		preview["tooltip"] = "Apply this upgrade to the ship."
		return preview


func _build_laser_upgrade_preview(applied_level: int) -> Dictionary:
	var current_damage := maxi(1, laser_base_damage * _laser_level)
	var next_damage := maxi(1, laser_base_damage * (_laser_level + applied_level))
	return {
		"title": "Laser",
		"summary": "Damage: %s -> %s (%s)" % [
			_format_number(current_damage, 0),
			_format_number(next_damage, 0),
			_format_change(current_damage, next_damage, 0),
		],
		"tooltip": "Each level adds %s base damage to the shot.\nCurrent damage: %s\nNew damage: %s\nIncrease: %s (%s)" % [
			_format_number(laser_base_damage, 0),
			_format_number(current_damage, 0),
			_format_number(next_damage, 0),
			_format_signed_change(current_damage, next_damage, 0),
			_format_change(current_damage, next_damage, 0),
		],
	}


func _build_laser_rate_upgrade_preview(applied_level: int) -> Dictionary:
	var current_interval := _get_laser_fire_interval_for_rate_level(_laser_rate_level)
	var next_interval := _get_laser_fire_interval_for_rate_level(_laser_rate_level + applied_level)
	var current_rate := 1.0 / maxf(current_interval, 0.001)
	var next_rate := 1.0 / maxf(next_interval, 0.001)
	return {
		"title": "Laser Rate Boost",
		"summary": "Fire rate: %s (%s)" % [
			_format_change(current_rate, next_rate, 1),
			"%s shots/s" % _format_number(next_rate, 2),
		],
		"tooltip": "Each level adds %s%% laser fire rate.\nCurrent cooldown: %s s\nNew cooldown: %s s\nCurrent fire rate: %s shots/s\nNew fire rate: %s shots/s\nIncrease: %s" % [
			_format_percent_delta_from_bonus(laser_fire_rate_bonus_per_level),
			_format_number(current_interval, 2),
			_format_number(next_interval, 2),
			_format_number(current_rate, 2),
			_format_number(next_rate, 2),
			_format_change(current_rate, next_rate, 1),
		],
	}


func _build_battery_upgrade_preview(applied_level: int) -> Dictionary:
	var next_level := _battery_level + applied_level
	var current_speed := _get_move_speed_for_level(_battery_level)
	var next_speed := _get_move_speed_for_level(next_level)
	var current_acceleration := _get_acceleration_for_level(_battery_level)
	var next_acceleration := _get_acceleration_for_level(next_level)
	var current_deceleration := _get_base_deceleration()
	var current_jet_length := _get_jet_length_for_level(_battery_level)
	var next_jet_length := _get_jet_length_for_level(next_level)
	var current_jet_turn_boost := _get_jet_turn_boost_for_level(_battery_level)
	var next_jet_turn_boost := _get_jet_turn_boost_for_level(next_level)
	var current_thrust_response := _get_thrust_response_for_level(_battery_level)
	var next_thrust_response := _get_thrust_response_for_level(next_level)
	return {
		"title": "Battery",
		"summary": "Speed +%s%%\nAcceleration +%s%%\nThrusters +%s%%\nVisual response +%s%%" % [
			_format_percent_delta_from_bonus(battery_move_speed_bonus_per_level),
			_format_percent_delta_from_bonus(battery_acceleration_bonus_per_level),
			_format_percent_delta_from_bonus(battery_jet_power_bonus_per_level),
			_format_percent_delta_from_bonus(battery_thrust_response_bonus_per_level),
		],
		"tooltip": "Speed: %s -> %s (%s)\nAcceleration: %s -> %s (%s)\nBraking: %s\nThrusters: %s -> %s (%s)\nThruster turn power: %s -> %s (%s)\nVisual response: %s -> %s (%s)" % [
			_format_number(current_speed, 1),
			_format_number(next_speed, 1),
			_format_change(current_speed, next_speed, 1),
			_format_number(current_acceleration, 1),
			_format_number(next_acceleration, 1),
			_format_change(current_acceleration, next_acceleration, 1),
			_format_number(current_deceleration, 1),
			_format_number(current_jet_length, 2),
			_format_number(next_jet_length, 2),
			_format_change(current_jet_length, next_jet_length, 1),
			_format_number(current_jet_turn_boost, 2),
			_format_number(next_jet_turn_boost, 2),
			_format_change(current_jet_turn_boost, next_jet_turn_boost, 1),
			_format_number(current_thrust_response, 2),
			_format_number(next_thrust_response, 2),
			_format_change(current_thrust_response, next_thrust_response, 1),
		],
	}


func _build_drone_upgrade_preview(applied_level: int) -> Dictionary:
	var current_drones := _drone_level
	var next_drones := _drone_level + applied_level
	return {
		"title": "Drone",
		"summary": "+%d drone%s" % [applied_level, "s" if applied_level != 1 else ""],
		"tooltip": "Current drones: %s\nNew drones: %s\nIncrease: +%s" % [
			_format_number(current_drones, 0),
			_format_number(next_drones, 0),
			_format_number(applied_level, 0),
		],
	}


func _build_homing_missile_upgrade_preview(applied_level: int) -> Dictionary:
	var homing_missile_config := _get_homing_missile_config()
	var current_missiles := maxi(_homing_missile_level, 0)
	var next_missiles := maxi(_homing_missile_level + applied_level, 0)
	var current_total_damage := current_missiles * maxi(homing_missile_config.damage_per_enemy, 1)
	var next_total_damage := next_missiles * maxi(homing_missile_config.damage_per_enemy, 1)
	return {
		"title": "Homing Missile",
		"summary": "%d missile%s per volley" % [next_missiles, "s" if next_missiles != 1 else ""],
		"tooltip": "Current missiles per volley: %s\nNew missiles per volley: %s\nFire interval: %s s\nImpact radius: %s px\nDamage per missile: %s\nPotential total damage per volley: %s -> %s" % [
			_format_number(float(current_missiles), 0),
			_format_number(float(next_missiles), 0),
			_format_number(homing_missile_config.fire_interval, 2),
			_format_number(homing_missile_config.impact_radius, 0),
			_format_number(float(maxi(homing_missile_config.damage_per_enemy, 1)), 0),
			_format_number(float(current_total_damage), 0),
			_format_number(float(next_total_damage), 0),
		],
	}


func _build_shield_upgrade_preview(applied_level: int) -> Dictionary:
	var current_shield := _shield_level
	var next_shield := _shield_level + applied_level
	var added_absorption := applied_level * SHIELD_HIT_POINTS_PER_LEVEL
	return {
		"title": "Shield",
		"summary": "+%d shield level%s (%s HP)" % [
			applied_level,
			"s" if applied_level != 1 else "",
			_format_number(added_absorption, 0),
		],
		"tooltip": "Each shield level adds %s max shield energy.\nCurrent shield levels: %s\nNew shield levels: %s\nAdditional energy: +%s HP" % [
			_format_number(SHIELD_HIT_POINTS_PER_LEVEL, 0),
			_format_number(current_shield, 0),
			_format_number(next_shield, 0),
			_format_number(added_absorption, 0),
		],
	}


func _build_vacuum_upgrade_preview(applied_level: int) -> Dictionary:
	var current_radius := _get_pickup_attraction_radius_for_level(_vacuum_level)
	var next_radius := _get_pickup_attraction_radius_for_level(_vacuum_level + applied_level)
	var radius_increase := next_radius - current_radius
	var radius_increase_percent := _format_change(current_radius, next_radius, 1)
	return {
		"title": "Vacuum",
		"summary": "Range: %s" % (radius_increase_percent if current_radius > 0.0 else "unlocks"),
		"tooltip": "Current range: %s px\nNew range: %s px\nIncrease: %s px (%s)" % [
			_format_number(current_radius, 0),
			_format_number(next_radius, 0),
			_format_signed_number(radius_increase, 0),
			radius_increase_percent if current_radius > 0.0 else "n/a",
		],
	}


func _build_radar_upgrade_preview(applied_level: int) -> Dictionary:
	var current_radius := _get_vision_radius_for_level(_radar_level, 0.0)
	var next_radius := _get_vision_radius_for_level(_radar_level + applied_level, 0.0)
	var radius_increase := next_radius - current_radius
	var radius_increase_percent := _format_change(current_radius, next_radius, 1)
	return {
		"title": "Radar",
		"summary": "Vision and weapon range: %s" % (radius_increase_percent if current_radius > 0.0 else "+%s px" % _format_number(radius_increase, 0)),
		"tooltip": "Current bonus range: %s px\nNew bonus range: %s px\nWeapons use ship vision range.\nIncrease: %s px (%s)" % [
			_format_number(current_radius, 0),
			_format_number(next_radius, 0),
			_format_signed_number(radius_increase, 0),
			radius_increase_percent if current_radius > 0.0 else "n/a",
		],
	}


func _build_invisibility_upgrade_preview(applied_level: int) -> Dictionary:
	var added_seconds := _get_invisibility_duration_for_level(applied_level)
	var current_seconds := maxf(_invisibility_time_left, 0.0)
	var next_seconds := current_seconds + added_seconds
	return {
		"title": "Invisibility",
		"summary": "Timer: %s -> %s" % [
			_format_duration(current_seconds),
			_format_duration(next_seconds),
		],
		"tooltip": "Enemies stop pursuing and attacking while the timer is active.\nCurrent timer: %s\nAdded time: %s\nNew timer: %s" % [
			_format_duration(current_seconds),
			_format_duration(added_seconds),
			_format_duration(next_seconds),
		],
	}


func _build_repairset_upgrade_preview(_applied_level: int, _repair_amount: int) -> Dictionary:
	var heal_amount := ceili(float(_get_max_hit_points()) * 0.5)
	return {
		"title": "Repair Kit",
		"summary": "Heals 50% HP",
		"tooltip": "Restores %s HP, equal to 50%% of max ship health." % [
			_format_number(float(heal_amount), 0),
		],
	}


func _build_colony_beacon_upgrade_preview(applied_level: int) -> Dictionary:
	var current_count := get_item_count(ItemPickup.ITEM_COLONY_BEACON)
	var next_count := current_count + applied_level
	return {
		"title": "Colony Beacon",
		"summary": "Beacons: %d -> %d" % [current_count, next_count],
		"tooltip": "Spend one beacon to colonize one planet.\nCurrent beacons: %d\nNew beacons: %d" % [
			current_count,
			next_count,
		],
	}


func _get_move_speed_for_level(level: int) -> float:
	return move_speed * (1.0 + float(maxi(level, 0)) * battery_move_speed_bonus_per_level)


func _get_acceleration_for_level(level: int) -> float:
	var boosted_acceleration := acceleration * (1.0 + float(maxi(level, 0)) * battery_acceleration_bonus_per_level)
	return minf(boosted_acceleration, maxf(_get_base_deceleration() - MIN_DECELERATION_ADVANTAGE, 0.0))


func _get_deceleration_for_level(_level: int) -> float:
	return _get_base_deceleration()


func _get_jet_length_for_level(level: int) -> float:
	return jet_length_scale_max * (1.0 + float(maxi(level, 0)) * battery_jet_power_bonus_per_level)


func _get_jet_turn_boost_for_level(level: int) -> float:
	return jet_turn_power_boost * (1.0 + float(maxi(level, 0)) * battery_jet_power_bonus_per_level)


func _get_thrust_response_for_level(level: int) -> float:
	return thrust_visual_response * (1.0 + float(maxi(level, 0)) * battery_thrust_response_bonus_per_level)


func _get_pickup_attraction_radius_for_level(level: int) -> float:
	if level <= 0:
		return 0.0

	return get_touch_radius() + float(level) * vacuum_pickup_radius_bonus_per_level


func _get_vision_radius_for_level(level: int, base_radius: float) -> float:
	return maxf(base_radius, 0.0) + float(maxi(level, 0)) * radar_vision_radius_bonus_per_level


func _get_effective_weapon_range() -> float:
	var vision_radius := get_vision_radius(_get_base_vision_radius())
	var soft_edge_radius := vision_radius * _get_vision_edge_softness_ratio()
	return maxf(vision_radius + soft_edge_radius * 0.5, 1.0)


func _get_base_vision_radius() -> float:
	var fog_of_war := _get_fog_of_war()
	if fog_of_war != null:
		return maxf(float(fog_of_war.get("visible_radius")), 1.0)

	return DEFAULT_BASE_VISION_RADIUS


func _get_vision_edge_softness_ratio() -> float:
	var fog_of_war := _get_fog_of_war()
	if fog_of_war != null:
		return clampf(float(fog_of_war.get("visible_edge_softness_ratio")), 0.0, 1.0)

	return 0.0


func _get_fog_of_war() -> Node:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null:
		return null

	return scene_root.find_child("FogOfWar", true, false)


func _format_number(value: float, decimals: int = 1) -> String:
	if decimals <= 0 or is_equal_approx(value, round(value)):
		return str(int(round(value)))

	var step := pow(10.0, -float(decimals))
	var rounded_value := snappedf(value, step)
	var format_string := "%0." + str(decimals) + "f"
	return format_string % rounded_value


func _format_signed_number(value: float, decimals: int = 1) -> String:
	if decimals <= 0 or is_equal_approx(value, round(value)):
		return "%+d" % int(round(value))

	var step := pow(10.0, -float(decimals))
	var rounded_value := snappedf(value, step)
	var format_string := "%+0." + str(decimals) + "f"
	return format_string % rounded_value


func _format_change(current_value: float, next_value: float, decimals: int = 1) -> String:
	if is_zero_approx(current_value):
		return "n/a"

	var percent_change := ((next_value - current_value) / current_value) * 100.0
	return "%s%%" % _format_signed_number(percent_change, decimals)


func _format_signed_change(current_value: float, next_value: float, decimals: int = 1) -> String:
	return _format_signed_number(next_value - current_value, decimals)


func _format_percent_delta_from_bonus(bonus: float) -> String:
	return _format_number(bonus * 100.0, 0)


func _format_duration(seconds: float) -> String:
	var safe_seconds := maxi(int(ceil(maxf(seconds, 0.0))), 0)
	var minutes := int(safe_seconds / 60)
	var remaining_seconds := safe_seconds % 60
	if minutes > 0:
		return "%d:%02d" % [minutes, remaining_seconds]

	return "%ds" % remaining_seconds


func _trigger_pickup_flash() -> void:
	if _ship_material == null:
		return

	if _pickup_flash_tween != null:
		_pickup_flash_tween.kill()

	_ship_material.set_shader_parameter("pickup_flash_strength", 0.0)
	_pickup_flash_tween = create_tween()
	_pickup_flash_tween.set_trans(Tween.TRANS_SINE)
	_pickup_flash_tween.set_ease(Tween.EASE_OUT)
	_pickup_flash_tween.tween_property(_ship_material, "shader_parameter/pickup_flash_strength", 1.0, 0.055)
	_pickup_flash_tween.tween_property(_ship_material, "shader_parameter/pickup_flash_strength", 0.0, 0.22)


func _trigger_damage_flash() -> void:
	if _ship_material == null:
		return

	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	_ship_material.set_shader_parameter("damage_flash_strength", 0.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.set_trans(Tween.TRANS_SINE)
	_damage_flash_tween.set_ease(Tween.EASE_OUT)
	_damage_flash_tween.tween_property(_ship_material, "shader_parameter/damage_flash_strength", 1.0, 0.055)
	_damage_flash_tween.tween_property(_ship_material, "shader_parameter/damage_flash_strength", 0.0, 0.22)


func _resolve_damage_impact_position(impact_world_position: Vector2) -> Vector2:
	if impact_world_position.is_finite():
		return impact_world_position

	return get_damage_impact_position(global_position + _get_forward_direction() * get_damage_impact_radius())


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
		_should_show_owned_fog_effect(impact_world_position),
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

	var fallback_direction := _get_forward_direction()
	if fallback_direction != Vector2.ZERO:
		return fallback_direction

	return Vector2.RIGHT


func get_hit_points() -> int:
	return _hit_points


func get_max_hit_points() -> int:
	return _get_max_hit_points()


func get_inventory_levels() -> Dictionary:
	return _inventory_levels.duplicate(true)


func get_item_count(item_kind: StringName) -> int:
	return maxi(int(_inventory_levels.get(item_kind, 0)), 0)


func consume_item(item_kind: StringName, amount: int = 1) -> bool:
	var safe_amount := maxi(amount, 1)
	var current_count := get_item_count(item_kind)
	if current_count < safe_amount:
		return false

	_set_inventory_level(item_kind, current_count - safe_amount)
	inventory_changed.emit(get_inventory_levels())
	return true


func has_artifact(item_kind: StringName) -> bool:
	var artifact := _get_artifact(item_kind)
	return artifact != null and artifact.is_owned()


func can_activate_artifact(item_kind: StringName) -> bool:
	var artifact := _get_artifact(item_kind)
	return not _is_destroyed and artifact != null and artifact.can_activate()


func start_predicted_artifact_cooldown(item_kind: StringName) -> bool:
	if not can_activate_artifact(item_kind):
		return false

	var artifact := _get_artifact(item_kind)
	if artifact == null:
		return false

	if not _debug_no_artifact_cooldowns:
		artifact.start_cooldown()
	return true


func activate_artifact(item_kind: StringName) -> bool:
	if not can_activate_artifact(item_kind):
		return false

	var artifact := _get_artifact(item_kind)
	if artifact == null:
		return false

	var activated := artifact.activate()
	if activated and not _debug_no_artifact_cooldowns:
		artifact.start_cooldown()
	return activated


func activate_artifact_at(item_kind: StringName, world_position: Vector2) -> bool:
	if not can_activate_artifact(item_kind):
		return false

	var artifact := _get_artifact(item_kind)
	if artifact == null:
		return false

	var activated := artifact.activate_at(world_position)
	if activated and not _debug_no_artifact_cooldowns:
		artifact.start_cooldown()
	return activated


func get_artifact_cooldown_states() -> Dictionary:
	if _artifact_by_item_kind.is_empty():
		_setup_artifacts()

	var cooldown_states: Dictionary = {}
	for item_kind_variant in _artifact_by_item_kind.keys():
		var item_kind := StringName(item_kind_variant)
		var artifact := _get_artifact(item_kind)
		if artifact == null or not artifact.is_owned():
			continue

		cooldown_states[item_kind] = artifact.get_cooldown_state()

	return cooldown_states


func get_artifact_tunables() -> Dictionary:
	if _artifact_by_item_kind.is_empty():
		_setup_artifacts()

	var tunables: Dictionary = {}
	for item_kind_variant in _artifact_by_item_kind.keys():
		var item_kind := StringName(item_kind_variant)
		var artifact := _get_artifact(item_kind)
		if artifact != null:
			tunables[item_kind] = artifact.get_tunables()

	return tunables


func apply_artifact_tunables(tunables: Dictionary) -> void:
	for item_kind_variant in tunables.keys():
		var item_kind := StringName(item_kind_variant)
		var artifact := _get_artifact(item_kind)
		var artifact_tunables: Variant = tunables.get(item_kind, {})
		if artifact != null and artifact_tunables is Dictionary:
			artifact.apply_tunables(artifact_tunables as Dictionary)


func get_artifact_preview_radius(item_kind: StringName) -> float:
	var artifact := _get_artifact(item_kind)
	if artifact == null:
		return 0.0

	return artifact.get_preview_radius()


func create_artifact_placement_preview(item_kind: StringName) -> Node2D:
	var artifact := _get_artifact(item_kind)
	if artifact == null:
		return null

	return artifact.create_placement_preview()


func get_shield_hit_points() -> int:
	return _get_current_shield_hit_points()


func get_max_shield_hit_points() -> int:
	return _get_max_shield_hit_points()


func get_shield_level() -> int:
	return _shield_level


func is_destroyed() -> bool:
	return _is_destroyed


func is_invisible() -> bool:
	return not _is_destroyed and _invisibility_time_left > 0.0


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
	_target_position = global_position
	_is_moving = false
	_combat_drift_time_left = 0.0

	var to_center := vortex_center - global_position
	if to_center.length_squared() > 0.001:
		var world_direction := to_center.normalized()
		_vortex_local_direction = world_direction.rotated(-ship_sprite.global_rotation).normalized()
		var desired_rotation := world_direction.angle() + sprite_forward_rotation_offset
		var turn_response := lerpf(0.45, 3.1, _vortex_capture_strength * _vortex_capture_strength)
		rotation = lerp_angle(rotation, desired_rotation, clampf(turn_response * maxf(delta, 0.0), 0.0, 1.0))
		_turn_bias = clampf(angle_difference(rotation, desired_rotation) * 4.0, -1.0, 1.0)

	_current_speed = maxf(_current_speed, _get_effective_move_speed() * lerpf(0.35, 1.0, _vortex_capture_strength))
	_launch_pulse = maxf(_launch_pulse, _vortex_capture_strength * 0.45)


func play_artifact_ship_warp(
	warp_direction: Vector2,
	distortion_duration: float,
	distortion_strength: float,
	holo_duration: float,
	holo_fade_out_duration: float,
	holo_strength: float
) -> void:
	if _is_destroyed:
		return

	var safe_direction := warp_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = _get_forward_direction()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	_artifact_warp_distortion_duration = maxf(distortion_duration, 0.0)
	_artifact_warp_distortion_time_left = _artifact_warp_distortion_duration
	_artifact_warp_vortex_target_strength = clampf(distortion_strength, 0.0, 1.0)
	_artifact_warp_vortex_strength = _artifact_warp_vortex_target_strength
	_artifact_warp_vortex_direction = safe_direction.rotated(-ship_sprite.global_rotation).normalized()
	_artifact_warp_holo_duration = maxf(holo_duration, 0.0)
	_artifact_warp_holo_fade_out_duration = maxf(holo_fade_out_duration, 0.0)
	_artifact_warp_holo_time_left = _artifact_warp_holo_duration
	_artifact_warp_holo_target_strength = clampf(holo_strength, 0.0, 1.0)
	_artifact_warp_holo_strength = _artifact_warp_holo_target_strength


func is_vortex_captured() -> bool:
	return _is_vortex_captured()


func get_invisibility_time_left() -> float:
	return maxf(_invisibility_time_left, 0.0)


func get_owner_peer_id() -> int:
	return owner_peer_id


func set_network_identity(peer_id: int, local_player: bool, server_authority: bool) -> void:
	owner_peer_id = peer_id
	is_local_player = local_player
	is_server_authority = server_authority
	_is_network_presentation = true
	name = "Player%d" % peer_id
	_apply_invisibility_presentation()
	if _drone_companion_manager != null and is_instance_valid(_drone_companion_manager):
		_sync_drone_companions()


func set_fog_presentation_visible(is_visible: bool, active_vision_query: Callable = Callable()) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0, active_vision_query)


func set_fog_presentation_alpha(alpha: float, active_vision_query: Callable = Callable()) -> void:
	var resolved_alpha := clampf(alpha, 0.0, 1.0)
	var is_visible_for_fog := resolved_alpha > FOG_PRESENTATION_VISIBLE_EPSILON
	var query_valid_changed := active_vision_query.is_valid() != _fog_active_vision_query.is_valid()
	_fog_active_vision_query = active_vision_query
	if is_equal_approx(resolved_alpha, _fog_presentation_alpha) and is_visible_for_fog == _is_fog_presentation_visible and not query_valid_changed:
		return

	_fog_presentation_alpha = resolved_alpha
	_is_fog_presentation_visible = is_visible_for_fog
	visible = _is_fog_presentation_visible and not _is_destroyed
	if not _is_fog_presentation_visible:
		_sleep_visual_presentation()
	if _ship_material != null:
		_ship_material.set_shader_parameter("global_fade", _fog_presentation_alpha)
	_apply_invisibility_presentation()


func set_network_snapshot(world_position: Vector2, world_rotation: float, destroyed: bool = false) -> void:
	if is_server_authority:
		return

	if destroyed:
		global_position = world_position
		rotation = world_rotation
		_network_snapshot_buffer.clear()
		_apply_destroyed_state()
		visible = false
		return

	if is_local_player:
		_reconcile_predicted_snapshot(world_position, world_rotation)
		_is_destroyed = false
		visible = true
		return

	_queue_network_snapshot(world_position, world_rotation)
	_is_destroyed = destroyed
	visible = _is_fog_presentation_visible and not destroyed


func apply_network_status(current_hp: int, max_hp_value: int) -> void:
	var resolved_max_hit_points := maxi(max_hp_value, 1)
	var resolved_hit_points := clampi(current_hp, 0, resolved_max_hit_points)
	var previous_hit_points := _hit_points
	var hp_changed_value := resolved_hit_points != _hit_points or resolved_max_hit_points != max_hit_points
	max_hit_points = resolved_max_hit_points
	_hit_points = resolved_hit_points
	if hp_changed_value:
		hp_changed.emit(_hit_points, _get_max_hit_points())
		if is_local_player and not is_server_authority and resolved_hit_points < previous_hit_points:
			_trigger_damage_flash()


func apply_network_inventory(inventory: Dictionary) -> void:
	_inventory_levels = inventory.duplicate(true)
	_laser_level = maxi(int(_inventory_levels.get(&"laser", 1)), 1)
	_laser_rate_level = maxi(int(_inventory_levels.get(&"laser_rate", 0)), 0)
	_battery_level = maxi(int(_inventory_levels.get(&"battery", 0)), 0)
	_drone_level = maxi(int(_inventory_levels.get(&"drone", 0)), 0)
	_homing_missile_level = maxi(int(_inventory_levels.get(&"homing_missile", 0)), 0)
	_shield_level = maxi(int(_inventory_levels.get(&"shield", 0)), 0)
	_vacuum_level = maxi(int(_inventory_levels.get(&"vacuum", 0)), 0)
	_radar_level = maxi(int(_inventory_levels.get(&"radar", 0)), 0)
	_sync_artifact_levels_from_inventory()
	_invisibility_time_left = maxf(float(_inventory_levels.get(&"invisibility", 0)), 0.0)
	_invisibility_last_inventory_seconds = _get_invisibility_inventory_seconds()
	if _shield_level <= 0:
		_shield_level_damage = 0
	else:
		_clamp_shield_damage()
	_sync_invisibility_inventory_entry()
	_apply_invisibility_presentation()
	_update_shield_visuals()
	_emit_shield_changed()
	if _is_destroyed:
		_clear_drone_companions()
	else:
		_sync_drone_companions()
	queue_redraw()


func apply_network_shield(current_shield_hp: int, _max_shield_hp: int, shield_level: int) -> void:
	_shield_level = maxi(shield_level, 0)
	var safe_current_shield_hp := clampi(current_shield_hp, 0, _get_max_shield_hit_points())
	_shield_level_damage = maxi(_get_max_shield_hit_points() - safe_current_shield_hp, 0)
	if _shield_level <= 0:
		_shield_level_damage = 0
	_set_inventory_level(&"shield", _shield_level)
	_update_shield_visuals()
	_emit_shield_changed()


func play_network_weapon_projectile(target_world_position: Vector2) -> void:
	if _is_destroyed:
		return

	_spawn_laser_projectile(null, 0, false, target_world_position, true)


func play_network_drone_beam(drone_index: int, target_world_position: Vector2) -> void:
	if _is_destroyed:
		return

	if _drone_companion_manager == null or not is_instance_valid(_drone_companion_manager):
		return

	_drone_companion_manager.play_network_beam(drone_index, target_world_position)


func play_network_homing_missile(payload: Dictionary, target: Node2D = null) -> void:
	if _is_destroyed:
		return

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	var missile := HOMING_MISSILE_SCENE.instantiate() as HomingMissile
	if missile == null:
		return

	fx_layer.add_child(missile)
	missile.owner_peer_id = int(payload.get("owner_peer_id", owner_peer_id))
	missile.deals_damage = false
	missile.ship_path = missile.get_path_to(self)
	missile.global_position = payload.get("launch_origin", global_position) as Vector2
	var launch_direction := (payload.get("launch_direction", _get_forward_direction()) as Vector2).normalized()
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()
	missile.rotation = launch_direction.angle() + HomingMissile.SPRITE_FORWARD_ROTATION_OFFSET
	missile.initialize(
		target,
		launch_direction,
		float(payload.get("deploy_lateral_sign", 1.0)),
		payload.get("target_world_position", global_position) as Vector2,
		payload.has("target_world_position")
	)
	if missile.has_method("set_fog_presentation_visible"):
		missile.call("set_fog_presentation_visible", _should_show_owned_fog_effect(missile.global_position))


func play_network_vortex(payload: Dictionary) -> void:
	if _is_destroyed:
		return

	var artifact := _get_artifact(ItemPickup.ITEM_VORTEX)
	if artifact != null and artifact.has_method("play_network"):
		artifact.call("play_network", payload)


func play_network_nuke(payload: Dictionary) -> void:
	if _is_destroyed:
		return

	var artifact := _get_artifact(ItemPickup.ITEM_NUKE)
	if artifact != null and artifact.has_method("play_network"):
		artifact.call("play_network", payload)


func play_network_explorer_beacon(payload: Dictionary) -> void:
	if _is_destroyed:
		return

	var artifact := _get_artifact(ItemPickup.ITEM_EXPLORER_BEACON)
	if artifact != null and artifact.has_method("play_network"):
		artifact.call("play_network", payload)


func play_destruction_fx() -> void:
	if _death_fx_played or is_local_player:
		return

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	_death_fx_played = true
	if not _should_show_owned_fog_effect(global_position):
		return
	if not ShipExplosionFx.can_spawn_active_explosion(get_tree()):
		return

	var explosion := SHIP_EXPLOSION_SCENE.instantiate() as Node2D
	if explosion == null:
		return

	fx_layer.add_child(explosion)
	if explosion.has_method("configure_from_ship"):
		explosion.call("configure_from_ship", self)
	if explosion.has_method("set_fog_presentation_visible"):
		explosion.call("set_fog_presentation_visible", _should_show_owned_fog_effect(explosion.global_position))


func _set_selection_ring_alpha(alpha: float) -> void:
	_selection_ring_alpha = alpha
	queue_redraw()


func _get_max_hit_points() -> int:
	return maxi(max_hit_points, 1)


func _get_max_shield_hit_points() -> int:
	return maxi(_shield_level, 0) * SHIELD_HIT_POINTS_PER_LEVEL


func _get_current_shield_hit_points() -> int:
	if _shield_level <= 0:
		return 0

	return maxi(_get_max_shield_hit_points() - _shield_level_damage, 0)


func _get_shield_touch_radius() -> float:
	if shield_visual == null:
		return get_touch_radius()

	var shield_sprite := shield_visual as Sprite2D
	if shield_sprite == null or shield_sprite.texture == null:
		return get_touch_radius()

	var texture_size := shield_sprite.texture.get_size()
	if texture_size == Vector2.ZERO:
		return get_touch_radius()

	var scaled_size := texture_size * shield_sprite.global_scale.abs()
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func _clamp_shield_damage() -> void:
	_shield_level_damage = clampi(_shield_level_damage, 0, _get_max_shield_hit_points())
	if _shield_level <= 0:
		_shield_regen_delay_left = 0.0
		_shield_regen_remainder = 0.0


func _emit_shield_changed() -> void:
	shield_changed.emit(_get_current_shield_hit_points(), _get_max_shield_hit_points(), _shield_level)


func _trigger_shield_hit(impact_world_position: Vector2, absorbed_damage: int) -> void:
	if shield_visual == null or not shield_visual.has_method("play_hit"):
		return

	var resolved_impact := impact_world_position
	if not resolved_impact.is_finite():
		resolved_impact = get_damage_impact_position(global_position + _get_forward_direction() * get_damage_impact_radius())

	var impact_strength := clampf(float(absorbed_damage) / float(SHIELD_HIT_POINTS_PER_LEVEL), 0.35, 1.4)
	shield_visual.call("play_hit", resolved_impact, impact_strength)


func _should_play_damage_flash_on_damage_apply() -> bool:
	if not _is_network_presentation:
		return true
	return not is_server_authority


func _should_simulate_movement() -> bool:
	return not _is_network_presentation or is_server_authority or is_local_player


func _should_interpolate_network_snapshots() -> bool:
	return _is_network_presentation and not is_server_authority and not is_local_player


func _should_run_authoritative_gameplay() -> bool:
	return not _is_network_presentation or is_server_authority


func _is_vortex_captured() -> bool:
	return _vortex_capture_time_left > 0.0 and _vortex_capture_strength > 0.01


func _update_vortex_capture_state(delta: float) -> void:
	if _vortex_capture_time_left > 0.0:
		_vortex_capture_time_left = maxf(_vortex_capture_time_left - maxf(delta, 0.0), 0.0)
		return

	_vortex_capture_strength = move_toward(_vortex_capture_strength, 0.0, maxf(delta, 0.0) * 7.0)


func _update_artifact_warp_distortion(delta: float) -> void:
	if _artifact_warp_distortion_time_left <= 0.0:
		_artifact_warp_vortex_strength = 0.0
		return

	_artifact_warp_distortion_time_left = maxf(_artifact_warp_distortion_time_left - maxf(delta, 0.0), 0.0)
	var duration := maxf(_artifact_warp_distortion_duration, 0.001)
	var fade_ratio := clampf(_artifact_warp_distortion_time_left / duration, 0.0, 1.0)
	_artifact_warp_vortex_strength = _artifact_warp_vortex_target_strength * fade_ratio


func _update_artifact_warp_holo(delta: float) -> void:
	if _artifact_warp_holo_time_left <= 0.0:
		_artifact_warp_holo_strength = 0.0
		return

	_artifact_warp_holo_time_left = maxf(_artifact_warp_holo_time_left - maxf(delta, 0.0), 0.0)
	var fade_duration := minf(maxf(_artifact_warp_holo_fade_out_duration, 0.001), maxf(_artifact_warp_holo_duration, 0.001))
	var fade_ratio := clampf(_artifact_warp_holo_time_left / fade_duration, 0.0, 1.0)
	_artifact_warp_holo_strength = _artifact_warp_holo_target_strength * fade_ratio


func _get_vortex_visual_strength() -> float:
	return maxf(_vortex_capture_strength, _artifact_warp_vortex_strength)


func _get_vortex_visual_direction() -> Vector2:
	if _vortex_capture_strength >= _artifact_warp_vortex_strength:
		return _vortex_local_direction

	return _artifact_warp_vortex_direction


func _reconcile_predicted_snapshot(world_position: Vector2, world_rotation: float) -> void:
	var correction := world_position - global_position
	var correction_distance := correction.length()
	if correction_distance >= NETWORK_CORRECTION_SNAP_DISTANCE:
		global_position = world_position
		rotation = world_rotation
		_current_speed = 0.0
		return

	if correction_distance >= NETWORK_CORRECTION_MIN_DISTANCE:
		global_position += correction * NETWORK_CORRECTION_BLEND
	rotation = lerp_angle(rotation, world_rotation, NETWORK_CORRECTION_BLEND)


func _queue_network_snapshot(world_position: Vector2, world_rotation: float) -> void:
	var received_time := Time.get_ticks_msec() * 0.001
	_network_snapshot_buffer.append({
		"time": received_time,
		"position": world_position,
		"rotation": world_rotation,
	})
	while _network_snapshot_buffer.size() > NETWORK_MAX_SNAPSHOT_BUFFER_SIZE:
		_network_snapshot_buffer.pop_front()

	if _network_snapshot_buffer.size() == 1:
		global_position = world_position
		rotation = world_rotation
		_last_interpolated_position = global_position


func _update_network_interpolation(delta: float) -> void:
	if _network_snapshot_buffer.is_empty():
		_update_network_visual_motion(delta, global_position, rotation)
		return

	var render_time := Time.get_ticks_msec() * 0.001 - NETWORK_INTERPOLATION_DELAY
	while _network_snapshot_buffer.size() >= 3 and float(_network_snapshot_buffer[1].get("time", 0.0)) <= render_time:
		_network_snapshot_buffer.pop_front()

	var target_position := global_position
	var target_rotation := rotation
	if _network_snapshot_buffer.size() >= 2:
		var previous_snapshot: Dictionary = _network_snapshot_buffer[0]
		var next_snapshot: Dictionary = _network_snapshot_buffer[1]
		var previous_time := float(previous_snapshot.get("time", 0.0))
		var next_time := float(next_snapshot.get("time", previous_time))
		if render_time > next_time:
			target_position = _extrapolate_latest_network_position(render_time, next_snapshot.get("position", global_position) as Vector2)
			target_rotation = float(next_snapshot.get("rotation", rotation))
		else:
			var time_span := maxf(next_time - previous_time, 0.001)
			var interpolation_alpha := clampf((render_time - previous_time) / time_span, 0.0, 1.0)
			target_position = (previous_snapshot.get("position", global_position) as Vector2).lerp(
				next_snapshot.get("position", global_position) as Vector2,
				interpolation_alpha
			)
			target_rotation = lerp_angle(
				float(previous_snapshot.get("rotation", rotation)),
				float(next_snapshot.get("rotation", rotation)),
				interpolation_alpha
			)
	elif _network_snapshot_buffer.size() == 1:
		var latest_snapshot: Dictionary = _network_snapshot_buffer[0]
		target_position = latest_snapshot.get("position", global_position) as Vector2
		target_rotation = float(latest_snapshot.get("rotation", rotation))
		if render_time > float(latest_snapshot.get("time", 0.0)):
			target_position = _extrapolate_latest_network_position(render_time, target_position)

	_update_network_visual_motion(delta, target_position, target_rotation)


func _extrapolate_latest_network_position(render_time: float, fallback_position: Vector2) -> Vector2:
	if _network_snapshot_buffer.size() < 2:
		return fallback_position

	var latest_snapshot: Dictionary = _network_snapshot_buffer[_network_snapshot_buffer.size() - 1]
	var previous_snapshot: Dictionary = _network_snapshot_buffer[_network_snapshot_buffer.size() - 2]
	var latest_time := float(latest_snapshot.get("time", 0.0))
	var previous_time := float(previous_snapshot.get("time", latest_time))
	var time_span := latest_time - previous_time
	if time_span <= 0.001:
		return fallback_position

	var latest_position := latest_snapshot.get("position", fallback_position) as Vector2
	var previous_position := previous_snapshot.get("position", latest_position) as Vector2
	var extrapolation_time := clampf(render_time - latest_time, 0.0, NETWORK_MAX_EXTRAPOLATION)
	return latest_position + ((latest_position - previous_position) / time_span) * extrapolation_time


func _update_network_visual_motion(delta: float, target_position: Vector2, target_rotation: float) -> void:
	var previous_position := global_position
	global_position = target_position
	rotation = target_rotation

	var displacement := global_position - previous_position
	_current_speed = displacement.length() / maxf(delta, 0.001)
	_is_moving = _current_speed > 5.0
	if _last_interpolated_position != Vector2.ZERO:
		var previous_direction := previous_position - _last_interpolated_position
		var current_direction := global_position - previous_position
		if previous_direction.length_squared() > 0.001 and current_direction.length_squared() > 0.001:
			_turn_bias = clampf(angle_difference(previous_direction.angle(), current_direction.angle()) * 8.0, -1.0, 1.0)
		else:
			_turn_bias = 0.0
	_last_interpolated_position = previous_position


func _sync_inventory_from_loadout() -> void:
	_set_inventory_level(&"laser", _laser_level)
	_set_inventory_level(&"laser_rate", _laser_rate_level)
	_set_inventory_level(&"battery", _battery_level)
	_set_inventory_level(&"drone", _drone_level)
	_set_inventory_level(&"homing_missile", _homing_missile_level)
	_set_inventory_level(&"shield", _shield_level)
	_set_inventory_level(&"vacuum", _vacuum_level)
	_set_inventory_level(&"radar", _radar_level)
	for artifact_variant in _artifact_by_item_kind.values():
		var artifact := artifact_variant as ShipArtifact
		if artifact == null:
			continue

		_set_inventory_level(artifact.item_kind, artifact.get_level())
	_sync_invisibility_inventory_entry()


func _add_invisibility_time(stack_count: int) -> void:
	var added_seconds := _get_invisibility_duration_for_level(stack_count)
	if added_seconds <= 0.0:
		return

	_invisibility_time_left = maxf(_invisibility_time_left, 0.0) + added_seconds
	_sync_invisibility_inventory_entry()
	_apply_invisibility_presentation()


func _update_invisibility(delta: float) -> void:
	if _invisibility_time_left <= 0.0:
		return

	var previous_seconds := _invisibility_last_inventory_seconds
	_invisibility_time_left = maxf(_invisibility_time_left - maxf(delta, 0.0), 0.0)
	_sync_invisibility_inventory_entry()
	var current_seconds := _invisibility_last_inventory_seconds
	if current_seconds <= 0 or previous_seconds <= 0:
		_apply_invisibility_presentation()

	if current_seconds != previous_seconds and _should_emit_inventory_timer_updates():
		inventory_changed.emit(get_inventory_levels())


func _get_invisibility_duration_for_level(level: int) -> float:
	return maxf(invisibility_duration_per_pickup, 0.0) * float(maxi(level, 0))


func _setup_artifacts() -> void:
	_artifact_by_item_kind.clear()
	if artifacts_root == null:
		artifacts_root = get_node_or_null("Artifacts")
	if artifacts_root == null:
		return

	for child in artifacts_root.get_children():
		var artifact := child as ShipArtifact
		if artifact == null:
			continue
		if artifact.item_kind == &"":
			continue

		artifact.configure(self)
		_artifact_by_item_kind[artifact.item_kind] = artifact


func _get_artifact(item_kind: StringName) -> ShipArtifact:
	if _artifact_by_item_kind.is_empty():
		_setup_artifacts()

	return _artifact_by_item_kind.get(item_kind, null) as ShipArtifact


func _sync_artifact_levels_from_inventory() -> void:
	if _artifact_by_item_kind.is_empty():
		_setup_artifacts()

	for item_kind_variant in _artifact_by_item_kind.keys():
		var item_kind := StringName(item_kind_variant)
		var artifact := _get_artifact(item_kind)
		if artifact == null:
			continue

		artifact.set_level(maxi(int(_inventory_levels.get(item_kind, 0)), 0))


func _update_artifacts(delta: float) -> void:
	if _artifact_by_item_kind.is_empty():
		return

	for artifact_variant in _artifact_by_item_kind.values():
		var artifact := artifact_variant as ShipArtifact
		if artifact != null:
			artifact.process_cooldown(delta)


func _clear_artifact_cooldowns() -> void:
	for artifact_variant in _artifact_by_item_kind.values():
		var artifact := artifact_variant as ShipArtifact
		if artifact != null:
			artifact.clear_cooldown()


func _get_invisibility_inventory_seconds() -> int:
	return maxi(int(ceil(maxf(_invisibility_time_left, 0.0))), 0)


func _sync_invisibility_inventory_entry() -> void:
	_invisibility_last_inventory_seconds = _get_invisibility_inventory_seconds()
	_set_inventory_level(ItemPickup.ITEM_INVISIBILITY, _invisibility_last_inventory_seconds)


func _should_emit_inventory_timer_updates() -> bool:
	return not _is_network_presentation or is_server_authority


func _absorb_shield_damage(amount: int) -> int:
	if amount <= 0 or _shield_level <= 0:
		return 0

	var current_shield_hit_points := _get_current_shield_hit_points()
	var absorbed_damage := mini(amount, current_shield_hit_points)
	if absorbed_damage <= 0:
		return 0

	var remaining_shield_hit_points := maxi(current_shield_hit_points - absorbed_damage, 0)
	_shield_level = int(ceil(float(remaining_shield_hit_points) / float(SHIELD_HIT_POINTS_PER_LEVEL)))
	_shield_level_damage = maxi(_get_max_shield_hit_points() - remaining_shield_hit_points, 0)
	_set_inventory_level(&"shield", _shield_level)
	_clamp_shield_damage()

	return absorbed_damage


func _reset_shield_regen_delay() -> void:
	_shield_regen_delay_left = maxf(shield_regen_delay, 0.0)
	_shield_regen_remainder = 0.0


func _update_shield_regen(delta: float) -> void:
	if _shield_level <= 0 or _shield_level_damage <= 0:
		_shield_regen_delay_left = 0.0
		_shield_regen_remainder = 0.0
		return

	if shield_regen_hit_points_per_second <= 0.0:
		return

	if _shield_regen_delay_left > 0.0:
		_shield_regen_delay_left = maxf(_shield_regen_delay_left - delta, 0.0)
		return

	_shield_regen_remainder += shield_regen_hit_points_per_second * delta
	var recovered_hit_points := int(floor(_shield_regen_remainder))
	if recovered_hit_points <= 0:
		return

	_shield_regen_remainder -= float(recovered_hit_points)
	_shield_level_damage = maxi(_shield_level_damage - recovered_hit_points, 0)
	if _shield_level_damage <= 0:
		_shield_regen_remainder = 0.0
	_emit_shield_changed()


func _set_inventory_level(item_kind: StringName, level: int) -> void:
	var safe_level := maxi(level, 0)
	if safe_level <= 0:
		_inventory_levels.erase(item_kind)
		return

	_inventory_levels[item_kind] = safe_level


func _increment_inventory_level(item_kind: StringName, amount: int) -> void:
	if amount <= 0:
		return

	var current_level := int(_inventory_levels.get(item_kind, 0))
	_inventory_levels[item_kind] = current_level + amount


func _destroy_ship() -> void:
	if _is_destroyed:
		return

	_apply_destroyed_state()
	died.emit()


func _apply_destroyed_state() -> void:
	_is_destroyed = true
	_stop_movement()
	_set_jets_emitting(false)
	_homing_missile_fire_cooldown = 0.0
	_clear_artifact_cooldowns()
	_homing_missile_volley_delay_left = 0.0
	_homing_missile_volley_index = 0
	_homing_missile_volley_total = 0
	_invisibility_time_left = 0.0
	_sync_invisibility_inventory_entry()
	_apply_invisibility_presentation()
	if shield_visual != null:
		shield_visual.visible = false
	_clear_owned_world_entities()


func _clear_owned_world_entities() -> void:
	_clear_drone_companions()
	_clear_owned_homing_missiles()
	_clear_owned_laser_projectiles()
	_clear_owned_explorer_beacons()


func _clear_owned_homing_missiles() -> void:
	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	for child in fx_layer.get_children():
		var missile := child as HomingMissile
		if missile == null or not is_instance_valid(missile):
			continue
		if missile.owner_peer_id != owner_peer_id:
			continue

		missile.queue_free()


func _clear_owned_laser_projectiles() -> void:
	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	for child in fx_layer.get_children():
		var projectile := child as Node
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.get_script() != LASER_PROJECTILE_SCRIPT:
			continue
		if int(projectile.get("owner_peer_id")) != owner_peer_id:
			continue

		projectile.queue_free()


func _clear_owned_explorer_beacons() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for beacon_node in tree.get_nodes_in_group(EXPLORER_BEACON_GROUP):
		var beacon := beacon_node as Node
		if beacon == null or not is_instance_valid(beacon):
			continue
		if not beacon.has_method("get_owner_peer_id"):
			continue
		if int(beacon.call("get_owner_peer_id")) != owner_peer_id:
			continue

		beacon.queue_free()


func _get_selection_ring_radius() -> float:
	if ship_sprite.texture == null:
		return selection_ring_padding

	var sprite_size := ship_sprite.get_rect().size * ship_sprite.scale.abs() * visuals_root.scale.abs()
	return maxf(sprite_size.x, sprite_size.y) * 0.5 + selection_ring_padding


func _update_movement(delta: float) -> void:
	if not _is_moving:
		return

	global_position = _clamp_to_galaxy_bounds(global_position)
	var travel_direction := _target_position - global_position
	var distance_to_target := travel_direction.length()
	if distance_to_target <= target_tolerance:
		global_position = _target_position
		_stop_movement()
		return

	var target_rotation := travel_direction.angle() + sprite_forward_rotation_offset
	var angle_delta := angle_difference(rotation, target_rotation)
	var max_turn_step := turn_speed * delta
	var applied_turn_step := clampf(angle_delta, -max_turn_step, max_turn_step)
	rotation += applied_turn_step
	_turn_bias = clampf(applied_turn_step / maxf(max_turn_step, 0.001), -1.0, 1.0)

	var effective_acceleration := _get_effective_acceleration()
	var effective_deceleration := _get_effective_deceleration()
	var effective_move_speed := _get_effective_move_speed()
	var stopping_distance := (_current_speed * _current_speed) / maxf(2.0 * effective_deceleration, 1.0)
	var desired_speed := effective_move_speed
	if stopping_distance >= distance_to_target - target_tolerance:
		desired_speed = sqrt(maxf(0.0, 2.0 * effective_deceleration * maxf(distance_to_target - target_tolerance, 0.0)))

	var alignment := maxf(0.0, cos(angle_difference(rotation, target_rotation)))
	var turn_speed_factor := lerpf(minimum_turn_speed_factor, 1.0, alignment)
	desired_speed *= turn_speed_factor
	var speed_change: float = effective_acceleration if desired_speed > _current_speed else effective_deceleration
	_current_speed = move_toward(_current_speed, desired_speed, speed_change * delta)

	var move_distance := _current_speed * delta
	var forward_direction := _get_forward_direction()
	var requested_move_distance := minf(move_distance, distance_to_target)
	global_position += forward_direction * requested_move_distance

	if move_distance >= distance_to_target:
		global_position = _target_position
		_stop_movement()
		return


func _update_combat_drift(delta: float) -> void:
	if _combat_drift_time_left <= 0.0:
		if not _is_moving:
			_current_speed = 0.0
		return

	_combat_drift_time_left = maxf(_combat_drift_time_left - delta, 0.0)
	if _is_moving or combat_drift_speed <= 0.0:
		return

	var drift_direction := _combat_drift_direction
	if drift_direction == Vector2.ZERO:
		drift_direction = _get_forward_direction()
	if drift_direction == Vector2.ZERO:
		return

	_current_speed = combat_drift_speed
	_turn_bias = 0.0
	global_position = _clamp_to_galaxy_bounds(global_position + drift_direction.normalized() * combat_drift_speed * delta)


func _get_forward_direction() -> Vector2:
	return Vector2.RIGHT.rotated(rotation - sprite_forward_rotation_offset)


func get_artifact_forward_direction() -> Vector2:
	return _get_forward_direction()


func get_artifact_launch_origin() -> Vector2:
	if ship_sprite != null and ship_sprite.texture != null:
		var sprite_rect := ship_sprite.get_rect()
		var front_local_position := Vector2(
			sprite_rect.position.x + sprite_rect.size.x * 0.5,
			sprite_rect.position.y
		)
		return ship_sprite.to_global(front_local_position)

	return global_position + get_artifact_forward_direction() * maxf(get_touch_radius() * 0.55, 18.0)


func clamp_artifact_world_position(world_position: Vector2) -> Vector2:
	return _clamp_to_galaxy_bounds(world_position)


func continue_artifact_movement(move_direction: Vector2, start_position: Vector2, continuation_distance: float) -> void:
	var safe_direction := move_direction.normalized()
	if safe_direction == Vector2.ZERO:
		_stop_movement()
		return

	var safe_continuation_distance := maxf(continuation_distance, target_tolerance + 1.0)
	_target_position = _clamp_to_galaxy_bounds(start_position + safe_direction * safe_continuation_distance)

	if start_position.distance_to(_target_position) <= target_tolerance:
		_stop_movement()
		return

	_is_moving = true
	_current_speed = maxf(_current_speed, _get_effective_move_speed() * 0.35)
	_turn_bias = 0.0


func pulse_artifact_activation() -> void:
	_launch_pulse = 1.0
	_trigger_pickup_flash()


func get_artifact_effects_layer() -> Node2D:
	return _get_fx_layer()


func get_artifact_ship_sprite() -> Sprite2D:
	return ship_sprite


func should_show_artifact_effect(world_position: Vector2) -> bool:
	return _should_show_owned_fog_effect(world_position)


func broadcast_artifact_effect(effect_name: StringName, payload: Dictionary) -> void:
	if not _is_network_presentation or not is_server_authority:
		return

	if multiplayer.multiplayer_peer == null:
		return

	var galaxy := get_tree().current_scene
	if effect_name == &"vortex_spawned" and galaxy != null and galaxy.has_method("client_ship_vortex_spawned"):
		galaxy.rpc("client_ship_vortex_spawned", payload)
	elif effect_name == &"nuke_launched" and galaxy != null and galaxy.has_method("client_ship_nuke_launched"):
		galaxy.rpc("client_ship_nuke_launched", payload)
	elif effect_name == &"explorer_beacon_launched" and galaxy != null and galaxy.has_method("client_explorer_beacon_launched"):
		galaxy.rpc("client_explorer_beacon_launched", payload)


func _stop_movement() -> void:
	_is_moving = false
	_current_speed = 0.0
	_turn_bias = 0.0


func _clamp_to_galaxy_bounds(world_position: Vector2) -> Vector2:
	var world_radius := _get_galaxy_world_radius()
	return Vector2(
		clampf(world_position.x, -world_radius, world_radius),
		clampf(world_position.y, -world_radius, world_radius)
	)


func _get_galaxy_world_radius() -> float:
	var galaxy := get_parent()
	if galaxy != null and galaxy.has_method("get_world_radius"):
		return maxf(float(galaxy.call("get_world_radius")), 1.0)

	return 10000.0


func _get_planet_field() -> Node2D:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null:
		return null

	return scene_root.find_child("PlanetField", true, false) as Node2D


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


func get_safe_zone_attack_multiplier() -> float:
	if _is_in_safe_zone(global_position, get_touch_radius()):
		return 2.0

	return 1.0


func _get_effective_move_speed() -> float:
	return move_speed * (1.0 + float(_battery_level) * battery_move_speed_bonus_per_level)


func _get_effective_acceleration() -> float:
	return _get_acceleration_for_level(_battery_level)


func _get_effective_deceleration() -> float:
	return _get_base_deceleration()


func _get_base_deceleration() -> float:
	return maxf(deceleration, acceleration + MIN_DECELERATION_ADVANTAGE)


func _get_effective_jet_length_scale_max() -> float:
	return jet_length_scale_max * (1.0 + float(_battery_level) * battery_jet_power_bonus_per_level)


func _get_effective_jet_turn_power_boost() -> float:
	return jet_turn_power_boost * (1.0 + float(_battery_level) * battery_jet_power_bonus_per_level)


func _get_effective_thrust_visual_response() -> float:
	return thrust_visual_response * (1.0 + float(_battery_level) * battery_thrust_response_bonus_per_level)


func _update_combat(delta: float) -> void:
	if _laser_level <= 0:
		return

	_weapon_fire_cooldown = maxf(_weapon_fire_cooldown - delta, 0.0)

	if _weapon_fire_cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_fire_weapon_at(target)
	_weapon_fire_cooldown = _get_effective_laser_fire_interval()


func _suppress_attacks_while_vortex_captured() -> void:
	if _laser_level > 0:
		_weapon_fire_cooldown = maxf(_weapon_fire_cooldown, _get_effective_laser_fire_interval())

	if _homing_missile_level <= 0:
		_homing_missile_volley_total = 0
		_homing_missile_volley_index = 0
		return

	var homing_missile_config := _get_homing_missile_config()
	if homing_missile_config == null:
		return

	_homing_missile_fire_cooldown = maxf(_homing_missile_fire_cooldown, homing_missile_config.fire_interval)
	_homing_missile_volley_delay_left = 0.0
	_homing_missile_volley_index = 0
	_homing_missile_volley_total = 0


func _update_homing_missiles(delta: float) -> void:
	var homing_missile_config := _get_homing_missile_config()
	if homing_missile_config == null:
		return

	if _homing_missile_level <= 0:
		_homing_missile_volley_total = 0
		_homing_missile_volley_index = 0
		return

	if _homing_missile_volley_index < _homing_missile_volley_total:
		_homing_missile_volley_delay_left = maxf(_homing_missile_volley_delay_left - delta, 0.0)
		if _homing_missile_volley_delay_left > 0.0:
			return

		if _fire_homing_missile(_homing_missile_volley_index, _homing_missile_volley_total):
			_homing_missile_volley_index += 1
			_homing_missile_volley_delay_left = homing_missile_config.volley_delay
			if _homing_missile_volley_index >= _homing_missile_volley_total:
				_homing_missile_fire_cooldown = homing_missile_config.fire_interval
			return

		_homing_missile_volley_total = 0
		_homing_missile_volley_index = 0
		_homing_missile_fire_cooldown = homing_missile_config.fire_interval
		return

	_homing_missile_fire_cooldown = maxf(_homing_missile_fire_cooldown - delta, 0.0)
	if _homing_missile_fire_cooldown > 0.0:
		return

	_start_homing_missile_volley()


func _start_homing_missile_volley() -> void:
	var homing_missile_config := _get_homing_missile_config()
	if homing_missile_config == null:
		return

	if _homing_missile_level <= 0:
		return

	_homing_missile_volley_total = maxi(_homing_missile_level, 0)
	_homing_missile_volley_index = 0
	_homing_missile_volley_delay_left = 0.0
	if _homing_missile_volley_total <= 0:
		return

	if _fire_homing_missile(_homing_missile_volley_index, _homing_missile_volley_total):
		_homing_missile_volley_index += 1
		if _homing_missile_volley_index < _homing_missile_volley_total:
			_homing_missile_volley_delay_left = homing_missile_config.volley_delay
		else:
			_homing_missile_fire_cooldown = homing_missile_config.fire_interval
		return

	_homing_missile_volley_total = 0
	_homing_missile_volley_index = 0


func _fire_homing_missile(missile_index: int, missile_count: int) -> bool:
	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return false

	if missile_count <= 0:
		return false

	var homing_missile_config := _get_homing_missile_config()
	if homing_missile_config == null:
		return false

	var launch_direction := _get_forward_direction()
	var launch_origin := _get_homing_missile_launch_origin(missile_index, missile_count)
	var deploy_lateral_sign := _get_homing_missile_deploy_lateral_sign(missile_index)
	var target := get_homing_missile_target(launch_origin, homing_missile_config.target_search_radius, homing_missile_config.cluster_radius)
	if target == null:
		return false

	var missile := HOMING_MISSILE_SCENE.instantiate() as HomingMissile
	if missile == null:
		return false

	fx_layer.add_child(missile)
	missile.owner_peer_id = owner_peer_id
	missile.ship_path = missile.get_path_to(self)
	missile.global_position = launch_origin
	missile.rotation = launch_direction.angle() + HomingMissile.SPRITE_FORWARD_ROTATION_OFFSET
	missile.initialize(
		target,
		launch_direction,
		deploy_lateral_sign,
		target.global_position,
		true
	)
	_prime_combat_drift(target.global_position)
	_broadcast_network_homing_missile_fire(target, launch_origin, launch_direction, deploy_lateral_sign)
	return true


func _get_homing_missile_launch_origin(missile_index: int = 0, missile_count: int = 1) -> Vector2:
	if ship_sprite == null or ship_sprite.texture == null:
		return global_position

	var sprite_rect := ship_sprite.get_rect()
	var side_sign := _get_homing_missile_deploy_lateral_sign(missile_index)
	var pair_index := missile_index / 2
	var pair_spacing := minf(float(pair_index) * 0.045, 0.12)
	var wing_x_ratio := 0.82 + pair_spacing if side_sign > 0.0 else 0.18 - pair_spacing
	if missile_count == 1:
		wing_x_ratio = 0.82

	var wing_mount_position := Vector2(
		sprite_rect.position.x + sprite_rect.size.x * clampf(wing_x_ratio, 0.08, 0.92),
		sprite_rect.position.y + sprite_rect.size.y * 0.64
	)
	return ship_sprite.to_global(wing_mount_position)


func _get_homing_missile_deploy_lateral_sign(missile_index: int) -> float:
	return 1.0 if missile_index % 2 == 0 else -1.0


func get_homing_missile_target(origin_position: Vector2 = Vector2.ZERO, search_radius: float = -1.0, cluster_radius: float = -1.0) -> Node2D:
	var homing_missile_config := _get_homing_missile_config()
	if homing_missile_config == null:
		return null

	var safe_search_radius := homing_missile_config.target_search_radius if search_radius <= 0.0 else search_radius
	var safe_cluster_radius := homing_missile_config.cluster_radius if cluster_radius <= 0.0 else cluster_radius
	return _find_homing_missile_target(origin_position, safe_search_radius, safe_cluster_radius)


func _find_homing_missile_target(origin_position: Vector2, _search_radius: float, cluster_radius: float) -> Node2D:
	var weapon_range := _get_effective_weapon_range()
	var enemy_candidates: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := candidate as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to(enemy.global_position) > weapon_range:
			continue

		enemy_candidates.append(enemy)

	if is_server_authority:
		for candidate in get_tree().get_nodes_in_group(PLAYER_GROUP):
			var player_ship := candidate as Node2D
			if not _is_player_ship_targetable(player_ship):
				continue
			if global_position.distance_to(player_ship.global_position) > weapon_range:
				continue

			enemy_candidates.append(player_ship)

		for candidate in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
			var beacon := candidate as Node2D
			if not _is_explorer_beacon_targetable(beacon):
				continue
			if global_position.distance_to(beacon.global_position) > weapon_range:
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

		var distance_to_origin := origin_position.distance_to(enemy.global_position)
		if cluster_size > best_cluster_size or (cluster_size == best_cluster_size and distance_to_origin < best_distance):
			best_cluster_size = cluster_size
			best_distance = distance_to_origin
			best_enemy = enemy

	return best_enemy


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := _get_effective_weapon_range()
	for candidate in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var enemy := candidate as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue

		var distance_to_enemy := global_position.distance_to(enemy.global_position)
		if distance_to_enemy > nearest_distance:
			continue
		if not _is_world_position_in_laser_fire_cone(enemy.global_position):
			continue

		nearest_distance = distance_to_enemy
		nearest_enemy = enemy

	if is_server_authority:
		for candidate in get_tree().get_nodes_in_group(PLAYER_GROUP):
			var player_ship := candidate as Node2D
			if not _is_player_ship_targetable(player_ship):
				continue

			var distance_to_player := global_position.distance_to(player_ship.global_position)
			if distance_to_player > nearest_distance:
				continue
			if not _is_world_position_in_laser_fire_cone(player_ship.global_position):
				continue

			nearest_distance = distance_to_player
			nearest_enemy = player_ship

		for candidate in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
			var beacon := candidate as Node2D
			if not _is_explorer_beacon_targetable(beacon):
				continue

			var distance_to_beacon := global_position.distance_to(beacon.global_position)
			if distance_to_beacon > nearest_distance:
				continue
			if not _is_world_position_in_laser_fire_cone(beacon.global_position):
				continue

			nearest_distance = distance_to_beacon
			nearest_enemy = beacon

	return nearest_enemy


func _is_player_ship_targetable(player_ship: Node2D) -> bool:
	if player_ship == null or not is_instance_valid(player_ship) or player_ship == self:
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


func _fire_weapon_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	var base_damage := maxi(1, laser_base_damage * _laser_level)
	var launch_origin := _get_laser_projectile_launch_origin()
	var impact_position := _get_target_damage_impact_position(target, launch_origin)
	_spawn_laser_projectile(target, base_damage, true, impact_position, true)
	_prime_combat_drift(impact_position)
	_broadcast_network_weapon_fire(impact_position)


func _spawn_laser_projectile(
	target: Node2D,
	damage_amount: int,
	should_deal_damage: bool,
	fallback_target_position: Vector2,
	fallback_target_position_valid: bool
) -> void:
	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	var projectile := LASER_PROJECTILE_SCRIPT.new() as Sprite2D
	if projectile == null:
		return

	fx_layer.add_child(projectile)
	projectile.set("owner_peer_id", owner_peer_id)
	projectile.global_position = _get_laser_projectile_launch_origin()
	projectile.call(
		"initialize",
		target,
		self,
		_laser_level,
		damage_amount,
		laser_projectile_speed,
		_get_laser_projectile_scale(),
		fallback_target_position,
		fallback_target_position_valid,
		should_deal_damage
	)
	projectile.call("set_fog_presentation_visible", _should_show_owned_fog_effect(projectile.global_position))
	GAME_SFX.play(self, GAME_SFX.CUE_LASER)


func _get_laser_projectile_launch_origin() -> Vector2:
	if ship_sprite != null and ship_sprite.texture != null:
		var sprite_rect := ship_sprite.get_rect()
		var front_local_position := Vector2(
			sprite_rect.position.x + sprite_rect.size.x * 0.5,
			sprite_rect.position.y
		)
		return ship_sprite.to_global(front_local_position)

	return global_position + _get_forward_direction() * maxf(get_touch_radius() * 0.55, 18.0)


func _get_target_damage_impact_position(target: Node2D, source_world_position: Vector2) -> Vector2:
	if target == null or not is_instance_valid(target):
		return source_world_position

	if target.has_method("get_damage_impact_position"):
		return target.call("get_damage_impact_position", source_world_position) as Vector2

	return target.global_position


func _prime_combat_drift(target_world_position: Vector2) -> void:
	if combat_drift_speed <= 0.0 or combat_drift_duration <= 0.0:
		return

	var drift_direction := _get_forward_direction()
	if drift_direction == Vector2.ZERO:
		var to_target := target_world_position - global_position
		if to_target != Vector2.ZERO:
			drift_direction = to_target.normalized()
	if drift_direction == Vector2.ZERO:
		return

	_combat_drift_direction = drift_direction.normalized()
	_combat_drift_time_left = maxf(_combat_drift_time_left, combat_drift_duration)


func _get_laser_projectile_scale() -> float:
	return laser_projectile_base_scale + maxf(float(_laser_level - 1), 0.0) * laser_projectile_scale_per_level


func _get_effective_laser_fire_interval() -> float:
	return _get_laser_fire_interval_for_rate_level(_laser_rate_level)


func _get_laser_fire_interval_for_rate_level(level: int) -> float:
	var fire_rate_multiplier := 1.0 + float(maxi(level, 0)) * laser_fire_rate_bonus_per_level
	return maxf(laser_fire_interval / maxf(fire_rate_multiplier, 0.001), 0.01)


func _is_world_position_in_laser_fire_cone(world_position: Vector2) -> bool:
	var cone_origin := _get_laser_projectile_launch_origin()
	var to_target := world_position - cone_origin
	if to_target == Vector2.ZERO:
		return true

	var angle_to_target := absf(angle_difference(_get_forward_direction().angle(), to_target.angle()))
	return angle_to_target <= _get_laser_fire_cone_half_angle()


func _get_laser_fire_cone_half_angle() -> float:
	return deg_to_rad(clampf(laser_fire_cone_degrees, 1.0, 180.0) * 0.5)


func _broadcast_network_weapon_fire(target_world_position: Vector2) -> void:
	if not _is_network_presentation or not is_server_authority:
		return

	if multiplayer.multiplayer_peer == null:
		return

	var galaxy := get_tree().current_scene
	if galaxy != null and galaxy.has_method("client_ship_weapon_fired"):
		galaxy.rpc("client_ship_weapon_fired", owner_peer_id, target_world_position)


func _broadcast_network_homing_missile_fire(
	target: Node2D,
	launch_origin: Vector2,
	launch_direction: Vector2,
	deploy_lateral_sign: float
) -> void:
	if not _is_network_presentation or not is_server_authority:
		return

	if multiplayer.multiplayer_peer == null:
		return

	var galaxy := get_tree().current_scene
	if galaxy == null or not galaxy.has_method("client_ship_homing_missile_fired"):
		return

	galaxy.rpc("client_ship_homing_missile_fired", {
		"owner_peer_id": owner_peer_id,
		"launch_origin": launch_origin,
		"launch_direction": launch_direction,
		"deploy_lateral_sign": deploy_lateral_sign,
		"target": _get_network_target_payload(target),
		"target_world_position": target.global_position,
	})


func _get_network_target_payload(target: Node2D) -> Dictionary:
	if target == null or not is_instance_valid(target):
		return {}

	if target is Enemy:
		return {
			"kind": "enemy",
			"id": int((target as Enemy).network_id),
		}

	if target.is_in_group(EXPLORER_BEACON_GROUP):
		return {
			"kind": "explorer_beacon",
			"id": int(target.get("network_id")),
		}

	if target.has_method("get_owner_peer_id"):
		return {
			"kind": "player",
			"id": int(target.call("get_owner_peer_id")),
		}

	return {}


func _get_fx_layer() -> Node2D:
	var parent := get_parent()
	if parent == null:
		return self

	var fx_layer := parent.find_child("FXLayer", true, false) as Node2D
	if fx_layer != null:
		return fx_layer

	var node_parent := parent as Node2D
	if node_parent != null:
		return node_parent

	return self


func _get_invisibility_presentation_alpha() -> float:
	if not is_invisible():
		return 1.0
	if _should_use_remote_invisibility_presentation():
		return clampf(remote_invisibility_visual_alpha, 0.0, 1.0)
	return clampf(invisibility_visual_alpha, 0.0, 1.0)


func _apply_invisibility_presentation() -> void:
	var presentation_alpha := _get_invisibility_presentation_alpha()
	if ship_sprite != null:
		var sprite_modulate := ship_sprite.modulate
		sprite_modulate.a = 1.0 if _should_use_remote_invisibility_presentation() else presentation_alpha
		ship_sprite.modulate = sprite_modulate
	_apply_invisibility_shader_presentation(presentation_alpha)
	if jets_root != null:
		var jets_modulate := jets_root.modulate
		jets_modulate.a = presentation_alpha
		jets_root.modulate = jets_modulate
	_update_shield_visuals()
	_apply_fog_presentation_to_owned_entities()


func _should_use_remote_invisibility_presentation() -> bool:
	return is_invisible() and not _is_vortex_captured() and _is_network_presentation and not is_local_player


func _apply_invisibility_shader_presentation(presentation_alpha: float) -> void:
	if _ship_material == null:
		return

	_ship_material.set_shader_parameter("alpha", presentation_alpha)
	_apply_remote_invisibility_shader_parameters()
	_apply_ship_sprite_material()


func _apply_ship_sprite_material() -> void:
	if ship_sprite == null:
		return

	var target_material: Material = _remote_invisibility_material if _should_use_remote_invisibility_presentation() else _ship_material
	if ship_sprite.material != target_material:
		ship_sprite.material = target_material


func _apply_remote_invisibility_shader_parameters() -> void:
	if _remote_invisibility_material == null:
		return

	_remote_invisibility_material.set_shader_parameter("time", _idle_elapsed)
	_remote_invisibility_material.set_shader_parameter("alpha", clampf(remote_invisibility_visual_alpha, 0.0, 1.0))
	_remote_invisibility_material.set_shader_parameter("global_fade", _fog_presentation_alpha)
	_remote_invisibility_material.set_shader_parameter("tint_color", remote_invisibility_tint_color)
	_remote_invisibility_material.set_shader_parameter("refraction_strength", remote_invisibility_refraction_strength)
	_remote_invisibility_material.set_shader_parameter("wave_frequency", remote_invisibility_wave_frequency)
	_remote_invisibility_material.set_shader_parameter("wave_speed", remote_invisibility_wave_speed)
	_remote_invisibility_material.set_shader_parameter("mirror_mix", remote_invisibility_mirror_mix)
	_remote_invisibility_material.set_shader_parameter("edge_strength", remote_invisibility_edge_strength)
	_remote_invisibility_material.set_shader_parameter("shimmer_strength", remote_invisibility_shimmer_strength)


func _ensure_drone_companion_manager() -> DroneCompanionManager:
	if _drone_companion_manager != null and is_instance_valid(_drone_companion_manager):
		_drone_companion_manager.set_owner_ship(self)
		return _drone_companion_manager

	var manager := DRONE_COMPANION_MANAGER_SCRIPT.new() as DroneCompanionManager
	if manager == null:
		return null

	manager.name = "DroneCompanionManager"
	manager.set_owner_ship(self)
	_drone_companion_manager = manager
	add_child(manager)
	return _drone_companion_manager


func _sync_drone_companions() -> void:
	var manager := _ensure_drone_companion_manager()
	if manager == null:
		return

	var active_drone_count := 0 if _is_destroyed else _drone_level
	manager.sync_companions(
		active_drone_count,
		_get_effective_weapon_range(),
		maxi(1, _laser_level),
		owner_peer_id,
		_is_network_presentation,
		is_server_authority,
		_is_fog_presentation_visible,
		_get_invisibility_presentation_alpha()
	)


func _clear_drone_companions() -> void:
	if _drone_companion_manager != null and is_instance_valid(_drone_companion_manager):
		_drone_companion_manager.clear()


func _apply_fog_presentation_to_owned_entities() -> void:
	if _drone_companion_manager != null and is_instance_valid(_drone_companion_manager):
		_drone_companion_manager.apply_presentation(_is_fog_presentation_visible, _get_invisibility_presentation_alpha())

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	for child in fx_layer.get_children():
		var missile := child as HomingMissile
		if missile != null and is_instance_valid(missile):
			if missile.owner_peer_id != owner_peer_id:
				continue

			var missile_visible := _should_show_owned_fog_effect(missile.global_position)
			if missile.has_method("set_fog_presentation_visible"):
				missile.call("set_fog_presentation_visible", missile_visible)
			else:
				missile.visible = missile_visible
			continue

		var projectile := child as Node2D
		if projectile == null or not is_instance_valid(projectile):
			continue
		if projectile.get_script() != LASER_PROJECTILE_SCRIPT:
			continue
		if int(projectile.get("owner_peer_id")) != owner_peer_id:
			continue

		projectile.call("set_fog_presentation_visible", _should_show_owned_fog_effect(projectile.global_position))


func _apply_owned_entity_presentation(entity: Node, is_fog_visible: bool) -> void:
	if entity == null or not is_instance_valid(entity):
		return

	if entity.has_method("set_owner_invisibility_alpha"):
		entity.call("set_owner_invisibility_alpha", _get_invisibility_presentation_alpha())
	elif entity is CanvasItem:
		var canvas_item := entity as CanvasItem
		var entity_modulate := canvas_item.modulate
		entity_modulate.a = _get_invisibility_presentation_alpha()
		canvas_item.modulate = entity_modulate

	if entity.has_method("set_fog_presentation_visible"):
		entity.call("set_fog_presentation_visible", is_fog_visible)
	elif entity is CanvasItem:
		(entity as CanvasItem).visible = is_fog_visible


func _should_show_owned_fog_effect(world_position: Vector2) -> bool:
	if not _is_fog_presentation_visible:
		return false
	if _fog_active_vision_query.is_valid():
		return bool(_fog_active_vision_query.call(world_position))
	return true


func _should_update_visual_presentation() -> bool:
	return _is_fog_presentation_visible and not _is_destroyed


func _sleep_visual_presentation() -> void:
	_set_jets_emitting(false)
	if shield_visual != null:
		shield_visual.visible = false


func _update_jets(delta: float) -> void:
	var is_propelling := _is_moving
	var target_strength := 1.0 if is_propelling else 0.0
	_jet_strength = move_toward(_jet_strength, target_strength, jet_warmup_speed * delta * 5)
	var speed_ratio := clampf(_current_speed / maxf(_get_effective_move_speed(), 1.0), 0.0, 1.0)
	var thrust_ratio := _jet_strength * speed_ratio
	var effective_jet_length_max := _get_effective_jet_length_scale_max()
	var effective_jet_turn_power_boost := _get_effective_jet_turn_power_boost()
	var jet_length_ratio := lerpf(jet_length_scale_min, effective_jet_length_max, thrust_ratio)
	var turn_ratio := absf(_turn_bias) * thrust_ratio
	var outer_jet_boost := lerpf(1.0, 1.0 + effective_jet_turn_power_boost, turn_ratio)
	var inner_jet_boost := lerpf(1.0, 1.0 - effective_jet_turn_power_boost, turn_ratio)

	var left_jet_boost := 1.0
	var right_jet_boost := 1.0
	if _turn_bias < 0.0:
		left_jet_boost = inner_jet_boost
		right_jet_boost = outer_jet_boost
	elif _turn_bias > 0.0:
		left_jet_boost = outer_jet_boost
		right_jet_boost = inner_jet_boost

	_apply_jet_visuals(left_jet, _left_jet_lifetime, _left_jet_speed_scale, _left_jet_scale_amount_max, jet_length_ratio, left_jet_boost)
	_apply_jet_visuals(right_jet, _right_jet_lifetime, _right_jet_speed_scale, _right_jet_scale_amount_max, jet_length_ratio, right_jet_boost)

	_set_jets_emitting(thrust_ratio > 0.02)


func _set_jets_emitting(is_emitting: bool) -> void:
	var was_emitting := _are_jets_emitting
	_are_jets_emitting = is_emitting
	if is_emitting and not was_emitting:
		_play_propulsion_sfx()
	elif not is_emitting and was_emitting:
		_stop_propulsion_sfx()
	left_jet.emitting = is_emitting
	right_jet.emitting = is_emitting
	left_jet.visible = is_emitting
	right_jet.visible = is_emitting


func _ensure_propulsion_player() -> void:
	if _propulsion_player != null and is_instance_valid(_propulsion_player):
		return

	var propulsion_stream: AudioStream = GAME_SFX.get_stream(GAME_SFX.CUE_PROPULSION)
	if propulsion_stream == null:
		return

	_propulsion_player = AudioStreamPlayer.new()
	_propulsion_player.name = "PropulsionSfx"
	_propulsion_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_propulsion_player.bus = GAME_SFX.get_bus_name()
	_propulsion_player.stream = propulsion_stream
	_propulsion_player.volume_db = -3.0
	_propulsion_player.finished.connect(_on_propulsion_sfx_finished)
	add_child(_propulsion_player)


func _play_propulsion_sfx() -> void:
	_ensure_propulsion_player()
	if _propulsion_player == null or not is_instance_valid(_propulsion_player):
		return
	if _propulsion_player.playing:
		return

	GAME_SFX.request_web_audio_unlock()
	_propulsion_player.pitch_scale = randf_range(0.96, 1.04)
	_propulsion_player.play()


func _stop_propulsion_sfx() -> void:
	if _propulsion_player == null or not is_instance_valid(_propulsion_player):
		return
	if not _propulsion_player.playing:
		return

	_propulsion_player.stop()


func _on_propulsion_sfx_finished() -> void:
	if not _are_jets_emitting:
		return
	if _propulsion_player == null or not is_instance_valid(_propulsion_player):
		return

	GAME_SFX.request_web_audio_unlock()
	_propulsion_player.pitch_scale = randf_range(0.96, 1.04)
	_propulsion_player.play()


func _apply_jet_visuals(
	jet: CPUParticles2D,
	base_lifetime: float,
	base_speed_scale: float,
	base_scale_amount_max: float,
	jet_length_ratio: float,
	jet_boost: float
) -> void:
	jet.lifetime = base_lifetime * jet_length_ratio * jet_boost
	jet.speed_scale = base_speed_scale * jet_length_ratio * jet_boost
	jet.scale_amount_max = base_scale_amount_max * jet_length_ratio * jet_boost


func _update_ship_visuals(delta: float) -> void:
	_idle_elapsed += delta
	_launch_pulse = move_toward(_launch_pulse, 0.0, launch_pulse_decay * delta)

	var speed_ratio := clampf(_current_speed / maxf(_get_effective_move_speed(), 1.0), 0.0, 1.0)
	var target_thrust_strength := clampf(_jet_strength * speed_ratio, 0.0, 1.0)
	_thrust_visual_strength = move_toward(_thrust_visual_strength, target_thrust_strength, _get_effective_thrust_visual_response() * delta)

	var combined_thrust := clampf(maxf(_thrust_visual_strength, _launch_pulse), 0.0, 1.0)
	var idle_weight := 1.0 - combined_thrust
	var idle_phase := _idle_elapsed * idle_float_speed

	var drift_offset := Vector2(
		sin(idle_phase + _idle_seed_a) * 0.85 + sin(idle_phase * 2.17 + _idle_seed_b) * 0.35,
		cos(idle_phase * 0.91 + _idle_seed_c) * 0.9 + sin(idle_phase * 1.73 + _idle_seed_a * 0.5) * 0.3
	) * idle_float_amount * idle_weight

	var launch_offset := Vector2(
		sin(_idle_elapsed * launch_vibration_speed + _idle_seed_b) * 1.15,
		cos(_idle_elapsed * (launch_vibration_speed * 1.23) + _idle_seed_c) * 0.85
	) * launch_shake_amount * _launch_pulse

	var drift_rotation := (
		sin(idle_phase * 0.8 + _idle_seed_b) * 0.7
		+ cos(idle_phase * 1.33 + _idle_seed_c) * 0.5
	) * idle_rotation_amount * idle_weight
	var launch_rotation := sin(_idle_elapsed * launch_vibration_speed * 1.35 + _idle_seed_a) * launch_rotation_amount * _launch_pulse
	var drift_scale := 1.0 + idle_weight * idle_scale_amount * 1.35 + combined_thrust * thrust_scale_boost + _launch_pulse * launch_scale_boost

	visuals_root.position = _visuals_base_position + drift_offset + launch_offset
	visuals_root.rotation = _visuals_base_rotation + drift_rotation + launch_rotation
	visuals_root.scale = _visuals_base_scale * drift_scale

	var internal_wobble_phase := _idle_elapsed * idle_internal_wobble_speed
	var internal_wobble := Vector2(
		sin(internal_wobble_phase + _idle_seed_c) * 0.85,
		cos(internal_wobble_phase * 1.37 + _idle_seed_a) * 0.55
	) * idle_internal_wobble_amount * idle_weight

	ship_sprite.position = _sprite_base_position + internal_wobble
	ship_sprite.rotation = _sprite_base_rotation + sin(internal_wobble_phase * 0.9 + _idle_seed_b) * 0.02 * idle_weight
	ship_sprite.scale = _sprite_base_scale
	_update_shield_visuals(delta)

	jets_root.position = _jets_base_position + internal_wobble * 0.7 + Vector2(0.0, combined_thrust * 3.0)
	jets_root.rotation = _jets_base_rotation
	jets_root.scale = _jets_base_scale * (1.0 + combined_thrust * 0.012 + _launch_pulse * 0.02)

	if _ship_material != null:
		var invisibility_thrust := 0.18 if is_invisible() else 0.0
		_ship_material.set_shader_parameter("time", _idle_elapsed)
		_ship_material.set_shader_parameter("thrust_strength", maxf(combined_thrust, invisibility_thrust))
		_ship_material.set_shader_parameter("distortion_strength", thrust_distortion_amount + (invisibility_distortion_bonus if is_invisible() else 0.0))
		_ship_material.set_shader_parameter("engine_focus", thrust_distortion_focus)
		_ship_material.set_shader_parameter("vortex_strength", _get_vortex_visual_strength())
		_ship_material.set_shader_parameter("vortex_direction", _get_vortex_visual_direction())
		_ship_material.set_shader_parameter("holo_effect_strength", _artifact_warp_holo_strength)
		_apply_invisibility_shader_presentation(_get_invisibility_presentation_alpha())

	if _debug_show_vacuum_radius or _is_selected or _selection_ring_alpha > 0.0:
		queue_redraw()


func _apply_ship_visuals() -> void:
	visuals_root.position = _visuals_base_position
	visuals_root.rotation = _visuals_base_rotation
	visuals_root.scale = _visuals_base_scale
	ship_sprite.position = _sprite_base_position
	ship_sprite.rotation = _sprite_base_rotation
	ship_sprite.scale = _sprite_base_scale
	_update_shield_visuals()
	jets_root.position = _jets_base_position
	jets_root.rotation = _jets_base_rotation
	jets_root.scale = _jets_base_scale


func _update_shield_visuals(delta: float = -1.0) -> void:
	if shield_visual == null:
		return

	shield_visual.call(
		"update_presentation",
		_shield_level,
		_current_speed,
		_get_effective_move_speed(),
		_fog_presentation_alpha * _get_invisibility_presentation_alpha(),
		delta,
		_is_destroyed,
		ship_sprite.global_rotation,
		_idle_elapsed
	)

extends Node2D
class_name NukeExplosionEffect

const MUSHROOM_SHADER: Shader = preload("res://shaders/nuke_mushroom_cloud.gdshader")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const ENEMY_GROUP: StringName = &"enemies"
const PLAYER_GROUP: StringName = &"player_ships"
const EXPLORER_BEACON_GROUP: StringName = &"explorer_beacons"
const SMOKE_PARTICLE_LIFETIME_SECONDS: float = 6.4
const SMOKE_FADE_DELAY_SECONDS: float = 1.8
const SMOKE_FADE_DURATION_SECONDS: float = 4.6
const MEGA_CAMERA_SHAKE_INTENSITY: float = 1.85

@export_range(64.0, 6000.0, 10.0) var blast_radius: float = 700.0
@export_range(1, 999, 1) var damage: int = 30
@export_range(0.2, 12.0, 0.05) var duration_seconds: float = 10.0
@export var deals_damage: bool = true
@export var owner_peer_id: int = 0
@export_group("Damage Timing")
@export_range(0.0, 1.0, 0.01) var blast_growth_duration_ratio: float = 0.36
@export_range(0.0, 1.0, 0.01) var blast_damage_edge_ratio: float = 0.18
@export_range(0.0, 1.0, 0.01) var blast_min_damage_ratio: float = 0.55
@export_range(0.0, 200.0, 0.1) var radiation_damage_per_second: float = 3.0
@export_range(0.05, 5.0, 0.05) var radiation_tick_interval_seconds: float = 1.0
@export_range(0.0, 1.0, 0.01) var radiation_damage_edge_ratio: float = 0.28
@export_range(0.0, 1.0, 0.01) var radiation_min_damage_ratio: float = 0.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var fire_sparkles: CPUParticles2D = get_node_or_null("FireSparkles") as CPUParticles2D
@onready var ember_sparkles: CPUParticles2D = get_node_or_null("EmberSparkles") as CPUParticles2D
@onready var smoke_puffs: CPUParticles2D = get_node_or_null("SmokePuffs") as CPUParticles2D

var _elapsed: float = 0.0
var _fog_alpha: float = 1.0
var _particle_fog_alpha: float = 1.0
var _blast_damaged_nodes: Dictionary = {}
var _radiation_damage_remainders: Dictionary = {}
var _radiation_tick_time_left: float = 0.0
var _white_texture: ImageTexture
var _material: ShaderMaterial
var _uses_fog_visibility_mask: bool = false
var _fog_visibility_mask: Texture2D
var _fog_world_bounds_min: Vector2 = Vector2.ZERO
var _fog_world_bounds_max: Vector2 = Vector2.ONE
var _has_played_explosion_sfx: bool = false


func configure(
	world_position: Vector2,
	effect_blast_radius: float,
	effect_damage: int,
	effect_duration_seconds: float,
	should_deal_damage: bool = true,
	effect_owner_peer_id: int = 0,
	damage_config: Dictionary = {}
) -> void:
	global_position = world_position
	blast_radius = maxf(effect_blast_radius, 1.0)
	damage = maxi(effect_damage, 1)
	duration_seconds = maxf(effect_duration_seconds, 0.1)
	deals_damage = should_deal_damage
	owner_peer_id = effect_owner_peer_id
	_elapsed = 0.0
	_apply_damage_config(damage_config)
	_reset_damage_state()
	if is_node_ready():
		_apply_visual_setup()


func set_fog_presentation_alpha(alpha: float) -> void:
	_fog_alpha = clampf(alpha, 0.0, 1.0)
	_update_visibility()


func set_fog_presentation_visible(is_visible: bool) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0)


func get_fog_presentation_radius() -> float:
	return maxf(blast_radius * 1.38, blast_radius)


func set_fog_visibility_mask(mask_texture: Texture2D, world_bounds_min: Vector2, world_bounds_max: Vector2, is_enabled: bool) -> void:
	_fog_visibility_mask = mask_texture
	_fog_world_bounds_min = world_bounds_min
	_fog_world_bounds_max = world_bounds_max
	_uses_fog_visibility_mask = is_enabled and _fog_visibility_mask != null
	_update_shader_parameters()


func set_particle_fog_presentation_alpha(alpha: float) -> void:
	_particle_fog_alpha = clampf(alpha, 0.0, 1.0)
	_update_particle_visibility()


func _ready() -> void:
	_apply_visual_setup()
	_configure_sparkle_emitters()
	_reset_damage_state()
	_play_explosion_sfx()
	_request_camera_shake()


func _process(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_elapsed += safe_delta
	_apply_progressive_damage(safe_delta)
	_update_shader_parameters()
	_update_visibility()

	if _elapsed >= duration_seconds:
		queue_free()


func _apply_visual_setup() -> void:
	if sprite == null:
		return

	if _white_texture == null:
		_white_texture = _create_white_texture()
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = MUSHROOM_SHADER
		_material.set_shader_parameter("seed", randf_range(0.0, 1000.0))

	sprite.texture = _white_texture
	sprite.material = _material
	sprite.centered = true
	sprite.z_index = 70
	var texture_size := _white_texture.get_size()
	var texture_extent := maxf(texture_size.x, texture_size.y)
	var diameter := blast_radius * 3.2
	sprite.scale = Vector2.ONE * (diameter / maxf(texture_extent, 1.0))
	_update_shader_parameters()
	_update_visibility()


func _play_explosion_sfx() -> void:
	if _has_played_explosion_sfx:
		return

	_has_played_explosion_sfx = true
	GAME_SFX.play(self, GAME_SFX.CUE_NUKE_EXPLOSION)


func _configure_sparkle_emitters() -> void:
	_configure_sparkle_emitter(
		fire_sparkles,
		0.04,
		0.95,
		maxi(int(blast_radius * 0.52), 180),
		maxf(blast_radius * 0.028, 14.0),
		Color(1.0, 0.5, 0.08, 1.0)
	)
	_configure_sparkle_emitter(
		ember_sparkles,
		0.02,
		0.52,
		maxi(int(blast_radius * 0.34), 110),
		maxf(blast_radius * 0.052, 26.0),
		Color(1.0, 0.86, 0.32, 0.82)
	)
	_configure_sparkle_emitter(
		smoke_puffs,
		0.01,
		0.2,
		maxi(int(blast_radius * 0.32), 150),
		maxf(blast_radius * 0.09, 44.0),
		Color(0.24, 0.22, 0.28, 0.58)
	)
	_fade_smoke_puffs()


func _configure_sparkle_emitter(
	emitter: CPUParticles2D,
	min_velocity_ratio: float,
	max_velocity_ratio: float,
	particle_amount: int,
	emission_radius: float,
	sparkle_color: Color
) -> void:
	if emitter == null:
		return

	emitter.amount = particle_amount
	emitter.emission_sphere_radius = emission_radius
	emitter.initial_velocity_min = maxf(blast_radius * min_velocity_ratio, 1.0)
	emitter.initial_velocity_max = maxf(blast_radius * max_velocity_ratio, emitter.initial_velocity_min)
	emitter.color = sparkle_color
	emitter.restart()
	emitter.emitting = true


func _fade_smoke_puffs() -> void:
	if smoke_puffs == null:
		return

	smoke_puffs.lifetime = SMOKE_PARTICLE_LIFETIME_SECONDS
	smoke_puffs.modulate = Color(1.0, 1.0, 1.0, 0.92)
	var smoke_tween := create_tween()
	smoke_tween.set_trans(Tween.TRANS_SINE)
	smoke_tween.set_ease(Tween.EASE_IN_OUT)
	smoke_tween.tween_interval(SMOKE_FADE_DELAY_SECONDS)
	smoke_tween.tween_property(smoke_puffs, "modulate:a", 0.0, SMOKE_FADE_DURATION_SECONDS)


func _apply_damage_config(damage_config: Dictionary) -> void:
	if damage_config.is_empty():
		return

	if damage_config.has("blast_growth_duration_ratio"):
		blast_growth_duration_ratio = clampf(float(damage_config.get("blast_growth_duration_ratio", blast_growth_duration_ratio)), 0.0, 1.0)
	if damage_config.has("blast_damage_edge_ratio"):
		blast_damage_edge_ratio = clampf(float(damage_config.get("blast_damage_edge_ratio", blast_damage_edge_ratio)), 0.0, 1.0)
	if damage_config.has("blast_min_damage_ratio"):
		blast_min_damage_ratio = clampf(float(damage_config.get("blast_min_damage_ratio", blast_min_damage_ratio)), 0.0, 1.0)
	if damage_config.has("radiation_damage_per_second"):
		radiation_damage_per_second = maxf(float(damage_config.get("radiation_damage_per_second", radiation_damage_per_second)), 0.0)
	if damage_config.has("radiation_tick_interval_seconds"):
		radiation_tick_interval_seconds = maxf(float(damage_config.get("radiation_tick_interval_seconds", radiation_tick_interval_seconds)), 0.05)
	if damage_config.has("radiation_damage_edge_ratio"):
		radiation_damage_edge_ratio = clampf(float(damage_config.get("radiation_damage_edge_ratio", radiation_damage_edge_ratio)), 0.0, 1.0)
	if damage_config.has("radiation_min_damage_ratio"):
		radiation_min_damage_ratio = clampf(float(damage_config.get("radiation_min_damage_ratio", radiation_min_damage_ratio)), 0.0, 1.0)


func _reset_damage_state() -> void:
	_blast_damaged_nodes.clear()
	_radiation_damage_remainders.clear()
	_radiation_tick_time_left = _get_radiation_tick_interval()


func _apply_progressive_damage(delta: float) -> void:
	if not deals_damage:
		return

	var current_radius := _get_current_damage_radius()
	var blast_processed_nodes: Dictionary = {}
	for node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		_damage_body_if_reached_by_blast(node as Node2D, current_radius, blast_processed_nodes)
	for node in get_tree().get_nodes_in_group(PLAYER_GROUP):
		_damage_body_if_reached_by_blast(node as Node2D, current_radius, blast_processed_nodes)
	for node in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
		_damage_body_if_reached_by_blast(node as Node2D, current_radius, blast_processed_nodes)

	if radiation_damage_per_second <= 0.0:
		return

	_radiation_tick_time_left -= delta
	var tick_interval := _get_radiation_tick_interval()
	while _radiation_tick_time_left <= 0.0:
		_damage_bodies_in_radiation(current_radius, tick_interval)
		_radiation_tick_time_left += tick_interval


func _damage_body_if_reached_by_blast(body: Node2D, current_radius: float, processed_nodes: Dictionary) -> void:
	if not _is_damageable_body(body):
		return
	if processed_nodes.has(body):
		return
	processed_nodes[body] = true
	if _blast_damaged_nodes.has(body):
		return
	if not _is_body_inside_damage_radius(body, current_radius):
		return

	var distance := _get_body_edge_distance(body)
	var applied_damage := _calculate_damage_for_distance(
		float(damage),
		distance,
		blast_damage_edge_ratio,
		blast_min_damage_ratio
	)
	_apply_damage_to_body(body, applied_damage, not (body is Enemy))
	_blast_damaged_nodes[body] = true


func _damage_bodies_in_radiation(current_radius: float, tick_interval: float) -> void:
	var processed_nodes: Dictionary = {}
	for node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		_damage_body_if_in_radiation(node as Node2D, current_radius, tick_interval, processed_nodes)
	for node in get_tree().get_nodes_in_group(PLAYER_GROUP):
		_damage_body_if_in_radiation(node as Node2D, current_radius, tick_interval, processed_nodes)
	for node in get_tree().get_nodes_in_group(EXPLORER_BEACON_GROUP):
		_damage_body_if_in_radiation(node as Node2D, current_radius, tick_interval, processed_nodes)


func _damage_body_if_in_radiation(body: Node2D, current_radius: float, tick_interval: float, processed_nodes: Dictionary) -> void:
	if not _is_damageable_body(body):
		return
	if processed_nodes.has(body):
		return
	processed_nodes[body] = true
	if not _is_body_inside_damage_radius(body, current_radius):
		return

	var distance := _get_body_edge_distance(body)
	var damage_ratio := _calculate_damage_ratio_for_distance(
		distance,
		radiation_damage_edge_ratio,
		radiation_min_damage_ratio
	)
	var damage_total := float(_radiation_damage_remainders.get(body, 0.0))
	damage_total += maxf(radiation_damage_per_second, 0.0) * tick_interval * damage_ratio
	var applied_damage := int(floor(damage_total))
	if applied_damage <= 0:
		_radiation_damage_remainders[body] = damage_total
		return

	_radiation_damage_remainders[body] = damage_total - float(applied_damage)
	_apply_damage_to_body(body, applied_damage, false)


func _is_damageable_body(body: Node2D) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	if body.has_method("is_destroyed") and bool(body.call("is_destroyed")):
		return false
	if not body.has_method("take_damage"):
		return false

	return true


func _is_body_inside_damage_radius(body: Node2D, radius: float) -> bool:
	return _get_body_edge_distance(body) <= maxf(radius, 0.0)


func _get_body_edge_distance(body: Node2D) -> float:
	var touch_radius := 0.0
	if body.has_method("get_touch_radius"):
		touch_radius = maxf(float(body.call("get_touch_radius")), 0.0)

	var distance := body.global_position.distance_to(global_position)
	return maxf(distance - touch_radius, 0.0)


func _get_current_damage_radius() -> float:
	var progress := clampf(_elapsed / maxf(duration_seconds, 0.001), 0.0, 1.0)
	if blast_growth_duration_ratio <= 0.0:
		return blast_radius

	return blast_radius * smoothstep(0.0, clampf(blast_growth_duration_ratio, 0.001, 1.0), progress)


func _calculate_damage_for_distance(base_damage: float, distance: float, edge_ratio: float, min_damage_ratio: float) -> int:
	var damage_ratio := _calculate_damage_ratio_for_distance(distance, edge_ratio, min_damage_ratio)
	return maxi(int(ceil(base_damage * damage_ratio)), 1)


func _calculate_damage_ratio_for_distance(distance: float, edge_ratio: float, min_damage_ratio: float) -> float:
	var safe_edge_ratio := clampf(edge_ratio, 0.0, 1.0)
	var safe_min_damage_ratio := clampf(min_damage_ratio, 0.0, 1.0)
	var damage_ratio := 1.0
	if safe_edge_ratio > 0.0:
		var falloff_start := blast_radius * (1.0 - safe_edge_ratio)
		if distance > falloff_start:
			damage_ratio = 1.0 - clampf((distance - falloff_start) / maxf(blast_radius - falloff_start, 1.0), 0.0, 1.0)

	return lerpf(safe_min_damage_ratio, 1.0, damage_ratio)


func _apply_damage_to_body(body: Node2D, applied_damage: int, should_spawn_hit_fx: bool) -> void:
	if applied_damage <= 0:
		return

	if body is Enemy or body is ExplorerBeacon:
		body.call("take_damage", applied_damage, global_position, should_spawn_hit_fx)
	else:
		body.call("take_damage", applied_damage, global_position)


func _get_radiation_tick_interval() -> float:
	return maxf(radiation_tick_interval_seconds, 0.05)


func _request_camera_shake() -> void:
	var scene_root := get_tree().current_scene
	if scene_root != null and scene_root.has_method("request_camera_shake"):
		scene_root.call("request_camera_shake", MEGA_CAMERA_SHAKE_INTENSITY, global_position)


func _update_shader_parameters() -> void:
	if _material == null:
		return

	var progress := clampf(_elapsed / maxf(duration_seconds, 0.001), 0.0, 1.0)
	_material.set_shader_parameter("progress", progress)
	_material.set_shader_parameter("global_fade", _fog_alpha)
	_material.set_shader_parameter("expansion_duration_ratio", clampf(blast_growth_duration_ratio, 0.0, 1.0))
	_material.set_shader_parameter("use_fog_visibility_mask", _uses_fog_visibility_mask)
	_material.set_shader_parameter("fog_world_bounds_min", _fog_world_bounds_min)
	_material.set_shader_parameter("fog_world_bounds_max", _fog_world_bounds_max)
	if _fog_visibility_mask != null:
		_material.set_shader_parameter("fog_visibility_mask", _fog_visibility_mask)


func _update_visibility() -> void:
	visible = _fog_alpha > 0.01
	_update_particle_visibility()


func _update_particle_visibility() -> void:
	var particles_are_visible := _particle_fog_alpha > 0.01
	for particles in [fire_sparkles, ember_sparkles, smoke_puffs]:
		if particles == null:
			continue
		particles.visible = particles_are_visible


func _create_white_texture() -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

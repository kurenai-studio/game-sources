extends Node2D
class_name ShipExplosionFx

const SHIP_SCRIPT: Script = preload("res://scripts/ship.gd")
const FIRE_SHADER: Shader = preload("res://shaders/explosion_fire.gdshader")
const SMOKE_SHADER: Shader = preload("res://shaders/explosion_smoke.gdshader")
const SPARKS_SHADER: Shader = preload("res://shaders/explosion_sparks.gdshader")
const DEBRIS_SHADER: Shader = preload("res://shaders/explosion_debris.gdshader")
const FRAGMENT_SHADER: Shader = preload("res://shaders/ship_fragment.gdshader")
const DISTORTION_SHADER: Shader = preload("res://shaders/ship_distortion.gdshader")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const EXPLOSION_SCALE: float = 0.5
const EXPLOSION_ABOVE_SHIP_OFFSET_RATIO: float = 0.33
const FRAGMENT_SCALE_MULTIPLIER: float = 1.5
const DEFAULT_CAMERA_SHAKE_INTENSITY: float = 0.5
const ENEMY_CAMERA_SHAKE_INTENSITY: float = 0.36
const SHIP_CAMERA_SHAKE_INTENSITY: float = 1.0
const FOG_PRESENTATION_VISIBLE_EPSILON: float = 0.01
const EXPLOSION_GROUP: StringName = &"ship_explosion_fx"
const FRAGMENT_GROUP: StringName = &"ship_explosion_fragments"
const DEBRIS_GROUP: StringName = &"ship_explosion_debris"
const DEFAULT_MAX_ACTIVE_EXPLOSION_EFFECTS: int = 10

## Seconds to wait before the explosion starts fading out and deleting itself.
@export_range(1.0, 30.0, 0.1) var cleanup_delay: float = 10.0
## Duration of the final fade-out after the effect has finished.
@export_range(0.1, 10.0, 0.1) var fade_out_duration: float = 4.0
## Minimum number of ship fragments spawned during the breakup.
@export_range(3, 12, 1) var fragment_count_min: int = 3
## Maximum number of ship fragments spawned during the breakup.
@export_range(3, 12, 1) var fragment_count_max: int = 6
## Time used for fragments to drift away after the ship breaks apart.
@export_range(0.4, 8.0, 0.05) var fragment_drift_duration: float = 3.1
## Minimum constant world-space speed assigned to each ship fragment.
@export_range(0.0, 1200.0, 5.0) var fragment_speed_min: float = 95.0
## Maximum constant world-space speed assigned to each ship fragment.
@export_range(0.0, 1200.0, 5.0) var fragment_speed_max: float = 240.0
## Delay before the secondary smoke burst is spawned.
@export_range(0.0, 2.0, 0.01) var secondary_burst_delay: float = 0.22
## Duration of the main fire burst at the center of the explosion.
@export_range(0.2, 6.0, 0.05) var core_burst_duration: float = 1.55
## Lifetime of the main smoke plume.
@export_range(0.4, 8.0, 0.05) var smoke_duration: float = 3.8
## Lifetime of the spark burst.
@export_range(0.2, 5.0, 0.05) var spark_duration: float = 1.45
## Number of spark particles emitted in the burst.
@export_range(0, 64, 1) var spark_count: int = 32
## Number of smoke particles emitted in the burst.
@export_range(0, 32, 1) var smoke_count: int = 14
## Number of ember particles spawned around the ship.
@export_range(0, 16, 1) var ember_count: int = 8
## Number of dark debris chunks thrown out of the explosion.
@export_range(0, 48, 1) var debris_count: int = 24
## Minimum constant world-space speed assigned to each dark debris chunk.
@export_range(0.0, 1600.0, 5.0) var debris_speed_min: float = 140.0
## Maximum constant world-space speed assigned to each dark debris chunk.
@export_range(0.0, 1600.0, 5.0) var debris_speed_max: float = 360.0
## Maximum ship-fragment sprites allowed across all active explosion effects.
@export_range(0, 256, 1) var max_active_fragment_sprites: int = 36
## Maximum dark debris chunks allowed across all active explosion effects.
@export_range(0, 512, 1) var max_active_debris_particles: int = 72
## Duration of the distortion overlay.
@export_range(0.1, 2.0, 0.05) var distortion_duration: float = 0.7
## Strength of the source texture distortion.
@export_range(0.0, 0.05, 0.001) var distortion_strength: float = 0.022
## Alpha used by the distortion overlay before fade-out.
@export_range(0.0, 1.0, 0.01) var distortion_alpha: float = 0.7
## Vertical focus used by the distortion shader.
@export_range(0.0, 1.0, 0.01) var distortion_engine_focus: float = 0.0
## Per-frame scanline noise frequency used by the distortion shader.
@export_range(0.0, 40.0, 0.1) var distortion_jitter_frequency: float = 18.0
## Per-frame shimmer frequency used by the distortion shader.
@export_range(0.0, 40.0, 0.1) var distortion_shimmer_frequency: float = 9.5
## Controls how soft the ship fragment slice edges look in the shader.
@export_range(0.0, 0.2, 0.001) var slice_softness: float = 0.06
## Adds irregularity to the fragment borders so they do not look perfectly cut.
@export_range(0.0, 0.2, 0.001) var fragment_edge_jaggedness: float = 0.05
## Frequency of the jagged edge noise on the fragment shader.
@export_range(1.0, 64.0, 0.5) var fragment_edge_jagged_frequency: float = 18.0
## Chance that a breakup uses horizontal slices instead of vertical ones.
@export_range(0.0, 1.0, 0.01) var horizontal_fragment_breakup_chance: float = 0.5

@onready var particle_layer: Node2D = $ParticleLayer
@onready var fragment_layer: Node2D = $FragmentLayer
@onready var fire_sprite: Sprite2D = $FireSprite
@onready var smoke_sprite: Sprite2D = $SmokeSprite
@onready var distortion_sprite: Sprite2D = $DistortionSprite
@onready var sparks_sprite: Sprite2D = $SparksSprite

var _source_ref: Node2D
var _source_sprite_path: NodePath = NodePath("Visuals/shipSprite")
var _source_vertical_offset_ratio: float = EXPLOSION_ABOVE_SHIP_OFFSET_RATIO
var _source_explosion_scale: float = 1.0
var _camera_shake_intensity: float = DEFAULT_CAMERA_SHAKE_INTENSITY
var _elapsed: float = 0.0
var _has_started: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _white_texture: ImageTexture
var _fire_material: ShaderMaterial
var _smoke_material: ShaderMaterial
var _distortion_material: ShaderMaterial
var _sparks_material: ShaderMaterial
var _back_glow_sprite: Sprite2D
var _back_glow_material: ShaderMaterial
var _front_smoke_sprite: Sprite2D
var _front_smoke_material: ShaderMaterial
var _tracked_materials: Array = []
var _cleanup_fade_materials: Array = []
var _is_fading_out: bool = false
var _fade_elapsed: float = 0.0
var _cleanup_fade_amount: float = 1.0
var _fog_presentation_alpha: float = 1.0
var _is_fog_presentation_visible: bool = true


static func can_spawn_active_explosion(tree: SceneTree, limit: int = DEFAULT_MAX_ACTIVE_EXPLOSION_EFFECTS) -> bool:
	if limit <= 0:
		return false
	if tree == null:
		return true

	return tree.get_nodes_in_group(EXPLOSION_GROUP).size() < limit


func configure_from_ship(ship: Node2D) -> void:
	_camera_shake_intensity = SHIP_CAMERA_SHAKE_INTENSITY
	configure_from_source(ship, NodePath("Visuals/shipSprite"), EXPLOSION_ABOVE_SHIP_OFFSET_RATIO, 1.0)


func configure_from_enemy(enemy: Node2D, explosion_scale: float = 1.0) -> void:
	_camera_shake_intensity = ENEMY_CAMERA_SHAKE_INTENSITY
	_apply_enemy_explosion_budget()
	configure_from_source(enemy, NodePath("EnemySprite"), 0.0, explosion_scale)


func configure_from_source(source: Node2D, sprite_path: NodePath, vertical_offset_ratio: float = EXPLOSION_ABOVE_SHIP_OFFSET_RATIO, explosion_scale: float = 1.0) -> void:
	_source_ref = source
	_source_sprite_path = sprite_path
	_source_vertical_offset_ratio = clampf(vertical_offset_ratio, 0.0, 1.0)
	_source_explosion_scale = maxf(explosion_scale, 0.01)
	if is_node_ready():
		_start_explosion()


func set_fog_presentation_visible(is_visible: bool) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0)


func set_fog_presentation_alpha(alpha: float) -> void:
	var resolved_alpha := clampf(alpha, 0.0, 1.0)
	var is_visible_for_fog := resolved_alpha > FOG_PRESENTATION_VISIBLE_EPSILON
	if is_equal_approx(resolved_alpha, _fog_presentation_alpha) and is_visible_for_fog == _is_fog_presentation_visible:
		return

	_fog_presentation_alpha = resolved_alpha
	_is_fog_presentation_visible = is_visible_for_fog
	visible = _is_fog_presentation_visible
	if not _is_fog_presentation_visible:
		_cull_hidden_fog_effect()
		return

	_update_global_fade()


func _enter_tree() -> void:
	add_to_group(EXPLOSION_GROUP)


func _ready() -> void:
	_rng.randomize()
	_build_base_materials()
	if _source_ref != null:
		_start_explosion()
	set_process(true)


func _process(delta: float) -> void:
	if not _is_fog_presentation_visible:
		return

	_elapsed += delta
	_update_shader_time()
	_update_piece_motion(delta)
	_update_cleanup_fade(delta)


func _cull_hidden_fog_effect() -> void:
	set_process(false)
	_clear_layer_children(particle_layer)
	_clear_layer_children(fragment_layer)
	_tracked_materials.clear()
	_cleanup_fade_materials.clear()
	if is_inside_tree():
		queue_free()


func _start_explosion() -> void:
	if _has_started:
		return

	_has_started = true

	if not _apply_source_configuration():
		queue_free()
		return

	_play_explosion_sfx()
	_request_camera_shake()
	_spawn_particle_bursts()
	_play_explosion_animation()
	_begin_cleanup_sequence()


func _build_base_materials() -> void:
	_white_texture = _create_white_texture(64, 64)

	_fire_material = ShaderMaterial.new()
	_fire_material.shader = FIRE_SHADER
	_fire_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_fire_material.set_shader_parameter("alpha", 1.0)
	_fire_material.set_shader_parameter("global_fade", 1.0)
	_fire_material.set_shader_parameter("core_color", Color(1.0, 0.78, 0.18, 1.0))
	_fire_material.set_shader_parameter("outer_color", Color(1.0, 0.38, 0.1, 1.0))
	_tracked_materials.append(_fire_material)
	_cleanup_fade_materials.append(_fire_material)
	fire_sprite.material = _fire_material
	fire_sprite.texture = _white_texture
	fire_sprite.centered = true
	fire_sprite.z_index = 35
	_back_glow_sprite = Sprite2D.new()
	_back_glow_material = ShaderMaterial.new()
	_back_glow_material.shader = FIRE_SHADER
	_back_glow_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_back_glow_material.set_shader_parameter("alpha", 0.72)
	_back_glow_material.set_shader_parameter("global_fade", 1.0)
	_back_glow_material.set_shader_parameter("core_color", Color(1.0, 0.62, 0.16, 1.0))
	_back_glow_material.set_shader_parameter("outer_color", Color(0.96, 0.14, 0.05, 1.0))
	_tracked_materials.append(_back_glow_material)
	_cleanup_fade_materials.append(_back_glow_material)
	_back_glow_sprite.name = "BackGlowSprite"
	_back_glow_sprite.material = _back_glow_material
	_back_glow_sprite.texture = _white_texture
	_back_glow_sprite.centered = true
	_back_glow_sprite.z_index = 2
	add_child(_back_glow_sprite)

	_smoke_material = ShaderMaterial.new()
	_smoke_material.shader = SMOKE_SHADER
	_smoke_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_smoke_material.set_shader_parameter("alpha", 0.92)
	_smoke_material.set_shader_parameter("global_fade", 1.0)
	_smoke_material.set_shader_parameter("smoke_color", Color(0.1, 0.09, 0.1, 0.98))
	_tracked_materials.append(_smoke_material)
	_cleanup_fade_materials.append(_smoke_material)
	smoke_sprite.material = _smoke_material
	smoke_sprite.texture = _white_texture
	smoke_sprite.centered = true
	smoke_sprite.z_index = 8
	_front_smoke_sprite = Sprite2D.new()
	_front_smoke_material = ShaderMaterial.new()
	_front_smoke_material.shader = SMOKE_SHADER
	_front_smoke_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_front_smoke_material.set_shader_parameter("alpha", 0.64)
	_front_smoke_material.set_shader_parameter("global_fade", 1.0)
	_front_smoke_material.set_shader_parameter("smoke_color", Color(0.2, 0.18, 0.2, 0.84))
	_tracked_materials.append(_front_smoke_material)
	_cleanup_fade_materials.append(_front_smoke_material)
	_front_smoke_sprite.name = "FrontSmokeSprite"
	_front_smoke_sprite.material = _front_smoke_material
	_front_smoke_sprite.texture = _white_texture
	_front_smoke_sprite.centered = true
	_front_smoke_sprite.z_index = 48
	add_child(_front_smoke_sprite)

	_sparks_material = ShaderMaterial.new()
	_sparks_material.shader = SPARKS_SHADER
	_sparks_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_sparks_material.set_shader_parameter("alpha", 0.38)
	_sparks_material.set_shader_parameter("global_fade", 1.0)
	_sparks_material.set_shader_parameter("spark_color", Color(1.0, 0.48, 0.1, 1.0))
	_tracked_materials.append(_sparks_material)
	_cleanup_fade_materials.append(_sparks_material)
	sparks_sprite.material = _sparks_material
	sparks_sprite.texture = _white_texture
	sparks_sprite.centered = true
	sparks_sprite.z_index = 42

	_distortion_material = ShaderMaterial.new()
	_distortion_material.shader = DISTORTION_SHADER
	_distortion_material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	_distortion_material.set_shader_parameter("alpha", distortion_alpha)
	_distortion_material.set_shader_parameter("global_fade", 1.0)
	_distortion_material.set_shader_parameter("thrust_strength", 1.0)
	_distortion_material.set_shader_parameter("distortion_strength", distortion_strength)
	_distortion_material.set_shader_parameter("jitter_frequency", distortion_jitter_frequency)
	_distortion_material.set_shader_parameter("shimmer_frequency", distortion_shimmer_frequency)
	_distortion_material.set_shader_parameter("engine_focus", distortion_engine_focus)
	_tracked_materials.append(_distortion_material)
	_cleanup_fade_materials.append(_distortion_material)
	distortion_sprite.material = _distortion_material
	distortion_sprite.centered = true
	distortion_sprite.z_index = 26
	distortion_sprite.visible = false


func _play_explosion_sfx() -> void:
	if _source_ref == null or not is_instance_valid(_source_ref):
		return
	if _source_ref is HomingMissile:
		GAME_SFX.play(self, GAME_SFX.CUE_MISSILE_EXPLOSION)
		return
	if _source_ref is Enemy:
		GAME_SFX.play(self, GAME_SFX.CUE_MEDIUM_EXPLOSION)
		return
	if _source_ref.get_script() == SHIP_SCRIPT:
		GAME_SFX.play(self, GAME_SFX.CUE_MEDIUM_EXPLOSION)


func _apply_source_configuration() -> bool:
	if _source_ref == null:
		return false

	var source_sprite := _source_ref.get_node_or_null(_source_sprite_path) as Sprite2D
	if source_sprite == null or source_sprite.texture == null:
		return false

	global_position = _source_ref.global_position
	global_rotation = _source_ref.global_rotation

	var source_texture := source_sprite.texture
	var source_visual_size := source_sprite.get_rect().size * source_sprite.global_scale.abs()
	if source_visual_size == Vector2.ZERO:
		source_visual_size = Vector2(96.0, 96.0)
	var explosion_visual_scale := maxf(_source_explosion_scale, 0.01)
	var explosion_visual_size := source_visual_size * explosion_visual_scale
	scale = Vector2.ONE * EXPLOSION_SCALE
	global_position += Vector2.UP.rotated(global_rotation) * source_visual_size.y * _source_vertical_offset_ratio

	fire_sprite.position = Vector2(0.0, -explosion_visual_size.y * 0.18)
	fire_sprite.scale = Vector2.ONE * maxf(explosion_visual_size.x * 0.068, 4.2 * explosion_visual_scale)
	if _back_glow_sprite != null:
		_back_glow_sprite.position = Vector2(0.0, -explosion_visual_size.y * 0.08)
		_back_glow_sprite.scale = fire_sprite.scale * 1.58
	smoke_sprite.position = Vector2(0.0, explosion_visual_size.y * 0.08)
	smoke_sprite.scale = Vector2.ONE * maxf(explosion_visual_size.x * 0.09, 5.2 * explosion_visual_scale)
	if _front_smoke_sprite != null:
		_front_smoke_sprite.position = Vector2(explosion_visual_size.x * 0.03, explosion_visual_size.y * 0.12)
		_front_smoke_sprite.scale = smoke_sprite.scale * 0.82
	sparks_sprite.position = Vector2(0.0, -explosion_visual_size.y * 0.1)
	sparks_sprite.scale = Vector2.ONE * maxf(explosion_visual_size.x * 0.045, 2.9 * explosion_visual_scale)
	distortion_sprite.texture = source_texture
	distortion_sprite.position = Vector2.ZERO
	distortion_sprite.rotation = 0.0
	distortion_sprite.scale = source_sprite.global_scale.abs() / maxf(EXPLOSION_SCALE, 0.001) * 1.08 * explosion_visual_scale
	distortion_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	distortion_sprite.visible = true

	_clear_layer_children(fragment_layer)
	_create_fragments(source_texture, source_sprite.global_scale, source_visual_size)

	return true


func _request_camera_shake() -> void:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root == null or not scene_root.has_method("request_camera_shake"):
		return

	var intensity := _camera_shake_intensity
	if _source_ref is HomingMissile:
		intensity = _get_scene_float_property(scene_root, &"homing_missile_camera_shake_intensity", intensity)
	elif _source_ref != null and _source_ref.is_in_group(&"player_ships"):
		intensity = _get_scene_float_property(scene_root, &"ship_destroyed_camera_shake_intensity", intensity)

	scene_root.call("request_camera_shake", intensity, global_position)


func _get_scene_float_property(scene_root: Node, property_name: StringName, fallback: float) -> float:
	for property in scene_root.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return float(scene_root.get(property_name))

	return fallback


func _create_fragments(ship_texture: Texture2D, fragment_scale: Vector2, ship_visual_size: Vector2) -> void:
	var requested_count := clampi(_rng.randi_range(fragment_count_min, fragment_count_max), 3, 12)
	var count := mini(requested_count, _get_remaining_global_piece_budget(FRAGMENT_GROUP, max_active_fragment_sprites))
	if count <= 0:
		return

	var use_horizontal_breakup := _rng.randf() < horizontal_fragment_breakup_chance
	var weights: Array[float] = []
	weights.resize(count)
	var boundary_seeds: Array[float] = []
	boundary_seeds.resize(max(count - 1, 0))

	var total_weight := 0.0
	for index in range(count):
		var weight := _rng.randf_range(0.18, 1.0)
		weights[index] = weight
		total_weight += weight
	for boundary in range(count - 1):
		boundary_seeds[boundary] = _rng.randf_range(0.0, 1000.0)

	var outer_left_seed := _rng.randf_range(0.0, 1000.0)
	var outer_right_seed := _rng.randf_range(0.0, 1000.0)

	var slice_start := 0.0
	for index in range(count):
		var slice_width := weights[index] / maxf(total_weight, 0.001)
		var slice_end := 1.0 if index == count - 1 else minf(slice_start + slice_width, 1.0)
		var left_edge_seed := outer_left_seed if index == 0 else boundary_seeds[index - 1]
		var right_edge_seed := outer_right_seed if index == count - 1 else boundary_seeds[index]
		var left_edge_jaggedness := _get_fragment_edge_jaggedness(slice_end - slice_start, index == 0)
		var right_edge_jaggedness := _get_fragment_edge_jaggedness(slice_end - slice_start, index == count - 1)
		var fragment := _create_fragment_sprite(
			ship_texture,
			fragment_scale,
			slice_start,
			slice_end,
			left_edge_seed,
			right_edge_seed,
			left_edge_jaggedness,
			right_edge_jaggedness,
			use_horizontal_breakup,
			index,
			count
		)
		fragment_layer.add_child(fragment)
		_animate_fragment(fragment, ship_visual_size, slice_start, slice_end, use_horizontal_breakup, index, count)
		slice_start = slice_end


func _create_fragment_sprite(
	ship_texture: Texture2D,
	fragment_scale: Vector2,
	slice_start: float,
	slice_end: float,
	left_edge_seed: float,
	right_edge_seed: float,
	left_edge_jaggedness: float,
	right_edge_jaggedness: float,
	use_horizontal_breakup: bool,
	index: int,
	count: int
) -> Sprite2D:
	var fragment := Sprite2D.new()
	var material := ShaderMaterial.new()
	material.shader = FRAGMENT_SHADER
	material.set_shader_parameter("slice_min", slice_start)
	material.set_shader_parameter("slice_max", slice_end)
	material.set_shader_parameter("slice_softness", slice_softness)
	material.set_shader_parameter("left_edge_jaggedness", left_edge_jaggedness)
	material.set_shader_parameter("right_edge_jaggedness", right_edge_jaggedness)
	material.set_shader_parameter("jagged_frequency", fragment_edge_jagged_frequency)
	material.set_shader_parameter("left_edge_seed", left_edge_seed)
	material.set_shader_parameter("right_edge_seed", right_edge_seed)
	material.set_shader_parameter("slice_is_horizontal", 1.0 if use_horizontal_breakup else 0.0)
	material.set_shader_parameter("fade", 1.0)
	material.set_shader_parameter("global_fade", 1.0)
	material.set_shader_parameter("tint", Color(1.0, 1.0, 1.0, 1.0))
	_cleanup_fade_materials.append(material)
	_apply_material_global_fade(material)
	fragment.material = material
	fragment.texture = ship_texture
	fragment.centered = true
	fragment.z_index = -12 + index
	fragment.scale = fragment_scale * FRAGMENT_SCALE_MULTIPLIER * _rng.randf_range(1.0 - 0.08, 1.0 + 0.08)
	fragment.position = Vector2.ZERO
	fragment.rotation = _rng.randf_range(-0.08, 0.08)
	fragment.modulate = Color(1.0, 1.0, 1.0, 1.0)
	fragment.add_to_group(FRAGMENT_GROUP)
	return fragment


func _get_fragment_edge_jaggedness(fragment_width: float, is_outer_edge: bool) -> float:
	var base_jaggedness := clampf(fragment_edge_jaggedness, 0.0, 0.2)
	if is_outer_edge:
		base_jaggedness *= 0.75
	return minf(base_jaggedness, maxf(fragment_width * 0.35, 0.0))


func _animate_fragment(
	fragment: Sprite2D,
	_ship_visual_size: Vector2,
	slice_start: float,
	slice_end: float,
	_use_horizontal_breakup: bool,
	_index: int,
	_count: int
) -> void:
	var slice_center := (slice_start + slice_end) * 0.5
	var side_bias := (slice_center - 0.5) * 2.0
	var travel_direction := _random_normalized_direction()
	var travel_speed := _rng.randf_range(
		minf(fragment_speed_min, fragment_speed_max),
		maxf(fragment_speed_min, fragment_speed_max)
	)
	var angular_velocity := _rng.randf_range(-2.2, 2.2) + side_bias * _rng.randf_range(-0.8, 0.8)

	fragment.set_meta("_fx_world_velocity", travel_direction * travel_speed)
	fragment.set_meta("_fx_angular_velocity", angular_velocity)


func _update_piece_motion(delta: float) -> void:
	_update_moving_children(fragment_layer, delta)
	_update_moving_children(particle_layer, delta)


func _update_moving_children(layer: Node, delta: float) -> void:
	if layer == null:
		return

	for child in layer.get_children():
		var piece := child as Sprite2D
		if piece == null:
			continue

		if not piece.has_meta("_fx_world_velocity"):
			continue

		var velocity := piece.get_meta("_fx_world_velocity") as Vector2
		var angular_velocity := float(piece.get_meta("_fx_angular_velocity", 0.0))
		piece.global_position += velocity * delta
		piece.rotation += angular_velocity * delta


func _spawn_particle_bursts() -> void:
	var source_sprite := _source_ref.get_node_or_null(_source_sprite_path) as Sprite2D
	if source_sprite == null:
		return

	var source_visual_size := source_sprite.get_rect().size * source_sprite.global_scale.abs()
	if source_visual_size == Vector2.ZERO:
		source_visual_size = Vector2(96.0, 96.0)
	var explosion_visual_scale := maxf(_source_explosion_scale, 0.01)
	var explosion_visual_size := source_visual_size * explosion_visual_scale

	_spawn_core_particle(
		fire_sprite,
		FIRE_SHADER,
		explosion_visual_size,
		Vector2(0.0, -explosion_visual_size.y * 0.12),
		Vector2.ONE * (4.25 * explosion_visual_scale),
		core_burst_duration,
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.0),
		30,
		0.65,
		0.08
	)

	_spawn_core_particle(
		smoke_sprite,
		SMOKE_SHADER,
		explosion_visual_size,
		Vector2(0.0, -explosion_visual_size.y * 0.42),
		Vector2.ONE * (5.1 * explosion_visual_scale),
		smoke_duration,
		Color(1.0, 1.0, 1.0, 0.86),
		Color(1.0, 1.0, 1.0, 0.0),
		-8,
		0.15,
		0.95
	)

	_spawn_core_particle(
		sparks_sprite,
		SPARKS_SHADER,
		explosion_visual_size,
		Vector2(0.0, -explosion_visual_size.y * 0.05),
		Vector2.ONE * (2.5 * explosion_visual_scale),
		spark_duration,
		Color(1.0, 1.0, 1.0, 0.42),
		Color(1.0, 1.0, 1.0, 0.0),
		7,
		0.3,
		0.6
	)

	for index in range(ember_count):
		_spawn_shader_particle(
			FIRE_SHADER,
			explosion_visual_size,
			Vector2(
				_rng.randf_range(-explosion_visual_size.x * 0.1, explosion_visual_size.x * 0.1),
				_rng.randf_range(-explosion_visual_size.y * 0.08, explosion_visual_size.y * 0.08)
			),
			Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(explosion_visual_size.x * 1.3, explosion_visual_size.x * 3.4)
			+ Vector2(0.0, _rng.randf_range(-explosion_visual_size.y * 0.55, -explosion_visual_size.y * 0.08)),
			_rng.randf_range(0.8, 1.7),
			Vector2.ONE * (_rng.randf_range(0.18, 0.42) * explosion_visual_scale),
			Vector2.ONE * (_rng.randf_range(0.5, 0.98) * explosion_visual_scale),
			Color(1.0, 0.9, 0.55, 1.0),
			Color(1.0, 0.65, 0.2, 0.0),
			8,
			_rng.randf_range(-1.4, 1.4)
		)

	for index in range(spark_count):
		_spawn_shader_particle(
			SPARKS_SHADER,
			explosion_visual_size,
			Vector2(
				_rng.randf_range(-explosion_visual_size.x * 0.12, explosion_visual_size.x * 0.12),
				_rng.randf_range(-explosion_visual_size.y * 0.1, explosion_visual_size.y * 0.1)
			),
			Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(explosion_visual_size.x * 2.0, explosion_visual_size.x * 6.5)
			+ Vector2(0.0, _rng.randf_range(-explosion_visual_size.y * 0.35, explosion_visual_size.y * 0.6)),
			_rng.randf_range(0.75, 1.6),
			Vector2.ONE * (_rng.randf_range(0.1, 0.32) * explosion_visual_scale),
			Vector2.ONE * (_rng.randf_range(0.02, 0.09) * explosion_visual_scale),
			Color(1.0, 0.66, 0.24, 0.58),
			Color(1.0, 0.75, 0.26, 0.0),
			10,
			_rng.randf_range(-2.8, 2.8)
		)

	var resolved_debris_count := mini(debris_count, _get_remaining_global_piece_budget(DEBRIS_GROUP, max_active_debris_particles))
	for index in range(resolved_debris_count):
		_spawn_debris_particle(source_visual_size, index)

	for index in range(smoke_count):
		_spawn_shader_particle(
			SMOKE_SHADER,
			explosion_visual_size,
			Vector2(
				_rng.randf_range(-explosion_visual_size.x * 0.26, explosion_visual_size.x * 0.26),
				_rng.randf_range(-explosion_visual_size.y * 0.18, explosion_visual_size.y * 0.18)
			),
			Vector2(
				_rng.randf_range(-explosion_visual_size.x * 1.2, explosion_visual_size.x * 1.2),
				_rng.randf_range(-explosion_visual_size.y * 1.1, explosion_visual_size.y * 0.5)
			),
			_rng.randf_range(2.4, 5.4),
			Vector2.ONE * (_rng.randf_range(0.28, 0.62) * explosion_visual_scale),
			Vector2.ONE * (_rng.randf_range(1.35, 2.9) * explosion_visual_scale),
			Color(0.55, 0.52, 0.56, 0.78),
			Color(0.28, 0.27, 0.3, 0.0),
			-9,
			_rng.randf_range(-0.35, 0.35)
		)

	_spawn_delayed_smoke(source_visual_size)


func _spawn_delayed_smoke(ship_visual_size: Vector2) -> void:
	var delayed_tween := create_tween()
	delayed_tween.tween_interval(secondary_burst_delay)
	delayed_tween.tween_callback(func() -> void:
		for index in range(maxi(4, smoke_count / 2)):
			_spawn_shader_particle(
				SMOKE_SHADER,
				ship_visual_size,
				Vector2(
					_rng.randf_range(-ship_visual_size.x * 0.16, ship_visual_size.x * 0.16),
					_rng.randf_range(-ship_visual_size.y * 0.08, ship_visual_size.y * 0.08)
				),
				Vector2(
					_rng.randf_range(-ship_visual_size.x * 0.8, ship_visual_size.x * 0.8),
					_rng.randf_range(-ship_visual_size.y * 0.82, ship_visual_size.y * 0.28)
				),
				_rng.randf_range(2.8, 5.8),
				Vector2.ONE * (_rng.randf_range(0.18, 0.42) * maxf(_source_explosion_scale, 0.01)),
				Vector2.ONE * (_rng.randf_range(1.5, 2.9) * maxf(_source_explosion_scale, 0.01)),
				Color(0.46, 0.44, 0.48, 0.7),
				Color(0.22, 0.21, 0.24, 0.0),
				-9,
				_rng.randf_range(-0.25, 0.25)
			)
	)


func _spawn_core_particle(
	sprite: Sprite2D,
	shader: Shader,
	ship_visual_size: Vector2,
	target_offset: Vector2,
	target_scale: Vector2,
	duration: float,
	start_modulate: Color,
	end_modulate: Color,
	z_index: int,
	rotation_delta: float,
	position_jitter: float
) -> void:
	var particle := _create_shader_particle(shader, z_index)
	particle.texture = _white_texture
	particle.centered = true
	particle.position = sprite.position + Vector2(
		_rng.randf_range(-position_jitter, position_jitter) * ship_visual_size.x,
		_rng.randf_range(-position_jitter, position_jitter) * ship_visual_size.y
	)
	particle.scale = sprite.scale
	particle.rotation = sprite.rotation + _rng.randf_range(-0.2, 0.2)
	particle.modulate = start_modulate
	particle_layer.add_child(particle)

	var particle_material := particle.material as ShaderMaterial
	if particle_material != null:
		particle_material.set_shader_parameter("alpha", start_modulate.a)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "position", sprite.position + target_offset, duration)
	tween.parallel().tween_property(particle, "scale", target_scale, duration)
	tween.parallel().tween_property(particle, "rotation", particle.rotation + rotation_delta, duration)
	if particle_material != null:
		tween.parallel().tween_property(particle_material, "shader_parameter/alpha", end_modulate.a, duration)
	tween.tween_callback(Callable(self, "_release_particle").bind(particle, particle_material))


func _spawn_shader_particle(
	shader: Shader,
	ship_visual_size: Vector2,
	start_offset: Vector2,
	end_offset: Vector2,
	duration: float,
	start_scale: Vector2,
	end_scale: Vector2,
	start_modulate: Color,
	end_modulate: Color,
	z_index: int,
	rotation_delta: float
) -> void:
	var particle := _create_shader_particle(shader, z_index)
	particle.texture = _white_texture
	particle.centered = true
	particle.position = start_offset
	particle.scale = start_scale
	particle.rotation = _rng.randf_range(-PI, PI)
	particle.modulate = start_modulate
	particle_layer.add_child(particle)

	var particle_material := particle.material as ShaderMaterial
	if particle_material != null:
		particle_material.set_shader_parameter("alpha", start_modulate.a)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "position", end_offset, duration)
	tween.parallel().tween_property(particle, "scale", end_scale, duration)
	tween.parallel().tween_property(particle, "rotation", particle.rotation + rotation_delta, duration)
	if particle_material != null:
		tween.parallel().tween_property(particle_material, "shader_parameter/alpha", end_modulate.a, duration)
	tween.tween_callback(Callable(self, "_release_particle").bind(particle, particle_material))


func _spawn_debris_particle(ship_visual_size: Vector2, index: int) -> void:
	var particle := _create_shader_particle(DEBRIS_SHADER, 18 + (index % 7))
	particle.texture = _white_texture
	particle.centered = true
	particle.position = Vector2(
		_rng.randf_range(-ship_visual_size.x * 0.13, ship_visual_size.x * 0.13),
		_rng.randf_range(-ship_visual_size.y * 0.12, ship_visual_size.y * 0.12)
	)
	var direction := _random_normalized_direction()
	var speed := _rng.randf_range(
		minf(debris_speed_min, debris_speed_max),
		maxf(debris_speed_min, debris_speed_max)
	)
	var start_size := _rng.randf_range(0.1, 0.28)
	var end_size := start_size * _rng.randf_range(0.75, 1.25)
	var duration := _rng.randf_range(1.2, 3.4)
	particle.scale = Vector2.ONE * start_size
	particle.rotation = _rng.randf_range(-PI, PI)
	particle.add_to_group(DEBRIS_GROUP)
	particle.set_meta("_fx_world_velocity", direction * speed)
	particle.set_meta("_fx_angular_velocity", _rng.randf_range(-6.0, 6.0) / duration)
	particle_layer.add_child(particle)

	var particle_material := particle.material as ShaderMaterial
	if particle_material != null:
		particle_material.set_shader_parameter("alpha", _rng.randf_range(0.78, 1.0))
		particle_material.set_shader_parameter("chunk_color", Color(
			_rng.randf_range(0.055, 0.16),
			_rng.randf_range(0.028, 0.075),
			_rng.randf_range(0.022, 0.06),
			1.0
		))
		particle_material.set_shader_parameter("rim_color", Color(1.0, _rng.randf_range(0.13, 0.34), 0.04, 1.0))

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "scale", Vector2.ONE * end_size, duration)
	if particle_material != null:
		tween.parallel().tween_property(particle_material, "shader_parameter/alpha", 0.0, duration)
	tween.tween_callback(Callable(self, "_release_particle").bind(particle, particle_material))


func _create_shader_particle(shader: Shader, z_index: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("time", 0.0)
	material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	material.set_shader_parameter("alpha", 1.0)
	material.set_shader_parameter("global_fade", 1.0)
	sprite.material = material
	sprite.z_index = z_index
	_tracked_materials.append(material)
	_cleanup_fade_materials.append(material)
	_apply_material_global_fade(material)
	return sprite


func _release_particle(particle: Node, particle_material: ShaderMaterial) -> void:
	if particle_material != null:
		_tracked_materials.erase(particle_material)
		_cleanup_fade_materials.erase(particle_material)
	if particle != null and is_instance_valid(particle):
		particle.queue_free()


func _get_remaining_global_piece_budget(group_name: StringName, limit: int) -> int:
	if limit <= 0:
		return 0

	var tree := get_tree()
	if tree == null:
		return limit

	return maxi(limit - tree.get_nodes_in_group(group_name).size(), 0)


func _random_normalized_direction() -> Vector2:
	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)).normalized()


func _apply_enemy_explosion_budget() -> void:
	cleanup_delay = minf(cleanup_delay, 2.0)
	fade_out_duration = minf(fade_out_duration, 0.45)
	fragment_count_min = mini(fragment_count_min, 3)
	fragment_count_max = mini(fragment_count_max, 3)
	core_burst_duration = minf(core_burst_duration, 0.85)
	smoke_duration = minf(smoke_duration, 1.4)
	spark_duration = minf(spark_duration, 0.75)
	secondary_burst_delay = minf(secondary_burst_delay, 0.12)
	distortion_duration = minf(distortion_duration, 0.35)
	spark_count = mini(spark_count, 10)
	smoke_count = mini(smoke_count, 4)
	ember_count = mini(ember_count, 2)
	debris_count = mini(debris_count, 6)


func _play_explosion_animation() -> void:
	var fire_tween := create_tween()
	fire_tween.set_trans(Tween.TRANS_QUAD)
	fire_tween.set_ease(Tween.EASE_OUT)
	fire_tween.tween_property(fire_sprite, "scale", fire_sprite.scale * 3.4, core_burst_duration)
	fire_tween.parallel().tween_property(fire_sprite, "position", fire_sprite.position + Vector2(0.0, -fire_sprite.scale.x * 4.0), core_burst_duration)
	fire_tween.parallel().tween_property(fire_sprite, "rotation", fire_sprite.rotation + _rng.randf_range(-0.45, 0.45), core_burst_duration)
	fire_tween.parallel().tween_property(_fire_material, "shader_parameter/alpha", 0.0, core_burst_duration)
	if _back_glow_sprite != null and _back_glow_material != null:
		fire_tween.parallel().tween_property(_back_glow_sprite, "scale", _back_glow_sprite.scale * 4.6, core_burst_duration)
		fire_tween.parallel().tween_property(_back_glow_sprite, "position", _back_glow_sprite.position + Vector2(0.0, -_back_glow_sprite.scale.x * 2.4), core_burst_duration)
		fire_tween.parallel().tween_property(_back_glow_material, "shader_parameter/alpha", 0.0, core_burst_duration)

	var smoke_tween := create_tween()
	smoke_tween.tween_interval(secondary_burst_delay)
	smoke_tween.set_trans(Tween.TRANS_SINE)
	smoke_tween.set_ease(Tween.EASE_OUT)
	smoke_tween.tween_property(smoke_sprite, "scale", smoke_sprite.scale * 4.8, smoke_duration)
	smoke_tween.parallel().tween_property(smoke_sprite, "position", smoke_sprite.position + Vector2(0.0, -smoke_sprite.scale.x * 8.8), smoke_duration)
	smoke_tween.parallel().tween_property(smoke_sprite, "rotation", smoke_sprite.rotation + _rng.randf_range(-0.2, 0.2), smoke_duration)
	smoke_tween.parallel().tween_property(_smoke_material, "shader_parameter/alpha", 0.0, smoke_duration)
	if _front_smoke_sprite != null and _front_smoke_material != null:
		smoke_tween.parallel().tween_property(_front_smoke_sprite, "scale", _front_smoke_sprite.scale * 3.9, smoke_duration)
		smoke_tween.parallel().tween_property(_front_smoke_sprite, "position", _front_smoke_sprite.position + Vector2(_front_smoke_sprite.scale.x * 0.28, -_front_smoke_sprite.scale.x * 6.7), smoke_duration)
		smoke_tween.parallel().tween_property(_front_smoke_sprite, "rotation", _front_smoke_sprite.rotation + _rng.randf_range(-0.16, 0.16), smoke_duration)
		smoke_tween.parallel().tween_property(_front_smoke_material, "shader_parameter/alpha", 0.0, smoke_duration)

	var sparks_tween := create_tween()
	sparks_tween.set_trans(Tween.TRANS_QUAD)
	sparks_tween.set_ease(Tween.EASE_OUT)
	sparks_tween.tween_property(sparks_sprite, "scale", sparks_sprite.scale * 2.4, spark_duration)
	sparks_tween.parallel().tween_property(sparks_sprite, "position", sparks_sprite.position + Vector2(0.0, -sparks_sprite.scale.x * 1.6), spark_duration)
	sparks_tween.parallel().tween_property(sparks_sprite, "rotation", sparks_sprite.rotation + _rng.randf_range(-0.25, 0.25), spark_duration)
	sparks_tween.parallel().tween_property(_sparks_material, "shader_parameter/alpha", 0.0, spark_duration)

	var distortion_tween := create_tween()
	distortion_tween.set_trans(Tween.TRANS_SINE)
	distortion_tween.set_ease(Tween.EASE_OUT)
	distortion_tween.tween_property(distortion_sprite, "scale", distortion_sprite.scale * 1.08, distortion_duration)
	distortion_tween.parallel().tween_property(_distortion_material, "shader_parameter/thrust_strength", 0.0, distortion_duration)
	distortion_tween.parallel().tween_property(_distortion_material, "shader_parameter/alpha", 0.0, distortion_duration)


func _begin_cleanup_sequence() -> void:
	_run_cleanup_sequence()


func _run_cleanup_sequence() -> void:
	await get_tree().create_timer(cleanup_delay).timeout
	if not is_inside_tree():
		return

	_is_fading_out = true
	_fade_elapsed = 0.0


func _update_cleanup_fade(delta: float) -> void:
	if not _is_fading_out:
		return

	_fade_elapsed += delta
	var fade_progress := clampf(_fade_elapsed / maxf(fade_out_duration, 0.001), 0.0, 1.0)
	var fade_amount := 1.0 - fade_progress
	var fade_modulate := modulate
	fade_modulate.a = fade_amount
	modulate = fade_modulate
	_cleanup_fade_amount = fade_amount
	_update_global_fade()

	if fade_progress >= 1.0 and is_inside_tree():
		queue_free()


func _update_global_fade() -> void:
	for material in _cleanup_fade_materials:
		var shader_material := material as ShaderMaterial
		if shader_material != null:
			_apply_material_global_fade(shader_material)


func _apply_material_global_fade(shader_material: ShaderMaterial) -> void:
	if shader_material == null:
		return

	shader_material.set_shader_parameter("global_fade", _cleanup_fade_amount * _fog_presentation_alpha)


func _update_shader_time() -> void:
	for material in _tracked_materials:
		var shader_material := material as ShaderMaterial
		if shader_material != null:
			shader_material.set_shader_parameter("time", _elapsed)


func _clear_layer_children(layer: Node) -> void:
	if layer == null:
		return

	for child in layer.get_children():
		child.queue_free()


func _create_white_texture(width: int, height: int) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(image)

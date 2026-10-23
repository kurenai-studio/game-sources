@tool
class_name ProceduralGalaxyBackground
extends Node2D

const QUALITY_LOW: int = 0
const QUALITY_MEDIUM: int = 1
const QUALITY_HIGH: int = 2
const QUALITY_ULTRA: int = 3

const PALETTE_BLUE_VOID: int = 0
const PALETTE_TEAL_NEBULA: int = 1
const PALETTE_PURPLE_RIFT: int = 2
const PALETTE_GREEN_ION_CLOUD: int = 3
const PALETTE_RED_DANGER_SECTOR: int = 4
const PALETTE_GOLDEN_ANCIENT_SECTOR: int = 5

const PLANET_EDGE_LEFT: int = 0
const PLANET_EDGE_RIGHT: int = 1
const PLANET_EDGE_BOTTOM: int = 2
const PLANET_EDGE_TOP: int = 3

const STAR_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_star.gdshader")
const NEBULA_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_nebula.gdshader")
const EFFECTS_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_effects.gdshader")
const ASTEROID_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_asteroid.gdshader")
const PLANET_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_planet_rim.gdshader")

const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(1600.0, 900.0)
const STAR_TILE_SCALE: float = 2.35
const STAR_LAYER_NAMES: PackedStringArray = ["FarStars", "MidStars"]
const NEBULA_LAYER_NAMES: PackedStringArray = ["NebulaLayer1", "NebulaLayer2", "NebulaLayer3", "NebulaLayer4"]
const FAR_STAR_CAMERA_MOTION_RATIO: float = 0.15
const MID_STAR_CAMERA_MOTION_RATIO: float = 0.17
const ASTEROID_CAMERA_MOTION_RATIO: float = 0.19
const GALAXY_EFFECTS_CAMERA_MOTION_RATIO: float = 0.13
const NEBULA_MIN_CAMERA_MOTION_RATIO: float = 0.1
const NEBULA_MAX_CAMERA_MOTION_RATIO: float = 0.14

@export_group("Generation")
@export var seed: int = 1337
@export_enum("Low", "Medium", "High", "Ultra") var quality_preset: int = QUALITY_HIGH
@export_range(0.1, 3.0, 0.05) var star_density: float = 1.0
@export_range(0.1, 3.0, 0.05) var star_brightness: float = 1.0
@export_range(0.0, 1.0, 0.01) var star_color_variation: float = 0.45
@export_range(0, 256, 1) var rare_bright_star_count: int = 36

@export_group("Galaxy Colors")
@export var use_palette_colors: bool = true
@export var galaxy_background_color: Color = Color(0.002, 0.014, 0.022, 1.0)
@export var galaxy_nebula_mid_color: Color = Color(0.02, 0.32, 0.39, 1.0)
@export var galaxy_nebula_glow_color: Color = Color(0.35, 1.0, 0.88, 1.0)

@export_group("Nebula")
@export var nebula_enabled: bool = true
@export_range(0.0, 3.0, 0.05) var nebula_intensity: float = 1.0
@export var nebula_animation_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var nebula_animation_speed: float = 0.08
@export_enum("Blue Void", "Teal Nebula", "Purple Rift", "Green Ion Cloud", "Red Danger Sector", "Golden Ancient Sector") var nebula_color_palette: int = PALETTE_TEAL_NEBULA
@export_range(1, 4, 1) var nebula_layer_count: int = 3

@export_group("Galaxy Effects")
@export var galaxy_effects_enabled: bool = true
@export_range(0.0, 3.0, 0.05) var galaxy_effects_intensity: float = 0.8
@export_range(0.0, 1.0, 0.01) var galaxy_effects_animation_speed: float = 0.035
@export_range(0.05, 3.0, 0.05) var galaxy_effects_density: float = 0.45
@export_range(0.1, 3.0, 0.05) var galaxy_effects_cluster_scale: float = 1.0
@export_range(0.0, 2.0, 0.05) var galaxy_effects_streak_strength: float = 0.75
@export var galaxy_effects_warm_color: Color = Color(1.0, 0.62, 0.16, 1.0)
@export var galaxy_effects_cool_color: Color = Color(0.22, 0.85, 1.0, 1.0)
@export var galaxy_effects_core_color: Color = Color(0.98, 0.96, 1.0, 1.0)

@export_group("Parallax")
@export_range(0.0, 1.0, 0.01) var parallax_strength: float = 0.72

@export_group("Asteroid Belt")
@export var asteroid_belt_enabled: bool = true
@export_range(0.0, 3.0, 0.05) var asteroid_belt_density: float = 0.65
@export_range(-180.0, 180.0, 1.0) var asteroid_belt_angle: float = -10.0
@export_range(0.0, 1.0, 0.01) var asteroid_belt_opacity: float = 0.38

@export_group("Planet Rim")
@export var planet_enabled: bool = true
@export_enum("Left", "Right", "Bottom", "Top") var planet_edge_position: int = PLANET_EDGE_LEFT
@export_range(180.0, 1800.0, 10.0) var planet_radius: float = 760.0
@export var planet_color: Color = Color(0.38, 0.68, 0.72, 1.0)
@export var atmosphere_color: Color = Color(0.23, 0.95, 1.0, 1.0)
@export_range(0.0, 3.0, 0.05) var planet_brightness: float = 0.95

@export_group("Debug")
@export var debug_stats_enabled: bool = false

var _camera_position: Vector2 = Vector2.ZERO
var _camera_zoom: Vector2 = Vector2.ONE
var _canvas_size: Vector2 = DEFAULT_VIEWPORT_SIZE
var _star_counts: Array[int] = [0, 0]
var _nebula_layers_active: int = 0
var _asteroid_count: int = 0
var _settings_signature: int = 0
var _generation_queued: bool = false

@onready var _parallax_root: Node2D = $ParallaxRoot
@onready var _canvas_layer: CanvasLayer = $CanvasLayer
@onready var _background: ColorRect = $CanvasLayer/Background
@onready var _galaxy_effects: ColorRect = $CanvasLayer/GalaxyEffects
@onready var _far_stars: MultiMeshInstance2D = $CanvasLayer/FarStars
@onready var _mid_stars: MultiMeshInstance2D = $CanvasLayer/MidStars
@onready var _asteroid_belt: MultiMeshInstance2D = $CanvasLayer/AsteroidBelt
@onready var _planet_rim: ColorRect = $CanvasLayer/PlanetRim
@onready var _debug_stats: Label = $CanvasLayer/DebugStats


func _ready() -> void:
	set_process(true)
	call_deferred("regenerate")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var next_signature := _build_settings_signature()
		if next_signature != _settings_signature and not _generation_queued:
			_generation_queued = true
			call_deferred("regenerate")

	_update_dynamic_materials()
	_update_layer_offsets()


func sync_to_camera(camera_position: Vector2, camera_zoom: Vector2 = Vector2.ONE) -> void:
	if _camera_position == camera_position and _camera_zoom == camera_zoom:
		return

	_camera_position = camera_position
	_camera_zoom = camera_zoom
	_update_dynamic_materials()
	_update_layer_offsets()


func regenerate() -> void:
	if not is_inside_tree():
		return

	_generation_queued = false
	_canvas_size = _resolve_canvas_size()
	_settings_signature = _build_settings_signature()
	_configure_canvas()
	_configure_star_layers()
	_configure_nebula_layers()
	_configure_galaxy_effects()
	_configure_asteroid_belt()
	_configure_planet_rim()
	_update_layer_offsets()
	_update_debug_stats()


func get_stats_text() -> String:
	return "Galaxy BG | Quality: %s | Stars: %d | Nebula: %d | Effects: %s | Asteroids: %d | Draws: ~%d" % [
		_get_quality_name(),
		_star_counts[0] + _star_counts[1],
		_nebula_layers_active,
		"on" if _are_galaxy_effects_active() else "off",
		_asteroid_count,
		_get_approx_draw_calls(),
	]


func _configure_canvas() -> void:
	_canvas_layer.layer = -100
	_canvas_layer.follow_viewport_enabled = false
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.color = _get_galaxy_colors()[0]
	_far_stars.material = _create_star_material(0.055)
	_mid_stars.material = _create_star_material(0.085)
	_asteroid_belt.material = _create_asteroid_material()


func _configure_star_layers() -> void:
	var preset := _get_quality_profile()
	var far_count := int(round(float(preset["far_stars"]) * star_density))
	var mid_count := int(round(float(preset["mid_stars"]) * star_density))
	_star_counts = [far_count, mid_count]
	_build_star_multimesh(_far_stars, far_count, seed + 11, 0.9, 2.5, 1.05)
	_build_star_multimesh(_mid_stars, mid_count, seed + 37, 0.85, 3.6, 0.9)


func _configure_nebula_layers() -> void:
	_nebula_layers_active = 0
	var preset := _get_quality_profile()
	var active_count := 0
	if nebula_enabled:
		active_count = clampi(mini(nebula_layer_count, int(preset["nebula_layers"])), 1, 4)

	var palette := _get_galaxy_colors()
	for i in NEBULA_LAYER_NAMES.size():
		var layer := get_node("CanvasLayer/%s" % NEBULA_LAYER_NAMES[i]) as ColorRect
		layer.visible = i < active_count
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		if not layer.visible:
			continue

		var material := ShaderMaterial.new()
		material.shader = NEBULA_SHADER
		layer.material = material
		_set_nebula_material_static(material, i, active_count, preset, palette)
		_nebula_layers_active += 1


func _configure_galaxy_effects() -> void:
	var preset := _get_quality_profile()
	_galaxy_effects.visible = _are_galaxy_effects_active()
	_galaxy_effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_galaxy_effects.set_anchors_preset(Control.PRESET_FULL_RECT)
	if not _galaxy_effects.visible:
		return

	var material := _galaxy_effects.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = EFFECTS_SHADER
		_galaxy_effects.material = material

	material.set_shader_parameter("seed", float(seed + 503))
	material.set_shader_parameter("camera_position", _camera_position)
	material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
	material.set_shader_parameter("viewport_size", _canvas_size)
	material.set_shader_parameter("parallax_scale", parallax_strength * GALAXY_EFFECTS_CAMERA_MOTION_RATIO)
	material.set_shader_parameter("intensity", galaxy_effects_intensity)
	material.set_shader_parameter("animation_speed", galaxy_effects_animation_speed)
	material.set_shader_parameter("density", galaxy_effects_density)
	material.set_shader_parameter("cluster_scale", galaxy_effects_cluster_scale)
	material.set_shader_parameter("streak_strength", galaxy_effects_streak_strength)
	material.set_shader_parameter("warm_color", galaxy_effects_warm_color)
	material.set_shader_parameter("cool_color", galaxy_effects_cool_color)
	material.set_shader_parameter("core_color", galaxy_effects_core_color)
	material.set_shader_parameter("detail_steps", int(preset["effect_steps"]))


func _configure_asteroid_belt() -> void:
	var preset := _get_quality_profile()
	var enabled := asteroid_belt_enabled and bool(preset["asteroids_enabled"])
	_asteroid_count = int(round(float(preset["asteroids"]) * asteroid_belt_density)) if enabled else 0
	_asteroid_belt.visible = _asteroid_count > 0
	_build_asteroid_multimesh(_asteroid_belt, _asteroid_count, seed + 101)


func _configure_planet_rim() -> void:
	_planet_rim.visible = planet_enabled
	_planet_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_planet_rim.set_anchors_preset(Control.PRESET_FULL_RECT)

	var material := _planet_rim.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = PLANET_SHADER
		_planet_rim.material = material

	_update_planet_material(material)


func _build_star_multimesh(target: MultiMeshInstance2D, count: int, local_seed: int, min_size: float, max_size: float, alpha_scale: float) -> void:
	var multimesh := MultiMesh.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh.mesh = quad
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	target.visible = count > 0

	if count <= 0:
		multimesh.instance_count = 0
		target.multimesh = multimesh
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = local_seed
	var noise := FastNoiseLite.new()
	noise.seed = local_seed
	noise.frequency = 0.0017
	noise.fractal_octaves = 3

	var palette := _get_galaxy_colors()
	var tile_size := _get_star_tile_size()
	var base_transforms: Array[Transform2D] = []
	var base_colors: Array[Color] = []
	var accepted := 0
	var attempts := 0
	var max_attempts := count * 28
	while accepted < count and attempts < max_attempts:
		attempts += 1
		var position := Vector2(
			rng.randf_range(-tile_size.x * 0.5, tile_size.x * 0.5),
			rng.randf_range(-tile_size.y * 0.5, tile_size.y * 0.5)
		)
		var density := (noise.get_noise_2d(position.x, position.y) + 1.0) * 0.5
		var cluster_weight := 0.12 + pow(density, 2.0) * 0.88
		if rng.randf() > cluster_weight:
			continue

		var rare_index := accepted >= count - mini(rare_bright_star_count, count)
		var size_bias := pow(rng.randf(), 3.2)
		var star_size := lerpf(min_size, max_size, size_bias)
		var alpha := rng.randf_range(0.22, 0.82) * alpha_scale * star_brightness
		if rare_index:
			star_size *= rng.randf_range(1.8, 3.2)
			alpha *= rng.randf_range(1.35, 2.15)

		var transform := Transform2D.IDENTITY
		transform = transform.scaled(Vector2.ONE * star_size)
		transform.origin = position
		base_transforms.append(transform)
		base_colors.append(_pick_star_color(rng, palette, clampf(alpha, 0.0, 2.0)))
		accepted += 1

	var tile_offsets: Array[Vector2] = []
	for tile_y in range(-1, 2):
		for tile_x in range(-1, 2):
			tile_offsets.append(Vector2(float(tile_x) * tile_size.x, float(tile_y) * tile_size.y))

	multimesh.instance_count = accepted * tile_offsets.size()
	var instance_index := 0
	for tile_offset in tile_offsets:
		for base_index in accepted:
			var tiled_transform := base_transforms[base_index]
			tiled_transform.origin += tile_offset
			multimesh.set_instance_transform_2d(instance_index, tiled_transform)
			multimesh.set_instance_color(instance_index, base_colors[base_index])
			instance_index += 1

	target.multimesh = multimesh


func _build_asteroid_multimesh(target: MultiMeshInstance2D, count: int, local_seed: int) -> void:
	var multimesh := MultiMesh.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	multimesh.mesh = quad
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.instance_count = count
	target.multimesh = multimesh

	if count <= 0:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = local_seed
	var angle: float = deg_to_rad(asteroid_belt_angle)
	var along: Vector2 = Vector2(cos(angle), sin(angle))
	var across: Vector2 = Vector2(-along.y, along.x)
	var belt_length: float = _canvas_size.length() * 1.55
	var belt_width: float = _canvas_size.y * 0.16

	for i in count:
		var center_bias: float = rng.randfn(0.0, 0.38)
		var position: Vector2 = along * rng.randf_range(-belt_length, belt_length) + across * center_bias * belt_width
		position += Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
		var radius: float = rng.randf_range(2.0, 11.0) * (1.0 + abs(center_bias) * 0.35)
		var stretch: float = rng.randf_range(0.55, 1.6)
		var local_angle: float = rng.randf_range(-PI, PI)
		var x_axis: Vector2 = Vector2(cos(local_angle), sin(local_angle)) * radius * stretch
		var y_axis: Vector2 = Vector2(-sin(local_angle), cos(local_angle)) * radius * rng.randf_range(0.45, 0.95)
		var transform: Transform2D = Transform2D(x_axis, y_axis, position)
		var alpha: float = clampf(asteroid_belt_opacity * rng.randf_range(0.18, 0.75), 0.0, 1.0)
		var tint: float = rng.randf_range(0.18, 0.42)
		multimesh.set_instance_transform_2d(i, transform)
		multimesh.set_instance_color(i, Color(tint * 0.75, tint * 0.9, tint, alpha))


func _update_layer_offsets() -> void:
	if not is_inside_tree():
		return

	var center := _canvas_size * 0.5
	var star_tile_size := _get_star_tile_size()
	var camera_offset := -_camera_position * parallax_strength
	_far_stars.position = center + _wrapped_offset(camera_offset * FAR_STAR_CAMERA_MOTION_RATIO, star_tile_size)
	_mid_stars.position = center + _wrapped_offset(camera_offset * MID_STAR_CAMERA_MOTION_RATIO, star_tile_size)
	_asteroid_belt.position = center + _wrapped_offset(camera_offset * ASTEROID_CAMERA_MOTION_RATIO)


func _update_dynamic_materials() -> void:
	if not is_inside_tree():
		return

	for i in NEBULA_LAYER_NAMES.size():
		var layer := get_node_or_null("CanvasLayer/%s" % NEBULA_LAYER_NAMES[i]) as ColorRect
		if layer == null or layer.material == null:
			continue

		var material := layer.material as ShaderMaterial
		if material == null:
			continue

		material.set_shader_parameter("camera_position", _camera_position)
		material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
		material.set_shader_parameter("viewport_size", _canvas_size)
		material.set_shader_parameter("animation_enabled", 1.0 if nebula_animation_enabled else 0.0)

	var effects_material := _galaxy_effects.material as ShaderMaterial
	if effects_material != null:
		effects_material.set_shader_parameter("camera_position", _camera_position)
		effects_material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
		effects_material.set_shader_parameter("viewport_size", _canvas_size)

	var planet_material := _planet_rim.material as ShaderMaterial
	if planet_material != null:
		_update_planet_material(planet_material)


func _set_nebula_material_static(material: ShaderMaterial, layer_index: int, active_count: int, preset: Dictionary, palette: Array[Color]) -> void:
	var layer_factor := float(layer_index) / maxf(float(active_count - 1), 1.0)
	material.set_shader_parameter("seed", float(seed + layer_index * 97))
	material.set_shader_parameter("layer_index", float(layer_index))
	material.set_shader_parameter("camera_position", _camera_position)
	material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
	material.set_shader_parameter("viewport_size", _canvas_size)
	material.set_shader_parameter(
		"parallax_scale",
		parallax_strength * lerpf(NEBULA_MIN_CAMERA_MOTION_RATIO, NEBULA_MAX_CAMERA_MOTION_RATIO, layer_factor)
	)
	material.set_shader_parameter("noise_scale", lerpf(1.35, 3.2, layer_factor))
	material.set_shader_parameter("distortion", lerpf(0.2, float(preset["nebula_distortion"]), layer_factor))
	material.set_shader_parameter("opacity", nebula_intensity * lerpf(0.24, 0.42, layer_factor))
	material.set_shader_parameter("color_a", palette[0])
	material.set_shader_parameter("color_b", palette[1])
	material.set_shader_parameter("color_c", palette[2])
	material.set_shader_parameter("glow_strength", lerpf(0.12, 0.34, layer_factor) * nebula_intensity)
	material.set_shader_parameter("edge_softness", lerpf(0.16, 0.34, layer_factor))
	material.set_shader_parameter("animation_speed", nebula_animation_speed * lerpf(0.55, 1.35, layer_factor))
	material.set_shader_parameter("animation_enabled", 1.0 if nebula_animation_enabled else 0.0)
	material.set_shader_parameter("octave_count", int(preset["nebula_octaves"]))


func _update_planet_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter("viewport_size", _canvas_size)
	material.set_shader_parameter("edge_position", planet_edge_position)
	material.set_shader_parameter("radius", planet_radius)
	material.set_shader_parameter("planet_color", planet_color)
	material.set_shader_parameter("atmosphere_color", atmosphere_color)
	material.set_shader_parameter("brightness", planet_brightness)


func _update_debug_stats() -> void:
	_debug_stats.visible = debug_stats_enabled
	_debug_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_stats.text = get_stats_text()
	_debug_stats.position = Vector2(18.0, 132.0)
	_debug_stats.add_theme_font_size_override("font_size", 13)
	_debug_stats.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0, 0.92))


func _create_star_material(twinkle_strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = STAR_SHADER
	material.set_shader_parameter("twinkle_strength", twinkle_strength if nebula_animation_enabled else 0.0)
	return material


func _create_asteroid_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ASTEROID_SHADER
	return material


func _pick_star_color(rng: RandomNumberGenerator, palette: Array[Color], alpha: float) -> Color:
	var white := Color(0.92, 0.97, 1.0, alpha)
	var tint_source := palette[rng.randi_range(1, 2)]
	var tint := Color(tint_source.r, tint_source.g, tint_source.b, alpha)
	return white.lerp(tint, rng.randf() * star_color_variation)


func _wrapped_offset(offset: Vector2, wrap_size: Vector2 = Vector2.ZERO) -> Vector2:
	var wrap := wrap_size if wrap_size != Vector2.ZERO else _canvas_size
	return Vector2(wrapf(offset.x, -wrap.x * 0.5, wrap.x * 0.5), wrapf(offset.y, -wrap.y * 0.5, wrap.y * 0.5))


func _get_star_tile_size() -> Vector2:
	return _canvas_size * STAR_TILE_SCALE


func _resolve_canvas_size() -> Vector2:
	if not is_inside_tree() or get_viewport() == null:
		return DEFAULT_VIEWPORT_SIZE

	var size := get_viewport_rect().size
	if size.x <= 1.0 or size.y <= 1.0:
		return DEFAULT_VIEWPORT_SIZE
	return size


func _get_quality_profile() -> Dictionary:
	match quality_preset:
		QUALITY_LOW:
			return {
				"far_stars": 620,
				"mid_stars": 140,
				"nebula_layers": 1,
				"nebula_octaves": 2,
				"nebula_distortion": 0.18,
				"asteroids_enabled": false,
				"asteroids": 0,
				"effects_enabled": false,
				"effect_steps": 1,
			}
		QUALITY_MEDIUM:
			return {
				"far_stars": 1250,
				"mid_stars": 320,
				"nebula_layers": 2,
				"nebula_octaves": 3,
				"nebula_distortion": 0.34,
				"asteroids_enabled": asteroid_belt_enabled,
				"asteroids": 80,
				"effects_enabled": galaxy_effects_enabled,
				"effect_steps": 2,
			}
		QUALITY_ULTRA:
			return {
				"far_stars": 3500,
				"mid_stars": 920,
				"nebula_layers": 4,
				"nebula_octaves": 4,
				"nebula_distortion": 0.68,
				"asteroids_enabled": asteroid_belt_enabled,
				"asteroids": 190,
				"effects_enabled": galaxy_effects_enabled,
				"effect_steps": 4,
			}
		_:
			return {
				"far_stars": 2200,
				"mid_stars": 580,
				"nebula_layers": 3,
				"nebula_octaves": 4,
				"nebula_distortion": 0.52,
				"asteroids_enabled": asteroid_belt_enabled,
				"asteroids": 130,
				"effects_enabled": galaxy_effects_enabled,
				"effect_steps": 3,
			}


func _get_palette_colors() -> Array[Color]:
	match nebula_color_palette:
		PALETTE_BLUE_VOID:
			return [Color(0.004, 0.009, 0.026, 1.0), Color(0.05, 0.18, 0.46, 1.0), Color(0.28, 0.76, 1.0, 1.0)]
		PALETTE_PURPLE_RIFT:
			return [Color(0.012, 0.006, 0.028, 1.0), Color(0.2, 0.08, 0.42, 1.0), Color(0.77, 0.38, 1.0, 1.0)]
		PALETTE_GREEN_ION_CLOUD:
			return [Color(0.002, 0.018, 0.014, 1.0), Color(0.05, 0.36, 0.25, 1.0), Color(0.45, 1.0, 0.62, 1.0)]
		PALETTE_RED_DANGER_SECTOR:
			return [Color(0.026, 0.004, 0.006, 1.0), Color(0.46, 0.08, 0.06, 1.0), Color(1.0, 0.34, 0.18, 1.0)]
		PALETTE_GOLDEN_ANCIENT_SECTOR:
			return [Color(0.025, 0.015, 0.004, 1.0), Color(0.52, 0.31, 0.08, 1.0), Color(1.0, 0.76, 0.28, 1.0)]
		_:
			return [Color(0.002, 0.014, 0.022, 1.0), Color(0.02, 0.32, 0.39, 1.0), Color(0.35, 1.0, 0.88, 1.0)]


func _get_galaxy_colors() -> Array[Color]:
	if use_palette_colors:
		return _get_palette_colors()

	return [
		galaxy_background_color,
		galaxy_nebula_mid_color,
		galaxy_nebula_glow_color,
	]


func _get_quality_name() -> String:
	match quality_preset:
		QUALITY_LOW:
			return "Low"
		QUALITY_MEDIUM:
			return "Medium"
		QUALITY_ULTRA:
			return "Ultra"
		_:
			return "High"


func _get_approx_draw_calls() -> int:
	var draws := 0
	draws += 1 if _star_counts[0] > 0 else 0
	draws += 1 if _star_counts[1] > 0 else 0
	draws += _nebula_layers_active
	draws += 1 if _are_galaxy_effects_active() else 0
	draws += 1 if _asteroid_count > 0 else 0
	draws += 1 if planet_enabled else 0
	return draws


func _are_galaxy_effects_active() -> bool:
	var preset := _get_quality_profile()
	return galaxy_effects_enabled and bool(preset["effects_enabled"]) and galaxy_effects_intensity > 0.0


func _build_settings_signature() -> int:
	return hash([
		seed,
		quality_preset,
		star_density,
		star_brightness,
		star_color_variation,
		rare_bright_star_count,
		use_palette_colors,
		galaxy_background_color,
		galaxy_nebula_mid_color,
		galaxy_nebula_glow_color,
		nebula_enabled,
		nebula_intensity,
		nebula_animation_enabled,
		nebula_animation_speed,
		nebula_color_palette,
		nebula_layer_count,
		galaxy_effects_enabled,
		galaxy_effects_intensity,
		galaxy_effects_animation_speed,
		galaxy_effects_density,
		galaxy_effects_cluster_scale,
		galaxy_effects_streak_strength,
		galaxy_effects_warm_color,
		galaxy_effects_cool_color,
		galaxy_effects_core_color,
		parallax_strength,
		asteroid_belt_enabled,
		asteroid_belt_density,
		asteroid_belt_angle,
		asteroid_belt_opacity,
		planet_enabled,
		planet_edge_position,
		planet_radius,
		planet_color,
		atmosphere_color,
		planet_brightness,
		debug_stats_enabled,
	])

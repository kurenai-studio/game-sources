class_name Planet
extends Node2D

const DEFAULT_VISUAL_PIXEL_SIZE: float = 180.0
const COLONIZATION_SCAN_SHADER: Shader = preload("res://galaxy_entities/planets/planet_colonization_scan.gdshader")
const SAFE_ZONE_REVEAL_ADVANCE_SECONDS: float = 0.5
const VISUAL_SURFACE_ATTACHMENT_SCROLL_SCALE: float = 0.04


static func visual_get_multiplier(mat) -> float:
	return (round(mat.get_shader_parameter("size")) * 2.0) / mat.get_shader_parameter("time_speed")


static func visual_get_colors_from_shader(mat, uniform_name := "colors"):
	return mat.get_shader_parameter(uniform_name)


static func visual_set_colors_on_shader(mat, colors, uniform_name := "colors") -> void:
	mat.set_shader_parameter(uniform_name, colors)


static func visual_generate_new_colorscheme(n_colors: int, hue_diff := 0.9, saturation := 0.5) -> PackedColorArray:
	var a := Vector3(0.5, 0.5, 0.5)
	var b := Vector3(0.5, 0.5, 0.5) * saturation
	var c := Vector3(randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5)) * hue_diff
	var d := Vector3(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0)) * randf_range(1.0, 3.0)

	var cols := PackedColorArray()
	var n := maxf(1.0, float(n_colors - 1.0))
	for i in range(0, n_colors, 1):
		var vec3 := Vector3()
		var color_index := float(i) / n
		vec3.x = a.x + b.x * cos(6.28318 * (c.x * color_index + d.x))
		vec3.y = a.y + b.y * cos(6.28318 * (c.y * color_index + d.y))
		vec3.z = a.z + b.z * cos(6.28318 * (c.z * color_index + d.z))
		cols.append(Color(vec3.x, vec3.y, vec3.z))

	return cols


static func visual_get_layers(visual: Node) -> Array:
	var layers := []
	for child in visual.get_children():
		var canvas_item := child as CanvasItem
		layers.append({"name": child.get_name(), "visible": canvas_item == null or canvas_item.visible})
	return layers


static func visual_toggle_layer(visual: Node, num: int) -> void:
	var canvas_item := visual.get_children()[num] as CanvasItem
	if canvas_item != null:
		canvas_item.visible = not canvas_item.visible


signal conquered_changed(is_conquered: bool)

@export var network_id: int = 0
@export_range(32.0, 8192.0, 1.0) var visual_pixel_size: float = DEFAULT_VISUAL_PIXEL_SIZE:
	get:
		return _visual_pixel_size
	set(value):
		_visual_pixel_size = maxf(value, 1.0)
		_refresh_visuals()

@export var animate_visual_layers: bool = true:
	get:
		return _animate_visual_layers
	set(value):
		_animate_visual_layers = value
		_visual_configuration_key = ""
		_refresh_visuals()

@export_file("*.tscn") var visual_scene_path: String = "":
	get:
		return _visual_scene_path
	set(value):
		_visual_scene_path = value
		_rebuild_visual_scene()
		_refresh_visuals()

@export var seed: int = 0:
	get:
		return _seed
	set(value):
		_seed = value
		_refresh_visuals()

@export_range(0.05, 100.0, 0.01) var planet_scale: float = 1.0:
	get:
		return _planet_scale
	set(value):
		_planet_scale = value
		_refresh_visuals()

@export_range(0.0, 0.5, 0.001) var size_jitter: float = 0.08:
	get:
		return _size_jitter
	set(value):
		_size_jitter = value
		_refresh_visuals()

@export_range(0.0, 0.5, 0.001) var rotation_jitter: float = 0.14:
	get:
		return _rotation_jitter
	set(value):
		_rotation_jitter = value
		_refresh_visuals()

@export_range(-2.0, 2.0, 0.001) var visual_rotation_speed: float = 0.55:
	get:
		return _visual_rotation_speed
	set(value):
		_visual_rotation_speed = value

@export_range(0.0, 6.283185307179586, 0.001) var visual_rotation_phase: float = 0.0:
	get:
		return _visual_rotation_phase
	set(value):
		_visual_rotation_phase = fposmod(value, TAU)

@export_range(0.0, 0.25, 0.001) var brightness_jitter: float = 0.04:
	get:
		return _brightness_jitter
	set(value):
		_brightness_jitter = value
		_refresh_visuals()

@export_range(1.0, 10.0, 0.1) var conquered_zone_scale: float = 3.0:
	get:
		return _conquered_zone_scale
	set(value):
		_conquered_zone_scale = maxf(value, 1.0)
		_refresh_visuals()

@export_range(64.0, 50000.0, 1.0) var visibility_radius: float = 900.0
@export var colonization_glow_color: Color = Color(0.24, 1.0, 0.42, 0.9)
@export_range(0.02, 0.35, 0.01) var colonization_flash_in_duration: float = 0.14
@export_range(0.08, 1.2, 0.01) var colonization_flash_out_duration: float = 0.72
@export_range(0.2, 1.2, 0.01) var colonization_safe_zone_delay: float = 0.44
@export_range(1.0, 4.0, 0.01) var colonization_glow_radius_scale: float = 2.28
@export_range(0.1, 1.2, 0.01) var colonization_scan_duration: float = 0.92

@onready var planet_visual: Node2D = $PlanetVisual
@onready var planet_safe_zone: PlanetSafeZone = $PlanetSafeZone

var _visual_scene_path: String = ""
var _visual_instance: Node
var _visual_instance_path: String = ""
var _colonization_scan_overlay: Sprite2D
var _colonization_scan_material: ShaderMaterial
var _colonization_scan_texture: ImageTexture
var _visual_touch_radius: float = 0.0
var _visual_pixel_size: float = DEFAULT_VISUAL_PIXEL_SIZE
var _visual_time: float = 1000.0
var _animate_visual_layers: bool = true
var _visual_configuration_key: String = ""
var _seed: int = 0
var _planet_scale: float = 1.0
var _size_jitter: float = 0.08
var _rotation_jitter: float = 0.14
var _visual_rotation_speed: float = 0.55
var _visual_rotation_phase: float = 0.0
var _brightness_jitter: float = 0.04
var _conquered_zone_scale: float = 3.0
var _is_conquered: bool = false
var _fog_presentation_alpha: float = 1.0
var _colonization_flash_alpha: float = 0.0
var _colonization_wave_alpha: float = 0.0
var _colonization_wave_progress: float = 0.0
var _colonization_echo_alpha: float = 0.0
var _colonization_echo_progress: float = 0.0
var _colonization_scan_alpha: float = 0.0
var _colonization_scan_progress: float = 0.0
var _colonization_scan_time: float = 0.0
var _colonization_effect_tweens: Array[Tween] = []


func _ready() -> void:
	_rebuild_visual_scene()
	_refresh_visuals()


func _process(delta: float) -> void:
	_process_visual_time(delta)
	_process_colonization_scan_time(delta)


func _draw() -> void:
	if _colonization_flash_alpha <= 0.001 and _colonization_wave_alpha <= 0.001 and _colonization_echo_alpha <= 0.001:
		return

	var touch_radius := get_touch_radius()
	if touch_radius <= 0.0:
		return

	var glow_color := colonization_glow_color
	var flash_alpha := _colonization_flash_alpha * _fog_presentation_alpha
	if flash_alpha > 0.001:
		draw_circle(
			Vector2.ZERO,
			touch_radius * colonization_glow_radius_scale,
			Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * flash_alpha * 0.2)
		)
		draw_circle(
			Vector2.ZERO,
			touch_radius * 1.22,
			Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * flash_alpha * 0.36)
		)

	_draw_colonization_wave(touch_radius, _colonization_wave_progress, _colonization_wave_alpha)
	_draw_colonization_wave(touch_radius, _colonization_echo_progress, _colonization_echo_alpha, 0.58)


func is_conquered() -> bool:
	return _is_conquered


func set_conquered(value: bool) -> void:
	if _is_conquered == value:
		return

	var was_conquered := _is_conquered
	_is_conquered = value
	_refresh_visuals()
	if planet_safe_zone != null:
		if _is_conquered and not was_conquered:
			var safe_zone_delay := maxf(
				colonization_scan_duration + colonization_safe_zone_delay - SAFE_ZONE_REVEAL_ADVANCE_SECONDS,
				0.0
			)
			planet_safe_zone.reveal(safe_zone_delay)
			_play_colonization_effect()
		elif not _is_conquered:
			planet_safe_zone.conceal()
			_stop_colonization_effect()
	conquered_changed.emit(_is_conquered)


func apply_network_state(state: Dictionary) -> void:
	network_id = int(state.get("network_id", network_id))
	position = state.get("position", position) as Vector2
	seed = int(state.get("seed", seed))
	visual_scene_path = str(state.get("visual_scene_path", visual_scene_path))
	planet_scale = float(state.get("planet_scale", planet_scale))
	rotation_jitter = float(state.get("rotation_jitter", rotation_jitter))
	visual_rotation_speed = float(state.get("visual_rotation_speed", visual_rotation_speed))
	visual_rotation_phase = float(state.get("visual_rotation_phase", visual_rotation_phase))
	size_jitter = float(state.get("size_jitter", size_jitter))
	brightness_jitter = float(state.get("brightness_jitter", brightness_jitter))
	z_index = int(state.get("z_index", z_index))


func to_network_state() -> Dictionary:
	return {
		"network_id": network_id,
		"position": position,
		"seed": seed,
		"visual_scene_path": visual_scene_path,
		"planet_scale": planet_scale,
		"rotation_jitter": rotation_jitter,
		"visual_rotation_speed": visual_rotation_speed,
		"visual_rotation_phase": visual_rotation_phase,
		"size_jitter": size_jitter,
		"brightness_jitter": brightness_jitter,
		"z_index": z_index,
	}


func get_visibility_radius() -> float:
	var safe_zone_radius := 0.0
	if planet_safe_zone != null:
		safe_zone_radius = planet_safe_zone.radius

	return maxf(maxf(visibility_radius, get_touch_radius()), safe_zone_radius)


func get_touch_radius() -> float:
	return maxf(_visual_touch_radius, 0.0)


func get_visual_rotation_time() -> float:
	return _visual_rotation_phase + _visual_time * _visual_rotation_speed


func get_visual_surface_scroll_offset(anchor_visual_rotation_time: float) -> Vector2:
	if not _animate_visual_layers:
		return Vector2.ZERO

	var visual_diameter := maxf(get_touch_radius() * 2.0, 1.0)
	var visual_time_delta := get_visual_rotation_time() - anchor_visual_rotation_time
	return Vector2(-visual_time_delta * visual_diameter * VISUAL_SURFACE_ATTACHMENT_SCROLL_SCALE, 0.0)


func set_fog_presentation_alpha(alpha: float) -> void:
	var next_alpha := clampf(alpha, 0.0, 1.0)
	if is_equal_approx(_fog_presentation_alpha, next_alpha):
		return

	_fog_presentation_alpha = next_alpha
	visible = _fog_presentation_alpha > 0.01
	_refresh_visuals()


func _refresh_visuals() -> void:
	_refresh_custom_visuals()
	_refresh_safe_zone_visuals()


func _rebuild_visual_scene() -> void:
	if _visual_instance_path == _visual_scene_path:
		return

	_clear_visual_scene()
	_visual_instance_path = _visual_scene_path
	_visual_touch_radius = 0.0
	_visual_time = 0.0
	_visual_configuration_key = ""

	if _visual_scene_path.is_empty():
		return

	if not ResourceLoader.exists(_visual_scene_path):
		push_warning("Could not find planet visual scene: %s" % _visual_scene_path)
		return

	var visual_scene := load(_visual_scene_path) as PackedScene
	if visual_scene == null:
		push_warning("Could not load planet visual scene: %s" % _visual_scene_path)
		return

	_visual_instance = visual_scene.instantiate()
	if _visual_instance == null:
		return

	_visual_instance.name = "PlanetVisual"
	_get_visual_parent().add_child(_visual_instance)
	_disable_visual_mouse_input(_visual_instance)


func _clear_visual_scene() -> void:
	if _visual_instance == null:
		return

	if is_instance_valid(_visual_instance):
		_visual_instance.queue_free()
	_visual_instance = null
	_visual_configuration_key = ""


func _refresh_custom_visuals() -> bool:
	if _visual_scene_path.is_empty():
		return false

	if _visual_instance == null or not is_instance_valid(_visual_instance):
		_rebuild_visual_scene()
	if _visual_instance == null:
		return false

	_ensure_colonization_scan_overlay()

	var rng := RandomNumberGenerator.new()
	rng.seed = _resolve_seed()
	var scale_factor := maxf(0.05, _planet_scale * (1.0 + rng.randf_range(-_size_jitter, _size_jitter)))
	var pixel_size := maxf(8.0, _visual_pixel_size * scale_factor)
	_visual_touch_radius = pixel_size * 0.5

	var rotation := 0.0
	var configuration_key := "%s|%d|%.3f|%.3f|%.3f|%s" % [
		_visual_scene_path,
		_resolve_seed(),
		pixel_size,
		rotation,
		_visual_pixel_size,
		str(_animate_visual_layers),
	]
	if configuration_key != _visual_configuration_key:
		_visual_configuration_key = configuration_key
		if _visual_instance.has_method("set_pixels"):
			_visual_instance.call("set_pixels", pixel_size)
		if _visual_instance.has_method("set_seed"):
			_visual_instance.call("set_seed", _resolve_seed())
		if _visual_instance.has_method("set_rotates"):
			_visual_instance.call("set_rotates", rotation)
		if _visual_instance.has_method("set_light"):
			_visual_instance.call("set_light", Vector2(0.39, 0.39))
		_configure_visual_layer_animation(_visual_instance)

	var brightness := 1.0 + rng.randf_range(-_brightness_jitter, _brightness_jitter)
	var base_color := Color(brightness, brightness, brightness, 1.0)
	if _is_conquered:
		base_color = base_color.lerp(Color(0.72, 1.0, 0.72, 1.0), 0.35)
	if _colonization_flash_alpha > 0.0:
		base_color = base_color.lerp(Color(0.58, 1.0, 0.52, 1.0), minf(_colonization_flash_alpha * 0.72, 0.72))
	base_color.a *= _fog_presentation_alpha

	_configure_visual_canvas_item(_visual_instance, pixel_size, base_color)
	_configure_colonization_scan_overlay(pixel_size)
	return true


func _configure_visual_canvas_item(visual: Node, pixel_size: float, visual_modulate: Color) -> void:
	var visual_canvas_item := visual as CanvasItem
	if visual_canvas_item != null:
		visual_canvas_item.visible = true
		visual_canvas_item.modulate = visual_modulate
		visual_canvas_item.z_index = 0

	var visual_control := visual as Control
	if visual_control != null:
		var visual_size := Vector2(pixel_size, pixel_size)
		visual_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual_control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		visual_control.position = -visual_size * 0.5
		visual_control.size = visual_size
		visual_control.custom_minimum_size = visual_size
		visual_control.pivot_offset = visual_size * 0.5
		visual_control.scale = Vector2.ONE
		return

	var visual_node_2d := visual as Node2D
	if visual_node_2d != null:
		visual_node_2d.position = -Vector2(pixel_size, pixel_size) * 0.5
		visual_node_2d.scale = Vector2.ONE


func _ensure_colonization_scan_overlay() -> void:
	if _colonization_scan_overlay != null and is_instance_valid(_colonization_scan_overlay):
		return

	_ensure_colonization_scan_texture()
	_colonization_scan_material = ShaderMaterial.new()
	_colonization_scan_material.shader = COLONIZATION_SCAN_SHADER
	_colonization_scan_material.set_shader_parameter("grid_color", colonization_glow_color)
	_colonization_scan_material.set_shader_parameter("progress", _colonization_scan_progress)
	_colonization_scan_material.set_shader_parameter("alpha", _colonization_scan_alpha)
	_colonization_scan_material.set_shader_parameter("time", _colonization_scan_time)

	_colonization_scan_overlay = Sprite2D.new()
	_colonization_scan_overlay.name = "ColonizationScanOverlay"
	_colonization_scan_overlay.centered = true
	_colonization_scan_overlay.texture = _colonization_scan_texture
	_colonization_scan_overlay.material = _colonization_scan_material
	_colonization_scan_overlay.z_index = 6
	_colonization_scan_overlay.visible = false
	_get_visual_parent().add_child(_colonization_scan_overlay)


func _ensure_colonization_scan_texture() -> void:
	if _colonization_scan_texture != null:
		return

	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_colonization_scan_texture = ImageTexture.create_from_image(image)


func _configure_colonization_scan_overlay(pixel_size: float) -> void:
	if _colonization_scan_overlay == null or not is_instance_valid(_colonization_scan_overlay):
		return

	_colonization_scan_overlay.position = Vector2.ZERO
	_colonization_scan_overlay.scale = Vector2.ONE * pixel_size
	_colonization_scan_overlay.visible = _colonization_scan_alpha > 0.001
	_sync_colonization_scan_material()


func _sync_colonization_scan_material() -> void:
	if _colonization_scan_material == null:
		return

	_colonization_scan_material.set_shader_parameter("grid_color", colonization_glow_color)
	_colonization_scan_material.set_shader_parameter("progress", _colonization_scan_progress)
	_colonization_scan_material.set_shader_parameter("alpha", _colonization_scan_alpha * _fog_presentation_alpha)
	_colonization_scan_material.set_shader_parameter("time", _colonization_scan_time)


func _disable_visual_mouse_input(node: Node) -> void:
	var control := node as Control
	if control != null:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)

	for child in node.get_children():
		_disable_visual_mouse_input(child)


func _configure_visual_layer_animation(visual: Node) -> void:
	if not _animate_visual_layers and visual.has_method("set_custom_time"):
		visual.call("set_custom_time", float(abs(_resolve_seed()) % 1000) / 1000.0)

	for child in visual.get_children():
		_configure_visual_layer_animation(child)


func _process_visual_time(delta: float) -> void:
	if not _animate_visual_layers:
		return
	if _visual_instance == null or not is_instance_valid(_visual_instance):
		return
	if not _visual_instance.has_method("update_time"):
		return

	_visual_time += delta
	_visual_instance.call("update_time", _visual_rotation_phase + _visual_time * _visual_rotation_speed)


func _process_colonization_scan_time(delta: float) -> void:
	if _colonization_scan_alpha <= 0.001:
		return

	_colonization_scan_time += delta
	_sync_colonization_scan_material()


func _refresh_safe_zone_visuals() -> void:
	if planet_safe_zone == null:
		return

	if not _is_conquered:
		planet_safe_zone.conceal()
		return

	var touch_radius := get_touch_radius()
	if touch_radius <= 0.0:
		planet_safe_zone.conceal()
		return

	planet_safe_zone.radius = touch_radius * _conquered_zone_scale
	planet_safe_zone.fill_color = Color(0.18, 1.0, 0.36, 0.12)


func _draw_colonization_wave(touch_radius: float, progress: float, alpha: float, width_scale: float = 1.0) -> void:
	var wave_alpha := clampf(alpha, 0.0, 1.0) * _fog_presentation_alpha
	if wave_alpha <= 0.001:
		return

	var eased_progress := 1.0 - pow(1.0 - clampf(progress, 0.0, 1.0), 2.6)
	var radius := touch_radius * lerpf(0.72, colonization_glow_radius_scale, eased_progress)
	var line_width := maxf(touch_radius * 0.075 * width_scale * (1.0 - eased_progress * 0.46), 2.0)
	var glow_color := colonization_glow_color
	var hot_color := Color(0.84, 1.0, 0.72, 1.0)
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		96,
		Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * wave_alpha * 0.62),
		line_width * 2.1,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		96,
		Color(hot_color.r, hot_color.g, hot_color.b, hot_color.a * wave_alpha * 0.92),
		line_width,
		true
	)


func _play_colonization_effect() -> void:
	_stop_colonization_effect()
	_colonization_flash_alpha = 0.0
	_colonization_wave_alpha = 0.0
	_colonization_wave_progress = 0.0
	_colonization_echo_alpha = 0.0
	_colonization_echo_progress = 0.0
	_colonization_scan_alpha = 0.0
	_colonization_scan_progress = 0.0
	_colonization_scan_time = 0.0
	_ensure_colonization_scan_overlay()
	_sync_colonization_scan_material()
	queue_redraw()

	var scan_alpha_tween := create_tween()
	_colonization_effect_tweens.append(scan_alpha_tween)
	scan_alpha_tween.tween_method(_set_colonization_scan_alpha, 0.0, 1.0, colonization_scan_duration * 0.18)
	scan_alpha_tween.tween_interval(colonization_scan_duration * 0.58)
	scan_alpha_tween.tween_method(_set_colonization_scan_alpha, 1.0, 0.0, colonization_scan_duration * 0.24)

	var scan_progress_tween := create_tween()
	_colonization_effect_tweens.append(scan_progress_tween)
	scan_progress_tween.tween_method(
		_set_colonization_scan_progress,
		0.0,
		1.0,
		colonization_scan_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var flash_tween := create_tween()
	_colonization_effect_tweens.append(flash_tween)
	flash_tween.tween_method(_set_colonization_flash_alpha, 0.0, 1.0, colonization_flash_in_duration)
	flash_tween.tween_method(_set_colonization_flash_alpha, 1.0, 0.0, colonization_flash_out_duration)

	var wave_alpha_tween := create_tween()
	_colonization_effect_tweens.append(wave_alpha_tween)
	wave_alpha_tween.tween_method(_set_colonization_wave_alpha, 0.0, 1.0, colonization_flash_in_duration)
	wave_alpha_tween.tween_method(_set_colonization_wave_alpha, 1.0, 0.0, colonization_flash_out_duration * 1.05)

	var wave_progress_tween := create_tween()
	_colonization_effect_tweens.append(wave_progress_tween)
	wave_progress_tween.tween_method(
		_set_colonization_wave_progress,
		0.0,
		1.0,
		colonization_flash_in_duration + colonization_flash_out_duration * 1.05
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	var echo_alpha_tween := create_tween()
	_colonization_effect_tweens.append(echo_alpha_tween)
	echo_alpha_tween.tween_interval(colonization_flash_in_duration * 1.6)
	echo_alpha_tween.tween_method(_set_colonization_echo_alpha, 0.78, 0.0, colonization_flash_out_duration * 0.95)

	var echo_progress_tween := create_tween()
	_colonization_effect_tweens.append(echo_progress_tween)
	echo_progress_tween.tween_interval(colonization_flash_in_duration * 1.6)
	echo_progress_tween.tween_method(
		_set_colonization_echo_progress,
		0.0,
		1.0,
		colonization_flash_out_duration * 0.95
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _stop_colonization_effect() -> void:
	for effect_tween in _colonization_effect_tweens:
		if effect_tween != null and effect_tween.is_running():
			effect_tween.kill()

	_colonization_effect_tweens.clear()
	_set_colonization_flash_alpha(0.0)
	_set_colonization_wave_alpha(0.0)
	_set_colonization_wave_progress(0.0)
	_set_colonization_echo_alpha(0.0)
	_set_colonization_echo_progress(0.0)
	_set_colonization_scan_alpha(0.0)
	_set_colonization_scan_progress(0.0)


func _set_colonization_flash_alpha(alpha: float) -> void:
	_colonization_flash_alpha = clampf(alpha, 0.0, 1.0)
	_refresh_custom_visuals()
	queue_redraw()


func _set_colonization_wave_alpha(alpha: float) -> void:
	_colonization_wave_alpha = clampf(alpha, 0.0, 1.0)
	queue_redraw()


func _set_colonization_wave_progress(progress: float) -> void:
	_colonization_wave_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func _set_colonization_echo_alpha(alpha: float) -> void:
	_colonization_echo_alpha = clampf(alpha, 0.0, 1.0)
	queue_redraw()


func _set_colonization_echo_progress(progress: float) -> void:
	_colonization_echo_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func _set_colonization_scan_alpha(alpha: float) -> void:
	_colonization_scan_alpha = clampf(alpha, 0.0, 1.0)
	if _colonization_scan_overlay != null and is_instance_valid(_colonization_scan_overlay):
		_colonization_scan_overlay.visible = _colonization_scan_alpha > 0.001
	_sync_colonization_scan_material()


func _set_colonization_scan_progress(progress: float) -> void:
	_colonization_scan_progress = clampf(progress, 0.0, 1.0)
	_sync_colonization_scan_material()


func _get_visual_parent() -> Node:
	if planet_visual != null:
		return planet_visual

	var visual_parent := get_node_or_null("PlanetVisual")
	if visual_parent != null:
		return visual_parent

	return self


func _resolve_seed() -> int:
	if _seed != 0:
		return _seed

	var path_seed := hash(str(get_path()))
	if path_seed != 0:
		return path_seed

	return hash(name)

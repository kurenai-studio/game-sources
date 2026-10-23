@tool
extends Node2D

const SHADER_RECT_PATH: NodePath = ^"CanvasLayer/ShaderRect"

@export_group("Zoom Response")
@export_range(0.1, 4.0, 0.05) var reference_zoom: float = 1.0
@export_range(0.0, 1.0, 0.01) var zoomed_out_parallax_strength: float = 0.35

@export_group("Far Stars")
@export var far_stars_enabled: bool = true
@export_range(0.01, 1.0, 0.01) var far_scroll_scale: float = 0.1
@export_range(8.0, 256.0, 1.0) var far_cell_size: float = 38.0
@export_range(0.05, 4.0, 0.05) var far_star_min_size: float = 0.15
@export_range(0.05, 4.0, 0.05) var far_star_max_size: float = 0.55
@export_range(0.0, 1.0, 0.01) var far_zoom_size_influence: float = 0.3

@export_group("Mid Stars")
@export var mid_stars_enabled: bool = true
@export_range(8.0, 512.0, 1.0) var mid_cell_size: float = 86.0
@export_range(0.01, 1.0, 0.01) var mid_scroll_scale: float = 0.3
@export_range(0.05, 4.0, 0.05) var mid_star_min_size: float = 0.35
@export_range(0.05, 4.0, 0.05) var mid_star_max_size: float = 0.9
@export_range(0.0, 1.0, 0.01) var mid_zoom_size_influence: float = 0.45

@export_group("Near Stars")
@export var near_stars_enabled: bool = true
@export_range(8.0, 1024.0, 1.0) var near_cell_size: float = 220.0
@export_range(0.01, 1.0, 0.01) var near_scroll_scale: float = 1.0
@export_range(0.05, 4.0, 0.05) var near_star_min_size: float = 0.7
@export_range(0.05, 4.0, 0.05) var near_star_max_size: float = 1.55
@export_range(0.0, 1.0, 0.01) var near_zoom_size_influence: float = 0.65

@export_group("Nebula")
@export var nebula_enabled: bool = true
@export var nebula_animated: bool = true
@export_range(0.0, 4.0, 0.01) var nebula_animation_speed: float = 0.18
@export_range(0.0, 4.0, 0.01) var nebula_scroll_scale: float = 0.08
@export_range(0.1, 8.0, 0.05) var nebula_scale: float = 2.25
@export_range(0.1, 8.0, 0.05) var nebula_detail_scale: float = 5.2
@export_range(0.0, 8.0, 0.01) var nebula_warp_strength: float = 0.62
@export_range(0.0, 8.0, 0.01) var nebula_detail_strength: float = 0.9
@export_range(0.0, 8.0, 0.01) var nebula_density: float = 0.82
@export_range(0.0, 2.0, 0.01) var nebula_cutoff: float = 0.3
@export_range(0.0, 2.0, 0.01) var nebula_softness: float = 0.32
@export_range(0.0, 2.0, 0.01) var nebula_opacity: float = 0.72
@export_range(0.0, 2.0, 0.01) var nebula_saturation: float = 1.0
@export_range(0.0, 2.0, 0.01) var nebula_brightness: float = 0.82
@export_range(0.0, 2.0, 0.01) var nebula_shadow_strength: float = 1.1
@export_range(0.0, 2.0, 0.01) var nebula_glow_strength: float = 0.34
@export_range(0.0, 2.0, 0.01) var nebula_twist: float = 0.9
@export_range(0.0, 2.0, 0.01) var nebula_flow: float = 0.08
@export_range(0.0, 2.0, 0.01) var nebula_pulse_speed: float = 0.22
@export_range(0.0, 2.0, 0.01) var nebula_pulse_amount: float = 0.08
@export_range(0.0, 2.0, 0.01) var nebula_vignette_strength: float = 0.15
@export var nebula_offset: Vector2 = Vector2.ZERO
@export var nebula_background_color: Color = Color(0.07450980392156863, 0.08235294117647059, 0.10980392156862745, 1.0)
@export var nebula_dark_color: Color = Color(0.005, 0.006, 0.014, 1.0)
@export var nebula_primary_color: Color = Color(0.31, 0.14, 0.56, 1.0)
@export var nebula_secondary_color: Color = Color(0.12, 0.24, 0.64, 1.0)
@export var nebula_accent_color: Color = Color(0.06, 0.05, 0.14, 1.0)
@export var nebula_halo_color: Color = Color(0.48, 0.34, 0.94, 1.0)
@export_range(0.0, 1.0, 0.01) var nebula_halo_strength: float = 0.26

var _camera_position: Vector2 = Vector2.ZERO
var _camera_zoom: Vector2 = Vector2.ONE
var _nebula_time: float = 0.0


func _ready() -> void:
	set_process(true)
	_update_shader()


func _process(delta: float) -> void:
	if nebula_enabled and nebula_animated:
		_nebula_time += delta

	if Engine.is_editor_hint():
		_update_shader()
		return

	_update_dynamic_shader_parameters()


func sync_to_camera(camera_position: Vector2, camera_zoom: Vector2 = Vector2.ONE) -> void:
	if _camera_position == camera_position and _camera_zoom == camera_zoom:
		return

	_camera_position = camera_position
	_camera_zoom = camera_zoom
	_update_dynamic_shader_parameters()


func _update_shader() -> void:
	if not is_inside_tree():
		return

	var material := _get_shader_material()
	if material == null:
		return

	material.set_shader_parameter("camera_position", _camera_position)
	material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
	material.set_shader_parameter("viewport_size", get_viewport_rect().size)
	material.set_shader_parameter("reference_zoom", maxf(reference_zoom, 0.1))
	material.set_shader_parameter("zoomed_out_parallax_strength", clampf(zoomed_out_parallax_strength, 0.0, 1.0))
	material.set_shader_parameter("far_enabled", 1.0 if far_stars_enabled else 0.0)
	material.set_shader_parameter("far_scroll_scale", far_scroll_scale)
	material.set_shader_parameter("far_cell_size", maxf(far_cell_size, 8.0))
	material.set_shader_parameter("far_min_size", far_star_min_size)
	material.set_shader_parameter("far_max_size", far_star_max_size)
	material.set_shader_parameter("far_zoom_size_influence", clampf(far_zoom_size_influence, 0.0, 1.0))
	material.set_shader_parameter("mid_enabled", 1.0 if mid_stars_enabled else 0.0)
	material.set_shader_parameter("mid_scroll_scale", mid_scroll_scale)
	material.set_shader_parameter("mid_cell_size", maxf(mid_cell_size, 8.0))
	material.set_shader_parameter("mid_min_size", mid_star_min_size)
	material.set_shader_parameter("mid_max_size", mid_star_max_size)
	material.set_shader_parameter("mid_zoom_size_influence", clampf(mid_zoom_size_influence, 0.0, 1.0))
	material.set_shader_parameter("near_enabled", 1.0 if near_stars_enabled else 0.0)
	material.set_shader_parameter("near_scroll_scale", near_scroll_scale)
	material.set_shader_parameter("near_cell_size", maxf(near_cell_size, 8.0))
	material.set_shader_parameter("near_min_size", near_star_min_size)
	material.set_shader_parameter("near_max_size", near_star_max_size)
	material.set_shader_parameter("near_zoom_size_influence", clampf(near_zoom_size_influence, 0.0, 1.0))
	material.set_shader_parameter("nebula_enabled", 1.0 if nebula_enabled else 0.0)
	material.set_shader_parameter("nebula_time", _nebula_time)
	material.set_shader_parameter("nebula_animation_enabled", 1.0 if nebula_animated else 0.0)
	material.set_shader_parameter("nebula_animation_speed", maxf(nebula_animation_speed, 0.0))
	material.set_shader_parameter("nebula_scroll_scale", maxf(nebula_scroll_scale, 0.0))
	material.set_shader_parameter("nebula_scale", maxf(nebula_scale, 0.1))
	material.set_shader_parameter("nebula_detail_scale", maxf(nebula_detail_scale, 0.1))
	material.set_shader_parameter("nebula_warp_strength", maxf(nebula_warp_strength, 0.0))
	material.set_shader_parameter("nebula_detail_strength", maxf(nebula_detail_strength, 0.0))
	material.set_shader_parameter("nebula_density", maxf(nebula_density, 0.0))
	material.set_shader_parameter("nebula_cutoff", clampf(nebula_cutoff, 0.0, 2.0))
	material.set_shader_parameter("nebula_softness", maxf(nebula_softness, 0.001))
	material.set_shader_parameter("nebula_opacity", clampf(nebula_opacity, 0.0, 2.0))
	material.set_shader_parameter("nebula_saturation", clampf(nebula_saturation, 0.0, 2.0))
	material.set_shader_parameter("nebula_brightness", maxf(nebula_brightness, 0.0))
	material.set_shader_parameter("nebula_shadow_strength", clampf(nebula_shadow_strength, 0.0, 2.0))
	material.set_shader_parameter("nebula_glow_strength", clampf(nebula_glow_strength, 0.0, 2.0))
	material.set_shader_parameter("nebula_twist", maxf(nebula_twist, 0.0))
	material.set_shader_parameter("nebula_flow", maxf(nebula_flow, 0.0))
	material.set_shader_parameter("nebula_pulse_speed", maxf(nebula_pulse_speed, 0.0))
	material.set_shader_parameter("nebula_pulse_amount", clampf(nebula_pulse_amount, 0.0, 2.0))
	material.set_shader_parameter("nebula_vignette_strength", clampf(nebula_vignette_strength, 0.0, 2.0))
	material.set_shader_parameter("nebula_offset", nebula_offset)
	material.set_shader_parameter("nebula_background_color", nebula_background_color)
	material.set_shader_parameter("nebula_dark_color", nebula_dark_color)
	material.set_shader_parameter("nebula_primary_color", nebula_primary_color)
	material.set_shader_parameter("nebula_secondary_color", nebula_secondary_color)
	material.set_shader_parameter("nebula_accent_color", nebula_accent_color)
	material.set_shader_parameter("nebula_halo_color", nebula_halo_color)
	material.set_shader_parameter("nebula_halo_strength", clampf(nebula_halo_strength, 0.0, 1.0))


func _update_dynamic_shader_parameters() -> void:
	if not is_inside_tree():
		return

	var material := _get_shader_material()
	if material == null:
		return

	material.set_shader_parameter("camera_position", _camera_position)
	material.set_shader_parameter("camera_zoom", maxf(_camera_zoom.x, 0.001))
	material.set_shader_parameter("viewport_size", get_viewport_rect().size)
	material.set_shader_parameter("nebula_time", _nebula_time)


func _get_shader_material() -> ShaderMaterial:
	var shader_rect := get_node_or_null(SHADER_RECT_PATH) as ColorRect
	if shader_rect == null:
		return null

	return shader_rect.material as ShaderMaterial

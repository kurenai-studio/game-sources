extends PanelContainer
class_name GalaxyMinimap

const QUALITY_LOW: int = 0
const QUALITY_MEDIUM: int = 1
const QUALITY_ULTRA: int = 3
const PALETTE_BLUE_VOID: int = 0
const PALETTE_PURPLE_RIFT: int = 2
const PALETTE_GREEN_ION_CLOUD: int = 3
const PALETTE_RED_DANGER_SECTOR: int = 4
const PALETTE_GOLDEN_ANCIENT_SECTOR: int = 5
const NEBULA_SHADER: Shader = preload("res://shaders/systems/procedural_galaxy_nebula.gdshader")
const NEBULA_LAYER_COUNT: int = 4
const NEBULA_MIN_CAMERA_MOTION_RATIO: float = 0.1
const NEBULA_MAX_CAMERA_MOTION_RATIO: float = 0.14
const NEBULA_SHADER_PARAMETER_NAMES: PackedStringArray = [
	"seed",
	"layer_index",
	"camera_position",
	"camera_zoom",
	"viewport_size",
	"parallax_scale",
	"noise_scale",
	"distortion",
	"opacity",
	"color_a",
	"color_b",
	"color_c",
	"glow_strength",
	"edge_softness",
	"animation_speed",
	"animation_enabled",
	"octave_count",
]
const NEBULA_SIGNATURE_PARAMETER_NAMES: PackedStringArray = [
	"seed",
	"layer_index",
	"parallax_scale",
	"noise_scale",
	"distortion",
	"opacity",
	"color_a",
	"color_b",
	"color_c",
	"glow_strength",
	"edge_softness",
	"animation_speed",
	"octave_count",
]

@export var galaxy_path: NodePath = NodePath("")
@export var planet_field_path: NodePath = NodePath("")
@export var asteroid_field_path: NodePath = NodePath("")
@export var enemy_field_path: NodePath = NodePath("")
@export var ship_path: NodePath = NodePath("")
@export var fog_of_war_path: NodePath = NodePath("")

@export_range(16, 256, 1) var sample_resolution: int = 64
@export_range(0.03, 1.0, 0.01) var redraw_interval: float = 0.25
@export_range(0.0, 32.0, 0.5) var padding: float = 8.0
@export_range(1.0, 12.0, 0.5) var planet_pixel_size: float = 4.0
@export_range(1.0, 12.0, 0.5) var asteroid_pixel_size: float = 2.0
@export_range(1.0, 12.0, 0.5) var enemy_pixel_size: float = 3.0
@export_range(1.0, 12.0, 0.5) var explorer_beacon_pixel_size: float = 2.0
@export_range(1.0, 12.0, 0.5) var ship_pixel_size: float = 5.0
@export_range(1.0, 3.0, 0.1) var camera_outline_thickness: float = 1.0

@export_group("Nebula Background")
@export var nebula_background_enabled: bool = true
@export_range(64, 512, 1) var nebula_background_resolution: int = 256
@export_range(0.0, 2.0, 0.01) var nebula_background_opacity: float = 1.0

@export_group("Colors")
@export var background_color: Color = Color(0.02, 0.03, 0.06, 0.92)
@export var revealed_cell_color: Color = Color(0.09, 0.22, 0.38, 0.58)
@export var explored_fog_cell_color: Color = Color(0.04, 0.12, 0.22, 0.58)
@export var fog_cell_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var planet_new_color: Color = Color(0.18, 0.52, 1.0, 1.0)
@export var planet_conquered_color: Color = Color(0.2, 1.0, 0.38, 1.0)
@export var asteroid_color: Color = Color(0.62, 0.62, 0.58, 1.0)
@export var enemy_color: Color = Color(1.0, 0.22, 0.22, 1.0)
@export var explorer_beacon_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var ship_color: Color = Color(0.95, 0.95, 1.0, 1.0)
@export var other_player_ship_color: Color = Color(1.0, 0.22, 0.22, 1.0)
@export var camera_outline_color: Color = Color(0.52, 0.9, 1.0, 0.85)
@export var galaxy_border_color: Color = Color(0.38, 0.6, 1.0, 0.38)

var _galaxy: Node
var _planet_field: Node2D
var _asteroid_field: Node2D
var _enemy_field: Node2D
var _ship: Node2D
var _fog_of_war: Node
var _world_radius: float = 10000.0
var _world_extent: float = 10000.0
var _is_dragging_minimap: bool = false
var _redraw_accumulator: float = 0.0
var _fog_preview_image: Image
var _fog_preview_texture: ImageTexture
var _fog_preview_exploration_version: int = -1
var _fog_preview_visibility_version: int = -1
var _fog_preview_enabled: bool = true
var _fog_preview_world_extent: float = 0.0
var _nebula_viewport: SubViewport
var _nebula_background_rect: ColorRect
var _nebula_layers: Array[ColorRect] = []
var _nebula_signature: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_resolve_bindings()
	_update_nebula_renderer()
	set_process(true)


func _process(delta: float) -> void:
	if _is_dragging_minimap and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_is_dragging_minimap = false

	_redraw_accumulator += maxf(delta, 0.0)
	if not _is_dragging_minimap and _redraw_accumulator < redraw_interval:
		return

	_redraw_accumulator = 0.0
	_resolve_bindings()
	_update_nebula_renderer()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _try_place_pending_artifact_at_mouse_position(event.position):
				accept_event()
				return
			_is_dragging_minimap = true
			_center_camera_on_mouse_position(event.position)
		else:
			_is_dragging_minimap = false
		accept_event()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_move_ship_to_mouse_position(event.position)
		accept_event()
		return

	if event is InputEventMouseMotion and _is_dragging_minimap:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_is_dragging_minimap = false
			return

		_center_camera_on_mouse_position(event.position)
		accept_event()


func _resolve_bindings() -> void:
	_galaxy = _resolve_node(galaxy_path)
	_planet_field = _resolve_node(planet_field_path) as Node2D
	_asteroid_field = _resolve_node(asteroid_field_path) as Node2D
	_enemy_field = _resolve_node(enemy_field_path) as Node2D
	_fog_of_war = _resolve_node(fog_of_war_path)
	_ship = _resolve_local_ship()

	_world_radius = 10000.0
	if _galaxy != null and _galaxy.has_method("get_world_radius"):
		_world_radius = maxf(1.0, float(_galaxy.call("get_world_radius")))

	_world_extent = _world_radius
	if _fog_of_war != null and _fog_of_war.has_method("get"):
		_world_extent = maxf(_world_extent, float(_fog_of_war.get("world_half_extent")))


func _draw() -> void:
	var content_rect := _get_content_rect()
	if content_rect.size.x <= 0.0 or content_rect.size.y <= 0.0:
		return

	draw_rect(content_rect, background_color, true)
	_draw_nebula_background(content_rect)
	_draw_fog_grid(content_rect)
	_draw_galaxy_border(content_rect)
	_draw_planets(content_rect)
	_draw_asteroids(content_rect)
	_draw_enemies(content_rect)
	_draw_explorer_beacons(content_rect)
	_draw_ships(content_rect)
	_draw_camera_view(content_rect)


func _get_content_rect() -> Rect2:
	var inset := maxf(padding, 0.0)
	var content_position := Vector2(inset, inset)
	var content_size := size - Vector2(inset * 2.0, inset * 2.0)
	if content_size.x < 0.0 or content_size.y < 0.0:
		return Rect2()

	return Rect2(content_position, content_size)


func _draw_fog_grid(content_rect: Rect2) -> void:
	var cells := maxi(sample_resolution, 1)
	_ensure_fog_preview(cells)
	if _fog_preview_image == null or _fog_preview_texture == null:
		return

	var exploration_version := _get_fog_mask_version("get_exploration_mask_version")
	var visibility_version := _get_fog_mask_version("get_visibility_mask_version")
	var fog_enabled := _is_fog_enabled()
	if (
		_fog_preview_exploration_version == exploration_version
		and _fog_preview_visibility_version == visibility_version
		and _fog_preview_enabled == fog_enabled
		and is_equal_approx(_fog_preview_world_extent, _world_extent)
	):
		draw_texture_rect(_fog_preview_texture, content_rect, false)
		return

	for y in range(cells):
		for x in range(cells):
			var sample_map_position := content_rect.position + Vector2(
				(float(x) + 0.5) / float(cells) * content_rect.size.x,
				(float(y) + 0.5) / float(cells) * content_rect.size.y
			)
			var sample_world_position := _map_to_world(sample_map_position, content_rect)
			var explored_alpha := _get_world_explored_alpha(sample_world_position)
			var active_alpha := _get_world_visible_alpha(sample_world_position)
			var cell_color := _get_fog_cell_draw_color(explored_alpha, active_alpha)
			_fog_preview_image.set_pixel(x, y, cell_color)

	_fog_preview_texture.update(_fog_preview_image)
	_fog_preview_exploration_version = exploration_version
	_fog_preview_visibility_version = visibility_version
	_fog_preview_enabled = fog_enabled
	_fog_preview_world_extent = _world_extent
	draw_texture_rect(_fog_preview_texture, content_rect, false)


func _ensure_fog_preview(resolution: int) -> void:
	var safe_resolution := maxi(resolution, 1)
	if _fog_preview_image != null and _fog_preview_image.get_width() == safe_resolution and _fog_preview_image.get_height() == safe_resolution:
		return

	_fog_preview_image = Image.create(safe_resolution, safe_resolution, false, Image.FORMAT_RGBA8)
	_fog_preview_texture = ImageTexture.create_from_image(_fog_preview_image)
	_fog_preview_exploration_version = -1
	_fog_preview_visibility_version = -1


func _draw_nebula_background(content_rect: Rect2) -> void:
	if not _should_draw_nebula_background():
		return
	if _nebula_viewport == null:
		return

	var texture := _nebula_viewport.get_texture()
	if texture == null:
		return

	var tint := Color(1.0, 1.0, 1.0, clampf(nebula_background_opacity, 0.0, 2.0))
	var source_rect := _get_texture_cover_source_rect(texture, content_rect.size)
	draw_texture_rect_region(texture, content_rect, source_rect, tint)


func _get_texture_cover_source_rect(texture: Texture2D, target_size: Vector2) -> Rect2:
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or target_size.x <= 0.0 or target_size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size)

	var texture_aspect := texture_size.x / texture_size.y
	var target_aspect := target_size.x / target_size.y
	if texture_aspect > target_aspect:
		var source_width := texture_size.y * target_aspect
		return Rect2(Vector2((texture_size.x - source_width) * 0.5, 0.0), Vector2(source_width, texture_size.y))

	var source_height := texture_size.x / target_aspect
	return Rect2(Vector2(0.0, (texture_size.y - source_height) * 0.5), Vector2(texture_size.x, source_height))


func _get_fog_cell_draw_color(explored_alpha: float, active_alpha: float) -> Color:
	var cell_color := fog_cell_color.lerp(explored_fog_cell_color, explored_alpha)
	return cell_color.lerp(revealed_cell_color, active_alpha)


func _should_draw_nebula_background() -> bool:
	return nebula_background_enabled and nebula_background_opacity > 0.0


func _update_nebula_renderer() -> void:
	if not _should_draw_nebula_background():
		return

	_ensure_nebula_renderer()
	if _nebula_viewport == null:
		return

	var render_size := _get_nebula_render_size(clampi(nebula_background_resolution, 64, 512))
	_nebula_viewport.size = render_size
	var signature := _build_nebula_signature(render_size)
	if signature == _nebula_signature:
		_update_nebula_dynamic_parameters()
		return

	_nebula_signature = signature
	_configure_nebula_renderer(render_size)


func _ensure_nebula_renderer() -> void:
	if _nebula_viewport != null:
		return

	_nebula_viewport = SubViewport.new()
	_nebula_viewport.name = "MinimapNebulaViewport"
	_nebula_viewport.disable_3d = true
	_nebula_viewport.transparent_bg = false
	_nebula_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_nebula_viewport)

	_nebula_background_rect = ColorRect.new()
	_nebula_background_rect.name = "Background"
	_nebula_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nebula_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nebula_viewport.add_child(_nebula_background_rect)

	for i in NEBULA_LAYER_COUNT:
		var layer := ColorRect.new()
		layer.name = "NebulaLayer%d" % [i + 1]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_nebula_viewport.add_child(layer)
		_nebula_layers.append(layer)


func _configure_nebula_renderer(render_size: Vector2i) -> void:
	var source := _resolve_nebula_source()
	if _configure_live_nebula_layers(source):
		return

	var preset := _get_nebula_quality_profile(_get_source_int(source, "quality_preset", QUALITY_MEDIUM))
	var active_count := 0
	if _get_source_bool(source, "nebula_enabled", true):
		var source_layer_count := _get_source_int(source, "nebula_layer_count", 3)
		active_count = clampi(mini(source_layer_count, int(preset["nebula_layers"])), 1, NEBULA_LAYER_COUNT)

	var palette := _get_source_galaxy_colors(source)
	if _nebula_background_rect != null:
		_nebula_background_rect.color = palette[0]

	for i in _nebula_layers.size():
		var layer := _nebula_layers[i]
		layer.visible = i < active_count
		if not layer.visible:
			continue

		var material := ShaderMaterial.new()
		material.shader = NEBULA_SHADER
		layer.material = material
		_set_nebula_material_parameters(material, i, active_count, preset, palette, source, render_size)


func _configure_live_nebula_layers(source: Node) -> bool:
	if source == null:
		return false

	var copied_any := false
	for i in _nebula_layers.size():
		var target_layer := _nebula_layers[i]
		var source_layer := _get_source_nebula_layer(source, i)
		var source_material := _get_source_nebula_material(source_layer)
		target_layer.visible = source_layer != null and source_layer.visible and source_material != null
		if not target_layer.visible:
			target_layer.material = null
			continue

		var material := ShaderMaterial.new()
		material.shader = NEBULA_SHADER
		_copy_nebula_shader_parameters(source_material, material)
		_apply_fixed_nebula_map_parameters(material)
		target_layer.material = material
		copied_any = true

	var source_background := source.get_node_or_null("CanvasLayer/Background") as ColorRect
	if source_background != null and _nebula_background_rect != null:
		_nebula_background_rect.color = source_background.color

	return copied_any


func _set_nebula_material_parameters(
		material: ShaderMaterial,
		layer_index: int,
		active_count: int,
		preset: Dictionary,
		palette: Array[Color],
		source: Node,
		render_size: Vector2i
) -> void:
	var layer_factor := float(layer_index) / maxf(float(active_count - 1), 1.0)
	var seed := _get_source_int(source, "seed", 1337)
	var parallax_strength := _get_source_float(source, "parallax_strength", 0.72)
	var intensity := _get_source_float(source, "nebula_intensity", 1.0)
	var animation_speed := _get_source_float(source, "nebula_animation_speed", 0.08)
	var animation_enabled := _get_source_bool(source, "nebula_animation_enabled", true)
	material.set_shader_parameter("seed", float(seed + layer_index * 97))
	material.set_shader_parameter("layer_index", float(layer_index))
	material.set_shader_parameter("camera_position", Vector2.ZERO)
	material.set_shader_parameter("camera_zoom", 1.0)
	material.set_shader_parameter("viewport_size", Vector2(float(render_size.x), float(render_size.y)))
	material.set_shader_parameter(
		"parallax_scale",
		parallax_strength * lerpf(NEBULA_MIN_CAMERA_MOTION_RATIO, NEBULA_MAX_CAMERA_MOTION_RATIO, layer_factor)
	)
	material.set_shader_parameter("noise_scale", lerpf(1.35, 3.2, layer_factor))
	material.set_shader_parameter("distortion", lerpf(0.2, float(preset["nebula_distortion"]), layer_factor))
	material.set_shader_parameter("opacity", intensity * lerpf(0.24, 0.42, layer_factor))
	material.set_shader_parameter("color_a", palette[0])
	material.set_shader_parameter("color_b", palette[1])
	material.set_shader_parameter("color_c", palette[2])
	material.set_shader_parameter("glow_strength", lerpf(0.12, 0.34, layer_factor) * intensity)
	material.set_shader_parameter("edge_softness", lerpf(0.16, 0.34, layer_factor))
	material.set_shader_parameter("animation_speed", animation_speed * lerpf(0.55, 1.35, layer_factor))
	material.set_shader_parameter("animation_enabled", 1.0 if animation_enabled else 0.0)
	material.set_shader_parameter("octave_count", int(preset["nebula_octaves"]))


func _update_nebula_dynamic_parameters() -> void:
	var source := _resolve_nebula_source()
	for layer in _nebula_layers:
		if layer == null or not layer.visible:
			continue

		var layer_index := _nebula_layers.find(layer)
		var source_material := _get_source_nebula_material(_get_source_nebula_layer(source, layer_index))
		var material := layer.material as ShaderMaterial
		if material == null:
			continue

		if source_material != null:
			_copy_nebula_shader_parameters(source_material, material)
			_apply_fixed_nebula_map_parameters(material)


func _build_nebula_signature(render_size: Vector2i) -> int:
	var source := _resolve_nebula_source()
	var live_signature := _get_live_nebula_signature(source)
	if not live_signature.is_empty():
		return hash([
			render_size,
			nebula_background_enabled,
			nebula_background_opacity,
			live_signature,
		])

	if source == null:
		return hash([render_size, nebula_background_enabled, nebula_background_opacity])

	return hash([
		render_size,
		nebula_background_enabled,
		nebula_background_opacity,
		_get_source_int(source, "seed", 1337),
		_get_source_int(source, "quality_preset", QUALITY_MEDIUM),
		_get_source_bool(source, "use_palette_colors", true),
		_get_source_value(source, "galaxy_background_color", Color(0.002, 0.014, 0.022, 1.0)),
		_get_source_value(source, "galaxy_nebula_mid_color", Color(0.02, 0.32, 0.39, 1.0)),
		_get_source_value(source, "galaxy_nebula_glow_color", Color(0.35, 1.0, 0.88, 1.0)),
		_get_source_bool(source, "nebula_enabled", true),
		_get_source_float(source, "nebula_intensity", 1.0),
		_get_source_bool(source, "nebula_animation_enabled", true),
		_get_source_float(source, "nebula_animation_speed", 0.08),
		_get_source_int(source, "nebula_color_palette", 1),
		_get_source_int(source, "nebula_layer_count", 3),
		_get_source_float(source, "parallax_strength", 0.72),
	])


func _get_nebula_render_size(max_edge: int) -> Vector2i:
	var source_size := _get_live_nebula_viewport_size(_resolve_nebula_source())
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Vector2i(max_edge, max_edge)

	var aspect := source_size.x / source_size.y
	if aspect >= 1.0:
		return Vector2i(max_edge, maxi(1, int(round(float(max_edge) / aspect))))

	return Vector2i(maxi(1, int(round(float(max_edge) * aspect))), max_edge)


func _get_live_nebula_viewport_size(source: Node) -> Vector2:
	for i in NEBULA_LAYER_COUNT:
		var source_material := _get_source_nebula_material(_get_source_nebula_layer(source, i))
		if source_material == null:
			continue

		var viewport_size = source_material.get_shader_parameter("viewport_size")
		if viewport_size is Vector2:
			return viewport_size

	return get_viewport_rect().size


func _get_live_nebula_signature(source: Node) -> Array:
	var signature := []
	if source == null:
		return signature

	for i in NEBULA_LAYER_COUNT:
		var source_layer := _get_source_nebula_layer(source, i)
		var source_material := _get_source_nebula_material(source_layer)
		if source_layer == null or source_material == null:
			signature.append([i, false])
			continue

		var parameter_values := []
		for parameter_name in NEBULA_SIGNATURE_PARAMETER_NAMES:
			parameter_values.append(source_material.get_shader_parameter(parameter_name))
		signature.append([i, source_layer.visible, parameter_values])

	return signature


func _get_source_nebula_layer(source: Node, layer_index: int) -> ColorRect:
	if source == null:
		return null

	return source.get_node_or_null("CanvasLayer/NebulaLayer%d" % [layer_index + 1]) as ColorRect


func _get_source_nebula_material(source_layer: ColorRect) -> ShaderMaterial:
	if source_layer == null:
		return null

	return source_layer.material as ShaderMaterial


func _copy_nebula_shader_parameters(source_material: ShaderMaterial, target_material: ShaderMaterial) -> void:
	for parameter_name in NEBULA_SHADER_PARAMETER_NAMES:
		target_material.set_shader_parameter(parameter_name, source_material.get_shader_parameter(parameter_name))


func _apply_fixed_nebula_map_parameters(material: ShaderMaterial) -> void:
	material.set_shader_parameter("camera_position", Vector2.ZERO)
	material.set_shader_parameter("camera_zoom", 1.0)
	if _nebula_viewport != null:
		var render_size := _nebula_viewport.size
		material.set_shader_parameter("viewport_size", Vector2(float(render_size.x), float(render_size.y)))


func _resolve_nebula_source() -> Node:
	if _galaxy != null:
		var source := _galaxy.get("starfield") as Node
		if source != null:
			return source

	return _resolve_node(NodePath("../../Starfield"))


func _get_source_galaxy_colors(source: Node) -> Array[Color]:
	if source != null and not _get_source_bool(source, "use_palette_colors", true):
		return [
			_get_source_value(source, "galaxy_background_color", Color(0.002, 0.014, 0.022, 1.0)) as Color,
			_get_source_value(source, "galaxy_nebula_mid_color", Color(0.02, 0.32, 0.39, 1.0)) as Color,
			_get_source_value(source, "galaxy_nebula_glow_color", Color(0.35, 1.0, 0.88, 1.0)) as Color,
		]

	return _get_palette_colors(_get_source_int(source, "nebula_color_palette", 1))


func _get_palette_colors(palette: int) -> Array[Color]:
	match palette:
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


func _get_nebula_quality_profile(quality_preset: int) -> Dictionary:
	match quality_preset:
		QUALITY_LOW:
			return {"nebula_layers": 1, "nebula_octaves": 2, "nebula_distortion": 0.18}
		QUALITY_ULTRA:
			return {"nebula_layers": 4, "nebula_octaves": 4, "nebula_distortion": 0.68}
		QUALITY_MEDIUM:
			return {"nebula_layers": 2, "nebula_octaves": 3, "nebula_distortion": 0.34}
		_:
			return {"nebula_layers": 3, "nebula_octaves": 4, "nebula_distortion": 0.52}


func _get_source_bool(source: Node, property: StringName, default_value: bool) -> bool:
	if source == null:
		return default_value

	var value = source.get(property)
	return default_value if value == null else bool(value)


func _get_source_int(source: Node, property: StringName, default_value: int) -> int:
	if source == null:
		return default_value

	var value = source.get(property)
	return default_value if value == null else int(value)


func _get_source_float(source: Node, property: StringName, default_value: float) -> float:
	if source == null:
		return default_value

	var value = source.get(property)
	return default_value if value == null else float(value)


func _get_source_value(source: Node, property: StringName, default_value: Variant) -> Variant:
	if source == null:
		return default_value

	var value = source.get(property)
	return default_value if value == null else value


func _draw_galaxy_border(content_rect: Rect2) -> void:
	var extent := maxf(_world_radius, 1.0)
	var top_left := _world_to_map(Vector2(-extent, -extent), content_rect)
	var bottom_right := _world_to_map(Vector2(extent, extent), content_rect)
	var border_rect := Rect2(top_left, bottom_right - top_left)
	draw_rect(border_rect, galaxy_border_color, false, 1.0)


func _draw_planets(content_rect: Rect2) -> void:
	if _planet_field == null:
		return

	for child in _planet_field.get_children():
		var planet := child as Planet
		if planet == null:
			continue
		if not _is_world_explored(planet.global_position):
			continue

		var pixel_color := planet_conquered_color if planet.is_conquered() else planet_new_color
		_draw_entity_pixel(planet.global_position, content_rect, planet_pixel_size, pixel_color)


func _draw_asteroids(content_rect: Rect2) -> void:
	if _asteroid_field == null:
		return

	for child in _asteroid_field.get_children():
		var asteroid := child as Node2D
		if asteroid == null:
			continue
		if asteroid.has_method("is_destroyed") and bool(asteroid.call("is_destroyed")):
			continue
		if not _is_world_explored(asteroid.global_position):
			continue

		_draw_entity_pixel(asteroid.global_position, content_rect, asteroid_pixel_size, asteroid_color)


func _draw_enemies(content_rect: Rect2) -> void:
	if _enemy_field == null:
		return

	for child in _enemy_field.get_children():
		var enemy := child as Enemy
		if enemy == null:
			continue
		if not _is_world_visible(enemy.global_position):
			continue

		_draw_entity_pixel(enemy.global_position, content_rect, enemy_pixel_size, enemy_color)


func _draw_explorer_beacons(content_rect: Rect2) -> void:
	if _galaxy == null or _galaxy.get_tree() == null:
		return

	for beacon_node in _galaxy.get_tree().get_nodes_in_group(&"explorer_beacons"):
		var beacon := beacon_node as Node2D
		if not _should_draw_explorer_beacon_marker(beacon):
			continue
		if not _is_world_visible(beacon.global_position):
			continue

		_draw_entity_pixel(beacon.global_position, content_rect, explorer_beacon_pixel_size, explorer_beacon_color)


func _draw_ships(content_rect: Rect2) -> void:
	if _ship != null and _should_draw_ship_marker(_ship):
		_draw_entity_pixel(_ship.global_position, content_rect, ship_pixel_size, ship_color)

	if _ship == null or _galaxy == null or _galaxy.get_tree() == null:
		return

	for player_node in _galaxy.get_tree().get_nodes_in_group(&"player_ships"):
		var player_ship := player_node as Node2D
		if player_ship == null or player_ship == _ship:
			continue
		if not _should_draw_ship_marker(player_ship):
			continue
		if not _is_world_visible(player_ship.global_position):
			continue

		_draw_entity_pixel(player_ship.global_position, content_rect, ship_pixel_size, other_player_ship_color)


func _should_draw_ship_marker(player_ship: Node2D) -> bool:
	if player_ship == null or not is_instance_valid(player_ship):
		return false
	if not player_ship.visible:
		return false
	if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
		return false

	return true


func _should_draw_explorer_beacon_marker(beacon: Node2D) -> bool:
	if beacon == null or not is_instance_valid(beacon):
		return false
	if beacon.has_method("is_destroyed") and bool(beacon.call("is_destroyed")):
		return false

	return true


func _resolve_local_ship() -> Node2D:
	var path_ship := _resolve_node(ship_path) as Node2D
	if _should_draw_ship_marker(path_ship):
		return path_ship

	var galaxy_ship := _get_galaxy_ship()
	if _should_draw_ship_marker(galaxy_ship):
		return galaxy_ship

	if _galaxy != null and _galaxy.get_tree() != null:
		for player_node in _galaxy.get_tree().get_nodes_in_group(&"player_ships"):
			var player_ship := player_node as Node2D
			if player_ship == null:
				continue
			if bool(player_ship.get("is_local_player")) and _should_draw_ship_marker(player_ship):
				return player_ship

	return path_ship


func _get_galaxy_ship() -> Node2D:
	if _galaxy == null:
		return null

	return _galaxy.get("ship") as Node2D


func _draw_camera_view(content_rect: Rect2) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var viewport_size := get_viewport_rect().size
	var safe_zoom := Vector2(maxf(camera.zoom.x, 0.001), maxf(camera.zoom.y, 0.001))
	var half_view_size := viewport_size * 0.5 / safe_zoom
	var top_left := _world_to_map(camera.global_position - half_view_size, content_rect)
	var bottom_right := _world_to_map(camera.global_position + half_view_size, content_rect)
	draw_rect(Rect2(top_left, bottom_right - top_left), camera_outline_color, false, camera_outline_thickness)


func _draw_entity_pixel(world_position: Vector2, content_rect: Rect2, pixel_size: float, color: Color) -> void:
	var map_position := _world_to_map(world_position, content_rect)
	var size_vector := Vector2.ONE * maxf(pixel_size, 1.0)
	draw_rect(Rect2(map_position - size_vector * 0.5, size_vector), color, true)


func _world_to_map(world_position: Vector2, content_rect: Rect2) -> Vector2:
	var extent := maxf(_world_extent, 1.0)
	var normalized := Vector2(
		clampf(inverse_lerp(-extent, extent, world_position.x), 0.0, 1.0),
		clampf(inverse_lerp(-extent, extent, world_position.y), 0.0, 1.0)
	)
	return content_rect.position + normalized * content_rect.size


func _map_rect_center_to_world(map_rect: Rect2, content_rect: Rect2) -> Vector2:
	var local_center := map_rect.position + map_rect.size * 0.5
	return _map_to_world(local_center, content_rect)


func _map_to_world(map_position: Vector2, content_rect: Rect2) -> Vector2:
	var extent := maxf(_world_extent, 1.0)
	var normalized := Vector2.ZERO
	if content_rect.size.x > 0.0:
		normalized.x = clampf((map_position.x - content_rect.position.x) / content_rect.size.x, 0.0, 1.0)
	if content_rect.size.y > 0.0:
		normalized.y = clampf((map_position.y - content_rect.position.y) / content_rect.size.y, 0.0, 1.0)

	return Vector2(
		lerpf(-extent, extent, normalized.x),
		lerpf(-extent, extent, normalized.y)
	)


func _is_world_visible(world_position: Vector2) -> bool:
	if _fog_of_war == null:
		return true

	if not _is_fog_enabled():
		return true

	if _fog_of_war.has_method("is_world_position_in_active_vision"):
		return bool(_fog_of_war.call("is_world_position_in_active_vision", world_position))

	return true


func _is_world_explored(world_position: Vector2) -> bool:
	if _fog_of_war == null:
		return true

	if not _is_fog_enabled():
		return true

	if _fog_of_war.has_method("is_world_position_explored"):
		return bool(_fog_of_war.call("is_world_position_explored", world_position))

	if _fog_of_war.has_method("is_world_position_visible"):
		return bool(_fog_of_war.call("is_world_position_visible", world_position))

	return true


func _get_world_visible_alpha(world_position: Vector2) -> float:
	if _fog_of_war == null:
		return 1.0

	if not _is_fog_enabled():
		return 1.0

	if _fog_of_war.has_method("get_world_position_active_vision_alpha"):
		return clampf(float(_fog_of_war.call("get_world_position_active_vision_alpha", world_position)), 0.0, 1.0)

	return 1.0 if _is_world_visible(world_position) else 0.0


func _get_world_explored_alpha(world_position: Vector2) -> float:
	if _fog_of_war == null:
		return 1.0

	if not _is_fog_enabled():
		return 1.0

	if _fog_of_war.has_method("get_world_position_explored_alpha"):
		return clampf(float(_fog_of_war.call("get_world_position_explored_alpha", world_position)), 0.0, 1.0)

	return 1.0 if _is_world_explored(world_position) else 0.0


func _get_fog_mask_version(method_name: StringName) -> int:
	if _fog_of_war == null or not _fog_of_war.has_method(method_name):
		return -1

	return int(_fog_of_war.call(method_name))


func _is_fog_enabled() -> bool:
	if _galaxy != null and _galaxy.has_method("is_fog_of_war_enabled"):
		return bool(_galaxy.call("is_fog_of_war_enabled"))

	return true


func _resolve_node(path: NodePath) -> Node:
	if path == NodePath(""):
		return null

	return get_node_or_null(path)


func _center_camera_on_mouse_position(screen_position: Vector2) -> void:
	if _galaxy == null or not _galaxy.has_method("center_camera_on_world_position"):
		return

	var content_rect := _get_content_rect()
	if not content_rect.has_point(screen_position):
		return

	var world_position := _map_to_world(screen_position, content_rect)
	_galaxy.call("center_camera_on_world_position", world_position)


func _move_ship_to_mouse_position(screen_position: Vector2) -> void:
	if _galaxy == null or not _galaxy.has_method("request_ship_move_to_world_position"):
		return

	var content_rect := _get_content_rect()
	if not content_rect.has_point(screen_position):
		return

	var world_position := _map_to_world(screen_position, content_rect)
	_galaxy.call("request_ship_move_to_world_position", world_position, true)


func _try_place_pending_artifact_at_mouse_position(screen_position: Vector2) -> bool:
	if _galaxy == null or not _galaxy.has_method("has_pending_artifact_placement"):
		return false
	if not bool(_galaxy.call("has_pending_artifact_placement")):
		return false
	if not _galaxy.has_method("try_place_pending_artifact_at_world_position"):
		return false

	var content_rect := _get_content_rect()
	if not content_rect.has_point(screen_position):
		return false

	var world_position := _map_to_world(screen_position, content_rect)
	return bool(_galaxy.call("try_place_pending_artifact_at_world_position", world_position))

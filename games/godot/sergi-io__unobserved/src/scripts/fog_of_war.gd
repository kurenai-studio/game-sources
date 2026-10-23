extends ColorRect
class_name FogOfWar

const FOG_SHADER: Shader = preload("res://shaders/fog_of_war.gdshader")

@export_group("Visibility")
@export_range(64.0, 5000.0, 1.0) var visible_radius: float = 900.0
@export_range(0.0, 1.0, 0.01) var visible_edge_softness_ratio: float = 0.3
@export var unexplored_fog_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var explored_fog_color: Color = Color(0, 0, 0, 0.5)
@export var draw_explored_fog: bool = true
@export_range(0.0, 30.0, 0.1) var active_visibility_cooldown: float = 0.0
@export_range(0.01, 1.0, 0.01) var stamp_spacing_ratio: float = 0.08
@export var use_fast_mask_sampling: bool = true
@export_range(0.0, 1.0, 0.005) var fog_visual_fade_duration: float = 0.12

@export_group("Coverage")
@export_range(1024.0, 40000.0, 10.0) var world_half_extent: float = 10000.0
@export_range(128, 4096, 64) var mask_resolution: int = 256

var _fog_material: ShaderMaterial
var _exploration_mask_image: Image
var _exploration_mask_texture: ImageTexture
var _visibility_mask_image: Image
var _visibility_mask_texture: ImageTexture
var _fog_previous_mask_image: Image
var _fog_previous_mask_texture: ImageTexture
var _fog_current_mask_image: Image
var _fog_current_mask_texture: ImageTexture
var _world_bounds_min: Vector2 = Vector2.ZERO
var _world_bounds_max: Vector2 = Vector2.ONE
var _last_stamp_position: Vector2 = Vector2.ZERO
var _last_stamp_radius: float = 0.0
var _has_stamp_position: bool = false
var _is_visibility_update_open: bool = false
var _visibility_mask_dirty: bool = false
var _visibility_mask_should_clear: bool = true
var _fog_render_mask_dirty: bool = true
var _visibility_tick_elapsed: float = 0.0
var _active_visibility_sources: Array[Dictionary] = []
var _exploration_mask_version: int = 0
var _visibility_mask_version: int = 0
var _fog_blend_elapsed: float = 0.0
var _fog_blend_duration: float = 0.001
var _has_fog_render_mask: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rebuild_mask()
	_rebuild_material()
	_set_world_half_extent(world_half_extent)


func _process(delta: float) -> void:
	_process_visibility_clear_tick(delta)
	_process_fog_visual_blend(delta)
	_sync_camera_uniforms()


func set_world_half_extent(value: float) -> void:
	world_half_extent = maxf(value, 1.0)
	_set_world_half_extent(world_half_extent)


func reset_reveal() -> void:
	_has_stamp_position = false
	_last_stamp_radius = 0.0
	_rebuild_mask()
	_set_world_half_extent(world_half_extent)


func reveal_at_world_position(world_position: Vector2, radius: float = -1.0) -> void:
	if _exploration_mask_image == null:
		return

	var stamp_radius := _resolve_radius(radius)
	var stamp_spacing := maxf(stamp_radius * stamp_spacing_ratio, 1.0)
	var mask_changed := false
	if not _has_stamp_position:
		mask_changed = _stamp_explored(world_position, stamp_radius)
		_last_stamp_position = world_position
		_last_stamp_radius = stamp_radius
		_has_stamp_position = true
		if mask_changed:
			_update_exploration_texture()
		return

	var delta := world_position - _last_stamp_position
	var distance := delta.length()
	if distance < stamp_spacing:
		if stamp_radius > _last_stamp_radius:
			mask_changed = _stamp_explored(world_position, stamp_radius)
			_last_stamp_position = world_position
			_last_stamp_radius = stamp_radius
			if mask_changed:
				_update_exploration_texture()
		return

	var direction := delta / distance
	var next_stamp_position := _last_stamp_position
	while next_stamp_position.distance_to(world_position) >= stamp_spacing:
		next_stamp_position += direction * stamp_spacing
		mask_changed = _stamp_explored(next_stamp_position, stamp_radius) or mask_changed

	_last_stamp_position = next_stamp_position
	_last_stamp_radius = maxf(_last_stamp_radius, stamp_radius)
	if mask_changed:
		_update_exploration_texture()


func reveal_disc_at_world_position(world_position: Vector2, radius: float = -1.0) -> void:
	var stamp_radius := _resolve_radius(radius)
	if _stamp_explored(world_position, stamp_radius):
		_update_exploration_texture()


func reveal_discs_at_world_positions(world_positions: Array[Vector2], radius: float = -1.0) -> void:
	if _exploration_mask_image == null or world_positions.is_empty():
		return

	var stamp_radius := _resolve_radius(radius)
	var mask_changed := false
	if world_positions.size() < 16:
		for world_position in world_positions:
			mask_changed = _stamp_explored(world_position, stamp_radius) or mask_changed
	elif world_positions.size() >= 128:
		var combined_stamp := _build_combined_disc_reveal_stamp(world_positions, stamp_radius)
		mask_changed = _stamp_explored(
			combined_stamp.get("position", Vector2.ZERO) as Vector2,
			float(combined_stamp.get("radius", stamp_radius))
		)
	else:
		for stamp in _build_coalesced_disc_reveal_stamps(world_positions, stamp_radius):
			mask_changed = _stamp_explored(
				stamp.get("position", Vector2.ZERO) as Vector2,
				float(stamp.get("radius", stamp_radius))
			) or mask_changed
	if mask_changed:
		_update_exploration_texture()


func _build_combined_disc_reveal_stamp(world_positions: Array[Vector2], stamp_radius: float) -> Dictionary:
	var center := Vector2.ZERO
	for world_position in world_positions:
		center += world_position
	center /= float(maxi(world_positions.size(), 1))

	var max_distance := 0.0
	for world_position in world_positions:
		max_distance = maxf(max_distance, center.distance_to(world_position))

	return {
		"position": center,
		"radius": stamp_radius + max_distance,
	}


func _build_coalesced_disc_reveal_stamps(world_positions: Array[Vector2], stamp_radius: float) -> Array[Dictionary]:
	var cell_size := maxf(stamp_radius, 1.0)
	var bucket_sums: Dictionary = {}
	var bucket_counts: Dictionary = {}
	for world_position in world_positions:
		var bucket_key := Vector2i(
			floori(world_position.x / cell_size),
			floori(world_position.y / cell_size)
		)
		bucket_sums[bucket_key] = (bucket_sums.get(bucket_key, Vector2.ZERO) as Vector2) + world_position
		bucket_counts[bucket_key] = int(bucket_counts.get(bucket_key, 0)) + 1

	var stamps: Array[Dictionary] = []
	var radius_expansion := cell_size * sqrt(0.5)
	for bucket_key in bucket_sums.keys():
		var count := maxi(int(bucket_counts.get(bucket_key, 1)), 1)
		stamps.append({
			"position": (bucket_sums.get(bucket_key, Vector2.ZERO) as Vector2) / float(count),
			"radius": stamp_radius + radius_expansion,
		})
	return stamps


func begin_visibility_update() -> void:
	if _visibility_mask_image == null:
		return

	_active_visibility_sources.clear()
	_is_visibility_update_open = true


func add_visibility_source(world_position: Vector2, radius: float = -1.0) -> void:
	if _visibility_mask_image == null:
		return

	if not _is_visibility_update_open:
		begin_visibility_update()

	_active_visibility_sources.append({
		"position": world_position,
		"radius": _resolve_radius(radius),
	})


func commit_visibility_update() -> void:
	if _visibility_mask_image == null:
		_is_visibility_update_open = false
		_active_visibility_sources.clear()
		return

	if _visibility_mask_should_clear:
		_visibility_mask_image.fill(Color(1.0, 1.0, 1.0, 1.0))
		_visibility_mask_should_clear = false
		_visibility_mask_dirty = true
		_fog_render_mask_dirty = true
		_visibility_mask_version += 1

	for source in _active_visibility_sources:
		_stamp_visible(source.get("position", Vector2.ZERO) as Vector2, float(source.get("radius", visible_radius)))

	if draw_explored_fog:
		_update_fog_render_texture()
	_is_visibility_update_open = false
	_active_visibility_sources.clear()


func is_world_position_visible(world_position: Vector2) -> bool:
	return is_world_position_explored(world_position)


func is_world_position_explored(world_position: Vector2) -> bool:
	if _exploration_mask_image == null:
		return true

	return _sample_mask_alpha(_exploration_mask_image, world_position) <= 0.5


func is_world_position_in_active_vision(world_position: Vector2) -> bool:
	if _visibility_mask_image == null:
		return true

	return _sample_mask_alpha(_visibility_mask_image, world_position) <= 0.5


func get_world_position_explored_alpha(world_position: Vector2) -> float:
	return _get_mask_visibility_alpha(_exploration_mask_image, world_position)


func get_world_position_active_vision_alpha(world_position: Vector2) -> float:
	return _get_mask_visibility_alpha(_visibility_mask_image, world_position)


func get_visibility_mask_texture() -> Texture2D:
	if _visibility_mask_dirty:
		_update_visibility_texture()
		_visibility_mask_dirty = false
	return _visibility_mask_texture


func get_world_bounds_min() -> Vector2:
	return _world_bounds_min


func get_world_bounds_max() -> Vector2:
	return _world_bounds_max


func get_exploration_mask_version() -> int:
	return _exploration_mask_version


func get_visibility_mask_version() -> int:
	return _visibility_mask_version


func _get_mask_visibility_alpha(mask_image: Image, world_position: Vector2) -> float:
	if mask_image == null:
		return 1.0

	return clampf(1.0 - _sample_mask_alpha(mask_image, world_position), 0.0, 1.0)


func _sample_mask_alpha(mask_image: Image, world_position: Vector2) -> float:
	var mask_size := mask_image.get_size()
	if mask_size.x <= 0 or mask_size.y <= 0:
		return 0.0

	var bounds_size := _world_bounds_max - _world_bounds_min
	if bounds_size.x <= 0.0 or bounds_size.y <= 0.0:
		return 0.0

	var uv := Vector2(
		clampf(inverse_lerp(_world_bounds_min.x, _world_bounds_max.x, world_position.x), 0.0, 1.0),
		clampf(inverse_lerp(_world_bounds_min.y, _world_bounds_max.y, world_position.y), 0.0, 1.0)
	)

	var pixel_position := Vector2(
		uv.x * float(mask_size.x - 1),
		uv.y * float(mask_size.y - 1)
	)
	if use_fast_mask_sampling:
		var nearest_pixel := Vector2i(
			clampi(roundi(pixel_position.x), 0, mask_size.x - 1),
			clampi(roundi(pixel_position.y), 0, mask_size.y - 1)
		)
		return mask_image.get_pixelv(nearest_pixel).a

	var min_x := clampi(floori(pixel_position.x), 0, mask_size.x - 1)
	var min_y := clampi(floori(pixel_position.y), 0, mask_size.y - 1)
	var max_x := clampi(min_x + 1, 0, mask_size.x - 1)
	var max_y := clampi(min_y + 1, 0, mask_size.y - 1)
	var blend_x := clampf(pixel_position.x - float(min_x), 0.0, 1.0)
	var blend_y := clampf(pixel_position.y - float(min_y), 0.0, 1.0)
	var top_alpha := lerpf(mask_image.get_pixel(min_x, min_y).a, mask_image.get_pixel(max_x, min_y).a, blend_x)
	var bottom_alpha := lerpf(mask_image.get_pixel(min_x, max_y).a, mask_image.get_pixel(max_x, max_y).a, blend_x)
	return lerpf(top_alpha, bottom_alpha, blend_y)


func _rebuild_material() -> void:
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = FOG_SHADER
	material = _fog_material
	_apply_shader_parameters()


func _rebuild_mask() -> void:
	var resolution: int = maxi(mask_resolution, 32)
	_active_visibility_sources.clear()
	_visibility_mask_dirty = false
	_visibility_mask_should_clear = true
	_fog_render_mask_dirty = true
	_has_fog_render_mask = false
	_fog_blend_elapsed = 0.0
	_fog_blend_duration = maxf(fog_visual_fade_duration, 0.001)
	_visibility_tick_elapsed = 0.0
	_exploration_mask_version += 1
	_visibility_mask_version += 1
	_exploration_mask_image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	_exploration_mask_image.fill(Color(1.0, 1.0, 1.0, 1.0))
	_exploration_mask_texture = ImageTexture.create_from_image(_exploration_mask_image)
	_visibility_mask_image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	_visibility_mask_image.fill(Color(1.0, 1.0, 1.0, 1.0))
	_visibility_mask_texture = ImageTexture.create_from_image(_visibility_mask_image)
	_fog_previous_mask_image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	_fog_previous_mask_image.fill(Color.TRANSPARENT)
	_fog_previous_mask_texture = ImageTexture.create_from_image(_fog_previous_mask_image)
	_fog_current_mask_image = Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	_fog_current_mask_image.fill(Color.TRANSPARENT)
	_fog_current_mask_texture = ImageTexture.create_from_image(_fog_current_mask_image)
	_update_fog_render_texture()


func _set_world_half_extent(value: float) -> void:
	var extent := maxf(value, 1.0)
	_world_bounds_min = Vector2(-extent, -extent)
	_world_bounds_max = Vector2(extent, extent)
	_apply_shader_parameters()


func _apply_shader_parameters() -> void:
	if _fog_material == null:
		return

	_fog_material.set_shader_parameter("fog_mask_previous", _fog_previous_mask_texture)
	_fog_material.set_shader_parameter("fog_mask_current", _fog_current_mask_texture)
	_fog_material.set_shader_parameter("fog_blend_progress", _get_fog_blend_progress())
	_fog_material.set_shader_parameter("outside_fog_color", unexplored_fog_color)
	_fog_material.set_shader_parameter("world_bounds_min", _world_bounds_min)
	_fog_material.set_shader_parameter("world_bounds_max", _world_bounds_max)


func _sync_camera_uniforms() -> void:
	if _fog_material == null:
		return

	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	_fog_material.set_shader_parameter("camera_position", camera.get_screen_center_position())
	_fog_material.set_shader_parameter("camera_zoom", camera.zoom)
	_fog_material.set_shader_parameter("viewport_size", get_viewport_rect().size)


func _stamp_explored(world_position: Vector2, radius: float) -> bool:
	return _stamp_mask(_exploration_mask_image, world_position, radius)


func _stamp_visible(world_position: Vector2, radius: float) -> void:
	if _stamp_mask(_visibility_mask_image, world_position, radius):
		_visibility_mask_dirty = true
		_fog_render_mask_dirty = true
		_visibility_mask_version += 1


func _stamp_mask(mask_image: Image, world_position: Vector2, radius: float) -> bool:
	if mask_image == null:
		return false

	var mask_size := mask_image.get_size()
	if mask_size.x <= 0 or mask_size.y <= 0:
		return false

	var bounds_size := _world_bounds_max - _world_bounds_min
	if bounds_size.x <= 0.0 or bounds_size.y <= 0.0:
		return false

	var uv := Vector2(
		clampf(inverse_lerp(_world_bounds_min.x, _world_bounds_max.x, world_position.x), 0.0, 1.0),
		clampf(inverse_lerp(_world_bounds_min.y, _world_bounds_max.y, world_position.y), 0.0, 1.0)
	)
	var pixel_center := Vector2(
		uv.x * float(mask_size.x - 1),
		uv.y * float(mask_size.y - 1)
	)

	var stamp_radius_pixels := (
		_resolve_radius(radius)
		/ maxf(bounds_size.x, bounds_size.y)
		* float(maxf(mask_size.x, mask_size.y) - 1)
	)
	var soft_edge_pixels := maxf(stamp_radius_pixels * visible_edge_softness_ratio, 1.0)
	var stamp_outer_radius := stamp_radius_pixels + soft_edge_pixels

	var min_x := maxi(0, floori(pixel_center.x - stamp_outer_radius))
	var max_x := mini(mask_size.x - 1, ceili(pixel_center.x + stamp_outer_radius))
	var min_y := maxi(0, floori(pixel_center.y - stamp_outer_radius))
	var max_y := mini(mask_size.y - 1, ceili(pixel_center.y + stamp_outer_radius))
	var changed := false

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var offset_x := float(x) - pixel_center.x
			var offset_y := float(y) - pixel_center.y
			var distance_squared := offset_x * offset_x + offset_y * offset_y
			if distance_squared > stamp_outer_radius * stamp_outer_radius:
				continue

			var distance := sqrt(distance_squared)
			var reveal_alpha := 0.0
			if soft_edge_pixels <= 0.0:
				reveal_alpha = 0.0 if distance <= stamp_radius_pixels else 1.0
			else:
				var reveal_t := clampf((distance - stamp_radius_pixels) / soft_edge_pixels, 0.0, 1.0)
				reveal_alpha = reveal_t * reveal_t * (3.0 - 2.0 * reveal_t)

			var current_color := mask_image.get_pixel(x, y)
			if reveal_alpha < current_color.a:
				current_color.a = reveal_alpha
				mask_image.set_pixel(x, y, current_color)
				changed = true

	return changed


func _update_exploration_texture() -> void:
	_exploration_mask_version += 1
	_fog_render_mask_dirty = true
	_update_fog_render_texture()


func _update_visibility_texture() -> void:
	if _visibility_mask_texture != null and _visibility_mask_image != null:
		_visibility_mask_texture.update(_visibility_mask_image)


func _update_fog_render_texture() -> void:
	if not _fog_render_mask_dirty:
		return
	if _fog_previous_mask_image == null or _fog_previous_mask_texture == null:
		return
	if _fog_current_mask_image == null or _fog_current_mask_texture == null:
		return
	if _exploration_mask_image == null or _visibility_mask_image == null:
		return

	if _has_fog_render_mask:
		var old_previous_image := _fog_previous_mask_image
		var old_previous_texture := _fog_previous_mask_texture
		_fog_previous_mask_image = _fog_current_mask_image
		_fog_previous_mask_texture = _fog_current_mask_texture
		_fog_current_mask_image = old_previous_image
		_fog_current_mask_texture = old_previous_texture
		_update_fog_mask_shader_textures()

	var render_size := _fog_current_mask_image.get_size()
	for y in range(render_size.y):
		for x in range(render_size.x):
			var exploration_alpha := _exploration_mask_image.get_pixel(x, y).a
			var visibility_alpha := 0.0
			if draw_explored_fog:
				visibility_alpha = _visibility_mask_image.get_pixel(x, y).a
			_fog_current_mask_image.set_pixel(x, y, _get_fog_render_color(exploration_alpha, visibility_alpha))

	if not _has_fog_render_mask:
		_fog_previous_mask_image.copy_from(_fog_current_mask_image)
		_fog_previous_mask_texture.update(_fog_previous_mask_image)

	_fog_current_mask_texture.update(_fog_current_mask_image)
	_fog_render_mask_dirty = false
	_has_fog_render_mask = true
	_fog_blend_elapsed = _fog_blend_duration if _fog_blend_duration <= 0.001 else 0.0
	_apply_fog_blend_progress()


func _get_fog_render_color(exploration_alpha: float, visibility_alpha: float) -> Color:
	var unexplored_alpha := unexplored_fog_color.a * exploration_alpha
	var explored_alpha := explored_fog_color.a * visibility_alpha * (1.0 - exploration_alpha)
	var final_alpha := unexplored_alpha + explored_alpha * (1.0 - unexplored_alpha)
	if final_alpha <= 0.001:
		return Color(0.0, 0.0, 0.0, 0.0)

	var unexplored_weight := unexplored_alpha
	var explored_weight := explored_alpha * (1.0 - unexplored_alpha)
	return Color(
		(
			unexplored_fog_color.r * unexplored_weight
			+ explored_fog_color.r * explored_weight
		) / final_alpha,
		(
			unexplored_fog_color.g * unexplored_weight
			+ explored_fog_color.g * explored_weight
		) / final_alpha,
		(
			unexplored_fog_color.b * unexplored_weight
			+ explored_fog_color.b * explored_weight
		) / final_alpha,
		final_alpha
	)


func _process_fog_visual_blend(delta: float) -> void:
	if _fog_material == null:
		return
	if _fog_blend_elapsed >= _fog_blend_duration:
		return

	_fog_blend_elapsed = minf(_fog_blend_elapsed + maxf(delta, 0.0), _fog_blend_duration)
	_apply_fog_blend_progress()


func _update_fog_mask_shader_textures() -> void:
	if _fog_material == null:
		return

	_fog_material.set_shader_parameter("fog_mask_previous", _fog_previous_mask_texture)
	_fog_material.set_shader_parameter("fog_mask_current", _fog_current_mask_texture)


func _apply_fog_blend_progress() -> void:
	if _fog_material == null:
		return

	_fog_material.set_shader_parameter("fog_blend_progress", _get_fog_blend_progress())


func _get_fog_blend_progress() -> float:
	if _fog_blend_duration <= 0.001:
		return 1.0

	var progress := clampf(_fog_blend_elapsed / _fog_blend_duration, 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)


func _process_visibility_clear_tick(delta: float) -> void:
	var clear_interval := maxf(active_visibility_cooldown, 0.0)
	if clear_interval <= 0.0:
		_visibility_mask_should_clear = true
		return

	_visibility_tick_elapsed += maxf(delta, 0.0)
	if _visibility_tick_elapsed < clear_interval:
		return

	_visibility_tick_elapsed = fmod(_visibility_tick_elapsed, clear_interval)
	_visibility_mask_should_clear = true


func _resolve_radius(radius: float) -> float:
	if radius > 0.0:
		return radius

	return maxf(visible_radius, 1.0)

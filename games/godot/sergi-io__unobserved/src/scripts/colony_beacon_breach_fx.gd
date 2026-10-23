class_name ColonyBeaconBreachFx
extends Node2D

const BEACON_TEXTURE: Texture2D = preload("res://textures/items/colony_beacon_runtime.png")
const SMOKE_SHADER: Shader = preload("res://shaders/explosion_smoke.gdshader")
const DECAL_OPACITY: float = 0.5

@export_range(16.0, 220.0, 1.0) var breach_width: float = 52.0
@export_range(8.0, 240.0, 1.0) var breach_depth: float = 104.0
@export_range(0, 96, 1) var beacon_smoke_amount: int = 34
@export_range(0.2, 4.0, 0.01) var beacon_smoke_lifetime: float = 2.2
@export_range(1.0, 16.0, 0.1) var lifetime: float = 8.0

var _surface_normal: Vector2 = Vector2.UP
var _beacon_rotation: float = 0.0
var _fade_tween: Tween
var _white_texture: Texture2D
var _elapsed: float = 0.0
var _smoke_emit_elapsed: float = 0.0
var _smoke_emit_interval: float = 0.2
var _smoke_origin: Vector2 = Vector2.ZERO
var _is_smoke_emitting: bool = false
var _rng := RandomNumberGenerator.new()
var _smoke_materials: Array[ShaderMaterial] = []
var _tracked_planet: Planet
var _tracked_planet_local_position: Vector2 = Vector2.ZERO
var _tracked_visual_rotation_time: float = 0.0
var _is_tracking_planet_surface: bool = false


func configure(world_position: Vector2, surface_normal: Vector2, beacon_rotation: float, tracked_planet: Planet = null) -> void:
	_rng.randomize()
	_elapsed = 0.0
	_smoke_emit_elapsed = 0.0
	global_position = world_position
	_surface_normal = surface_normal.normalized() if surface_normal != Vector2.ZERO else Vector2.UP
	_beacon_rotation = beacon_rotation
	global_rotation = (-_surface_normal).angle() - Vector2.DOWN.angle()
	_configure_planet_surface_tracking(world_position, tracked_planet)
	_spawn_inserted_beacon()
	_spawn_beacon_smoke()
	_start_lifetime()
	queue_redraw()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	_update_planet_surface_tracking()
	for material in _smoke_materials:
		if material != null:
			material.set_shader_parameter("time", _elapsed)
	_update_smoke_emission(delta)


func _draw() -> void:
	var width := maxf(breach_width, 1.0)
	var depth := maxf(breach_depth, 1.0)
	var half_width := width * 0.5

	var main_crack := PackedVector2Array([
		Vector2(-half_width * 0.16, -depth * 0.54),
		Vector2(half_width * 0.06, -depth * 0.3),
		Vector2(-half_width * 0.22, -depth * 0.12),
		Vector2(half_width * 0.1, depth * 0.06),
		Vector2(-half_width * 0.08, depth * 0.24),
		Vector2(half_width * 0.24, depth * 0.48),
	])
	_draw_main_crack(main_crack, width)
	_draw_branch(Vector2(-half_width * 0.2, -depth * 0.12), [
		Vector2(-half_width * 0.6, -depth * 0.2),
		Vector2(-half_width * 0.78, -depth * 0.36),
		Vector2(-half_width * 0.96, -depth * 0.48),
	], 5.2)
	_draw_branch(Vector2(half_width * 0.04, depth * 0.05), [
		Vector2(half_width * 0.5, -depth * 0.02),
		Vector2(half_width * 0.86, -depth * 0.12),
		Vector2(half_width * 1.1, -depth * 0.1),
	], 4.4)
	_draw_branch(Vector2(-half_width * 0.04, depth * 0.24), [
		Vector2(-half_width * 0.5, depth * 0.34),
		Vector2(-half_width * 0.82, depth * 0.5),
	], 4.8)
	_draw_branch(Vector2(half_width * 0.22, depth * 0.48), [
		Vector2(half_width * 0.02, depth * 0.64),
		Vector2(half_width * 0.18, depth * 0.82),
	], 4.2)


func _draw_main_crack(path: PackedVector2Array, width: float) -> void:
	draw_polyline(path, Color(0.0, 0.0, 0.0, DECAL_OPACITY * 0.34), width * 0.34, true)
	draw_polyline(path, Color(0.0, 0.0, 0.0, DECAL_OPACITY * 0.96), width * 0.16, true)
	draw_polyline(path, Color(0.0, 0.0, 0.0, DECAL_OPACITY), width * 0.08, true)
	for index in range(1, path.size()):
		var previous := path[index - 1]
		var current := path[index]
		var direction := (current - previous).normalized()
		if direction == Vector2.ZERO:
			continue
		var normal := Vector2(-direction.y, direction.x)
		var chip_size := lerpf(width * 0.08, width * 0.18, float(index % 3) / 2.0)
		var chip := PackedVector2Array([
			previous + normal * chip_size * 0.4,
			current - normal * chip_size,
			current + direction * chip_size * 0.45,
			previous - normal * chip_size * 0.6,
		])
		draw_colored_polygon(chip, Color(0.0, 0.0, 0.0, DECAL_OPACITY * 0.88))


func _draw_branch(start: Vector2, points: Array[Vector2], width: float) -> void:
	var crack_points := PackedVector2Array([start])
	for point in points:
		crack_points.append(point)
	draw_polyline(crack_points, Color(0.0, 0.0, 0.0, DECAL_OPACITY * 0.22), width * 2.0, true)
	draw_polyline(crack_points, Color(0.0, 0.0, 0.0, DECAL_OPACITY * 0.92), width, true)


func _spawn_inserted_beacon() -> void:
	var beacon := Sprite2D.new()
	beacon.name = "InsertedBeacon"
	beacon.texture = BEACON_TEXTURE
	beacon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	beacon.region_enabled = true
	beacon.region_rect = Rect2(0.0, 0.0, float(BEACON_TEXTURE.get_width()), float(BEACON_TEXTURE.get_height()) * 0.5)
	beacon.scale = Vector2(0.18, 0.18)
	var exposed_height := float(BEACON_TEXTURE.get_height()) * 0.5 * beacon.scale.y
	beacon.position = Vector2(0.0, -exposed_height * 0.5 + breach_depth * 0.04)
	beacon.rotation = _beacon_rotation - global_rotation
	beacon.z_index = 2
	add_child(beacon)


func _spawn_beacon_smoke() -> void:
	if beacon_smoke_amount <= 0:
		return

	_smoke_origin = Vector2(0.0, -breach_depth * 0.28)
	_smoke_emit_interval = clampf(beacon_smoke_lifetime / maxf(float(beacon_smoke_amount) * 0.42, 1.0), 0.16, 0.36)
	_is_smoke_emitting = true
	_spawn_beacon_smoke_burst(_smoke_origin)


func _update_smoke_emission(delta: float) -> void:
	if not _is_smoke_emitting:
		return

	if _elapsed >= maxf(lifetime - 0.6, 0.1):
		_is_smoke_emitting = false
		return

	_smoke_emit_elapsed += delta
	while _smoke_emit_elapsed >= _smoke_emit_interval:
		_smoke_emit_elapsed -= _smoke_emit_interval
		_spawn_beacon_smoke_puff(_smoke_origin, false)


func _spawn_beacon_smoke_burst(smoke_origin: Vector2) -> void:
	var puff_count := clampi(int(roundf(float(beacon_smoke_amount) * 0.24)), 6, 14)
	for index in range(puff_count):
		_spawn_beacon_smoke_puff(smoke_origin, true, index)


func _spawn_beacon_smoke_puff(smoke_origin: Vector2, is_initial_burst: bool, burst_index: int = 0) -> void:
	var horizontal_range := maxf(breach_width * 0.32, 12.0)
	var vertical_range := maxf(breach_depth * 0.08, 8.0)
	var start_offset := smoke_origin + Vector2(
		_rng.randf_range(-horizontal_range, horizontal_range),
		_rng.randf_range(-vertical_range, vertical_range * 0.45)
	)
	var drift := Vector2(
		_rng.randf_range(-breach_width * 1.05, breach_width * 1.05),
		-_rng.randf_range(breach_depth * 0.42, breach_depth * 1.18)
	)
	var duration_min := beacon_smoke_lifetime * (1.05 if is_initial_burst else 1.35)
	var duration_max := beacon_smoke_lifetime * (1.95 if is_initial_burst else 2.3)
	var duration := _rng.randf_range(duration_min, duration_max)
	var start_scale := Vector2.ONE * _rng.randf_range(0.18, 0.34)
	var end_scale := start_scale * _rng.randf_range(3.4, 5.8)
	var material := _create_smoke_material(Color(
		_rng.randf_range(0.34, 0.5),
		_rng.randf_range(0.32, 0.46),
		_rng.randf_range(0.29, 0.41),
		_rng.randf_range(0.54, 0.78)
	))
	var puff := Sprite2D.new()
	puff.name = "BeaconSmokePuff"
	puff.texture = _get_white_texture()
	puff.centered = true
	puff.material = material
	puff.position = start_offset
	puff.rotation = _rng.randf_range(-PI, PI)
	puff.scale = start_scale
	puff.z_index = 3 + (burst_index % 3)
	add_child(puff)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(puff, "position", start_offset + drift, duration)
	tween.parallel().tween_property(puff, "scale", end_scale, duration)
	tween.parallel().tween_property(puff, "rotation", puff.rotation + _rng.randf_range(-0.55, 0.55), duration)
	tween.parallel().tween_property(material, "shader_parameter/alpha", 0.0, duration)
	tween.tween_callback(Callable(self, "_release_smoke_puff").bind(puff, material))


func _create_smoke_material(smoke_color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SMOKE_SHADER
	material.set_shader_parameter("time", 0.0)
	material.set_shader_parameter("seed", _rng.randf_range(0.0, 1000.0))
	material.set_shader_parameter("alpha", smoke_color.a)
	material.set_shader_parameter("global_fade", 1.0)
	material.set_shader_parameter("smoke_color", smoke_color)
	_smoke_materials.append(material)
	return material


func _release_smoke_puff(puff: Node, material: ShaderMaterial) -> void:
	if material != null:
		_smoke_materials.erase(material)
	if puff != null and is_instance_valid(puff):
		puff.queue_free()


func _get_white_texture() -> Texture2D:
	if _white_texture != null:
		return _white_texture

	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(image)
	return _white_texture


func _start_lifetime() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(maxf(lifetime - 1.0, 0.1))
	_fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	_fade_tween.tween_callback(Callable(self, "queue_free"))


func _configure_planet_surface_tracking(world_position: Vector2, tracked_planet: Planet) -> void:
	_tracked_planet = tracked_planet
	_is_tracking_planet_surface = false
	_tracked_planet_local_position = Vector2.ZERO
	_tracked_visual_rotation_time = 0.0
	if _tracked_planet == null or not is_instance_valid(_tracked_planet):
		return

	_tracked_planet_local_position = _tracked_planet.to_local(world_position)
	_tracked_visual_rotation_time = _tracked_planet.get_visual_rotation_time()
	_is_tracking_planet_surface = true


func _update_planet_surface_tracking() -> void:
	if not _is_tracking_planet_surface:
		return
	if _tracked_planet == null or not is_instance_valid(_tracked_planet):
		_is_tracking_planet_surface = false
		return

	global_position = _tracked_planet.to_global(
		_tracked_planet_local_position
		+ _tracked_planet.get_visual_surface_scroll_offset(_tracked_visual_rotation_time)
	)

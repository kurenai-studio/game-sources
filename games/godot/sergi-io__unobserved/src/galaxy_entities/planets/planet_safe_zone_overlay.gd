class_name PlanetSafeZoneOverlay
extends Sprite2D

const SAFE_ZONE_SHADER: Shader = preload("res://galaxy_entities/planets/planet_safe_zone_overlay.gdshader")
const MAX_SAFE_ZONES: int = 128

@export_range(1024.0, 250000.0, 1.0) var world_half_extent: float = 10000.0:
	get:
		return _world_half_extent
	set(value):
		_world_half_extent = maxf(value, 1.0)
		_sync_bounds()

var _world_half_extent: float = 10000.0
var _planet_field: Node2D
var _shader_material: ShaderMaterial
var _white_texture: ImageTexture


func _ready() -> void:
	centered = true
	_ensure_texture()
	_ensure_shader_material()
	_resolve_bindings()
	_sync_bounds()
	_process_safe_zones()


func _process(_delta: float) -> void:
	_process_safe_zones()


func _resolve_bindings() -> void:
	var parent := get_parent()
	if parent == null:
		return

	_planet_field = parent.get_node_or_null("PlanetField") as Node2D
	if _planet_field == null:
		return

	var resolved_half_extent := _world_half_extent
	if parent.has_method("get_world_radius"):
		resolved_half_extent = maxf(resolved_half_extent, float(parent.call("get_world_radius")))

	if _planet_field.has_method("get"):
		resolved_half_extent = maxf(resolved_half_extent, float(_planet_field.get("spawn_radius")))

	_world_half_extent = resolved_half_extent + 2048.0


func _ensure_texture() -> void:
	if _white_texture != null:
		texture = _white_texture
		return

	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(image)
	texture = _white_texture


func _ensure_shader_material() -> void:
	if _shader_material == null:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = SAFE_ZONE_SHADER
		material = _shader_material
	elif _shader_material.shader == null:
		_shader_material.shader = SAFE_ZONE_SHADER


func _sync_bounds() -> void:
	if _shader_material == null:
		return

	var extent := maxf(_world_half_extent, 1.0)
	scale = Vector2.ONE * extent * 2.0
	_shader_material.set_shader_parameter("world_bounds_min", Vector2(-extent, -extent))
	_shader_material.set_shader_parameter("world_bounds_max", Vector2(extent, extent))


func _process_safe_zones() -> void:
	if _shader_material == null:
		return

	if _planet_field == null:
		_shader_material.set_shader_parameter("safe_zone_count", 0)
		_shader_material.set_shader_parameter("safe_zone_centers", PackedVector4Array())
		_shader_material.set_shader_parameter("safe_zone_colors", PackedVector4Array())
		return

	var centers := PackedVector4Array()
	var colors := PackedVector4Array()

	for child in _planet_field.get_children():
		var planet := child as Planet
		if planet == null or not planet.is_conquered():
			continue

		var safe_zone := planet.planet_safe_zone
		if safe_zone == null:
			continue

		var radius := safe_zone.radius
		var color := safe_zone.get_effective_color()
		if radius <= 0.0 or color.a <= 0.0:
			continue

		centers.append(Vector4(planet.global_position.x, planet.global_position.y, radius, safe_zone.get_reveal_scale()))
		colors.append(Vector4(color.r, color.g, color.b, color.a))

		if centers.size() >= MAX_SAFE_ZONES:
			break

	_shader_material.set_shader_parameter("safe_zone_count", centers.size())
	_shader_material.set_shader_parameter("safe_zone_centers", centers)
	_shader_material.set_shader_parameter("safe_zone_colors", colors)

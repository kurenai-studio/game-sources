class_name Asteroid
extends Node2D

const DAMAGE_IMPACT_FX_SCRIPT: Script = preload("res://scripts/damage_impact_fx.gd")
const ENEMY_GROUP: StringName = &"enemies"
const DUST_TEXTURE_SIZE: int = 64

signal destroyed(xp_amount: int, world_position: Vector2, asteroid: Node2D)

@export var relative_scale: float = 1.0
@export var gui_zoom: float = 1.0
@export_range(1, 999, 1) var hit_points: int = 2
@export_range(0, 999, 1) var xp_reward: int = 1
@export_range(1, 32, 1) var xp_box_count: int = 1
@export_range(0.1, 10.0, 0.05) var explosion_size: float = 0.42
@export_group("Impact Motion")
@export_range(0.0, 1000.0, 1.0) var impact_push_speed: float = 72.0
@export_range(0.0, 1000.0, 1.0) var max_drift_speed: float = 180.0
@export_range(0.0, 20.0, 0.1) var impact_spin_min: float = 1.6
@export_range(0.0, 20.0, 0.1) var impact_spin_max: float = 4.6
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
@export_group("Breakup FX")
@export_range(0.1, 3.0, 0.01) var breakup_duration: float = 0.72
@export_range(0.0, 2000.0, 10.0) var breakup_piece_distance: float = 96.0
@export_range(0.0, 12.0, 0.1) var breakup_piece_spin: float = 4.6
@export_range(0, 192, 1) var breakup_dust_amount: int = 54

static var _dust_texture: ImageTexture

@onready var asteroid_visual: ColorRect = $Asteroid

var _hit_points: int = 2
var _is_destroyed: bool = false
var _fog_alpha: float = 1.0
var _damage_flash_tween: Tween
var _drift_velocity: Vector2 = Vector2.ZERO
var _drift_angular_velocity: float = 0.0


func _ready() -> void:
	_hit_points = maxi(hit_points, 1)
	_is_destroyed = false
	add_to_group(ENEMY_GROUP)
	_make_material_unique()
	_center_visual()


func _process(delta: float) -> void:
	if _is_destroyed:
		return

	position += _drift_velocity * delta
	rotation += _drift_angular_velocity * delta
	var rotation_value := float(asteroid_visual.material.get_shader_parameter("rotation"))
	asteroid_visual.material.set_shader_parameter("rotation", rotation_value + delta * 0.08)


func set_pixels(amount):
	asteroid_visual.material.set_shader_parameter("pixels", amount)
	asteroid_visual.size = Vector2(amount, amount)
	_center_visual()

func set_light(pos):
	asteroid_visual.material.set_shader_parameter("light_origin", pos)

func set_seed(sd):
	var converted_seed = sd%1000/100.0
	asteroid_visual.material.set_shader_parameter("seed", converted_seed)

func set_rotates(r):
	asteroid_visual.material.set_shader_parameter("rotation", r)

func update_time(_t):
	pass

func set_custom_time(t):
	asteroid_visual.material.set_shader_parameter("rotation", t * PI * 2.0)

func set_dither(d):
	asteroid_visual.material.set_shader_parameter("should_dither", d)

func get_dither():
	return asteroid_visual.material.get_shader_parameter("should_dither")

func get_colors():
	return Planet.visual_get_colors_from_shader(asteroid_visual.material)

func set_colors(colors):
	Planet.visual_set_colors_on_shader(asteroid_visual.material, colors)

func randomize_colors():
	var palette: PackedColorArray = _get_random_rock_palette()
	var brightness_jitter := randf_range(-0.06, 0.08)
	var cols := PackedColorArray()
	for color in palette:
		var rock_color: Color = color
		if brightness_jitter > 0.0:
			rock_color = rock_color.lightened(brightness_jitter)
		elif brightness_jitter < 0.0:
			rock_color = rock_color.darkened(-brightness_jitter)

		cols.append(rock_color)

	set_colors(cols)


func _get_random_rock_palette() -> PackedColorArray:
	match randi() % 4:
		0:
			return PackedColorArray([Color(0.58, 0.54, 0.48), Color(0.38, 0.36, 0.32), Color(0.2, 0.19, 0.18)])
		1:
			return PackedColorArray([Color(0.62, 0.58, 0.52), Color(0.43, 0.4, 0.36), Color(0.25, 0.23, 0.21)])
		2:
			return PackedColorArray([Color(0.5, 0.49, 0.46), Color(0.34, 0.34, 0.32), Color(0.18, 0.18, 0.17)])
		_:
			return PackedColorArray([Color(0.55, 0.48, 0.42), Color(0.36, 0.31, 0.27), Color(0.21, 0.18, 0.16)])


func take_damage(amount: int, impact_world_position: Vector2 = Vector2.INF, should_spawn_hit_fx: bool = true) -> int:
	if _is_destroyed or amount <= 0:
		return 0

	var applied_damage := mini(amount, _hit_points)
	if applied_damage <= 0:
		return 0

	_hit_points = maxi(_hit_points - applied_damage, 0)
	if should_spawn_hit_fx:
		var resolved_impact := _resolve_damage_impact_position(impact_world_position)
		_apply_impact_motion(resolved_impact)
		_trigger_damage_flash()
		_spawn_damage_sparks(resolved_impact)
	if _hit_points <= 0:
		_destroy_asteroid()

	return applied_damage


func is_destroyed() -> bool:
	return _is_destroyed


func get_touch_radius() -> float:
	if asteroid_visual == null:
		return 0.0

	var visual_scale: Vector2 = asteroid_visual.get_global_transform().get_scale().abs()
	var scaled_size: Vector2 = asteroid_visual.size * visual_scale
	return maxf(scaled_size.x, scaled_size.y) * 0.5


func get_damage_impact_radius() -> float:
	return get_touch_radius()


func get_damage_impact_position(source_world_position: Vector2 = Vector2.INF) -> Vector2:
	if not source_world_position.is_finite():
		return global_position

	var to_source := source_world_position - global_position
	if to_source == Vector2.ZERO:
		return global_position

	return global_position + to_source.normalized() * get_touch_radius() * 0.75


func set_fog_presentation_visible(is_visible: bool) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0)


func set_fog_presentation_alpha(alpha: float) -> void:
	_fog_alpha = clampf(alpha, 0.0, 1.0)
	visible = _fog_alpha > 0.01 and not _is_destroyed
	modulate.a = _fog_alpha


func get_xp_box_count() -> int:
	return maxi(xp_box_count, 1)


func _make_material_unique() -> void:
	if asteroid_visual == null or asteroid_visual.material == null:
		return

	asteroid_visual.material = asteroid_visual.material.duplicate()


func _center_visual() -> void:
	if asteroid_visual == null:
		return

	asteroid_visual.position = -asteroid_visual.size * 0.5


func _trigger_damage_flash() -> void:
	if asteroid_visual == null:
		return
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	asteroid_visual.modulate = Color(1.45, 0.86, 0.58, 1.0)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(asteroid_visual, "modulate", Color.WHITE, 0.14)


func _apply_impact_motion(impact_world_position: Vector2) -> void:
	var push_direction := global_position - impact_world_position
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	push_direction = push_direction.normalized()

	_drift_velocity += push_direction * maxf(impact_push_speed, 0.0)
	if _drift_velocity.length() > max_drift_speed:
		_drift_velocity = _drift_velocity.normalized() * maxf(max_drift_speed, 0.0)

	var spin_min := minf(impact_spin_min, impact_spin_max)
	var spin_max := maxf(impact_spin_min, impact_spin_max)
	var spin_direction := 1.0 if randf() >= 0.5 else -1.0
	var impact_offset := global_position - impact_world_position
	if impact_offset.length_squared() > 0.001:
		spin_direction = signf(push_direction.cross(impact_offset.normalized()))
		if is_zero_approx(spin_direction):
			spin_direction = 1.0 if randf() >= 0.5 else -1.0
	_drift_angular_velocity += spin_direction * randf_range(spin_min, spin_max)


func _resolve_damage_impact_position(impact_world_position: Vector2) -> Vector2:
	if impact_world_position.is_finite():
		return impact_world_position

	return get_damage_impact_position(global_position + Vector2.RIGHT.rotated(global_rotation) * get_damage_impact_radius())


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
		_fog_alpha > 0.01,
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

	return Vector2.RIGHT.rotated(global_rotation)


func _destroy_asteroid() -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	_spawn_breakup_fx()
	destroyed.emit(maxi(xp_reward, 0), global_position, self)
	queue_free()


func _spawn_breakup_fx() -> void:
	if asteroid_visual == null:
		return

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	var breakup_root := Node2D.new()
	breakup_root.name = "AsteroidBreakup"
	breakup_root.global_position = global_position
	breakup_root.global_rotation = global_rotation
	breakup_root.modulate.a = _fog_alpha
	fx_layer.add_child(breakup_root)

	var split_direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	_create_breakup_piece(breakup_root, split_direction, -1.0)
	_create_breakup_piece(breakup_root, -split_direction, 1.0)
	_spawn_breakup_dust(breakup_root, split_direction)
	_queue_breakup_cleanup(breakup_root)


func _create_breakup_piece(breakup_root: Node2D, direction: Vector2, spin_sign: float) -> void:
	var piece := Node2D.new()
	piece.name = "AsteroidPiece"
	breakup_root.add_child(piece)

	var visual := asteroid_visual.duplicate() as ColorRect
	if visual == null:
		return
	if visual.material != null:
		visual.material = visual.material.duplicate()
	visual.size = asteroid_visual.size * randf_range(0.52, 0.66)
	visual.position = -visual.size * 0.5
	visual.rotation = randf_range(-0.25, 0.25)
	visual.modulate = Color.WHITE
	piece.add_child(visual)

	var travel_distance := maxf(breakup_piece_distance, get_touch_radius() * 0.65) * randf_range(0.8, 1.25)
	var tween := piece.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", direction.normalized() * travel_distance, breakup_duration)
	tween.tween_property(piece, "rotation", spin_sign * breakup_piece_spin * randf_range(0.75, 1.2), breakup_duration)
	tween.tween_property(piece, "scale", Vector2.ONE * randf_range(0.72, 0.86), breakup_duration)
	tween.tween_property(visual, "modulate:a", 0.0, breakup_duration)


func _spawn_breakup_dust(breakup_root: Node2D, split_direction: Vector2) -> void:
	if breakup_dust_amount <= 0:
		return

	var safe_direction := split_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT.rotated(randf_range(0.0, TAU))

	var core_amount := maxi(int(round(float(breakup_dust_amount) * 0.36)), 1)
	var sheet_amount := maxi(int(round(float(breakup_dust_amount) * 0.24)), 1)
	var haze_amount := maxi(breakup_dust_amount - core_amount - sheet_amount * 2, 1)
	var radius := get_touch_radius()

	_spawn_dust_layer(
		breakup_root,
		"AsteroidRockDustCore",
		Vector2.RIGHT.rotated(randf_range(0.0, TAU)),
		core_amount,
		maxf(breakup_duration * 0.85, 0.12),
		0.96,
		360.0,
		maxf(radius * 0.14, 7.0),
		18.0,
		145.0,
		145.0,
		320.0,
		0.18,
		0.74,
		Color(0.42, 0.39, 0.34, 0.74 * _fog_alpha),
		74
	)
	_spawn_dust_layer(
		breakup_root,
		"AsteroidRockDustSheetA",
		safe_direction,
		sheet_amount,
		maxf(breakup_duration * 0.75, 0.12),
		0.9,
		74.0,
		maxf(radius * 0.08, 4.0),
		90.0,
		330.0,
		180.0,
		420.0,
		0.08,
		0.36,
		Color(0.53, 0.5, 0.44, 0.82 * _fog_alpha),
		78
	)
	_spawn_dust_layer(
		breakup_root,
		"AsteroidRockDustSheetB",
		-safe_direction,
		sheet_amount,
		maxf(breakup_duration * 0.75, 0.12),
		0.9,
		74.0,
		maxf(radius * 0.08, 4.0),
		90.0,
		330.0,
		180.0,
		420.0,
		0.08,
		0.36,
		Color(0.5, 0.47, 0.41, 0.82 * _fog_alpha),
		78
	)
	_spawn_dust_layer(
		breakup_root,
		"AsteroidFineDustHaze",
		Vector2.RIGHT.rotated(randf_range(0.0, TAU)),
		haze_amount,
		maxf(breakup_duration * 1.45, 0.2),
		0.68,
		360.0,
		maxf(radius * 0.22, 11.0),
		8.0,
		92.0,
		70.0,
		180.0,
		0.58,
		1.95,
		Color(0.33, 0.31, 0.28, 0.32 * _fog_alpha),
		58
	)


func _spawn_dust_layer(
	breakup_root: Node2D,
	layer_name: String,
	direction: Vector2,
	amount: int,
	lifetime: float,
	explosiveness: float,
	spread_degrees: float,
	emission_radius: float,
	velocity_min: float,
	velocity_max: float,
	damping_min: float,
	damping_max: float,
	scale_min: float,
	scale_max: float,
	dust_color: Color,
	z_index_value: int
) -> void:
	var dust := CPUParticles2D.new()
	dust.name = layer_name
	dust.texture = _get_dust_texture()
	dust.z_index = z_index_value
	dust.visible = _fog_alpha > 0.01
	dust.one_shot = true
	dust.amount = maxi(amount, 1)
	dust.lifetime = maxf(lifetime, 0.05)
	dust.explosiveness = clampf(explosiveness, 0.0, 1.0)
	dust.randomness = 0.86
	dust.local_coords = false
	dust.draw_order = CPUParticles2D.DRAW_ORDER_LIFETIME
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	dust.emission_sphere_radius = maxf(emission_radius, 0.0)
	dust.direction = direction.normalized()
	if dust.direction == Vector2.ZERO:
		dust.direction = Vector2.RIGHT
	dust.spread = clampf(spread_degrees, 0.0, 360.0)
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = maxf(velocity_min, 0.0)
	dust.initial_velocity_max = maxf(velocity_max, dust.initial_velocity_min)
	dust.damping_min = maxf(damping_min, 0.0)
	dust.damping_max = maxf(damping_max, dust.damping_min)
	dust.scale_amount_min = maxf(scale_min, 0.01)
	dust.scale_amount_max = maxf(scale_max, dust.scale_amount_min)
	dust.angular_velocity_min = -260.0
	dust.angular_velocity_max = 260.0
	dust.color = dust_color
	breakup_root.add_child(dust)
	dust.emitting = true
	dust.restart()


static func _get_dust_texture() -> ImageTexture:
	if _dust_texture != null:
		return _dust_texture

	var image := Image.create(DUST_TEXTURE_SIZE, DUST_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var texture_center := (float(DUST_TEXTURE_SIZE) - 1.0) * 0.5
	for y in range(DUST_TEXTURE_SIZE):
		for x in range(DUST_TEXTURE_SIZE):
			var uv := Vector2(
				(float(x) - texture_center) / texture_center,
				(float(y) - texture_center) / texture_center
			)
			var radius := uv.length()
			var edge := pow(clampf(1.0 - radius, 0.0, 1.0), 2.6)
			var grain := randf_range(0.64, 1.0)
			var chip := 1.0 if absf(uv.x * 0.85 + uv.y * 0.42) < 0.34 else 0.72
			var alpha := edge * grain * chip
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	_dust_texture = ImageTexture.create_from_image(image)
	return _dust_texture


func _queue_breakup_cleanup(breakup_root: Node2D) -> void:
	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = maxf(breakup_duration * 1.45, 0.2)
	cleanup_timer.timeout.connect(breakup_root.queue_free)
	breakup_root.add_child(cleanup_timer)
	cleanup_timer.start()


func _get_fx_layer() -> Node2D:
	var scene_root := get_tree().current_scene if get_tree() != null else null
	if scene_root != null:
		var root_fx_layer := scene_root.find_child("FXLayer", true, false) as Node2D
		if root_fx_layer != null:
			return root_fx_layer

	var parent := get_parent()
	if parent != null:
		var fx_layer := parent.find_child("FXLayer", true, false) as Node2D
		if fx_layer != null:
			return fx_layer
		var node_parent := parent as Node2D
		if node_parent != null:
			return node_parent

	return self

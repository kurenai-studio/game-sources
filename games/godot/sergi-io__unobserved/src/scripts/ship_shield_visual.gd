class_name ShipShieldVisual
extends Sprite2D

const SHIELD_SHADER: Shader = preload("res://shaders/ship_shield.gdshader")
const SHIELD_TEXTURE_PATH: String = "res://textures/items/shield.png"

@export_group("Motion")
@export_range(1.0, 60.0, 0.1) var rotation_follow_speed: float = 18.0
@export_range(0.0, 1.0, 0.01) var speed_oval_stretch: float = 0.18
@export_range(0.0, 0.5, 0.01) var speed_oval_squeeze: float = 0.06
@export_range(1.0, 60.0, 0.1) var bubble_response: float = 8.5
@export_range(0.0, 20.0, 0.1) var bubble_damping: float = 10.0
@export_range(0.0, 16.0, 0.1) var bubble_impulse: float = 0.45
@export_range(0.0, 0.5, 0.01) var bubble_wobble_amount: float = 0.015
@export_range(0.0, 40.0, 0.1) var bubble_wobble_speed: float = 19.0
@export_range(0.0, 20.0, 0.1) var bubble_wobble_decay: float = 4.8
@export_group("Impact")
@export_range(0.0, 64.0, 0.1) var hit_bounce_impulse: float = 12.0
@export_range(0.0, 60.0, 0.1) var hit_bounce_response: float = 24.0
@export_range(0.0, 30.0, 0.1) var hit_bounce_damping: float = 20.0
@export_range(0.0, 1.0, 0.01) var hit_wobble_strength: float = 0.1
@export_range(0.02, 1.0, 0.01) var hit_ring_duration: float = 0.32
@export var hit_flash_color: Color = Color(1.0, 0.42, 0.16, 1.0)
@export var normal_shield_color: Color = Color(0.08, 0.85, 1.0, 1.0)

var _base_position: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _rotation_follow: float = 0.0
var _oval_scale: Vector2 = Vector2.ONE
var _oval_velocity: Vector2 = Vector2.ZERO
var _hit_offset: Vector2 = Vector2.ZERO
var _hit_velocity: Vector2 = Vector2.ZERO
var _previous_speed_ratio: float = 0.0
var _bubble_wobble_phase: float = 0.0
var _bubble_wobble_strength: float = 0.0
var _noise_texture: Texture2D
var _shield_texture: Texture2D
var _hit_tween: Tween


func _ready() -> void:
	setup()


func setup() -> void:
	_base_position = position
	_base_scale = scale
	_rotation_follow = global_rotation
	_oval_scale = Vector2.ONE
	_oval_velocity = Vector2.ZERO
	_hit_offset = Vector2.ZERO
	_hit_velocity = Vector2.ZERO
	_previous_speed_ratio = 0.0
	_bubble_wobble_phase = 0.0
	_bubble_wobble_strength = 0.0
	_setup_material()
	visible = false


func update_presentation(
	shield_level: int,
	current_speed: float,
	effective_move_speed: float,
	presentation_alpha: float,
	delta: float,
	is_destroyed: bool,
	target_rotation: float,
	elapsed_time: float
) -> void:
	if delta < 0.0:
		_rotation_follow = target_rotation
	else:
		var follow_weight := clampf(delta * rotation_follow_speed, 0.0, 1.0)
		_rotation_follow = lerp_angle(_rotation_follow, target_rotation, follow_weight)
	global_rotation = _rotation_follow

	var shield_visible := shield_level > 0 and not is_destroyed
	visible = shield_visible
	if not shield_visible:
		return

	var shield_scale_factor := 1.0 + maxf(float(shield_level - 1), 0.0) * 0.05
	var speed_ratio := clampf(current_speed / maxf(effective_move_speed, 1.0), 0.0, 1.0)
	var target_oval_scale := Vector2(
		1.0 - speed_oval_squeeze * speed_ratio,
		1.0 + speed_oval_stretch * speed_ratio
	)
	_update_bubble_scale(target_oval_scale, speed_ratio, delta)
	_update_hit_bounce(delta)
	position = _base_position + _hit_offset
	scale = _base_scale * shield_scale_factor * _oval_scale * _get_wobble_scale()

	var shield_material := material as ShaderMaterial
	if shield_material != null:
		shield_material.set_shader_parameter("time", elapsed_time)
		shield_material.set_shader_parameter("intensity", (1.04 + float(shield_level - 1) * 0.12) * presentation_alpha)
		shield_material.set_shader_parameter("base_alpha", 0.8 * presentation_alpha)
		shield_material.set_shader_parameter("glow_strength", 1.05 + float(shield_level - 1) * 0.12)


func play_hit(impact_world_position: Vector2, impact_strength: float = 1.0) -> void:
	var shield_material := material as ShaderMaterial
	if shield_material == null:
		_setup_material()
		shield_material = material as ShaderMaterial
	if shield_material == null:
		return

	var hit_uv := _get_hit_uv(impact_world_position)
	var hit_direction := _get_local_hit_direction(impact_world_position)
	var safe_strength := maxf(impact_strength, 0.1)
	_hit_velocity -= hit_direction * hit_bounce_impulse * safe_strength
	_oval_velocity += Vector2(absf(hit_direction.x), absf(hit_direction.y)) * hit_wobble_strength * safe_strength
	_bubble_wobble_strength = minf(maxf(_bubble_wobble_strength, hit_wobble_strength * safe_strength), bubble_wobble_amount)
	_bubble_wobble_phase = 0.0

	if _hit_tween != null:
		_hit_tween.kill()

	shield_material.set_shader_parameter("hit_position", hit_uv)
	shield_material.set_shader_parameter("hit_color", hit_flash_color)
	shield_material.set_shader_parameter("hit_progress", 0.0)
	shield_material.set_shader_parameter("shield_color", hit_flash_color)
	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.set_trans(Tween.TRANS_SINE)
	_hit_tween.set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(shield_material, "shader_parameter/hit_progress", 1.0, maxf(hit_ring_duration, 0.02))
	_hit_tween.tween_property(shield_material, "shader_parameter/shield_color", normal_shield_color, maxf(hit_ring_duration, 0.02))


func _setup_material() -> void:
	if material == null or not (material is ShaderMaterial):
		var shield_material := ShaderMaterial.new()
		shield_material.shader = SHIELD_SHADER
		material = shield_material
	else:
		var existing_material := material as ShaderMaterial
		if existing_material.shader == null:
			existing_material.shader = SHIELD_SHADER

	if texture == null:
		texture = _load_shield_texture()

	var shield_material := material as ShaderMaterial
	if shield_material != null:
		shield_material.set_shader_parameter("shield_color", normal_shield_color)
		shield_material.set_shader_parameter("noise_texture", _load_noise_texture())
		shield_material.set_shader_parameter("wave_height", 0.16)
		shield_material.set_shader_parameter("wave_speed", Vector2(0.11, 0.07))
		shield_material.set_shader_parameter("fresnel_power", 2.4)
		shield_material.set_shader_parameter("center_visibility", 0.035)
		shield_material.set_shader_parameter("hit_position", Vector2(0.5, 0.5))
		shield_material.set_shader_parameter("hit_progress", 0.0)
		shield_material.set_shader_parameter("hit_color", Color(0.95, 1.0, 1.0, 1.0))
		shield_material.set_shader_parameter("hit_radius", 0.48)
		shield_material.set_shader_parameter("hit_ring_width", 0.05)
		shield_material.set_shader_parameter("hit_push_force", 0.5)
		shield_material.set_shader_parameter("pulse_speed", 3.0)
		shield_material.set_shader_parameter("pulse_amount", 0.09)
		shield_material.set_shader_parameter("noise_scale", 7.5)
		shield_material.set_shader_parameter("force_ring_strength", 0.95)
		shield_material.set_shader_parameter("force_ring_count", 3.0)


func _update_hit_bounce(delta: float) -> void:
	if delta <= 0.0:
		_hit_offset = Vector2.ZERO
		_hit_velocity = Vector2.ZERO
		position = _base_position
		return

	var safe_delta := minf(delta, 0.05)
	var response := maxf(hit_bounce_response, 1.0)
	var spring_force := -_hit_offset * (response * response)
	_hit_velocity += spring_force * safe_delta
	_hit_velocity *= exp(-maxf(hit_bounce_damping, 0.0) * safe_delta)
	_hit_offset += _hit_velocity * safe_delta
	if _hit_offset.length_squared() < 0.001 and _hit_velocity.length_squared() < 0.001:
		_hit_offset = Vector2.ZERO
		_hit_velocity = Vector2.ZERO


func _get_hit_uv(impact_world_position: Vector2) -> Vector2:
	if texture == null or not impact_world_position.is_finite():
		return Vector2(0.5, 0.5)

	var rect := get_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(0.5, 0.5)

	var local_hit := to_local(impact_world_position)
	return Vector2(
		clampf((local_hit.x - rect.position.x) / rect.size.x, 0.0, 1.0),
		clampf((local_hit.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	)


func _get_local_hit_direction(impact_world_position: Vector2) -> Vector2:
	if not impact_world_position.is_finite():
		return Vector2.UP

	var local_hit := to_local(impact_world_position)
	if local_hit.length_squared() <= 0.001:
		return Vector2.UP

	return local_hit.normalized()


func _update_bubble_scale(target_oval_scale: Vector2, speed_ratio: float, delta: float) -> void:
	if delta <= 0.0:
		_oval_scale = target_oval_scale
		_oval_velocity = Vector2.ZERO
		_previous_speed_ratio = speed_ratio
		_bubble_wobble_phase = 0.0
		_bubble_wobble_strength = 0.0
		return

	var safe_delta := minf(delta, 0.05)
	var speed_ratio_delta := speed_ratio - _previous_speed_ratio
	if not is_zero_approx(speed_ratio_delta):
		var impulse_strength := absf(speed_ratio_delta) * bubble_impulse
		var impulse_direction := 1.0 if speed_ratio_delta > 0.0 else -1.0
		_oval_velocity += Vector2(-speed_oval_squeeze, speed_oval_stretch) * impulse_strength * impulse_direction
		_bubble_wobble_strength = minf(
			maxf(_bubble_wobble_strength, absf(speed_ratio_delta) * bubble_wobble_amount),
			bubble_wobble_amount
		)
		_bubble_wobble_phase = 0.0
		_previous_speed_ratio = speed_ratio

	var response := maxf(bubble_response, 1.0)
	var spring_force := (_oval_scale - target_oval_scale) * -(response * response)
	_oval_velocity += spring_force * safe_delta
	_oval_velocity *= exp(-maxf(bubble_damping, 0.0) * safe_delta)
	_oval_scale += _oval_velocity * safe_delta
	_oval_scale.x = clampf(_oval_scale.x, 0.32, 1.65)
	_oval_scale.y = clampf(_oval_scale.y, 0.5, 2.65)

	_bubble_wobble_phase += bubble_wobble_speed * safe_delta
	_bubble_wobble_strength *= exp(-maxf(bubble_wobble_decay, 0.0) * safe_delta)
	if _bubble_wobble_strength < 0.001:
		_bubble_wobble_strength = 0.0


func _get_wobble_scale() -> Vector2:
	if _bubble_wobble_strength <= 0.0:
		return Vector2.ONE

	var wobble := sin(_bubble_wobble_phase) * _bubble_wobble_strength
	return Vector2(1.0 + wobble, 1.0 - wobble)


func _load_noise_texture() -> Texture2D:
	if _noise_texture != null:
		return _noise_texture

	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var value := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			image.set_pixel(x, y, Color(value, value, value, 1.0))

	_noise_texture = ImageTexture.create_from_image(image)
	return _noise_texture


func _load_shield_texture() -> Texture2D:
	if _shield_texture != null:
		return _shield_texture

	var loaded_texture := load(SHIELD_TEXTURE_PATH) as Texture2D
	if loaded_texture == null:
		return null

	_shield_texture = loaded_texture
	return _shield_texture

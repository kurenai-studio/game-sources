extends RefCounted
class_name DamageImpactFx

const SPARK_TEXTURE_SIZE: int = 48

static var _spark_texture: ImageTexture


static func get_sprite_impact_position(sprite: Sprite2D, source_world_position: Vector2, fallback_world_position: Vector2) -> Vector2:
	if sprite == null or sprite.texture == null or not source_world_position.is_finite():
		return fallback_world_position

	var sprite_rect := sprite.get_rect()
	if sprite_rect.size == Vector2.ZERO:
		return fallback_world_position

	var source_local := sprite.to_local(source_world_position)
	var sprite_center := sprite_rect.get_center()
	var to_center := sprite_center - source_local
	if to_center.length_squared() <= 0.001:
		return sprite.to_global(sprite_center)

	var texture_image := sprite.texture.get_image()
	if texture_image != null:
		var scan_direction := to_center.normalized()
		var scan_steps := maxi(int(ceil(to_center.length())), 1)
		var image_width := texture_image.get_width()
		var image_height := texture_image.get_height()
		for step in range(scan_steps + 1):
			var sample_position := source_local + scan_direction * float(step)
			if not sprite_rect.has_point(sample_position):
				continue

			var image_position := sample_position - sprite_rect.position
			var pixel_x := clampi(int(round(image_position.x)), 0, image_width - 1)
			var pixel_y := clampi(int(round(image_position.y)), 0, image_height - 1)
			if texture_image.get_pixel(pixel_x, pixel_y).a > 0.08:
				return sprite.to_global(sample_position)

	return sprite.to_global(_get_ellipse_impact_position(source_local, sprite_rect))


static func spawn_sparks(
	fx_layer: Node2D,
	impact_world_position: Vector2,
	impact_direction: Vector2,
	is_visible: bool,
	amount: int,
	lifetime: float,
	explosiveness: float,
	randomness: float,
	spread_degrees: float,
	velocity_min: float,
	velocity_max: float,
	damping: float,
	spark_color: Color
) -> void:
	if fx_layer == null or not impact_world_position.is_finite():
		return

	var safe_direction := impact_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	var sparks := CPUParticles2D.new()
	_configure_sparks(
		sparks,
		"DamageSparks",
		spark_color,
		amount,
		lifetime,
		explosiveness,
		randomness,
		spread_degrees,
		velocity_min,
		velocity_max,
		damping,
		0.18,
		0.56,
		3.2,
		is_visible
	)
	fx_layer.add_child(sparks)
	_place_and_start(sparks, impact_world_position, safe_direction)
	_queue_cleanup(sparks)

	var pin_sparks := CPUParticles2D.new()
	_configure_sparks(
		pin_sparks,
		"DamagePinSparks",
		Color(0.68, 0.82, 1.0, 0.72),
		maxi(int(round(float(amount) * 0.45)), 4),
		lifetime * 1.2,
		explosiveness,
		randomness,
		spread_degrees,
		velocity_min * 0.55,
		velocity_max * 0.7,
		damping,
		0.075,
		0.24,
		5.2,
		is_visible
	)
	fx_layer.add_child(pin_sparks)
	_place_and_start(pin_sparks, impact_world_position, safe_direction)
	_queue_cleanup(pin_sparks)


static func _configure_sparks(
	sparks: CPUParticles2D,
	spark_name: String,
	spark_color: Color,
	spark_amount: int,
	spark_lifetime: float,
	explosiveness: float,
	randomness: float,
	spread_degrees: float,
	velocity_min: float,
	velocity_max: float,
	damping: float,
	scale_min: float,
	scale_max: float,
	emission_radius: float,
	is_visible: bool
) -> void:
	sparks.name = spark_name
	sparks.texture = _get_spark_texture()
	sparks.z_index = 64
	sparks.visible = is_visible
	sparks.one_shot = true
	sparks.explosiveness = clampf(explosiveness, 0.0, 1.0)
	sparks.randomness = clampf(randomness, 0.0, 1.0)
	sparks.local_coords = false
	sparks.draw_order = CPUParticles2D.DRAW_ORDER_LIFETIME
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = maxf(emission_radius, 0.0)
	sparks.amount = maxi(spark_amount, 1)
	sparks.lifetime = maxf(spark_lifetime, 0.05)
	sparks.spread = clampf(spread_degrees, 0.0, 360.0)
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = maxf(velocity_min, 0.0)
	sparks.initial_velocity_max = maxf(velocity_max, sparks.initial_velocity_min)
	sparks.angular_velocity_min = -540.0
	sparks.angular_velocity_max = 540.0
	sparks.damping_min = maxf(damping * 0.75, 0.0)
	sparks.damping_max = maxf(damping * 1.25, sparks.damping_min)
	sparks.scale_amount_min = maxf(scale_min, 0.01)
	sparks.scale_amount_max = maxf(scale_max, sparks.scale_amount_min)
	sparks.color = spark_color
	sparks.emitting = true


static func _place_and_start(sparks: CPUParticles2D, impact_world_position: Vector2, impact_direction: Vector2) -> void:
	sparks.global_position = impact_world_position
	sparks.global_rotation = impact_direction.angle()
	sparks.restart()


static func _get_spark_texture() -> ImageTexture:
	if _spark_texture != null:
		return _spark_texture

	var image := Image.create(SPARK_TEXTURE_SIZE, SPARK_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var texture_center := (float(SPARK_TEXTURE_SIZE) - 1.0) * 0.5
	for y in range(SPARK_TEXTURE_SIZE):
		for x in range(SPARK_TEXTURE_SIZE):
			var uv := Vector2(
				(float(x) - texture_center) / texture_center,
				(float(y) - texture_center) / texture_center
			)
			var abs_uv := uv.abs()
			var radius := uv.length()
			var diamond := clampf(1.0 - (abs_uv.x + abs_uv.y) * 2.15, 0.0, 1.0)
			var horizontal := clampf(1.0 - abs_uv.x / 0.98, 0.0, 1.0) * clampf(1.0 - abs_uv.y / 0.075, 0.0, 1.0)
			var vertical := clampf(1.0 - abs_uv.y / 0.98, 0.0, 1.0) * clampf(1.0 - abs_uv.x / 0.095, 0.0, 1.0)
			var glow := clampf(1.0 - radius, 0.0, 1.0)
			var alpha := clampf(
				pow(diamond, 1.45) * 0.95
				+ pow(maxf(horizontal, vertical), 1.35) * 0.55
				+ pow(glow, 3.4) * 0.34,
				0.0,
				1.0
			)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	_spark_texture = ImageTexture.create_from_image(image)
	return _spark_texture


static func _get_ellipse_impact_position(source_local_position: Vector2, sprite_rect: Rect2) -> Vector2:
	var sprite_center := sprite_rect.get_center()
	var local_direction := source_local_position - sprite_center
	if local_direction.length_squared() <= 0.001:
		return sprite_center

	local_direction = local_direction.normalized()
	var half_size := sprite_rect.size * 0.5
	if half_size.x <= 0.0 or half_size.y <= 0.0:
		return sprite_center

	var denominator := sqrt(
		(local_direction.x * local_direction.x) / (half_size.x * half_size.x)
		+ (local_direction.y * local_direction.y) / (half_size.y * half_size.y)
	)
	if denominator <= 0.001:
		return sprite_center

	return sprite_center + local_direction / denominator


static func _queue_cleanup(sparks: CPUParticles2D) -> void:
	var cleanup_timer := Timer.new()
	cleanup_timer.one_shot = true
	cleanup_timer.wait_time = maxf(sparks.lifetime + 0.45, 0.1)
	cleanup_timer.timeout.connect(sparks.queue_free)
	sparks.add_child(cleanup_timer)
	cleanup_timer.start()

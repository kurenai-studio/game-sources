class_name WormholeDashArtifact
extends ShipArtifact

const SHIP_DISTORTION_SHADER: Shader = preload("res://shaders/ship_distortion.gdshader")
const PARTICLE_TEXTURE: Texture2D = preload("res://textures/star_particle.svg")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const TRAIL_COUNT: int = 3
const TRAIL_OPACITIES: Array[float] = [0.18, 0.34, 0.54]
const RING_POINT_COUNT: int = 64

@export_range(0.0, 5000.0, 10.0) var dash_distance: float = 1050.0
@export_range(0.0, 8.0, 0.1) var continuation_target_multiplier: float = 2.0
@export_range(0.05, 2.0, 0.01) var trail_duration: float = 0.62
@export_range(0.05, 2.0, 0.01) var launch_fx_duration: float = 0.56
@export_range(0.1, 8.0, 0.05) var ship_warp_duration: float = 2.0
@export_range(0.0, 1.0, 0.01) var ship_warp_strength: float = 1.0
@export_range(0.1, 8.0, 0.05) var ship_holo_duration: float = 3.0
@export_range(0.1, 8.0, 0.05) var ship_holo_fade_out_duration: float = 2.0
@export_range(0.0, 1.0, 0.01) var ship_holo_strength: float = 1.0


func _init() -> void:
	item_kind = &"wormhole_dash"
	cooldown_seconds = 4.0


func get_upgrade_preview() -> Dictionary:
	var safe_dash_distance := maxf(dash_distance, 0.0)
	var safe_cooldown_seconds := get_cooldown_duration()
	return {
		"title": "Wormhole Dash",
		"summary": "Artifact dash: %s px\nCooldown: %s" % [_format_number(safe_dash_distance, 0), _format_duration(safe_cooldown_seconds)],
		"tooltip": "Unlocks an Artifact Hud button.\nActivating it jumps the ship %s px forward, clamped inside the galaxy bounds.\nCooldown: %s" % [
			_format_number(safe_dash_distance, 0),
			_format_duration(safe_cooldown_seconds),
		],
	}


func activate() -> bool:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return false

	var safe_dash_distance := maxf(dash_distance, 0.0)
	if is_zero_approx(safe_dash_distance):
		return false

	var dash_direction := Vector2.RIGHT
	if owner_ship.has_method("get_artifact_forward_direction"):
		dash_direction = owner_ship.call("get_artifact_forward_direction") as Vector2
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
	dash_direction = dash_direction.normalized()

	var previous_position := owner_ship.global_position
	var target_position := previous_position + dash_direction * safe_dash_distance
	if owner_ship.has_method("clamp_artifact_world_position"):
		target_position = owner_ship.call("clamp_artifact_world_position", target_position) as Vector2
	if target_position.is_equal_approx(previous_position):
		return false

	owner_ship.global_position = target_position
	GAME_SFX.play(owner_ship, GAME_SFX.CUE_DASH, -1.0, randf_range(0.97, 1.03))
	_play_dash_fx(previous_position, target_position, dash_direction)
	if owner_ship.has_method("play_artifact_ship_warp"):
		owner_ship.call(
			"play_artifact_ship_warp",
			dash_direction,
			ship_warp_duration,
			ship_warp_strength,
			ship_holo_duration,
			ship_holo_fade_out_duration,
			ship_holo_strength
		)
	if owner_ship.has_method("continue_artifact_movement"):
		var continuation_distance := safe_dash_distance * maxf(continuation_target_multiplier, 0.0)
		owner_ship.call("continue_artifact_movement", dash_direction, target_position, continuation_distance)
	if owner_ship.has_method("pulse_artifact_activation"):
		owner_ship.call("pulse_artifact_activation")
	return true


func get_tunables() -> Dictionary:
	var tunables := super.get_tunables()
	tunables["dash_distance"] = dash_distance
	tunables["continuation_target_multiplier"] = continuation_target_multiplier
	tunables["trail_duration"] = trail_duration
	tunables["launch_fx_duration"] = launch_fx_duration
	tunables["ship_warp_duration"] = ship_warp_duration
	tunables["ship_warp_strength"] = ship_warp_strength
	tunables["ship_holo_duration"] = ship_holo_duration
	tunables["ship_holo_fade_out_duration"] = ship_holo_fade_out_duration
	tunables["ship_holo_strength"] = ship_holo_strength
	return tunables


func apply_tunables(tunables: Dictionary) -> void:
	super.apply_tunables(tunables)
	if tunables.has("dash_distance"):
		dash_distance = maxf(float(tunables.get("dash_distance", dash_distance)), 0.0)
	if tunables.has("continuation_target_multiplier"):
		continuation_target_multiplier = maxf(float(tunables.get("continuation_target_multiplier", continuation_target_multiplier)), 0.0)
	if tunables.has("trail_duration"):
		trail_duration = maxf(float(tunables.get("trail_duration", trail_duration)), 0.05)
	if tunables.has("launch_fx_duration"):
		launch_fx_duration = maxf(float(tunables.get("launch_fx_duration", launch_fx_duration)), 0.05)
	if tunables.has("ship_warp_duration"):
		ship_warp_duration = maxf(float(tunables.get("ship_warp_duration", ship_warp_duration)), 0.1)
	if tunables.has("ship_warp_strength"):
		ship_warp_strength = clampf(float(tunables.get("ship_warp_strength", ship_warp_strength)), 0.0, 1.0)
	if tunables.has("ship_holo_duration"):
		ship_holo_duration = maxf(float(tunables.get("ship_holo_duration", ship_holo_duration)), 0.1)
	if tunables.has("ship_holo_fade_out_duration"):
		ship_holo_fade_out_duration = maxf(float(tunables.get("ship_holo_fade_out_duration", ship_holo_fade_out_duration)), 0.1)
	if tunables.has("ship_holo_strength"):
		ship_holo_strength = clampf(float(tunables.get("ship_holo_strength", ship_holo_strength)), 0.0, 1.0)


func _play_dash_fx(start_position: Vector2, end_position: Vector2, dash_direction: Vector2) -> void:
	var safe_direction := dash_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	_spawn_dash_trail(start_position, end_position, safe_direction)
	_spawn_launch_burst(start_position, safe_direction)


func _spawn_dash_trail(start_position: Vector2, end_position: Vector2, dash_direction: Vector2) -> void:
	var source_sprite := _get_owner_ship_sprite()
	if source_sprite == null or source_sprite.texture == null:
		return
	if not _should_show_effect(end_position) and not _should_show_effect(start_position):
		return

	var dash_vector := end_position - start_position
	if dash_vector.length_squared() <= 1.0:
		return

	var safe_direction := dash_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = dash_vector.normalized()
	var side_axis := safe_direction.orthogonal()
	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	var safe_duration := maxf(trail_duration, 0.05)
	for index in range(TRAIL_COUNT):
		var trail_ratio := float(index + 1) / float(TRAIL_COUNT + 1)
		var trail_sprite := _create_dash_trail_sprite(source_sprite, index)
		fx_layer.add_child(trail_sprite)

		var ripple_offset := side_axis * sin(float(index + 1) * 1.7) * 18.0
		var trail_position := start_position.lerp(end_position, trail_ratio) + ripple_offset
		trail_sprite.global_position = trail_position
		trail_sprite.global_rotation = source_sprite.global_rotation
		trail_sprite.global_scale = source_sprite.global_scale * lerpf(0.92, 1.06, trail_ratio)
		trail_sprite.modulate = Color(0.48, 0.9, 1.0, TRAIL_OPACITIES[index])

		var trail_material := trail_sprite.material as ShaderMaterial
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(trail_sprite, "global_position", trail_position - safe_direction * lerpf(120.0, 42.0, trail_ratio), safe_duration)
		tween.tween_property(trail_sprite, "global_scale", trail_sprite.global_scale * lerpf(1.18, 1.05, trail_ratio), safe_duration)
		tween.tween_property(trail_sprite, "modulate:a", 0.0, safe_duration)
		if trail_material != null:
			tween.tween_property(trail_material, "shader_parameter/alpha", 0.0, safe_duration)
			tween.tween_property(trail_material, "shader_parameter/holo_effect_strength", 0.0, safe_duration)
			tween.tween_property(trail_material, "shader_parameter/vortex_strength", 0.0, safe_duration)
		tween.chain().tween_callback(trail_sprite.queue_free)


func _create_dash_trail_sprite(source_sprite: Sprite2D, index: int) -> Sprite2D:
	var trail_sprite := Sprite2D.new()
	trail_sprite.texture = source_sprite.texture
	trail_sprite.centered = source_sprite.centered
	trail_sprite.offset = source_sprite.offset
	trail_sprite.flip_h = source_sprite.flip_h
	trail_sprite.flip_v = source_sprite.flip_v
	trail_sprite.region_enabled = source_sprite.region_enabled
	trail_sprite.region_rect = source_sprite.region_rect
	trail_sprite.hframes = source_sprite.hframes
	trail_sprite.vframes = source_sprite.vframes
	trail_sprite.frame = source_sprite.frame
	trail_sprite.z_index = 8 + index

	var material := ShaderMaterial.new()
	material.shader = SHIP_DISTORTION_SHADER
	material.set_shader_parameter("time", float(Time.get_ticks_msec()) / 1000.0 + float(index) * 0.11)
	material.set_shader_parameter("thrust_strength", 0.78)
	material.set_shader_parameter("distortion_strength", 0.032)
	material.set_shader_parameter("jitter_frequency", 28.0)
	material.set_shader_parameter("shimmer_frequency", 16.0)
	material.set_shader_parameter("engine_focus", 0.58)
	material.set_shader_parameter("pickup_flash_strength", 0.0)
	material.set_shader_parameter("damage_flash_strength", 0.0)
	material.set_shader_parameter("vortex_strength", lerpf(0.58, 0.24, float(index) / maxf(float(TRAIL_COUNT - 1), 1.0)))
	material.set_shader_parameter("vortex_direction", Vector2(0.0, -1.0))
	material.set_shader_parameter("holo_effect_strength", 1.0)
	material.set_shader_parameter("alpha", TRAIL_OPACITIES[index])
	material.set_shader_parameter("global_fade", 1.0)
	trail_sprite.material = material
	return trail_sprite


func _spawn_launch_burst(world_position: Vector2, dash_direction: Vector2) -> void:
	if not _should_show_effect(world_position):
		return

	var fx_layer := _get_fx_layer()
	if fx_layer == null:
		return

	var burst_root := Node2D.new()
	burst_root.z_index = 18
	fx_layer.add_child(burst_root)
	burst_root.global_position = world_position

	_spawn_launch_rings(burst_root, dash_direction)
	_spawn_sparks(burst_root, dash_direction)

	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(maxf(launch_fx_duration, 0.05) + 0.45)
	cleanup_tween.tween_callback(burst_root.queue_free)


func _spawn_launch_rings(parent: Node2D, dash_direction: Vector2) -> void:
	var safe_direction := dash_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	var side_axis := safe_direction.orthogonal()
	var base_radius := maxf(_get_owner_touch_radius() * 0.34, 24.0)
	var safe_duration := maxf(launch_fx_duration, 0.05)

	for index in range(3):
		var ring := Line2D.new()
		ring.closed = true
		ring.width = maxf(5.0 - float(index) * 1.15, 1.4)
		ring.default_color = Color(0.24 + float(index) * 0.18, 0.86, 1.0, 0.54 - float(index) * 0.1)
		ring.points = _build_ring_points(base_radius + float(index) * 9.0, safe_direction, side_axis)
		ring.z_index = 2 + index
		parent.add_child(ring)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2.ONE * (2.35 + float(index) * 0.24), safe_duration * (0.82 + float(index) * 0.1))
		tween.tween_property(ring, "position", -safe_direction * (34.0 + float(index) * 18.0), safe_duration)
		tween.tween_property(ring, "modulate:a", 0.0, safe_duration)


func _build_ring_points(radius: float, forward_axis: Vector2, side_axis: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_radius := maxf(radius, 1.0)
	for point_index in range(RING_POINT_COUNT):
		var angle := TAU * float(point_index) / float(RING_POINT_COUNT)
		var point := forward_axis * cos(angle) * safe_radius * 0.56 + side_axis * sin(angle) * safe_radius
		points.append(point)
	return points


func _spawn_sparks(parent: Node2D, dash_direction: Vector2) -> void:
	var safe_direction := dash_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	var forward_sparks := _create_particles()
	forward_sparks.rotation = safe_direction.angle() + PI
	forward_sparks.amount = 80
	forward_sparks.lifetime = maxf(launch_fx_duration, 0.1)
	forward_sparks.initial_velocity_min = 340.0
	forward_sparks.initial_velocity_max = 980.0
	forward_sparks.spread = 34.0
	forward_sparks.scale_amount_min = 0.22
	forward_sparks.scale_amount_max = 0.9
	forward_sparks.color = Color(0.55, 0.93, 1.0, 0.92)
	parent.add_child(forward_sparks)
	forward_sparks.emitting = true

	var shock_sparks := _create_particles()
	shock_sparks.amount = 48
	shock_sparks.lifetime = maxf(launch_fx_duration * 0.78, 0.1)
	shock_sparks.initial_velocity_min = 120.0
	shock_sparks.initial_velocity_max = 440.0
	shock_sparks.spread = 180.0
	shock_sparks.scale_amount_min = 0.16
	shock_sparks.scale_amount_max = 0.62
	shock_sparks.color = Color(0.82, 0.64, 1.0, 0.72)
	parent.add_child(shock_sparks)
	shock_sparks.emitting = true


func _create_particles() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.texture = PARTICLE_TEXTURE
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.randomness = 0.74
	particles.speed_scale = 1.0
	particles.draw_order = CPUParticles2D.DRAW_ORDER_LIFETIME
	particles.gravity = Vector2.ZERO
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.damping_min = 820.0
	particles.damping_max = 1280.0
	return particles


func _get_fx_layer() -> Node2D:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_effects_layer"):
		return owner_ship.call("get_artifact_effects_layer") as Node2D
	return null


func _get_owner_ship_sprite() -> Sprite2D:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_ship_sprite"):
		return owner_ship.call("get_artifact_ship_sprite") as Sprite2D
	return null


func _get_owner_touch_radius() -> float:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_touch_radius"):
		return maxf(float(owner_ship.call("get_touch_radius")), 0.0)
	return 0.0


func _should_show_effect(world_position: Vector2) -> bool:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("should_show_artifact_effect"):
		return bool(owner_ship.call("should_show_artifact_effect", world_position))
	return true

class_name AsteroidField
extends Node2D

const ASTEROID_SCENE: PackedScene = preload("res://galaxy_entities/other/Asteroids/Asteroid.tscn")
const ASTEROID_Z_INDEX_DISTANCE_DIVISOR: float = 40.0
const ASTEROID_MIN_Z_INDEX: int = -4096

signal asteroid_destroyed(xp_amount: int, world_position: Vector2, asteroid: Node2D)

@export_range(0, 1000, 1) var asteroid_count: int = 125
@export_range(0, 128, 1) var cluster_count: int = 13
@export_range(1, 64, 1) var cluster_size_min: int = 4
@export_range(1, 64, 1) var cluster_size_max: int = 9
@export_range(100.0, 200000.0, 100.0) var spawn_radius: float = 45000.0
@export_range(0.0, 1.0, 0.01) var spawn_radius_ratio: float = 0.9
@export_range(0.0, 1.0, 0.01) var inner_clear_radius_ratio: float = 0.08
@export_range(0.0, 5000.0, 1.0) var min_separation: float = 120.0
@export_range(16.0, 512.0, 1.0) var asteroid_pixel_size_min: float = 56.0
@export_range(16.0, 512.0, 1.0) var asteroid_pixel_size_max: float = 132.0
@export_range(50.0, 5000.0, 10.0) var cluster_radius_min: float = 180.0
@export_range(50.0, 5000.0, 10.0) var cluster_radius_max: float = 740.0
@export_range(1, 999, 1) var asteroid_hit_points: int = 2
@export_range(0, 999, 1) var asteroid_xp_reward: int = 1
@export_range(1, 3, 1) var asteroid_xp_boxes_min: int = 1
@export_range(1, 3, 1) var asteroid_xp_boxes_max: int = 3
@export var world_seed: int = 0
@export var clear_existing_children: bool = true

var _world_radius: float = 10000.0


func _ready() -> void:
	_apply_galaxy_configuration()
	_spawn_asteroids()


func regenerate() -> void:
	_apply_galaxy_configuration()
	_spawn_asteroids()


func _apply_galaxy_configuration() -> void:
	var galaxy := get_parent()
	if galaxy != null and galaxy.has_method("get_world_radius"):
		_world_radius = float(galaxy.call("get_world_radius"))
	else:
		_world_radius = 10000.0

	spawn_radius = minf(spawn_radius, _world_radius * clampf(spawn_radius_ratio, 0.0, 1.0))
	min_separation = maxf(min_separation, 0.0)


func _spawn_asteroids() -> void:
	if clear_existing_children:
		for child in get_children():
			child.queue_free()

	var rng := RandomNumberGenerator.new()
	if world_seed == 0:
		rng.randomize()
	else:
		rng.seed = world_seed

	var spawned_positions: Array[Vector2] = []
	var remaining_count := maxi(asteroid_count, 0)
	var safe_cluster_count := mini(maxi(cluster_count, 0), remaining_count)
	for _cluster_index in safe_cluster_count:
		if remaining_count <= 0:
			break

		var center := _pick_spawn_position(rng, spawned_positions, 0.0)
		var cluster_size := mini(rng.randi_range(_get_cluster_size_min(), _get_cluster_size_max()), remaining_count)
		var cluster_radius := rng.randf_range(_get_cluster_radius_min(), _get_cluster_radius_max())
		for _asteroid_index in cluster_size:
			if remaining_count <= 0:
				break

			var position := _pick_cluster_position(rng, center, cluster_radius, spawned_positions)
			_spawn_asteroid(position, rng)
			spawned_positions.append(position)
			remaining_count -= 1

	while remaining_count > 0:
		var position := _pick_spawn_position(rng, spawned_positions, 0.0)
		_spawn_asteroid(position, rng)
		spawned_positions.append(position)
		remaining_count -= 1


func _spawn_asteroid(spawn_position: Vector2, rng: RandomNumberGenerator) -> void:
	var asteroid := ASTEROID_SCENE.instantiate() as Node2D
	if asteroid == null:
		return

	asteroid.name = "Asteroid%d" % (get_child_count() + 1)
	asteroid.position = spawn_position
	var pixel_size := _pick_asteroid_pixel_size(rng)
	var size_ratio := _get_asteroid_size_ratio(pixel_size)
	asteroid.set("hit_points", _get_hit_points_for_size(size_ratio))
	asteroid.set("xp_reward", maxi(asteroid_xp_reward, 0))
	asteroid.set("xp_box_count", _get_xp_box_count_for_size(size_ratio))
	asteroid.set("explosion_size", lerpf(0.32, 0.78, size_ratio))
	asteroid.set("breakup_piece_distance", lerpf(62.0, 170.0, size_ratio))
	asteroid.set("breakup_dust_amount", maxi(int(round(lerpf(28.0, 92.0, size_ratio))), 1))
	asteroid.set("impact_push_speed", lerpf(92.0, 44.0, size_ratio))
	asteroid.set("max_drift_speed", lerpf(210.0, 95.0, size_ratio))
	asteroid.z_index = maxi(-int(spawn_position.length() / ASTEROID_Z_INDEX_DISTANCE_DIVISOR), ASTEROID_MIN_Z_INDEX)
	add_child(asteroid)
	asteroid.call("set_pixels", pixel_size)
	asteroid.call("set_seed", rng.randi())
	asteroid.call("set_rotates", rng.randf_range(0.0, TAU))
	asteroid.call("randomize_colors")
	var destroyed_callable := Callable(self, "_on_asteroid_destroyed")
	if not asteroid.is_connected("destroyed", destroyed_callable):
		asteroid.connect("destroyed", destroyed_callable)


func _pick_spawn_position(rng: RandomNumberGenerator, spawned_positions: Array[Vector2], asteroid_radius: float) -> Vector2:
	var inner_radius := spawn_radius * clampf(inner_clear_radius_ratio, 0.0, 1.0)
	var fallback_position := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(inner_radius, spawn_radius)

	for _attempt in 32:
		var angle := rng.randf_range(0.0, TAU)
		var radius := lerpf(inner_radius, spawn_radius, pow(rng.randf(), 0.62))
		var candidate := Vector2.RIGHT.rotated(angle) * radius
		if _is_spawn_position_available(candidate, spawned_positions, asteroid_radius):
			return candidate

	return fallback_position


func _pick_cluster_position(
	rng: RandomNumberGenerator,
	cluster_center: Vector2,
	cluster_radius: float,
	spawned_positions: Array[Vector2]
) -> Vector2:
	var fallback_position := _clamp_to_world(cluster_center + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(0.0, cluster_radius))
	for _attempt in 24:
		var offset := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(0.0, cluster_radius)
		var candidate := _clamp_to_world(cluster_center + offset)
		if _is_spawn_position_available(candidate, spawned_positions, 0.0):
			return candidate

	return fallback_position


func _is_spawn_position_available(candidate: Vector2, spawned_positions: Array[Vector2], asteroid_radius: float) -> bool:
	if candidate.length() < spawn_radius * clampf(inner_clear_radius_ratio, 0.0, 1.0):
		return false
	if candidate.length() > spawn_radius:
		return false
	if _is_blocked_by_planet(candidate, asteroid_radius):
		return false
	for existing_position in spawned_positions:
		if candidate.distance_to(existing_position) < min_separation:
			return false

	return true


func _is_blocked_by_planet(candidate: Vector2, asteroid_radius: float) -> bool:
	var galaxy := get_parent()
	if galaxy == null:
		return false

	var planet_field := galaxy.get_node_or_null("PlanetField")
	if planet_field == null:
		return false

	for child in planet_field.get_children():
		var planet := child as Node2D
		if planet == null:
			continue
		if not planet.has_method("get_touch_radius"):
			continue

		var planet_radius := maxf(float(planet.call("get_touch_radius")), 0.0)
		if candidate.distance_to(planet.global_position) <= planet_radius + asteroid_radius + min_separation:
			return true

	return false


func _clamp_to_world(world_position: Vector2) -> Vector2:
	var radius := maxf(spawn_radius, 1.0)
	if world_position.length() <= radius:
		return world_position

	return world_position.normalized() * radius


func _get_cluster_size_min() -> int:
	return mini(cluster_size_min, cluster_size_max)


func _get_cluster_size_max() -> int:
	return maxi(cluster_size_min, cluster_size_max)


func _get_cluster_radius_min() -> float:
	return minf(cluster_radius_min, cluster_radius_max)


func _get_cluster_radius_max() -> float:
	return maxf(cluster_radius_min, cluster_radius_max)


func _get_asteroid_pixel_size_min() -> float:
	return minf(asteroid_pixel_size_min, asteroid_pixel_size_max)


func _get_asteroid_pixel_size_max() -> float:
	return maxf(asteroid_pixel_size_min, asteroid_pixel_size_max)


func _pick_asteroid_pixel_size(rng: RandomNumberGenerator) -> float:
	var min_size := _get_asteroid_pixel_size_min()
	var max_size := _get_asteroid_pixel_size_max()
	if is_equal_approx(min_size, max_size):
		return min_size

	var roll := rng.randf()
	var size_ratio := 0.0
	if roll < 0.56:
		size_ratio = rng.randf_range(0.0, 0.38)
	elif roll < 0.86:
		size_ratio = rng.randf_range(0.38, 0.72)
	else:
		size_ratio = rng.randf_range(0.72, 1.0)

	return lerpf(min_size, max_size, size_ratio)


func _get_asteroid_size_ratio(pixel_size: float) -> float:
	var min_size := _get_asteroid_pixel_size_min()
	var max_size := _get_asteroid_pixel_size_max()
	if is_equal_approx(min_size, max_size):
		return 0.0

	return clampf(inverse_lerp(min_size, max_size, pixel_size), 0.0, 1.0)


func _get_hit_points_for_size(size_ratio: float) -> int:
	return maxi(int(round(float(maxi(asteroid_hit_points, 1)) * lerpf(0.75, 2.6, size_ratio))), 1)


func _get_xp_box_count_for_size(size_ratio: float) -> int:
	var min_boxes := mini(asteroid_xp_boxes_min, asteroid_xp_boxes_max)
	var max_boxes := maxi(asteroid_xp_boxes_min, asteroid_xp_boxes_max)
	var size_step := 0
	if size_ratio >= 0.72:
		size_step = 2
	elif size_ratio >= 0.38:
		size_step = 1

	return clampi(min_boxes + size_step, min_boxes, max_boxes)


func _on_asteroid_destroyed(xp_amount: int, world_position: Vector2, asteroid: Node2D) -> void:
	asteroid_destroyed.emit(xp_amount, world_position, asteroid)

extends Node2D

const PLANET_SCENE: PackedScene = preload("res://galaxy_entities/planets/planet.tscn")
const PLANET_SCENE_PATH: String = "res://galaxy_entities/planets/planet.tscn"
const PLANET_VISUALS_DIRECTORY: String = "res://galaxy_entities/planets"
const PLANET_VISUAL_SCENE_PATHS: PackedStringArray = [
	"res://galaxy_entities/planets/DryTerran/DryTerran.tscn",
	"res://galaxy_entities/planets/GasPlanet/GasPlanet.tscn",
	"res://galaxy_entities/planets/GasPlanetLayers/GasPlanetLayers.tscn",
	"res://galaxy_entities/planets/IceWorld/IceWorld.tscn",
	"res://galaxy_entities/planets/LandMasses/LandMasses.tscn",
	"res://galaxy_entities/planets/LavaWorld/LavaWorld.tscn",
	"res://galaxy_entities/planets/NoAtmosphere/NoAtmosphere.tscn",
	"res://galaxy_entities/planets/Rivers/Rivers.tscn",
]
const PLANET_Z_INDEX_DISTANCE_DIVISOR: float = 32.0
const PLANET_MIN_Z_INDEX: int = -4096

@export_range(1, 128, 1) var planet_count: int = 18
@export_range(200.0, 120000.0, 10.0) var spawn_radius: float = 82000.0
@export_range(0.0, 1.0, 0.01) var inner_clear_radius_ratio: float = 0.22
@export_range(0.0, 50000.0, 1.0) var min_separation: float = 22000.0
@export_range(0.25, 100.0, 0.01) var min_planet_scale: float = 6.0
@export_range(0.25, 100.0, 0.01) var max_planet_scale: float = 12.0
@export_range(0.0, 2.0, 0.001) var min_planet_rotation_speed: float = 0.12
@export_range(0.0, 2.0, 0.001) var max_planet_rotation_speed: float = 0.25
@export var world_seed: int = 0
@export var clear_existing_children: bool = true

func _ready() -> void:
	_apply_galaxy_configuration()
	_spawn_planets()


func regenerate() -> void:
	_apply_galaxy_configuration()
	_spawn_planets()


func _apply_galaxy_configuration() -> void:
	var galaxy := get_parent()
	if galaxy == null or not galaxy.has_method("get_planet_field_spawn_radius"):
		return

	spawn_radius = float(galaxy.call("get_planet_field_spawn_radius"))
	min_separation = float(galaxy.call("get_planet_field_min_separation"))


func _spawn_planets() -> void:
	if clear_existing_children:
		for child in get_children():
			child.queue_free()

	var rng := RandomNumberGenerator.new()
	if world_seed == 0:
		rng.randomize()
	else:
		rng.seed = world_seed

	var planet_scene_paths := _get_planet_visual_scene_paths()
	var variant_count := planet_scene_paths.size()
	if variant_count <= 0:
		push_warning("No planet visual scenes found in %s" % PLANET_VISUALS_DIRECTORY)
		variant_count = 1

	var variant_order := _build_variant_order(rng, variant_count)
	var spawned_positions: Array[Vector2] = []
	for index in planet_count:
		var planet := PLANET_SCENE.instantiate() as Planet
		if planet == null:
			continue

		var variant_index := variant_order[index % variant_order.size()] % variant_count
		planet.name = "Planet%d" % (index + 1)
		planet.position = _pick_spawn_position(rng, spawned_positions)
		planet.seed = rng.randi()
		if not planet_scene_paths.is_empty():
			planet.visual_scene_path = planet_scene_paths[variant_index]
		planet.planet_scale = rng.randf_range(min_planet_scale, max_planet_scale)
		planet.rotation_jitter = 0.0
		planet.visual_rotation_speed = _pick_rotation_speed(rng)
		planet.visual_rotation_phase = rng.randf_range(0.0, TAU)
		planet.size_jitter = rng.randf_range(0.02, 0.12)
		planet.brightness_jitter = rng.randf_range(0.02, 0.08)
		planet.z_index = maxi(-int(planet.position.length() / PLANET_Z_INDEX_DISTANCE_DIVISOR), PLANET_MIN_Z_INDEX)
		add_child(planet)
		spawned_positions.append(planet.position)


func _pick_spawn_position(rng: RandomNumberGenerator, spawned_positions: Array[Vector2]) -> Vector2:
	var inner_radius := spawn_radius * inner_clear_radius_ratio
	var fallback_position := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(inner_radius, spawn_radius)

	for _attempt in 16:
		var angle := rng.randf_range(0.0, TAU)
		var radius := lerpf(inner_radius, spawn_radius, pow(rng.randf(), 0.58))
		var candidate := Vector2.RIGHT.rotated(angle) * radius
		if _is_far_enough(candidate, spawned_positions):
			return candidate

	return fallback_position


func _is_far_enough(candidate: Vector2, spawned_positions: Array[Vector2]) -> bool:
	for existing_position in spawned_positions:
		if candidate.distance_to(existing_position) < min_separation:
			return false

	return true


func _pick_rotation_speed(rng: RandomNumberGenerator) -> float:
	var min_speed := minf(min_planet_rotation_speed, max_planet_rotation_speed)
	var max_speed := maxf(min_planet_rotation_speed, max_planet_rotation_speed)
	var speed := rng.randf_range(min_speed, max_speed)
	if rng.randf() < 0.5:
		speed *= -1.0

	return speed


func _build_variant_order(rng: RandomNumberGenerator, variant_count: int) -> Array[int]:
	var variants: Array[int] = []
	for variant_index in variant_count:
		variants.append(variant_index)

	if variants.is_empty():
		variants.append(0)

	for index in range(variants.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temp := variants[index]
		variants[index] = variants[swap_index]
		variants[swap_index] = temp

	return variants


func _get_planet_visual_scene_paths() -> PackedStringArray:
	var scene_paths := PackedStringArray()
	_collect_planet_visual_scene_paths(PLANET_VISUALS_DIRECTORY, scene_paths)
	if scene_paths.is_empty():
		scene_paths = _get_export_safe_planet_visual_scene_paths()
	scene_paths.sort()

	return scene_paths


func _get_export_safe_planet_visual_scene_paths() -> PackedStringArray:
	var scene_paths := PackedStringArray()
	for scene_path in PLANET_VISUAL_SCENE_PATHS:
		if ResourceLoader.exists(scene_path):
			scene_paths.append(scene_path)
		else:
			push_warning("Configured planet visual scene does not exist: %s" % scene_path)

	return scene_paths


func _collect_planet_visual_scene_paths(directory_path: String, scene_paths: PackedStringArray) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("Could not open planet visuals directory: %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while not entry_name.is_empty():
		var entry_path := directory_path.path_join(entry_name)
		if directory.current_is_dir():
			if not entry_name.begins_with("."):
				_collect_planet_visual_scene_paths(entry_path, scene_paths)
		elif entry_name.get_extension() == "tscn" and entry_path != PLANET_SCENE_PATH:
			if ResourceLoader.exists(entry_path):
				scene_paths.append(entry_path)
			else:
				push_warning("Available planet visual scene does not exist: %s" % entry_path)
		entry_name = directory.get_next()

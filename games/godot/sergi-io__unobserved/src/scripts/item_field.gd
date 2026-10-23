extends Node2D
class_name ItemField

const LASER_SCENE: PackedScene = preload("res://scenes/items/laser.tscn")
const LASER_RATE_SCENE: PackedScene = preload("res://scenes/items/laser_rate.tscn")
const BATTERY_SCENE: PackedScene = preload("res://scenes/items/battery.tscn")
const DRONE_SCENE: PackedScene = preload("res://scenes/items/drone.tscn")
const HOMING_MISSILE_SCENE: PackedScene = preload("res://scenes/items/homing_missile.tscn")
const SHIELD_SCENE: PackedScene = preload("res://scenes/items/shield.tscn")
const VACUUM_SCENE: PackedScene = preload("res://scenes/items/vacuum.tscn")
const RADAR_SCENE: PackedScene = preload("res://scenes/items/radar.tscn")
const BOX_SCENE: PackedScene = preload("res://scenes/items/box.tscn")
const REPAIRSET_SCENE: PackedScene = preload("res://scenes/items/repairset.tscn")
const INVISIBILITY_SCENE: PackedScene = preload("res://scenes/items/invisibility.tscn")
const WORMHOLE_DASH_SCENE: PackedScene = preload("res://scenes/items/wormhole_dash.tscn")
const VORTEX_SCENE: PackedScene = preload("res://scenes/items/vortex.tscn")
const NUKE_SCENE: PackedScene = preload("res://scenes/items/nuke.tscn")
const EXPLORER_BEACON_SCENE: PackedScene = preload("res://scenes/items/explorer_beacon.tscn")
const COLONY_BEACON_SCENE: PackedScene = preload("res://scenes/items/colony_beacon.tscn")

@export_range(0, 32, 1) var laser_count: int = 2
@export_range(0, 32, 1) var battery_count: int = 2
@export_range(0, 32, 1) var drone_count: int = 1
@export_range(0, 32, 1) var repairset_count: int = 2
@export_range(400.0, 12000.0, 10.0) var spawn_radius: float = 2200.0
@export_range(0.0, 1.0, 0.01) var inner_clear_radius_ratio: float = 0.08
@export_range(0.0, 2000.0, 1.0) var min_separation: float = 220.0
@export var world_seed: int = 0
@export var clear_existing_children: bool = true

var _world_radius: float = 10000.0


func _ready() -> void:
	_apply_galaxy_configuration()
	_spawn_items()


func regenerate() -> void:
	_apply_galaxy_configuration()
	_spawn_items()


func get_upgrade_catalog() -> Array[Dictionary]:
	return [
		_build_catalog_entry(LASER_SCENE),
		_build_catalog_entry(LASER_RATE_SCENE),
		_build_catalog_entry(BATTERY_SCENE),
		_build_catalog_entry(DRONE_SCENE),
		_build_catalog_entry(HOMING_MISSILE_SCENE),
		_build_catalog_entry(SHIELD_SCENE),
		_build_catalog_entry(VACUUM_SCENE),
		_build_catalog_entry(RADAR_SCENE),
		_build_catalog_entry(REPAIRSET_SCENE),
		_build_catalog_entry(INVISIBILITY_SCENE),
		_build_catalog_entry(WORMHOLE_DASH_SCENE),
		_build_catalog_entry(VORTEX_SCENE),
		_build_catalog_entry(NUKE_SCENE),
		_build_catalog_entry(EXPLORER_BEACON_SCENE),
		_build_catalog_entry(COLONY_BEACON_SCENE),
	]


func get_random_upgrade_options(option_count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var catalog := get_upgrade_catalog()
	var available_catalog: Array[Dictionary] = []
	for entry in catalog:
		if entry.is_empty():
			continue
		available_catalog.append(entry)

	var options: Array[Dictionary] = []
	var target_count := clampi(option_count, 0, available_catalog.size())
	while options.size() < target_count and not available_catalog.is_empty():
		var selected_index := rng.randi_range(0, available_catalog.size() - 1)
		options.append(available_catalog[selected_index])
		available_catalog.remove_at(selected_index)

	return options


func _apply_galaxy_configuration() -> void:
	var galaxy := get_parent()
	if galaxy != null and galaxy.has_method("get_world_radius"):
		_world_radius = float(galaxy.call("get_world_radius"))
	else:
		_world_radius = 10000.0

	spawn_radius = minf(spawn_radius, _world_radius * 0.55)
	min_separation = maxf(min_separation, 160.0)


func _spawn_items() -> void:
	if clear_existing_children:
		for child in get_children():
			child.queue_free()

	var rng := RandomNumberGenerator.new()
	if world_seed == 0:
		rng.randomize()
	else:
		rng.seed = world_seed

	var spawned_positions: Array[Vector2] = []
	_spawn_item_group(LASER_SCENE, laser_count, rng, spawned_positions)
	_spawn_item_group(BATTERY_SCENE, battery_count, rng, spawned_positions)
	_spawn_item_group(DRONE_SCENE, drone_count, rng, spawned_positions)
	_spawn_item_group(REPAIRSET_SCENE, repairset_count, rng, spawned_positions)


func _spawn_item_group(scene: PackedScene, count: int, rng: RandomNumberGenerator, spawned_positions: Array[Vector2]) -> void:
	for index in range(count):
		var item := scene.instantiate() as ItemPickup
		if item == null:
			continue

		item.name = "%s%d" % [item.name, index + 1]
		item.position = _pick_spawn_position(rng, spawned_positions)
		item.z_index = -10
		add_child(item)
		spawned_positions.append(item.position)


func spawn_xp_box(
	world_position: Vector2,
	xp_amount: int,
	spawn_origin: Vector2 = Vector2.ZERO,
	spawn_initial_velocity: Vector2 = Vector2.ZERO,
	spawn_duration: float = 0.0,
	spawn_delay: float = 0.0,
	animate_spawn: bool = false
) -> void:
	if xp_amount <= 0:
		return

	var box := BOX_SCENE.instantiate() as ItemPickup
	if box == null:
		return

	box.position = world_position
	box.z_index = -10
	box.item_kind = &"xpbox"
	box.item_level = xp_amount
	add_child(box)
	if animate_spawn and box.has_method("play_splash_spawn"):
		box.call(
			"play_splash_spawn",
			spawn_origin,
			spawn_initial_velocity,
			maxf(spawn_duration, 0.01),
			maxf(spawn_delay, 0.0)
		)


func get_scene_for_item_kind(item_kind: StringName) -> PackedScene:
	match item_kind:
		ItemPickup.ITEM_LASER:
			return LASER_SCENE
		ItemPickup.ITEM_LASER_RATE:
			return LASER_RATE_SCENE
		ItemPickup.ITEM_BATTERY:
			return BATTERY_SCENE
		ItemPickup.ITEM_DRONE:
			return DRONE_SCENE
		ItemPickup.ITEM_HOMING_MISSILE:
			return HOMING_MISSILE_SCENE
		ItemPickup.ITEM_SHIELD:
			return SHIELD_SCENE
		ItemPickup.ITEM_VACUUM:
			return VACUUM_SCENE
		ItemPickup.ITEM_RADAR:
			return RADAR_SCENE
		ItemPickup.ITEM_REPAIRSET:
			return REPAIRSET_SCENE
		ItemPickup.ITEM_INVISIBILITY:
			return INVISIBILITY_SCENE
		ItemPickup.ITEM_WORMHOLE_DASH:
			return WORMHOLE_DASH_SCENE
		ItemPickup.ITEM_VORTEX:
			return VORTEX_SCENE
		ItemPickup.ITEM_NUKE:
			return NUKE_SCENE
		ItemPickup.ITEM_EXPLORER_BEACON:
			return EXPLORER_BEACON_SCENE
		ItemPickup.ITEM_COLONY_BEACON:
			return COLONY_BEACON_SCENE
		ItemPickup.ITEM_XP_BOX:
			return BOX_SCENE
		_:
			return LASER_SCENE


func create_item_for_network(state: Dictionary) -> ItemPickup:
	var item_kind := StringName(state.get("item_kind", ItemPickup.ITEM_LASER))
	var scene := get_scene_for_item_kind(item_kind)
	var item := scene.instantiate() as ItemPickup
	if item == null:
		return null

	item.network_id = int(state.get("network_id", 0))
	item.item_kind = item_kind
	item.item_level = maxi(int(state.get("item_level", 1)), 1)
	item.repair_amount = maxi(int(state.get("repair_amount", 4)), 0)
	item.position = state.get("position", Vector2.ZERO) as Vector2
	item.z_index = int(state.get("z_index", -10))
	add_child(item)
	if state.has("spawn_origin") and item.has_method("play_splash_spawn"):
		item.call(
			"play_splash_spawn",
			state.get("spawn_origin", Vector2.ZERO) as Vector2,
			state.get("spawn_initial_velocity", Vector2.ZERO) as Vector2,
			maxf(float(state.get("spawn_duration", 0.01)), 0.01),
			maxf(float(state.get("spawn_delay", 0.0)), 0.0)
		)
	return item


func _build_catalog_entry(scene: PackedScene) -> Dictionary:
	var item := scene.instantiate() as ItemPickup
	if item == null:
		return {}

	var entry := {
		"scene": scene,
		"item_kind": item.item_kind,
		"item_level": item.item_level,
		"repair_amount": item.repair_amount,
		"title": item.get_display_name(),
		"description": item.get_display_description(),
		"icon_texture": item.get_display_icon_texture(),
	}
	item.free()
	return entry


func _pick_spawn_position(rng: RandomNumberGenerator, spawned_positions: Array[Vector2]) -> Vector2:
	var inner_radius := spawn_radius * inner_clear_radius_ratio
	var fallback_position := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(inner_radius, spawn_radius)

	for _attempt in range(16):
		var angle := rng.randf_range(0.0, TAU)
		var radius := lerpf(inner_radius, spawn_radius, pow(rng.randf(), 0.7))
		var candidate := Vector2.RIGHT.rotated(angle) * radius
		if _is_far_enough(candidate, spawned_positions):
			return candidate

	return fallback_position


func _is_far_enough(candidate: Vector2, spawned_positions: Array[Vector2]) -> bool:
	for existing_position in spawned_positions:
		if candidate.distance_to(existing_position) < min_separation:
			return false

	return true

@icon("res://addons/horde_kit/icon_spawner.svg")
class_name HordeSpawner
extends Node2D
## Spawns enemies on a ring around a target, driven by a list of
## [SpawnWave] resources. Drop it in a scene, point [member target_path]
## at the player, add waves in the inspector.
##
## If a spawned enemy has a [code]target[/code] property, the spawner
## sets it to the target node before adding the enemy to the tree.
##
## Run time only advances while the target exists. Batches that would
## exceed [member max_alive] are dropped, not delayed.

signal enemy_spawned(enemy: Node2D)
signal wave_started(wave: SpawnWave)
signal wave_finished(wave: SpawnWave)

## Assigning a new array resets the run. Waves appended at runtime start
## from the current time instead of catching up on missed batches.
@export var waves: Array[SpawnWave] = []:
	set(value):
		waves = value
		reset()
## Node the enemies spawn around (usually the player).
@export var target_path: NodePath
## Where spawned enemies are added. Empty means this spawner.
@export var spawn_parent_path: NodePath
## Distance from the target. Keep it just outside the visible screen.
@export_range(16.0, 4096.0, 1.0, "suffix:px") var spawn_radius: float = 400.0
## Hard cap on alive enemies, to protect the frame rate.
@export_range(1, 5000) var max_alive: int = 400
## Every spawned enemy joins this group. Used for the alive count.
@export var enemy_group: StringName = &"horde_enemy"
## Fixed seed for reproducible spawn positions. 0 means random.
@export var rng_seed: int = 0
@export var autostart: bool = true

var elapsed: float = 0.0
var running: bool = false

var _fired: PackedInt32Array = []
var _active: Array[bool] = []
var _rng := RandomNumberGenerator.new()


## Point on a circle of [param radius] around [param center].
static func ring_position(center: Vector2, radius: float, angle: float) -> Vector2:
	return center + Vector2.from_angle(angle) * radius


func _ready() -> void:
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	reset()
	if autostart:
		start()


func start() -> void:
	running = true


func stop() -> void:
	running = false


func reset() -> void:
	elapsed = 0.0
	_fired.resize(waves.size())
	_fired.fill(0)
	_active.resize(waves.size())
	_active.fill(false)


func alive_count() -> int:
	return get_tree().get_node_count_in_group(enemy_group)


func _physics_process(delta: float) -> void:
	if not running:
		return
	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return
	elapsed += delta
	_sync_wave_state()
	for i in waves.size():
		_update_wave(i, target)


## Handles waves appended at runtime without going through the setter.
func _sync_wave_state() -> void:
	var old_size := _fired.size()
	if old_size == waves.size():
		return
	_fired.resize(waves.size())
	_active.resize(waves.size())
	for i in range(old_size, waves.size()):
		_fired[i] = waves[i].batches_due(elapsed) if waves[i] else 0
		_active[i] = false


func _update_wave(index: int, target: Node2D) -> void:
	var wave := waves[index]
	if wave == null or wave.enemy_scene == null:
		return
	var is_active := wave.is_active(elapsed)
	if is_active and not _active[index]:
		wave_started.emit(wave)
	elif not is_active and _active[index]:
		wave_finished.emit(wave)
	_active[index] = is_active
	var due := wave.batches_due(elapsed)
	while _fired[index] < due:
		_fired[index] += 1
		_spawn_batch(wave, target)


func _spawn_batch(wave: SpawnWave, target: Node2D) -> void:
	var parent := get_node_or_null(spawn_parent_path) if not spawn_parent_path.is_empty() else self
	if parent == null:
		push_error("HordeSpawner: spawn_parent_path %s not found" % spawn_parent_path)
		return
	for i in wave.batch_size:
		if alive_count() >= max_alive:
			return
		var instance := wave.enemy_scene.instantiate()
		var enemy := instance as Node2D
		if enemy == null:
			push_error("HordeSpawner: enemy_scene root must be a Node2D")
			instance.free()
			return
		enemy.add_to_group(enemy_group)
		if "target" in enemy:
			enemy.set("target", target)
		parent.add_child(enemy)
		enemy.global_position = ring_position(target.global_position, spawn_radius, _rng.randf() * TAU)
		enemy_spawned.emit(enemy)

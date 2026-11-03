extends Node

const SPAWN_RADIUS = 400

@export var rat_enemy_scene: PackedScene
@export var bug_enemy_scene: PackedScene
@export var slug_enemy_scene: PackedScene
@export var arena_time_manager: Node

@onready var timer = $Timer

var enemy_table = WeightedTable.new()
var enemy_scenes = {}

func _ready() -> void:
	enemy_scenes = {
		"rat": rat_enemy_scene,
		"bug": bug_enemy_scene,
		"slug": slug_enemy_scene,
	}
	_apply_spawn_steps(0)
	timer.start(Balance.SPAWN_BASE_TIME)
	timer.timeout.connect(_on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(_on_arena_difficulty_increased)


func _apply_spawn_steps(arena_difficulty: int):
	for step in Balance.SPAWN_STEPS:
		var difficulty = step[0]
		var enemy_id = step[1]
		var weight = step[2]
		if difficulty != arena_difficulty:
			continue

		if enemy_table.has_item_id(enemy_id):
			enemy_table.update_item_weight(enemy_id, weight)
		elif enemy_scenes.has(enemy_id):
			enemy_table.add_item(enemy_scenes[enemy_id], weight, enemy_id)
		else:
			push_error("Balance.SPAWN_STEPS names unknown enemy '%s'." % enemy_id)


func _get_spawn_position():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return Vector2.ZERO
	
	var spawn_position = Vector2.ZERO
	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
	
		var query_parameters = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position, 1 << 0)
		var collision = get_tree().root.world_2d.direct_space_state.intersect_ray(query_parameters)
	
		if collision.is_empty():
			break
		
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))
	
	return spawn_position


func _on_timer_timeout():
	timer.start()
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	var enemy_scene = enemy_table.pick_item()
	var enemy = enemy_scene.instantiate() as Node2D
	entities_layer.add_child(enemy)
	enemy.global_position = _get_spawn_position()


func _on_arena_difficulty_increased(arena_difficulty: int):
	var time_off = Balance.SPAWN_TIME_REDUCTION_PER_LEVEL * arena_difficulty
	time_off = min(time_off, Balance.SPAWN_MAX_TIME_REDUCTION)
	timer.wait_time = Balance.SPAWN_BASE_TIME - time_off
	_apply_spawn_steps(arena_difficulty)

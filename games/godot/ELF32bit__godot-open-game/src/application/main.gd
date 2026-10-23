extends Node

@onready var scene_tree: SceneTree = get_tree()


func _ready() -> void:
	scene_tree.scene_changed.connect(_on_scene_changed)
	call_deferred("load_map")


func load_map(map_path: String = "res://mapping/scenes/start.tscn") -> void:
	var map: PackedScene = load(map_path)
	scene_tree.change_scene_to_packed(map)


func _on_scene_changed(delay: float = 0.05) -> void:
	scene_tree.create_timer(delay).timeout.connect(_spawn_player)


func _spawn_player() -> void:
	var spawns := scene_tree.get_nodes_in_group("info_player_start")
	var player: PackedScene = load("res://sources/player/player.tscn")
	var player_instance := player.instantiate()

	if spawns.size(): player_instance.position = spawns[0].position
	else: push_warning("info_player_start not found in the map")
	scene_tree.current_scene.add_child(player_instance, true)

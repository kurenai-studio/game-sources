extends Node


@export var world :Node2D
@export var death_tint :CanvasModulate
@export var ui_root :Control
@export var levels := [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn"]
var current_level_node :Level
var player :Player
const PLAYER_SCENE := preload("res://components/scenes/player.tscn")
var candy_count := 0


func _ready() -> void:
	get_tree().paused = true
	GameManager.state_changed.connect(_on_game_manager_state_changed)
	GameManager.level_changed.connect(_on_game_manager_level_changed)


func _input(event: InputEvent) -> void:
	if ( event.is_action_pressed("restart")
			and GameManager.state in [
					GameManager.State.PLAYING,
					GameManager.State.DEAD]
			and GameManager.menu == GameManager.Menu.NONE ):
		GameManager.set_states(
				GameManager.State.PLAYING,
				GameManager.Menu.NONE)
		load_level()


func _on_game_manager_state_changed() -> void:
	if ( GameManager.menu == GameManager.Menu.NONE
			and GameManager.state == GameManager.State.PLAYING ):
		get_tree().paused = false
	else:
		get_tree().paused = true
	death_tint.visible = bool(GameManager.state == GameManager.State.DEAD)


func _on_game_manager_level_changed() -> void:
	if GameManager.level_index != -1:
		load_level()
	else:
		if player:
			player.queue_free()
		if current_level_node:
			current_level_node.queue_free()


func load_level() -> void:
	if player:
		player.queue_free()
	if current_level_node:
		current_level_node.queue_free()
	var scene := load(levels[GameManager.level_index]) as PackedScene
	var new_level_node := scene.instantiate()
	world.add_child(new_level_node)
	current_level_node = new_level_node
	await get_tree().process_frame
	var new_player := PLAYER_SCENE.instantiate()
	player = new_player
	player.global_position = current_level_node.spawn_point.global_position
	new_player.die.connect(_on_player_die)
	new_player.win.connect(_on_player_win)
	world.add_child(new_player)
	await get_tree().process_frame
	GameManager.count_candies()
	player.velocity = Vector2.ZERO


func _on_player_die() -> void:
	GameManager.set_states(GameManager.State.DEAD, GameManager.Menu.NONE)


func _on_player_win() -> void:
	GameManager.count_candies_collected()
	GameManager.set_states(GameManager.State.WON, GameManager.Menu.NONE)

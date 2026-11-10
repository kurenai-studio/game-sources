extends Node2D

var game_scene := preload("res://game/game_scene.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)


func _on_tutorial_button_pressed() -> void:
	var tutorial_game_scene = game_scene.instantiate()
	tutorial_game_scene.initial_level = 0
	
	var root = get_tree().get_root()
	self.queue_free()
	
	root.add_child(tutorial_game_scene)
	get_tree().current_scene = tutorial_game_scene
	

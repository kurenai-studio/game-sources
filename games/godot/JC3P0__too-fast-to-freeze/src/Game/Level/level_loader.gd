extends Node

const MAIN_LEVEL = preload("res://Game/Level/main.tscn")

var current_level = MAIN_LEVEL

func get_current_level_name() -> String:
	if get_child_count() > 0:
		var get_current_level = get_child(0)
		return get_current_level.name
	else:
		print("leveLoader:Error: could not find current level name.")
		return ""

func change_level(level_to_load: String) -> void:
	get_child(0).queue_free()
	var new_level
	if level_to_load == "main_level":
		current_level = MAIN_LEVEL
		new_level = MAIN_LEVEL.instantiate()
	else:
		print("level_manager:Error: Level not recognized.")
		return
	
	add_child(new_level)

func restart_level() -> void:
	get_tree().paused = false
	print("LeveLoader: Restarting current level: ", current_level)
	self.get_child(0).queue_free()
	var reset_level = current_level.instantiate()
	self.add_child(reset_level)
	print("LevelManager: New level instantiated and added to LevelManager")

extends Control

@onready var _how_to_play_page:Panel = get_node("%HowToPlay_BG")

func _ready() -> void:
	_how_to_play_page.visible = false
func _on_exit_button_down() -> void:
	get_tree().quit()


func _on_start_game_button_down() -> void:
	get_tree().change_scene_to_file("res://Levels/turret_testing_grounds.tscn")


func _on_how_to_play_button_down() -> void:
	if _how_to_play_page.visible:
		_how_to_play_page.visible = false
	else:
		_how_to_play_page.visible = true

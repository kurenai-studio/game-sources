extends Control

func _on_pause_button_pressed() -> void:
	Globals.game_speed = Globals.GameSpeed.PAUSED

func _on_x1_button_pressed() -> void:
	Globals.game_speed = Globals.GameSpeed.NORMAL

func _on_x2_button_pressed() -> void:
	Globals.game_speed = Globals.GameSpeed.FAST

extends Control

signal start_game
signal open_settings


func _on_exit_game_pressed():
	get_tree().quit()


func _on_new_game_pressed():
	start_game.emit()
	hide()

class_name GameStartHUD
extends CanvasLayer

@export var game: Game

func _on_start_pressed() -> void:
	game.start_game()
	queue_free()

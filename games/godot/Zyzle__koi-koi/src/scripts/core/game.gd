extends Node2D

@export var main_game: PackedScene;
@export var game_settings: PackedScene;

var game_settings_instance: GameSettings

func _on_main_menu_start_game():
	start_game()


func _on_game_settings_confirmed(rounds: int, ai_difficulty: AIPlayer.Difficulty) -> void:
	Global.game_rounds = rounds
	Global.ai_difficulty = ai_difficulty
	var game_instance = main_game.instantiate()
	add_child(game_instance)
	move_child(game_instance, 0)
	game_settings_instance.queue_free()


func start_game() -> void:
	game_settings_instance = game_settings.instantiate()
	game_settings_instance.connect("settings_confirmed", _on_game_settings_confirmed)
	add_child(game_settings_instance)
	move_child(game_settings_instance, 0)

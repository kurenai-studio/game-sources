extends Node

func _ready() -> void:
	GameManager.round_started.connect(_on_round_started)
	GameManager.game_over.connect(_on_game_over)
	
	# Start paused in the menu
	get_tree().paused = true

func _on_round_started() -> void:
	get_tree().paused = false

func _on_game_over() -> void:
	get_tree().paused = true

class_name GameSettings
extends Node2D

@export var rounds_group: ButtonGroup
@export var ai_level_group: ButtonGroup

@onready var rounds_3 = %Rounds3
@onready var rounds_6 = %Rounds6
@onready var rounds_12 = %Rounds12
@onready var ai_level_easy = %AIEasy
@onready var ai_level_medium = %AIMed
@onready var ai_level_hard = %AIHard

signal settings_confirmed(rounds: int, ai_difficulty: AIPlayer.Difficulty)

func _on_go_button_pressed():
	var rounds_button = rounds_group.get_pressed_button()
	var ai_level_button = ai_level_group.get_pressed_button()
	
	var rounds: int = 3
	var ai_difficulty: AIPlayer.Difficulty = AIPlayer.Difficulty.EASY

	match rounds_button:
		rounds_3:
			rounds = 3
		rounds_6:
			rounds = 6
		rounds_12:
			rounds = 12

	match ai_level_button:
		ai_level_easy:
			ai_difficulty = AIPlayer.Difficulty.EASY
		ai_level_medium:
			ai_difficulty = AIPlayer.Difficulty.MEDIUM
		ai_level_hard:
			ai_difficulty = AIPlayer.Difficulty.HARD

	settings_confirmed.emit(rounds, ai_difficulty)
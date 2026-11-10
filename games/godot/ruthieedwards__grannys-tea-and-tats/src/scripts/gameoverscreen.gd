extends Control

@export_file("*.tscn") var main_game_scene: String = ""

@onready var final_score_label: Label = $FinalScoreLabel
@onready var play_again_button: Button = $ReplayButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_button_pressed)
	final_score_label.text = "Final Score: " + str(snapped(GameManager.final_score, 0.1)) + "%"

func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file(main_game_scene)

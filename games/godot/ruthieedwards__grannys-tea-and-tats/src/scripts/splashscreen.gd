extends Control

@export_file("*.tscn") var main_game_scene: String = "res://scenes/Main.tscn"

@onready var play_button: Button = $PlayButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(main_game_scene)
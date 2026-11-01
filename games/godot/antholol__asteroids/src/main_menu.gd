extends Control
@onready var button_play: Button = $VBoxContainer/ButtonPLAY

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://root_scene.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().quit()
#end func

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		get_tree().quit()

func _ready() -> void:
	button_play.grab_focus()

extends Control

@onready var level_loader = $"../LevelLoader"
@onready var options_panel = $"../AudioSettings"

func _input(event):
	if event.is_action_pressed("pause_menu") and level_loader.get_child(0).name != "TitleScreen":
		toggle_pause()

func toggle_pause():
	if visible:
		pause_hide()
	else:
		pause_show()

func pause_show():
	visible = true
	get_tree().paused = true
	$PauseMenu/VBoxContainer/ContinueButton.grab_focus()

func pause_hide():
	visible = false
	get_tree().paused = false

func _on_continue_button_pressed() -> void:
	toggle_pause()

func _on_options_button_pressed() -> void:
	visible = false
	options_panel.visible = true
	options_panel.get_node("HBoxContainer/PanelContainer/VBoxContainer/back").grab_focus()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

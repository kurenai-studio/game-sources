extends Control

const UiInput := preload("res://scripts/ui_input.gd")
const GameSettings := preload("res://scripts/game_settings.gd")

const HARD_ON_COLOR := Color(1.0, 0.45, 0.5)
const HARD_OFF_COLOR := Color(0.55, 0.6, 0.72)
const HARD_FONT_STATES := [
	"font_color",
	"font_focus_color",
	"font_hover_color",
	"font_pressed_color",
	"font_hover_pressed_color",
]


func _ready() -> void:
	%HardModeToggle.button_pressed = GameSettings.maze_hard_mode
	_sync_hard_mode()
	%StickTrainingButton.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var viewport := get_viewport()
		if viewport != null and UiInput.activate_focused(viewport):
			viewport.set_input_as_handled()


func _on_controller_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controller_test.tscn")


func _on_stick_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stick_training.tscn")


func _on_movement_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/movement_training.tscn")


func _on_hard_mode_toggled(pressed: bool) -> void:
	GameSettings.maze_hard_mode = pressed
	_sync_hard_mode()


func _sync_hard_mode() -> void:
	var on: bool = %HardModeToggle.button_pressed
	%HardModeToggle.text = "Hard: ON" if on else "Hard: off"
	var color := HARD_ON_COLOR if on else HARD_OFF_COLOR
	for state in HARD_FONT_STATES:
		%HardModeToggle.add_theme_color_override(state, color)


func _on_maze_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/maze.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

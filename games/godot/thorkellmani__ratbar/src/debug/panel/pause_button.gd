class_name PauseButton extends Button

signal pause_requested
signal play_requested

var _is_paused: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)
	display_pause_state(_is_paused)


func display_pause_state(is_paused: bool) -> void:
	_is_paused = is_paused
	text = "▶" if _is_paused else "⏸"


func _on_pressed() -> void:
	if _is_paused:
		play_requested.emit()
	else:
		pause_requested.emit()

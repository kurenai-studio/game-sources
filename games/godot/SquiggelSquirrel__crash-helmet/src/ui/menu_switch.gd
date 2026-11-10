class_name MenuSwitchButton
extends Button

@export var next_menu :GameManager.Menu


func _pressed() -> void:
	GameManager.set_states(GameManager.state, next_menu)

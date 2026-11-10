extends Button


func _pressed() -> void:
	InputMap.load_from_project_settings()
	GameManager.inputs_remapped.emit()

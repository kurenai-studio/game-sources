extends Control


signal help_pressed()


func _on_help_button_pressed() -> void:
	help_pressed.emit()

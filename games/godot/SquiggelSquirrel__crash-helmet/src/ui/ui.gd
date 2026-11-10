extends Control


func _ready() -> void:
	get_tree().call_group(
			&"ui_buttons",
			&"connect",
			&"pressed",
			_on_button_pressed)


func _on_button_pressed() -> void:
	$Blip.play()

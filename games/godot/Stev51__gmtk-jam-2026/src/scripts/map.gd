extends Node2D

func _on_blank_space_clicker_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Globals.map_hoverable and Globals.clicked and Globals.hovered_countries <= 0:
			get_viewport().set_input_as_handled()
			Globals.map_unclick()

extends Control

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP

func _draw() -> void:
	if owner is RepairMinigame:
		owner.draw_wires(self)

func _gui_input(event: InputEvent) -> void:
	if owner is RepairMinigame:
		owner.on_canvas_input(event)

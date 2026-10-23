class_name MapButton
extends Button

signal make_map(map)

@export var map: String = "m1"


func _on_pressed() -> void:
	emit_signal("make_map", map)

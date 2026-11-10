extends Node2D

@export var rotation_speed: float = 1.0
@export var inverted: bool = false

func _process(delta: float) -> void:
	rotation_degrees += delta * 15.0 * rotation_speed * (-1.0 if inverted else 1.0)

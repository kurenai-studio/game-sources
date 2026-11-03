extends Node2D

## Sits above the avatar in draw order so the warning paints over her body.
var world: Node2D


func _draw() -> void:
	if world != null:
		world.draw_danger(self)

extends Node2D
## Generic node whose _draw is delegated to a callable.

var draw_fn: Callable


func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self)

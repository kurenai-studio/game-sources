extends Node2D

func _process(_delta: float) -> void:
	position.y = (sin(Time.get_ticks_msec() / 400.0) * 1.0) + 75.0

extends Control

@onready var hand_sprite_node = $Hand

func _process(_delta: float) -> void:
	hand_sprite_node.rotation_degrees = (DoomsdayClock.minutes / DoomsdayClock.MAX_MINUTES) * -360.0

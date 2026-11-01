extends AnimatedSprite2D



func _ready() -> void:
	play ("default")
	frame = randi() % sprite_frames.get_frame_count("default")
	speed_scale = randf_range(0.5, 1.5)

extends ParallaxBackground

func _physics_process(delta: float) -> void:
	scroll_base_offset.x -= Global.current_speed * delta

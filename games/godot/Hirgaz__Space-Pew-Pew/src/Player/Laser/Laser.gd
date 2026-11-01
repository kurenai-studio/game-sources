extends RigidBody2D


func exit_map() -> void:
	queue_free()


func hit_target() -> bool:
	queue_free()
	return true

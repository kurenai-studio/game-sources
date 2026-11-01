extends AnimationController
class_name PlayerAnimationController


func set_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		if animation.split("_")[0] != "idle":
			animation = "idle"
	elif animation.split("_")[0] != "move":
		animation = "move"
	super.set_direction(dir)
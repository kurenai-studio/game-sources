extends Area2D

@export var speed: float = 1000.0
var direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

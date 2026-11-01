extends RigidBody2D


@onready var despawn_timer : Timer = $DespawnTimer


func _ready() -> void:
	despawn_timer.wait_time = randf_range(0.5, 2.0)
	despawn_timer.start()


func exit_map() -> void:
	queue_free()


func _on_despawn_timer_timeout() -> void:
	queue_free()

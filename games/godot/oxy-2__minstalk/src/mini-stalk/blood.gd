extends CPUParticles2D

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(queue_free)

func _on_Timer_timeout():
	queue_free()

class_name Icesputter extends GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	one_shot = true
	emitting = true
	# Wait for the lifetime of the particles, then free the node
	await get_tree().create_timer(lifetime).timeout
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_finished() -> void:
	queue_free()

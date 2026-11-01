extends RigidBody2D


@export var part_scenes : Array[PackedScene]


func exit_map() -> void:
	queue_free()


func _spawn_parts() -> void:
	for i in randi_range(2, 6):
		var part : RigidBody2D = (part_scenes.pick_random() as PackedScene).instantiate()

		part.position = position
		part.rotation = randf() * 2 * PI
		part.linear_velocity = linear_velocity.rotated(randf_range(-PI / 6, PI / 6)) * randf_range(0.9, 1.5)
		part.angular_velocity = randf_range(PI / 4.0, PI / 3.0) * (randi_range(0, 2) - 1)

		get_parent().add_child.call_deferred(part)


func _on_detector_body_entered(body: Node2D) -> void:
	if body.has_method(&"hit_target") and body.hit_target():
		# TODO: Add to score.
		visible = false
		_spawn_parts()
		queue_free()
	elif body.has_method(&"collide_target") and body.collide_target(self):
		# TODO: React to hitting player.
		pass

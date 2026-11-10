class_name Spike
extends CharacterBody2D

var _is_falling := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var ray := $FloorFinder as RayCast2D
	var trigger_position :Vector2
	while ! ray.is_colliding():
		await get_tree().process_frame
	trigger_position = ray.get_collision_point() + Vector2.UP * 8.0
	$Trigger.global_position = trigger_position
	ray.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _is_falling:
		_process_falling(delta)


func _process_falling(delta: float) -> void:
	velocity += get_gravity() * delta
	var collision := move_and_collide(velocity * delta)
	if collision:
		collision_layer = 33
		collision_mask = 33
		process_mode = Node.PROCESS_MODE_DISABLED


func smash() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED 
	disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE
	get_node("Sprite2D").visible = false
	var particles := get_node("Particles") as CPUParticles2D
	particles.restart()
	particles.emitting = true
	$SmashSound.play()


func _on_trigger_body_entered(_body: Node2D) -> void:
	_is_falling = true
	$Trigger.queue_free()


func _on_particles_finished() -> void:
	queue_free()

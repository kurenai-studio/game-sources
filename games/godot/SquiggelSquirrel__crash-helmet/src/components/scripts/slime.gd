class_name Slime
extends CharacterBody2D


@onready var SCENE := load("res://components/scenes/slime.tscn")
const MAX_SPEED = 50.0
var _impulses := [0.0, 0.0, 0.0] as Array[float]


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()


func smash() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	get_node("Sprite").visible = false
	var particles := get_node("Particles") as CPUParticles2D
	particles.restart()
	particles.emitting = true
	$SquishSound.play()


func _on_timer_timeout() -> void:
	_impulses.pop_back()
	_impulses.push_back((randf() * 2.0 - 1.0) * MAX_SPEED)
	velocity.x = snappedf(
		(_impulses[0] + _impulses[1] + _impulses[2]) / 3.0,
		10.0)
	if velocity.x == 0.0 and ! $SpawnZone.has_overlapping_bodies():
		$Timer.paused = true
		await spawn_clone()
		$Timer.paused = false
	$Timer.wait_time = 3.0 + randf() * 3.0


func spawn_clone() -> void:
	var sprite := $Sprite as AnimatedSprite2D
	var tree := get_tree() as SceneTree
	var zone := $SpawnZone as Area2D
	sprite.speed_scale = 2.0
	await tree.create_timer(1.0).timeout
	sprite.speed_scale = 4.0
	await tree.create_timer(1.0).timeout
	sprite.speed_scale = 1.0
	sprite.play(&"splitting")
	await sprite.animation_finished
	if zone.has_overlapping_bodies():
		sprite.play_backwards(&"splitting")
		await sprite.animation_finished
		sprite.play(&"idle")
		return
	move_and_collide(Vector2(-8.0, 0))
	var new := SCENE.instantiate() as Slime
	new.global_position = zone.global_position
	get_parent().add_child(new, true)
	if collision_mask & 8 and randf() > 0.5:
		new.collision_mask |= 8
		collision_mask ^= 8
	sprite.play(&"idle")
	return


func _on_particles_finished() -> void:
	queue_free()

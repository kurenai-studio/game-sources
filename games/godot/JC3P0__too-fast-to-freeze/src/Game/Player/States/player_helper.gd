extends Node

@onready var animation_player: AnimationPlayer = $"../../Player4/AnimationPlayer"

func init_particles(player):
	player.idle_particles.emitting = false
	player.soft_turn_particles.emitting = false
	player.hard_turn_particles.emitting = false

func update_particle_effects(current_particles, speed: float):
	var speed_ratio = speed / 35

	if current_particles:
		current_particles.emitting = true
		current_particles.amount = int(lerp(8, 18, speed_ratio))
		
		var process_material = current_particles.process_material
		if process_material:
			process_material.initial_velocity_min = speed * 0.25
			process_material.initial_velocity_max = speed / 12
			process_material.scale_min = lerp(0.5, 1.0, speed_ratio)
			process_material.scale_max = lerp(1.0, 1.5, speed_ratio)

func handle_turn_input(player):
	if (player.turn_direction == 1 and Input.is_action_pressed("Turn_Left")) or \
	   (player.turn_direction == -1 and Input.is_action_pressed("Turn_Right")) or \
	   (player.turn_direction == 1 and not Input.is_action_pressed("Turn_Right")) or \
	   (player.turn_direction == -1 and not Input.is_action_pressed("Turn_Left")):
		player.player_state_manager.set_state("Idle")
		return true
	
	return false

func adjust_player_speed(target_speed: float, acc_rate: float, delta: float) -> void:
	var player = get_parent().player
	if player.player_speed < target_speed:
		player.player_speed += acc_rate * delta
	elif player.player_speed > target_speed + 1:
		player.player_speed -= acc_rate * delta
	elif target_speed == 0:
		player.player_speed = 0

func move_player(turn_speed: float, player, delta: float):
	#var current_pos = player.position
	#var target_x = current_pos.x + (player.turn_direction * turn_speed * delta)
	#player.position.x = target_x
	player.velocity.x = player.turn_direction * turn_speed
	player.move_and_slide()

func rotate_player(rotation_angle: float, rotation_speed: float, player, delta: float):
	var target_rotation = -player.turn_direction * rotation_angle
	var current_rotation = player.rotation.y
	var new_rotation = lerp(current_rotation, deg_to_rad(target_rotation), rotation_speed * delta)
	player.rotation.y = new_rotation

func determine_turn_direction(turn_direction):
	if Input.is_action_pressed("Turn_Right"):
		animation_player.play("TurnRight")
		turn_direction = 1
	elif Input.is_action_pressed("Turn_Left"):
		animation_player.play("TurnLeft")
		turn_direction = -1
	return turn_direction

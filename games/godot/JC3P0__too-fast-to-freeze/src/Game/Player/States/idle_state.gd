extends Node
var player

func set_player(player_instance):
	player = player_instance

func enter_state():
	print("entered: idle state")
	player.turn_direction = 0
	player.animation_player.play("SkiForward")
	#if Input.is_action_pressed("Turn_Right"):
		#player.player_state_manager.set_state("Soft")

	#if Input.is_action_pressed("Turn_Left"):
		#player.player_state_manager.set_state("Soft")

func exit_state():
	player.idle_particles.emitting = false

func handle_input(_event):
	if Input.is_action_pressed("Jump"):
		player.player_state_manager.set_state("Jump")

	if Input.is_action_pressed("Turn_Right") or Input.is_action_pressed("Turn_Left"):
		player.player_state_manager.set_state("Soft")

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(player.stats.idle_max_speed, player.stats.acc_rate, delta)
	player.player_state_manager.player_helper.rotate_player(0.0, player.stats.rotation_speed, player, delta)
	player.player_state_manager.player_helper.update_particle_effects(player.idle_particles, player.player_speed)

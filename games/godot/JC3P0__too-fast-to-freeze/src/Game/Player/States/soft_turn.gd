extends Node
var player
var hard_turn_timer: Timer

func set_player(player_instance):
	player = player_instance
	hard_turn_timer = Timer.new()
	hard_turn_timer.wait_time = 0.6  
	hard_turn_timer.one_shot = true
	hard_turn_timer.connect("timeout", Callable(self, "_on_hard_turn_timer_timeout"))
	player.add_child(hard_turn_timer)

func enter_state():
	print("entered: soft_turn state")
	player.turn_direction = player.player_state_manager.player_helper.determine_turn_direction(player.turn_direction)
	hard_turn_timer.start()

func exit_state():
	player.soft_turn_particles.emitting = false

func handle_input(_event):
	if Input.is_action_pressed("Jump"):
		hard_turn_timer.stop()
		player.player_state_manager.set_state("Jump")

	if player.player_state_manager.player_helper.handle_turn_input(player):
		hard_turn_timer.stop()

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(player.stats.soft_max_speed, player.stats.acc_rate, delta)
	player.player_state_manager.player_helper.move_player(player.stats.soft_turn_speed, player, delta)
	player.player_state_manager.player_helper.rotate_player(player.stats.soft_rotation_angle, player.stats.rotation_speed, player, delta)
	player.player_state_manager.player_helper.update_particle_effects(player.soft_turn_particles, player.player_speed)

func _on_hard_turn_timer_timeout():
	if player.player_state_manager.current_state_name == "Vuln":
		return

	if player.turn_direction == 1 and Input.is_action_pressed("Turn_Right"):
		player.player_state_manager.set_state("Hard")
	elif player.turn_direction == -1 and Input.is_action_pressed("Turn_Left"):
		player.player_state_manager.set_state("Hard")
	else:
		player.player_state_manager.set_state("Idle")

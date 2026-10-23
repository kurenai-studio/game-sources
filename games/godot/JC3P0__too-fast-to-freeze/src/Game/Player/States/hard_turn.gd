extends Node
var player
var stop_turn_timer: Timer

func set_player(player_instance):
	player = player_instance
	stop_turn_timer = Timer.new()
	stop_turn_timer.wait_time = 1.0  
	stop_turn_timer.one_shot = true
	stop_turn_timer.connect("timeout", Callable(self, "_on_stop_turn_timer_timeout"))
	player.add_child(stop_turn_timer)

func enter_state():
	print("entered: hard_turn state")
	player.turn_direction = player.player_state_manager.player_helper.determine_turn_direction(player.turn_direction)
	stop_turn_timer.start()

func exit_state():
	player.hard_turn_particles.emitting = false

func handle_input(_event):
	if Input.is_action_pressed("Jump"):
		stop_turn_timer.stop()
		player.player_state_manager.set_state("Jump")

	if player.player_state_manager.player_helper.handle_turn_input(player):
		stop_turn_timer.stop()

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(player.stats.hard_max_speed, player.stats.acc_rate, delta)
	player.player_state_manager.player_helper.move_player(player.stats.hard_turn_speed, player, delta)
	player.player_state_manager.player_helper.rotate_player(player.stats.hard_rotation_angle, player.stats.rotation_speed, player, delta)
	player.player_state_manager.player_helper.update_particle_effects(player.hard_turn_particles, player.player_speed)

func _on_stop_turn_timer_timeout():
	if player.player_state_manager.current_state_name == "Vuln":
		return

	if player.turn_direction == 1 and Input.is_action_pressed("Turn_Right"):
		player.player_state_manager.set_state("Stop")
	elif player.turn_direction == -1 and Input.is_action_pressed("Turn_Left"):
		player.player_state_manager.set_state("Stop")
	else:
		player.player_state_manager.set_state("Idle")

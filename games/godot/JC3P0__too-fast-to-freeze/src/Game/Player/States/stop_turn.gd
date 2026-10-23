extends Node
var player

func set_player(player_instance):
	player = player_instance

func enter_state():
	print("entered: stop_turn state")
	player.turn_direction = player.player_state_manager.player_helper.determine_turn_direction(player.turn_direction)

func exit_state():
	player.idle_particles.emitting = false

func handle_input(_event):
	if player.player_state_manager.player_helper.handle_turn_input(player):
		print("stop_turn: player released button or pressed a different direction")

func process_state(delta):
	player.player_state_manager.player_helper.adjust_player_speed(0.0, player.stats.acc_rate * 4, delta)
	player.player_state_manager.player_helper.rotate_player(player.stats.stop_rotation_angle, player.stats.rotation_speed, player, delta)

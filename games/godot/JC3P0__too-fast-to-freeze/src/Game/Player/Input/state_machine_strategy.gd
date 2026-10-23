class_name StateMachineStrategy
extends InputStrategy

## Wraps the existing player_state_manager turn system (Idle, Soft, Hard, Stop, Jump, Vuln).
## player_state_manager self-ticks via its own _physics_process as a child node,
## so process_input is a no-op here. This strategy just handles input event routing
## and keeps the interface consistent with DirectionalStrategy.

func process_input(player: CharacterBody3D, _delta: float) -> void:
	# player_state_manager runs its own _physics_process — no extra processing needed.
	# Sync unified movement vars so obstacle_move.gd always reads from the same place.
	player.player_direction = Vector3(0, 0, 1)
	player.player_current_speed = player.player_speed

func handle_input_event(player: CharacterBody3D, event: InputEvent) -> void:
	if player.player_state_manager.current_state_name == "Vuln":
		return
	if player.player_state_manager.current_state:
		player.player_state_manager.current_state.handle_input(event)

func get_strategy_name() -> String:
	return "StateMachine"

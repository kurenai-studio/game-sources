extends Node

@onready var player_helper = $PlayerHelper

var player
var current_state: Node = null
var current_state_name: String = ""
var states = {}

func initialize(player_instance):
	player = player_instance
	load_states()

func load_states() -> void:
	states["Idle"] = $idle_state
	states["Soft"] = $soft_turn
	states["Hard"] = $hard_turn
	states["Stop"] = $stop_turn
	states["Jump"] = $jump
	states["Vuln"] = $vulnerable

	for state in states.values():
		state.set_player(player)

func set_state(state_name: String) -> void:
	if current_state:
		current_state.exit_state()

	current_state = states.get(state_name)
	current_state_name = state_name
	if current_state:
		current_state.enter_state()
	else:
		print("State not found:", state_name)

func _physics_process(delta):
	if current_state:
		current_state.process_state(delta)

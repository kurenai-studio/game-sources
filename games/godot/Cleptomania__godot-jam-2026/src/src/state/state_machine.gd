class_name StateMachine extends Node

@export var initial_state: State = null

@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()

func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to)
	
	await owner.ready
	state.enter("")

func _unhandled_input(event: InputEvent) -> void:
	state.input(event)
	
func _process(delta: float) -> void:
	state.update(delta)
	
func _physics_process(delta: float) -> void:
	state.physics_update(delta)

func _transition_to(target_state: String, data: Dictionary = {}) -> void:
	if not has_node(target_state):
		printerr(owner.name + ": Tried to transition to state " + target_state + " but it doesn't exist.")
		return
		
	var previous_state := state.name
	state.exit()
	state = get_node(target_state)
	state.enter(previous_state, data)

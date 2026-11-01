extends State

#transition states
@export var air_state: State

@export var jump_force: float

func enter() -> void:
	super()
	parent.velocity.y = -jump_force 
	
func process_physics(delta: float) -> State:
	return air_state

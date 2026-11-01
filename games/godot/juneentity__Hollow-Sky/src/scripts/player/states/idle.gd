extends State

# transition states
@export var walk_state : State
@export var jump_state: State
@export var air_state : State

func enter() -> void:
	super()
	parent.velocity.x = 0

func process_input(event: InputEvent) -> State:
	if Input.is_action_just_pressed("fly") and parent.is_on_floor():
		return jump_state
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		return walk_state
	return null

func process_physics(delta: float) -> State:
	parent.velocity.y += gravity * delta
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return air_state
	return null

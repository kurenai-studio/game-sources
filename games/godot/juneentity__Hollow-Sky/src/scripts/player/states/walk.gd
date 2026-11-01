extends State

# transition states
@export var jump_state : State
@export var air_state : State 
@export var idle_state : State

@export var walk_speed: float
@export var walk_acc: float
@export var walk_friction: float





func enter() -> void:
	super()

func process_physics(delta: float) -> State:
	var move_dir := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	if parent.is_on_floor():
		if Input.is_action_pressed("fly"):
			return jump_state
		if move_dir != 0:
			var target = walk_speed * move_dir
			parent.velocity.x = move_toward(parent.velocity.x, target, walk_acc*delta)
		else:
			parent.velocity.x = move_toward(parent.velocity.x, 0, walk_friction*delta)
	
	parent.velocity.y += gravity * delta
	parent.move_and_slide()
	
	if !parent.is_on_floor():
		return air_state
	if abs(move_dir) == 0.0 and abs(parent.velocity.x) <= epsilon:
		return idle_state
	return null

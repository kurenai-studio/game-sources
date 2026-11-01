extends State

@export var idle_state: State
@export var walk_state : State

@export var fall_max_speed : float
@export var strafe_max_speed : float
@export var strafe_acc : float
@export var strafe_friction : float

func enter() -> void:
	super()
	
func process_physics(delta : float) -> State:
	var move_dir := int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	parent.velocity.y = move_toward(parent.velocity.y, fall_max_speed, gravity*delta)
	parent.move_and_slide()
	
	if move_dir != 0:
		var target = strafe_max_speed * move_dir
		parent.velocity.x = move_toward(parent.velocity.x, target, strafe_acc*delta)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, strafe_friction*delta)
	
	if parent.is_on_floor():
		if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
			return walk_state
		else:
			return idle_state
	return null

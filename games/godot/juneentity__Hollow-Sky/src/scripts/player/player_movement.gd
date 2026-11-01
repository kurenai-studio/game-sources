extends CharacterBody2D


@export var MOVE_MAX_VEL := 300.0
@export var MOVE_ACC := 30.0
@export var FLY_MAX_VEL := -400.0
@export var FLY_ACC := 40.0

@export var MAX_ENERGY := 1.5
@export var MAX_HEALTH := 1


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("fly") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

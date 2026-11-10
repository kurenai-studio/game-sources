extends CharacterBody2D


const HORIZONTAL_CATCHUP_SPEED := 50.0
const FALL_SPEED_MULTIPLIER := 2.5
const JUMP_VELOCITY := -1000.0


func reset_position() -> void:
	position = Vector2(0, 0)


func _physics_process(delta: float) -> void:
	if not is_on_floor(): 
		var is_falling = velocity.y > 0
		
		# Allow player to hold for longer jumps... 
		# or early release for small jump
		if not is_falling and not Input.is_action_pressed("ui_accept"):
			velocity.y = 0   
		
		velocity.y += (get_gravity() * delta * FALL_SPEED_MULTIPLIER).y
		
		# Make falling a bit faster than jumping
		if is_falling:
			velocity.y *= 1 + (delta)
	
	# Make the player catch up if they've fallen behind
	if position.x < 0:
		velocity.x += HORIZONTAL_CATCHUP_SPEED * delta
	else:
		position.x = 0
		velocity.x = 0

	# Handle jump.
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Adjust player / stick rotation based on player Y position
	rotation_degrees = (position.y * 0.1)

	move_and_slide()

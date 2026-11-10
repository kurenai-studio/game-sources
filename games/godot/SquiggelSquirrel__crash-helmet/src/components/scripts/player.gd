class_name Player
extends CharacterBody2D

signal die
signal win

const THRUST = 80.0
const SPEED = 300.0
const JUMP_VELOCITY = -240.0
#var _input_reversed := false
var _jump_cancel_countdown := 0.0


func _physics_process(delta: float) -> void:
	var head := $Head as AnimatedSprite2D
	var skis := $Skis as Sprite2D
	
	# Add the gravity.
	if not is_on_floor():
		if absf(velocity.y) < 1.0:
			velocity += get_gravity() * delta * 0.5
		else:
			velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_jump_cancel_countdown = 0.15
		$JumpSound.play()
	_jump_cancel_countdown = move_toward(_jump_cancel_countdown, 0.0, delta)
	if Input.is_action_just_released("jump") and _jump_cancel_countdown > 0.0:
		velocity.y *= 0.5
		_jump_cancel_countdown = 0.0  

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	#if _input_reversed:
		#direction *= -1.0
	
	var friction :float
	if absf(velocity.x) > SPEED:
		friction = 1.0
	elif not is_on_floor():
		friction = 2.0
	elif is_on_ice():
		friction = 2.0
	else:
		friction = 10.0
	
	var floor_normal := Vector2.UP
	if is_on_floor():
		floor_normal = get_floor_normal()
	var vector_right := -1.0 * floor_normal.orthogonal()
	
	if direction and abs(velocity.x) < SPEED:
		velocity += vector_right * direction * THRUST * delta * friction
	elif ! direction:
		velocity.x = move_toward(
				velocity.x,
				0,
				abs(velocity.x) * friction * delta)
	if abs(velocity.x) < 1.0:
		velocity.x = 0.0
		
	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and ! was_on_floor:
		velocity = get_real_velocity()
	
	var can_smash := bool(
			absf(get_real_velocity().x) > 250.0
			or absf(get_real_velocity().y) > 250.0)
	if can_smash:
		smash_blocks()
		
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		if can_smash:
			head.play(&"head_down_running")
		else:
			head.play(&"running")
	else:
		if can_smash:
			head.play(&"head_down")
		else:
			head.play(&"idle")
	
	var v := get_real_velocity()
	var facing_left := bool(v.x < 0)
	var a := v.angle()
	if abs(v.x) + abs(v.y) < 10.0:
		a = 0
	else:
		head.flip_h = facing_left
		skis.flip_h = facing_left
	if facing_left:
		a = wrapf(a + PI, -PI, PI)
	skis.rotation = rotate_toward(
			skis.rotation,
			clampf(a, -0.25 * PI, 0.25 * PI),
			2.0 * delta)
	head.rotation = skis.rotation * 0.5
	
	$CPUParticles2D.emitting = bool(is_on_ice() and velocity.length_squared() > 10000)
	


func smash_blocks() -> void:
	var ray := $RayCast2D as RayCast2D
	ray.target_position = velocity.sign() * 16.0
	ray.force_raycast_update()
	if ! ray.is_colliding():
		return
	var block := ray.get_collider()
	if block.has_method(&"smash"):
		block.smash()


func is_on_ice() -> bool:
	if ! is_on_floor():
		return false
	var ray := $IceSense as RayCast2D
	return ray.is_colliding()


func bounce() -> void:
	pass


func _on_hazard_sense_body_entered(_body: Node2D) -> void:
	die.emit()
	$DeathSound.play()


func emit_win() -> void:
	win.emit()

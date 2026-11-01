extends CharacterBody2D

# Constants
const GRAVITY: float = 1200.0
const JUMP_FORCE: float = -400.0
const MAX_SPEED: float = 200.0
const ACCELERATION: float = 700.0
const DEFAULT_FRICTION: float = 300.0
const EARLY_JUMP_GRAVITY_MULTIPLIER: float = 2.0
const COYOTE_TIME: float = 0.1  # 1/10 second
const SHAKE_TIME: float = 0.2

const FALL_SHAKE_THRESHOLD: float = 600.0  # Shake speed threshold
const SHAKE_DURATION: float = 0.2  # duration
const SHAKE_STRENGTH: float = 6.0
const SHAKE_EPSILON: float = 0.05

# State
var has_jumped: bool = false
var coyote_timer: float = 0.0
var was_on_floor: bool = false
var fell_hard: bool = false

# Camera
@onready var sprite: Sprite2D = $MainCharacterSprite
@onready var camera: Camera2D = $"../Camera2D"
var shake_timer: float = 0.0

func _physics_process(delta: float) -> void:
	
	var direction := Input.get_axis("left", "right")
	var current_friction = DEFAULT_FRICTION

	# Horizontal movement with dynamic friction
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION * delta)
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)

	# Coyote time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jumping
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		velocity.y = JUMP_FORCE
		has_jumped = true
		coyote_timer = 0.0

	# Gravity
	if not is_on_floor():
		if velocity.y < 0 and has_jumped and not Input.is_action_pressed("jump"):
			velocity.y += GRAVITY * EARLY_JUMP_GRAVITY_MULTIPLIER * delta
		else:
			velocity.y += GRAVITY * delta

	# Detect fall impact
	if not is_on_floor() and velocity.y > FALL_SHAKE_THRESHOLD:
		fell_hard = true

	# Landed this frame
	if is_on_floor() and not was_on_floor:
		if fell_hard:
			start_camera_shake()
			fell_hard = false

	was_on_floor = is_on_floor()

	move_and_slide()

	# Camera shake
	if shake_timer > 0:
		shake_timer -= delta
		camera.offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * SHAKE_STRENGTH
	else:
		camera.offset = Vector2.ZERO

func start_camera_shake():
	shake_timer = SHAKE_DURATION
	Input.start_joy_vibration(0,1,1,shake_timer+SHAKE_EPSILON)

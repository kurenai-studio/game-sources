extends RigidBody2D


const LASER_SCENE = preload("res://Player/Laser/Laser.tscn")


const TURN_ACCEL = 20.0
const TURN_DECEL = 20.0
const MAX_ANGULAR_VELOCITY = PI

const MOVE_FORWARD_ACCEL = 300.0
const MOVE_BACK_ACCEL = 128.0
const MOVE_DECEL = 128.0
const MAX_MOVE_VELOCITY = 256.0

const HIT_COOLDOWN = 4.0
const HIT_REPEAT = 6
const SHOOT_COOLDOWN = 1.0 / 5.0
const LASER_VELOCITY = 500


@onready var laser_audio_player := $LaserAudioPlayer
@onready var marker_left := $MarkerLeft
@onready var marker_right := $MarkerRight
@onready var thrust := $Thrust
@onready var thruster_audio_player := $ThrusterAudioPlayer


var lives := 5
var shoot_time := 0.0
var is_hit := false
var hit_tween : Tween


func exit_map() -> void:
	# Wrap position.
	global_position = -global_position


func collide_target(_area: PhysicsBody2D) -> bool:
	if not is_hit:
		# TODO: Add some form of reflection?
		_get_hit()
		return true

	return false


func _get_hit() -> void:
	if hit_tween:
		hit_tween.kill()

	# Remove life, die if needed.
	if lives == 1:
		UI.game_over()
		return
	else:
		lives -= 1
		_update_lives()

	hit_tween = get_tree().create_tween()
	var pulse_tween := get_tree().create_tween().set_trans(Tween.TRANS_SINE)
	pulse_tween.set_ease(Tween.EASE_OUT).tween_property(self, "modulate", Color(1, 1, 1, 0.25), HIT_COOLDOWN / (HIT_REPEAT * 2.0))
	pulse_tween.set_ease(Tween.EASE_IN).tween_property(self, "modulate", Color(1, 1, 1, 1), HIT_COOLDOWN / (HIT_REPEAT * 2.0))
	pulse_tween.set_loops(HIT_REPEAT)
	hit_tween.tween_callback(_start_hit)
	hit_tween.tween_subtween(pulse_tween)
	hit_tween.tween_callback(_end_hit)


func _start_hit() -> void:
	is_hit = true


func _end_hit() -> void:
	is_hit = false
	# Reset shoot cooldown.
	shoot_time = SHOOT_COOLDOWN


func _ready() -> void:
	_update_lives()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var step := state.get_step()

	# Handle shooting.
	var shoot := Input.is_action_pressed(&"shoot")

	if shoot and not is_hit and shoot_time <= 0.0:
		shoot_time = SHOOT_COOLDOWN
		_spawn_laser.call_deferred()
	elif shoot_time > 0.0:
		shoot_time = max(shoot_time - step, 0.0)

	# Handle turning.
	var ang_velocity := state.get_angular_velocity()

	var turn_left := Input.is_action_pressed(&"turn_left")
	var turn_right := Input.is_action_pressed(&"turn_right")

	if turn_left != turn_right:
		if turn_left:
			if ang_velocity > -MAX_ANGULAR_VELOCITY:
				ang_velocity -= TURN_ACCEL * step
		elif turn_right:
			if ang_velocity < MAX_ANGULAR_VELOCITY:
				ang_velocity += TURN_ACCEL * step
	else:
		var abs_vel := absf(ang_velocity)
		abs_vel -= TURN_DECEL * step
		if abs_vel < 0:
			abs_vel = 0
		ang_velocity = signf(ang_velocity) * abs_vel

	state.set_angular_velocity(ang_velocity)

	# Handle acceleration/deceleration.
	var velocity := state.get_linear_velocity()

	var move_forward := Input.is_action_pressed(&"move_forward")
	var move_back := Input.is_action_pressed(&"move_back")

	if move_forward != move_back:
		# Forward direction in local space.
		var forward := transform.basis_xform(Vector2(0, -1.0))
		if move_forward:
			velocity = velocity.move_toward(forward * MAX_MOVE_VELOCITY, MOVE_FORWARD_ACCEL * step)
		elif move_back:
			velocity = velocity.move_toward(forward * -MAX_MOVE_VELOCITY, MOVE_BACK_ACCEL * step)

		if not thruster_audio_player.playing:
			thruster_audio_player.playing = true
		if not thrust.visible:
			thrust.visible = true
	else:
		velocity = velocity.move_toward(Vector2(), MOVE_DECEL * step)
		thruster_audio_player.playing = false
		thrust.visible = false

	state.set_linear_velocity(velocity)


func _spawn_laser_at(laser_position: Vector2) -> void:
	var laser : RigidBody2D = LASER_SCENE.instantiate()

	laser.rotation = global_rotation
	laser.position = laser_position

	laser.linear_velocity = global_transform.basis_xform(Vector2(0.0, -LASER_VELOCITY))

	get_parent().add_child.call_deferred(laser)
	add_collision_exception_with(laser)


func _spawn_laser() -> void:
	laser_audio_player.get_stream_playback().play_stream(preload("res://Player/Laser/LaserSound.ogg"))
	_spawn_laser_at(marker_left.global_position)
	_spawn_laser_at(marker_right.global_position)


func _update_lives() -> void:
	UI.update_health(lives)

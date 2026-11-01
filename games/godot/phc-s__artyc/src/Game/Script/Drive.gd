extends RigidBody2D

@export var speed_label: RichTextLabel

const MAX_SPEED: float = 450.0
const MAX_REVERSE: float = -50.0
const ACCEL_POWER: float = 75.0  
const BRAKE_POWER: float = 150.0  
const DECEL_POWER: float = 100.0  

const MAX_STEER_ANGLE: float = 0.025  
const STEER_SPEED: float = 0.04        

var steering_input: float = 0.0
var current_velocity: float = 0.0

func _physics_process(delta: float) -> void:
	var accel_input: float = Input.get_axis("down", "up") # Ranges continuously from -1.0 to 1.0
	
	if accel_input > 0.05:
		current_velocity += accel_input * ACCEL_POWER * delta
	elif accel_input < -0.05:
		current_velocity += accel_input * BRAKE_POWER * delta
	else:
		current_velocity = move_toward(current_velocity, 0.0, DECEL_POWER * delta)

	current_velocity = clamp(current_velocity, MAX_REVERSE, MAX_SPEED)
	var speed_ratio: float = abs(current_velocity) / MAX_SPEED

	var raw_steer: float = Input.get_axis("left", "right")

	if abs(raw_steer) > 0.05:
		steering_input = move_toward(steering_input, raw_steer, STEER_SPEED)
	else:
		var return_rate: float = lerp(0.02, 0.12, speed_ratio)
		steering_input = move_toward(steering_input, 0.0, return_rate)

	var turn_ability: float = 0.0
	if speed_ratio > 0.02:
		turn_ability = sin(speed_ratio * PI) * 0.7 + (1.0 - speed_ratio) * 0.3

	var reverse_factor: float = -1.0 if current_velocity < 0 else 1.0
	rotation += steering_input * MAX_STEER_ANGLE * turn_ability * reverse_factor

	linear_velocity = Vector2.from_angle(rotation) * current_velocity

	if speed_label:
		speed_label.text = str(int(abs(current_velocity / 5.0)))

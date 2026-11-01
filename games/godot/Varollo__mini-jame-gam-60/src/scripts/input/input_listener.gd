extends Node
class_name InputListener

const DIR_DOWN = "_down"
const DIR_UP = "_up"
const DIR_LEFT = "_left"
const DIR_RIGHT = "_right"

signal input_fired
signal input_vector_fired(vec: Vector2)

signal input_released
signal input_vector_released(vec: Vector2)

@export var action: String = ""
@export var is_vector: bool = false

var _prev_vec: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	if is_vector:
		var vec = Input.get_vector(
			action + DIR_LEFT, action + DIR_RIGHT, action + DIR_UP, action + DIR_DOWN
		)
		if vec != Vector2.ZERO:
			_prev_vec = vec
			input_vector_fired.emit(vec)
		elif vec != _prev_vec:
			_prev_vec = vec
			input_vector_released.emit(Vector2.ZERO)

	elif Input.is_action_pressed(action):
		input_fired.emit()
	elif Input.is_action_just_released(action):
		input_released.emit()

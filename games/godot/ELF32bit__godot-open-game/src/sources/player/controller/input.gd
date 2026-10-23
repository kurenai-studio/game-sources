extends Node

enum InputMode { MOUSE, JOYPAD }
var input_mode: InputMode = InputMode.MOUSE

const MOUSE_SENSITIVITY: float = 0.276
@export var mouse_sensitivity: float = 0.5
func get_mouse_sensitivity() -> float:
	return lerpf(0.0, MOUSE_SENSITIVITY, mouse_sensitivity)

const JOYPAD_SENSITIVITY: float = 5.76
@export var joypad_sensitivity: float = 0.5
func get_joypad_sensitivity() -> float:
	return lerpf(0.0, JOYPAD_SENSITIVITY, joypad_sensitivity)

var mouse_motion := Vector2.ZERO
var joy_axis_right := Vector2.ZERO

var move_vector := Vector2.ZERO
const JOY_AXIS_DEADZONE: float = 0.1

@onready var viewport := get_viewport()
var mouse_visible_position := Vector2i.ZERO

var camera_scroll_number: int = 0
var is_camera_orbit_pressed := false
var is_camera_focus_pressed := false

func get_camera_scroll_number() -> int:
	var number := int(camera_scroll_number)
	camera_scroll_number = 0
	return number

var is_jump_pressed := false
var is_jump_just_pressed := false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		input_mode = InputMode.MOUSE

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			mouse_motion += event.relative
			return

	if event is InputEventMouseButton:
		if event.is_action_pressed("player_camera_closer"):
			camera_scroll_number += 1
		if event.is_action_pressed("player_camera_further"):
			camera_scroll_number -= 1

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	joy_axis_right = Input.get_vector(
		"player_joy_right_stick_left", "player_joy_right_stick_right",
		"player_joy_right_stick_up", "player_joy_right_stick_down")
	if joy_axis_right != Vector2.ZERO:
		input_mode = InputMode.JOYPAD

	if Input.is_action_pressed("player_camera_closer"):
		camera_scroll_number += 1
	if Input.is_action_pressed("player_camera_further"):
		camera_scroll_number -= 1

	is_camera_orbit_pressed = Input.is_action_pressed("player_camera_orbit")
	is_camera_focus_pressed = Input.is_action_pressed("player_camera_focus")

	if input_mode == InputMode.MOUSE:
		if is_camera_orbit_pressed or is_camera_focus_pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				mouse_visible_position = viewport.get_mouse_position()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not is_camera_orbit_pressed and not is_camera_focus_pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Input.warp_mouse(mouse_visible_position)
	elif input_mode == InputMode.JOYPAD:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	move_vector = Input.get_vector(
		"player_move_left", "player_move_right",
		"player_move_back", "player_move_forward")
	if absf(move_vector.x) < JOY_AXIS_DEADZONE: move_vector.x = 0.0
	if absf(move_vector.y) < JOY_AXIS_DEADZONE: move_vector.y = 0.0
	if is_camera_focus_pressed and is_camera_orbit_pressed:
		move_vector.y = 1.0

	is_jump_pressed = Input.is_action_pressed("player_jump")
	is_jump_just_pressed = Input.is_action_just_pressed("player_jump")


func get_free_look() -> Vector2:
	var free_look := Vector2.ZERO
	free_look -= mouse_motion * get_mouse_sensitivity()
	free_look -= joy_axis_right * get_joypad_sensitivity()
	mouse_motion = Vector2.ZERO
	return free_look

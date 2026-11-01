extends Control

@export var action_negative: String = "left"    
@export var action_positive: String = "right"   
@export var is_vertical_axis: bool = false     

@export var joystick_radius: float = 65.0

var touch_index: int = -1
var touch_origin: Vector2 = Vector2.ZERO
var output_value: float = 0.0

func _ready() -> void:
	reset_joystick()

func _gui_input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and touch_index == -1:
			touch_index = -99 
			touch_origin = event.position 
			update_joystick(event.position)
		elif not event.pressed and touch_index == -99:
			reset_joystick()
			
	elif event is InputEventMouseMotion and touch_index == -99:
		update_joystick(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			touch_origin = event.position 
			update_joystick(event.position)
		elif not event.pressed and event.index == touch_index:
			reset_joystick()
			
	elif event is InputEventScreenDrag and event.index == touch_index:
		update_joystick(event.position)

func update_joystick(pos: Vector2) -> void:

	var vector = pos - touch_origin
	
	if vector.length() > joystick_radius:
		vector = vector.normalized() * joystick_radius
	
	var raw_val = (vector.y if is_vertical_axis else vector.x) / joystick_radius
	if is_vertical_axis:
		raw_val = -raw_val 
		
	output_value = raw_val
	apply_to_input_map()

func reset_joystick() -> void:
	touch_index = -1
	touch_origin = Vector2.ZERO
	output_value = 0.0
	apply_to_input_map()

func apply_to_input_map() -> void:
	if output_value < -0.05:
		Input.action_press(action_negative, abs(output_value))
		Input.action_release(action_positive)
	elif output_value > 0.05:
		Input.action_press(action_positive, abs(output_value))
		Input.action_release(action_negative)
	else:
		Input.action_release(action_negative)
		Input.action_release(action_positive)

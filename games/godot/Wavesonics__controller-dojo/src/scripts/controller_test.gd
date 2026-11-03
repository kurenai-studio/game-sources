extends Control

const UiInput := preload("res://scripts/ui_input.gd")

@onready var _device_label: Label = %DeviceLabel
@onready var _left_stick: Control = %LeftStick
@onready var _right_stick: Control = %RightStick
@onready var _left_value: Label = %LeftValue
@onready var _right_value: Label = %RightValue
@onready var _back: Button = %BackButton

var _device: int = -1


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_pick_device()


func _process(_delta: float) -> void:
	_left_value.text = _format(_left_stick.value)
	_right_value.text = _format(_right_stick.value)


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			if UiInput.activate_focused(viewport):
				viewport.set_input_as_handled()
			return
		if event.button_index in UiInput.MENU_BUTTONS:
			UiInput.toggle_back(_back)
			viewport.set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _format(stick: Vector2) -> String:
	return "x %+.2f    y %+.2f" % [stick.x, stick.y]


func _pick_device() -> void:
	var pads := Input.get_connected_joypads()
	_device = pads[0] if not pads.is_empty() else -1
	_left_stick.device = _device
	_right_stick.device = _device
	if _device >= 0:
		_device_label.text = "%s (device %d)" % [Input.get_joy_name(_device), _device]
	else:
		_device_label.text = "No controller connected"


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	_pick_device()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

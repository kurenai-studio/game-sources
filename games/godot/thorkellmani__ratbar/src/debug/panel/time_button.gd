class_name TimeButton extends Button

signal running_speed_requested(speed: float)

const RUNNING_SPEEDS := [1.0, 5.0, 10.0, 0.5]

var _index: int = 0


func _ready() -> void:
	pressed.connect(_on_pressed)
	display_running_speed(RUNNING_SPEEDS[_index])


func display_running_speed(speed: float) -> void:
	var speed_index: int = RUNNING_SPEEDS.find(speed)

	if speed_index == -1:
		push_error("TimeButton received an unsupported speed: %s." % speed)
		return

	_index = speed_index
	text = "Time: %.1fx" % speed


func _on_pressed() -> void:
	var next_index: int = (_index + 1) % RUNNING_SPEEDS.size()
	running_speed_requested.emit(RUNNING_SPEEDS[next_index])

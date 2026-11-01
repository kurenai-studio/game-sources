extends Node2D

var active_actions: Dictionary[int, StringName] = {}

func _input(event):
	if event is InputEventScreenTouch:
		_handle_pointer_event(event.index, event.position, event.pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_pointer_event(-1, event.position, event.pressed)

func _handle_pointer_event(pointer_id: int, pointer_position: Vector2, pressed: bool) -> void:
	var action_name: StringName = _get_action_for_position(pointer_position)

	if pressed:
		active_actions[pointer_id] = action_name
		Global.set_touch_action(action_name, true)
	elif active_actions.has(pointer_id):
		Global.set_touch_action(active_actions[pointer_id], false)
		active_actions.erase(pointer_id)

func _get_action_for_position(pointer_position: Vector2) -> StringName:
	var viewport_size := get_viewport_rect().size
	if pointer_position.x < viewport_size.x * 0.5:
		return &"up"
	return &"down"

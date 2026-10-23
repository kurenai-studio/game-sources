extends Node


var input_action_buffer:Array[String] = []


func is_pressed(action:String) -> bool:
	if input_action_buffer.is_empty():
		return false
	return input_action_buffer[input_action_buffer.size() - 1] == action


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("walk_left"):
		input_action_buffer.append("walk_left")
	elif Input.is_action_just_pressed("walk_right"):
		input_action_buffer.append("walk_right")
	elif Input.is_action_just_pressed("walk_up"):
		input_action_buffer.append("walk_up")
	elif Input.is_action_just_pressed("walk_down"):
		input_action_buffer.append("walk_down")
	
	
func update_buffer() -> void:
	if not Input.is_anything_pressed():
		input_action_buffer.clear()
		
	# important: iterate array backwards to removals don't affect us.
	for i in range(input_action_buffer.size() - 1, -1, -1):
		var action = input_action_buffer[i]
		if not Input.is_action_pressed(action):
			input_action_buffer.remove_at(i)

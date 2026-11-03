extends CanvasLayer

@export var arena_time_manager: Node
@onready var label = $%Label

func _process(delta):
	if arena_time_manager == null:
		return
	var time_elapsed = arena_time_manager.get_time_elapsed()
	var formatted_time = _format_seconds_to_string(time_elapsed)
	label.text = str(formatted_time)


func _format_seconds_to_string(seconds: float):
	var minutes = floor(seconds / 60)
	var remainder_in_seconds = seconds - (minutes * 60)
	return str(int(minutes)) + ":" + ("%02d" % floor(remainder_in_seconds)) 

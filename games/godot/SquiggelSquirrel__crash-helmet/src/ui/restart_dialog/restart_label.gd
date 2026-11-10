extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "Press (%s) to restart" % [
			InputMap.action_get_events(&"restart")[0].as_text()]

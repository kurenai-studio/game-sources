extends Enemy
class_name Ghost


func _act(delta: float) -> void:
	super(delta)
	if dying:
		return
	go_on_map(delta)

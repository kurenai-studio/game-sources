extends Node2D

func connect_levels() -> void:
	$AnimationPlayer.play("connect")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		connect_levels()

func set_connector() -> void:
	$AnimationPlayer.play("connect")
	$AnimationPlayer.seek(999, true)

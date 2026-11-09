extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.saw_tutorial = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")


func _on_refuel_button_pressed() -> void:
	$RefuelButton.disabled = true
	$RefuelTimer.start(5.0)


func _on_refuel_timer_timeout() -> void:
	$RefuelButton.disabled = false

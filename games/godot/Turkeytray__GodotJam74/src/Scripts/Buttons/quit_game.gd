extends Button

var wait := false

func _on_button_down() -> void:
	get_tree().quit(0)

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE) and not wait and name != "Quit":
		visible = !visible
		$Timer.start(0.35)
		wait = true

func _on_timer_timeout() -> void:
	wait = false

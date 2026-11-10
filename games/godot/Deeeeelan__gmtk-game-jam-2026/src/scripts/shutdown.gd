extends Button

func _pressed() -> void:
	%SFX_shutdown.play()
	%BGM.stop()
	%Fade.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween = get_tree().create_tween()
	tween.tween_property(%Fade, "color", Color(0.0, 0.0, 0.0, 1.0), 1.0)
	tween.play()
	await get_tree().create_timer(3).timeout
	GameManager.shutdown()

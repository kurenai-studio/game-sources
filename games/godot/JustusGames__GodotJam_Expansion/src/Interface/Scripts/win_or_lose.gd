extends Control

@onready var _win_or_lose_label:Label = get_node("%WinOrLoseLabel")

func _process(_delta: float) -> void:
	if self.visible:
		get_tree().paused = true


func _on_button_button_down() -> void:
	get_tree().paused = false
	var _stray_bullets = get_tree().get_nodes_in_group("NeedsCleaning")
	if _stray_bullets.size() >= 1:
		for stray in _stray_bullets:
			stray.queue_free()
	get_tree().change_scene_to_file("res://Levels/main_menu.tscn")


func _on_button_2_button_down() -> void:
	get_tree().quit()

func show_results(pResult:String = "Game Over"):
	visible = true
	_win_or_lose_label.text = pResult

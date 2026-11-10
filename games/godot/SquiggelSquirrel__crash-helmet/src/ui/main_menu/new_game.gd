extends Button


func _pressed() -> void:
	GameManager.set_level_index(0)
	GameManager.set_states(GameManager.State.PLAYING, GameManager.Menu.NONE)

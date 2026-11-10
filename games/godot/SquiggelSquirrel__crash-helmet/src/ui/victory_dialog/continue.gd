extends Button


func _pressed() -> void:
	GameManager.set_level_index(GameManager.level_index + 1)
	GameManager.set_states(GameManager.State.PLAYING, GameManager.Menu.NONE)

extends PanelContainer


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_manager_state_changed)


func _on_game_manager_state_changed() -> void:
	visible = bool(GameManager.menu == GameManager.Menu.SETTINGS)
	if visible:
		%MasterVolume.grab_focus()

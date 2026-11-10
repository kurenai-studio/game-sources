extends PanelContainer


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)


func _on_game_state_changed() -> void:
	visible = bool(GameManager.menu == GameManager.Menu.CONTROLS)
	if visible:
		%Left.grab_focus()

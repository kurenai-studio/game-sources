extends PanelContainer


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)
	%NewGame.grab_focus()


func _on_game_state_changed() -> void:
	match GameManager.menu:
		GameManager.Menu.START:
			visible = true
			%Title.text = "Crash Helmet"
			%Resume.disabled = true
			%NewGame.grab_focus()
		GameManager.Menu.PAUSED:
			visible = true
			%Title.text = "Game Paused"
			%Resume.disabled = false
			%Resume.grab_focus()
		_:
			visible = false

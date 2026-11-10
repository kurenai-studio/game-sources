extends Button

var previous := GameManager.Menu.START


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)


func _pressed() -> void:
	GameManager.set_states(GameManager.state, previous)


func _on_game_state_changed() -> void:
	if GameManager.menu == GameManager.Menu.START:
		previous = GameManager.Menu.START
	elif GameManager.menu == GameManager.Menu.PAUSED:
		previous = GameManager.Menu.PAUSED

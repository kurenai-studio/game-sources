extends Button

@export var game_path: String = ""
@export var game_name: String = ""

var generated = false
var wind: Control
const MINIGAME_WINDOW = preload("res://assets/nodes/minigame_window.tscn")

func _pressed() -> void:
	if not generated:
		generated = true
		var win := MINIGAME_WINDOW.instantiate()
		win.title = game_name
		win.initialize(load(game_path).instantiate())
		get_tree().get_first_node_in_group("windows").add_child(win)
		wind = win
	else:
		wind.visible = true

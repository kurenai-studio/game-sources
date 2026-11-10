extends Control

@onready var _how_to_play_page:Panel = get_node("%HowToPlay_BG")

signal pause_menu_closed

func _ready() -> void:
	_how_to_play_page.visible = false
func _on_exit_button_down() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if self.visible:
		get_tree().paused = true


func _on_start_game_button_down() -> void:
	get_tree().paused = false
	emit_signal("pause_menu_closed")
	self.visible = false


func _on_how_to_play_button_down() -> void:
	if _how_to_play_page.visible:
		_how_to_play_page.visible = false
	else:
		_how_to_play_page.visible = true

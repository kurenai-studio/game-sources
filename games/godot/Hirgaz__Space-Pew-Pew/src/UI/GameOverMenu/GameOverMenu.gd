extends Control


signal restart_pressed()
signal quit_pressed()


@onready var score_label := %GameOverScore

@onready var quit_button := %QuitButton


func _update_score() -> void:
	# TODO: Implement score system.
	var score := 9999
	score_label.text = tr_n("%5d point", "%5d points", score) % score


func _ready() -> void:
	# Disable quit button on Web.
	if OS.has_feature("web"):
		quit_button.visible = false


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_quit_button_game_pressed() -> void:
	quit_pressed.emit()


func _on_visibility_changed() -> void:
	if visible:
		_update_score()

# The "☰" menu's "Quitter la partie" button, which Android's back button
# also presses: during a game, back asks to quit it (the same dialog)
# instead of killing the app. Outside a game
# (the start menu), back quits the app as usual.
#
# Godot's own "quit on back" is turned off for this
# (`application/config/quit_on_go_back` in project.godot).
extends Button

# While this Control is shown (main.tscn's InputBlocker: the turn's
# points being counted), back does nothing, like a click on the button.
@export var blocked_by: Control


# Godot sends NOTIFICATION_WM_GO_BACK_REQUEST to every node when Android's
# back button (or back gesture) is used.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	# main.gd shows this button only while a game is on (`visible` is its
	# own flag: true even while the "☰" menu holding it is closed).
	if not visible:
		get_tree().quit()
	elif not blocked_by.visible:
		# Emitting the built-in signal by hand does what a click would.
		pressed.emit()

extends RefCounted

const MENU_BUTTONS: Array[int] = [JOY_BUTTON_BACK, JOY_BUTTON_START]


## Game screens hide the back button until Select or Start calls it up, so no
## single press she can reach by accident leaves the game.
static func toggle_back(button: Control) -> void:
	button.visible = not button.visible
	if button.visible:
		button.grab_focus()
	else:
		button.release_focus()


static func activate_focused(viewport: Viewport) -> bool:
	var focused := viewport.gui_get_focus_owner()
	if focused is BaseButton and not focused.disabled:
		if focused.toggle_mode:
			focused.button_pressed = not focused.button_pressed
		else:
			focused.pressed.emit()
		return true
	return false

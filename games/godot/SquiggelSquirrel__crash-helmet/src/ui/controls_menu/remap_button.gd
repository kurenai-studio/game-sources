class_name RemapButton
extends Button


@export var action: StringName


func _ready():
	set_process_unhandled_input(false)
	update_key_text()
	GameManager.inputs_remapped.connect(update_key_text)


func _toggled(toggled_on):
	set_process_unhandled_input(toggled_on)
	if toggled_on:
		text = "... Awaiting Input ..."
		release_focus()
	else:
		update_key_text()
		grab_focus()


func _unhandled_input(event):
	if event.pressed:
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		button_pressed = false
		GameManager.inputs_remapped.emit()


func update_key_text():
	text = "%s" % InputMap.action_get_events(action)[0].as_text()

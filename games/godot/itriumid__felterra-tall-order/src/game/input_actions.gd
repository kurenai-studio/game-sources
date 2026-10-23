class_name InputActions
extends RefCounted
## Every control, for keyboard and gamepad, registered in code so the bindings live in one
## readable place instead of serialized events in project.godot. The left hand never leaves
## movement.

const BINDINGS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"dodge": [KEY_SPACE],
	"change_gear": [KEY_G],
	"pause": [KEY_ESCAPE],
	"menu_choose": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
	"change_aim": [KEY_T],
	"toggle_blood": [KEY_B],
	"pick_1": [KEY_1],
	"pick_2": [KEY_2],
	"pick_3": [KEY_3],
	"reroll": [KEY_R],
	"banish": [KEY_X],
	"read_cards": [KEY_TAB],
	"show_kit": [KEY_I],
	"toggle_overlay": [KEY_F3],
	"toggle_fullscreen": [KEY_F11],
}

const GAMEPAD_BUTTONS := {
	"dodge": JOY_BUTTON_A,
	"change_gear": JOY_BUTTON_Y,
	"pause": JOY_BUTTON_START,
	"menu_choose": JOY_BUTTON_A,
	"change_aim": JOY_BUTTON_X,
	"pick_1": JOY_BUTTON_LEFT_SHOULDER,
	"pick_2": JOY_BUTTON_DPAD_UP,
	"pick_3": JOY_BUTTON_RIGHT_SHOULDER,
	"reroll": JOY_BUTTON_DPAD_DOWN,
	"banish": JOY_BUTTON_B,
	"read_cards": JOY_BUTTON_BACK,
	"show_kit": JOY_BUTTON_LEFT_STICK,
}


static func register() -> void:
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode: Key in BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
	for action: String in GAMEPAD_BUTTONS:
		var event := InputEventJoypadButton.new()
		event.button_index = GAMEPAD_BUTTONS[action]
		InputMap.action_add_event(action, event)
	for axis_action: String in ["move_left", "move_right", "move_up", "move_down"]:
		var stick := InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X if axis_action in ["move_left", "move_right"] else JOY_AXIS_LEFT_Y
		stick.axis_value = -1.0 if axis_action in ["move_left", "move_up"] else 1.0
		InputMap.action_add_event(axis_action, stick)

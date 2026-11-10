class_name WindowShortcuts
extends RefCounted
## Named window actions, their keyboard bindings and conflict rules.

const ACTIONS: Array[StringName] = [
	&"mode:strip", &"mode:corner", &"mode:window", &"scale:down", &"scale:up",
]
const LABELS: Array[String] = ["Strip", "Corner", "Window", "Smaller", "Larger"]
const DEFAULTS: Array = [
	[KEY_1], [KEY_2], [KEY_3], [KEY_MINUS, KEY_KP_SUBTRACT],
	[KEY_EQUAL, KEY_PLUS, KEY_KP_ADD, KEY_MASK_SHIFT | KEY_EQUAL, KEY_MASK_SHIFT | KEY_PLUS],
]
const RESERVED: Array[Key] = [
	KEY_ESCAPE, KEY_Q, KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_HOME,
	KEY_TAB, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_UP, KEY_DOWN, KEY_PAGEUP, KEY_PAGEDOWN, KEY_END,
	KEY_T, KEY_P, KEY_F, KEY_L, KEY_N, KEY_H, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_B, KEY_Y,
]
const MODIFIERS: Array[Key] = [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
const PREFIX: String = "tiny_ages_window_"

var enabled: bool = true
var bindings: Dictionary[StringName, PackedInt64Array] = {}


static func key_event(code: int) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = (code & KEY_CODE_MASK) as Key
	event.shift_pressed = (code & KEY_MASK_SHIFT) != 0
	event.ctrl_pressed = (code & KEY_MASK_CTRL) != 0
	event.alt_pressed = (code & KEY_MASK_ALT) != 0
	event.meta_pressed = (code & KEY_MASK_META) != 0
	return event


func _init() -> void:
	reset()


func reset() -> void:
	for index: int in ACTIONS.size():
		bindings[ACTIONS[index]] = PackedInt64Array(DEFAULTS[index])


func copy() -> WindowShortcuts:
	var result: WindowShortcuts = WindowShortcuts.new()
	result.enabled = enabled
	result.bindings = bindings.duplicate()
	return result


func install() -> void:
	for action: StringName in ACTIONS:
		var name: StringName = StringName(PREFIX + String(action))
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		InputMap.action_erase_events(name)
		for code: int in bindings[action]:
			InputMap.action_add_event(name, key_event(code))


func action_for(event: InputEventKey) -> StringName:
	if not enabled or not event.pressed or event.echo:
		return &""
	for action: StringName in ACTIONS:
		if event.is_action_pressed(StringName(PREFIX + String(action)), false, true):
			return action
	return &""


func label_for(action: StringName) -> String:
	var index: int = ACTIONS.find(action)
	if bindings[action] == PackedInt64Array(DEFAULTS[index]):
		return ["1", "2", "3", "- / Numpad -", "+ / = / Numpad +"][index]
	var labels: PackedStringArray = PackedStringArray()
	for code: int in bindings[action]:
		labels.append(OS.get_keycode_string(code))
	return " / ".join(labels)


## Empty on success; otherwise a message for the capture panel.
func rebind(action: StringName, code: int) -> String:
	if not ACTIONS.has(action):
		return "Unknown shortcut."
	var base: int = code & KEY_CODE_MASK
	if base == KEY_NONE or MODIFIERS.has(base):
		return "Press a key, not just a modifier."
	if RESERVED.has(base):
		return "Reserved key; choose another."
	for other: StringName in ACTIONS:
		if other != action and bindings[other].has(code):
			return "Already used by %s." % LABELS[ACTIONS.find(other)]
	bindings[action] = PackedInt64Array([code])
	return ""


func save_into(file: ConfigFile) -> void:
	file.set_value("shortcuts", "enabled", enabled)
	for action: StringName in ACTIONS:
		file.set_value("shortcuts", String(action), bindings[action])


func load_from(file: ConfigFile) -> void:
	reset()
	enabled = bool(file.get_value("shortcuts", "enabled", true))
	var loaded: Dictionary[StringName, PackedInt64Array] = {}
	var used: PackedInt64Array = PackedInt64Array()
	for action: StringName in ACTIONS:
		var value: Variant = file.get_value("shortcuts", String(action), bindings[action])
		if value is not PackedInt64Array or value.is_empty():
			push_warning("Invalid window shortcuts; using defaults.")
			return
		var codes: PackedInt64Array = value
		for code: int in codes:
			var base: int = code & KEY_CODE_MASK
			if base == KEY_NONE or MODIFIERS.has(base) or RESERVED.has(base) or used.has(code):
				push_warning("Invalid or conflicting window shortcuts; using defaults.")
				return
			used.append(code)
		loaded[action] = codes
	bindings = loaded

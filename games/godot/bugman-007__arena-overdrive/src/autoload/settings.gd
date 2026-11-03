extends Node
## Player settings (audio, video, gameplay, key bindings) persisted to a ConfigFile.

const DEFAULT_PATH := "user://settings.cfg"
const REBINDABLE: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right", &"dash", &"ability", &"pause"]
const DEFAULT_KEYS := {
	&"move_up": KEY_W, &"move_down": KEY_S, &"move_left": KEY_A, &"move_right": KEY_D,
	&"dash": KEY_SPACE, &"ability": KEY_E, &"pause": KEY_ESCAPE,
}
const ALT_KEYS := {
	&"move_up": KEY_UP, &"move_down": KEY_DOWN, &"move_left": KEY_LEFT, &"move_right": KEY_RIGHT,
	&"dash": KEY_SHIFT, &"ability": KEY_Q, &"pause": KEY_P,
}
const LOCALES: Array[String] = ["en", "es"]

var path: String = DEFAULT_PATH
var values: Dictionary = {}
var bindings: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply()


static func default_values() -> Dictionary:
	return {
		"master_volume": 0.8, "music_volume": 0.6, "sfx_volume": 0.8, "ui_volume": 0.7,
		"fullscreen": false, "vsync": true, "screen_shake": true, "locale": "en",
	}


func get_value(key: String) -> Variant:
	return values.get(key, default_values().get(key))


func set_value(key: String, value: Variant) -> void:
	values[key] = value
	apply()
	save_settings()


func load_settings() -> void:
	values = default_values()
	bindings = DEFAULT_KEYS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for key: String in values:
		values[key] = cfg.get_value("settings", key, values[key])
	for action: StringName in REBINDABLE:
		bindings[action] = int(cfg.get_value("input", String(action), bindings[action]))


func save_settings() -> Error:
	var cfg := ConfigFile.new()
	for key: String in values:
		cfg.set_value("settings", key, values[key])
	for action: StringName in bindings:
		cfg.set_value("input", String(action), bindings[action])
	return cfg.save(path)


## Rebinds the primary key. If another action used that key, the two are swapped.
func rebind(action: StringName, keycode: int) -> void:
	var previous: int = bindings.get(action, KEY_NONE)
	for other: StringName in bindings:
		if other != action and int(bindings[other]) == keycode:
			bindings[other] = previous
	bindings[action] = keycode
	apply_input()
	save_settings()


func reset_bindings() -> void:
	bindings = DEFAULT_KEYS.duplicate()
	apply_input()
	save_settings()


func key_label(action: StringName) -> String:
	return OS.get_keycode_string(int(bindings.get(action, KEY_NONE)))


func apply() -> void:
	apply_audio()
	apply_video()
	apply_input()
	TranslationServer.set_locale(String(get_value("locale")))
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.settings_changed.emit()


func apply_audio() -> void:
	for pair in [["Master", "master_volume"], ["Music", "music_volume"], ["SFX", "sfx_volume"], ["UI", "ui_volume"]]:
		var idx := AudioServer.get_bus_index(pair[0])
		if idx >= 0:
			var v: float = float(get_value(pair[1]))
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(idx, v <= 0.001)


func apply_video() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if get_value("fullscreen") else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if get_value("vsync") else DisplayServer.VSYNC_DISABLED)


static func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code as Key
	return ev


static func _joy_button(b: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	return ev


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


## (Re)builds all gameplay actions: primary key, alternate key and gamepad.
func apply_input() -> void:
	var pads := {
		&"move_up": [_joy_axis(JOY_AXIS_LEFT_Y, -1.0), _joy_button(JOY_BUTTON_DPAD_UP)],
		&"move_down": [_joy_axis(JOY_AXIS_LEFT_Y, 1.0), _joy_button(JOY_BUTTON_DPAD_DOWN)],
		&"move_left": [_joy_axis(JOY_AXIS_LEFT_X, -1.0), _joy_button(JOY_BUTTON_DPAD_LEFT)],
		&"move_right": [_joy_axis(JOY_AXIS_LEFT_X, 1.0), _joy_button(JOY_BUTTON_DPAD_RIGHT)],
		&"dash": [_joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)],
		&"ability": [_joy_button(JOY_BUTTON_X), _joy_button(JOY_BUTTON_LEFT_SHOULDER)],
		&"pause": [_joy_button(JOY_BUTTON_START)],
	}
	for action: StringName in REBINDABLE:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.3)
		InputMap.action_add_event(action, _key(int(bindings.get(action, DEFAULT_KEYS[action]))))
		if int(ALT_KEYS[action]) != int(bindings.get(action)):
			InputMap.action_add_event(action, _key(ALT_KEYS[action]))
		for ev: InputEvent in pads[action]:
			InputMap.action_add_event(action, ev)

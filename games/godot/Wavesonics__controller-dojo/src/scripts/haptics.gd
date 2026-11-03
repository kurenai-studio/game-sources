extends RefCounted

## Godot's Android port has no backend for Input.start_joy_vibration, so those
## calls are silently dropped in the APK. On Android the rumble goes through the
## ControllerRumble plugin in android/build instead, which drives the pad's own
## vibrator. That vibrator is a single motor, so the weak and strong strengths
## collapse into one amplitude there.

static var _plugin: Object = null
static var _plugin_checked := false
static var _android_ids: Dictionary[int, int] = {}


static func rumble(device: int, weak: float, strong: float, duration: float) -> void:
	if device < 0:
		return
	var plugin := _android_plugin()
	if plugin == null:
		Input.start_joy_vibration(device, weak, strong, duration)
		return
	var amplitude := maxf(weak, strong)
	var duration_ms := int(duration * 1000.0)
	var android_id := _android_id_for(plugin, device)
	if android_id >= 0:
		plugin.rumbleDevice(android_id, amplitude, duration_ms)
	else:
		plugin.rumble(amplitude, duration_ms)


static func stop(device: int) -> void:
	var plugin := _android_plugin()
	if plugin == null:
		if device >= 0:
			Input.stop_joy_vibration(device)
		return
	plugin.stopRumble()


## Android input device ids are not Godot joypad ids, so they are matched by
## name and cached. Call this whenever a pad connects or disconnects.
static func forget_devices() -> void:
	_android_ids.clear()


static func _android_plugin() -> Object:
	if not _plugin_checked:
		_plugin_checked = true
		if Engine.has_singleton("ControllerRumble"):
			_plugin = Engine.get_singleton("ControllerRumble")
	return _plugin


static func _android_id_for(plugin: Object, device: int) -> int:
	if _android_ids.has(device):
		return _android_ids[device]
	var wanted := Input.get_joy_name(device)
	var matched := -1
	for id: int in plugin.getGamepadIds():
		if plugin.getGamepadName(id) == wanted and plugin.hasVibrator(id):
			matched = id
			break
	_android_ids[device] = matched
	return matched

class_name UserSettings
extends RefCounted
## What the player chose about how the game sits on their desktop: the window mode, its size and
## whether it stays on top, plus its keyboard shortcuts. Saved separately (so a new game keeps
## them) and applied before the launch flags, which win. Pure data; the settings panel shows it
## and `Game` applies it.

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "window"
const MODES: Array[StringName] = [&"strip", &"corner", &"window"]

var mode: StringName = &"strip"
var pixel_scale: int = 2
var always_on_top: bool = true
var shortcuts: WindowShortcuts = WindowShortcuts.new()


## The settings a window currently has.
static func from_window(window: DesktopWindow) -> UserSettings:
	var settings: UserSettings = UserSettings.new()
	settings.mode = MODES[clampi(int(window.mode), 0, MODES.size() - 1)]
	settings.pixel_scale = window.pixel_scale
	settings.always_on_top = window.always_on_top
	return settings


## Reads the file; anything missing or out of range falls back to the default.
static func load_from(path: String = DEFAULT_PATH) -> UserSettings:
	var settings: UserSettings = UserSettings.new()
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return settings
	var wanted_mode: StringName = StringName(str(file.get_value(SECTION, "mode", settings.mode)))
	if MODES.has(wanted_mode):
		settings.mode = wanted_mode
	settings.pixel_scale = clampi(
		int(file.get_value(SECTION, "scale", settings.pixel_scale)),
		DesktopWindow.MIN_SCALE, DesktopWindow.MAX_SCALE
	)
	settings.always_on_top = bool(file.get_value(SECTION, "always_on_top", settings.always_on_top))
	settings.shortcuts.load_from(file)
	return settings


func save_to(path: String = DEFAULT_PATH) -> bool:
	var file: ConfigFile = ConfigFile.new()
	file.set_value(SECTION, "mode", String(mode))
	file.set_value(SECTION, "scale", pixel_scale)
	file.set_value(SECTION, "always_on_top", always_on_top)
	shortcuts.save_into(file)
	return file.save(path) == OK


func window_mode() -> DesktopWindow.Mode:
	return MODES.find(mode) as DesktopWindow.Mode


## Sets the window's mode, size and always-on-top before it is first shown (`DesktopWindow.apply`
## comes later).
func apply_to(window: DesktopWindow) -> void:
	window.always_on_top = always_on_top
	window.pixel_scale = pixel_scale
	window.mode = window_mode()


## The same, on a window that is already showing: each setter re-places it.
func apply_live(window: DesktopWindow) -> void:
	window.set_always_on_top(always_on_top)
	if window.pixel_scale != pixel_scale:
		window.set_pixel_scale(pixel_scale)
	if window.mode != window_mode():
		window.set_mode(window_mode())


## The settings after the player picks `action` in the settings panel (`mode:strip`, `scale:up`,
## `scale:down`, `ontop:on`, `ontop:off`, `shortcuts:on`, `shortcuts:off`).
## An unknown action changes nothing.
func changed_by(action: StringName) -> UserSettings:
	var result: UserSettings = UserSettings.new()
	result.mode = mode
	result.pixel_scale = pixel_scale
	result.always_on_top = always_on_top
	result.shortcuts = shortcuts.copy()
	var parts: PackedStringArray = String(action).split(":")
	if parts.size() != 2:
		return result
	match parts[0]:
		"mode":
			if MODES.has(StringName(parts[1])):
				result.mode = StringName(parts[1])
		"scale":
			var step: int = 1 if parts[1] == "up" else (-1 if parts[1] == "down" else 0)
			result.pixel_scale = clampi(
				pixel_scale + step, DesktopWindow.MIN_SCALE, DesktopWindow.MAX_SCALE
			)
		"ontop":
			if parts[1] == "on" or parts[1] == "off":
				result.always_on_top = parts[1] == "on"
		"shortcuts":
			if parts[1] == "on" or parts[1] == "off":
				result.shortcuts.enabled = parts[1] == "on"
	return result

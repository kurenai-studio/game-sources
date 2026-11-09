class_name GameSettings
extends RefCounted
## Player settings: music and sound volume (0..1) and fullscreen. Saved
## to [constant PATH]. [method current] loads and applies them on first
## use, so every scene can call it without an autoload.

const PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULT_VOLUME := 0.8
const SILENT_DB := -80.0
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

static var _current: GameSettings
## Where [method current] loads and [method save] writes. Tests point it
## elsewhere so they never touch the player's settings.
static var path: String = PATH

var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var fullscreen: bool = false
## False until the guided first run is finished or skipped.
var tutorial_done: bool = false


## The shared settings, loaded from disk and applied on first call.
static func current() -> GameSettings:
	if _current == null:
		_current = GameSettings.new()
		_current.load_from(path)
		_current.apply_volumes()
		# Browsers only allow fullscreen from a click, so web starts windowed.
		if not OS.has_feature("web"):
			_current.apply_fullscreen()
	return _current


static func volume_db(linear: float) -> float:
	return SILENT_DB if linear <= 0.0 else maxf(linear_to_db(linear), SILENT_DB)


static func percent_text(linear: float) -> String:
	return "%d%%" % roundi(linear * 100.0)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(MUSIC_BUS, music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(SFX_BUS, sfx_volume)


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_fullscreen()


func apply_volumes() -> void:
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)


func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save() -> void:
	var error := save_to(path)
	if error != OK:
		push_warning("GameSettings: cannot save %s (error %d)" % [path, error])


func save_to(path: String) -> Error:
	var config := ConfigFile.new()
	config.set_value(SECTION, "music_volume", music_volume)
	config.set_value(SECTION, "sfx_volume", sfx_volume)
	config.set_value(SECTION, "fullscreen", fullscreen)
	config.set_value(SECTION, "tutorial_done", tutorial_done)
	return config.save(path)


## Reads [param path]; a missing or broken file keeps the current values.
func load_from(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("GameSettings: cannot read %s, using defaults" % path)
		return
	music_volume = clampf(float(config.get_value(SECTION, "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value(SECTION, "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value(SECTION, "fullscreen", fullscreen))
	tutorial_done = bool(config.get_value(SECTION, "tutorial_done", tutorial_done))


func _set_bus_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, volume_db(linear))

class_name Settings
extends RefCounted
## The player's settings, stored inside the progress file (data["settings"]).
##
## Changing a synced setting stamps `updatedAt`, so the newest change wins when settings are
## merged across devices. The first-run coach flag is local only.

const THEMES: Array[String] = ["system", "light", "dark"]
const LOOK_FLAT := "flat"
const LOOK_DEPTH := "depth"
const LOOKS: Array[String] = [LOOK_FLAT, LOOK_DEPTH]
## What a player who never chose gets, including a save made before the setting existed.
const LOOK_DEFAULT := LOOK_DEPTH
const RUN_SPEEDS: Array[String] = ["slow", "normal", "fast"]

var _store: ProgressStore


func _init(store: ProgressStore) -> void:
	_store = store


func theme() -> String:
	return _s()["theme"]


func set_theme(value: String) -> void:
	if THEMES.has(value):
		_set_setting("theme", value)


## The look of the game on this device: depth (the default) or flat. It is not synced, because what
## a device can draw smoothly differs from device to device.
func look() -> String:
	var value: Variant = _s().get("look", LOOK_DEFAULT)
	return value if typeof(value) == TYPE_STRING and LOOKS.has(value) else LOOK_DEFAULT


func set_look(value: String) -> void:
	if LOOKS.has(value):
		_s()["look"] = value


func reduce_motion() -> bool:
	return _s()["reduceMotion"]


func set_reduce_motion(value: bool) -> void:
	_set_setting("reduceMotion", value)


func sound() -> bool:
	return _s()["sound"]


func set_sound(value: bool) -> void:
	_set_setting("sound", value)


func music() -> bool:
	return _s()["music"]


func set_music(value: bool) -> void:
	_set_setting("music", value)


func vibration() -> bool:
	return _s()["vibration"]


func set_vibration(value: bool) -> void:
	_set_setting("vibration", value)


func run_speed() -> String:
	return _s()["runSpeed"]


func set_run_speed(value: String) -> void:
	if RUN_SPEEDS.has(value):
		_set_setting("runSpeed", value)


## Seconds one step of a run takes. Never above 0.25: no animation is longer than that.
func step_seconds() -> float:
	match run_speed():
		"slow":
			return 0.25
		"fast":
			return 0.1
		_:
			return 0.2


## The first-run coach on level 1 is shown until it has been finished or dismissed once. This
## is local only: it is not part of the synced settings.
func tutorial_done() -> bool:
	return _s()["tutorialDone"]


func set_tutorial_done(value: bool) -> void:
	_s()["tutorialDone"] = value


## When a synced setting last changed, in Unix seconds (0 when never).
func settings_updated_at() -> float:
	return float(_s()["updatedAt"])


## The settings that follow the player across devices.
func synced_settings() -> Dictionary:
	var s: Dictionary = _s()
	return {
		"theme": s["theme"],
		"reduceMotion": s["reduceMotion"],
		"sound": s["sound"],
		"music": s["music"],
		"vibration": s["vibration"],
		"runSpeed": s["runSpeed"],
	}


## Takes the settings of another device when they are newer than ours. Returns true if applied.
func apply_synced_settings(remote: Dictionary, remote_updated_at: float) -> bool:
	if remote_updated_at <= settings_updated_at():
		return false
	var clean := clean_synced(remote)
	for key: String in clean:
		_s()[key] = clean[key]
	_s()["updatedAt"] = remote_updated_at
	return true


## Only the well-formed synced settings from a Dictionary.
static func clean_synced(raw: Dictionary) -> Dictionary:
	var out := {}
	if typeof(raw.get("theme")) == TYPE_STRING and THEMES.has(raw["theme"]):
		out["theme"] = raw["theme"]
	if typeof(raw.get("runSpeed")) == TYPE_STRING and RUN_SPEEDS.has(raw["runSpeed"]):
		out["runSpeed"] = raw["runSpeed"]
	for key in ["reduceMotion", "sound", "music", "vibration"]:
		if typeof(raw.get(key)) == TYPE_BOOL:
			out[key] = raw[key]
	return out


## Changes one synced setting and stamps when, so the newest change wins when syncing.
func _set_setting(key: String, value: Variant) -> void:
	_s()[key] = value
	_s()["updatedAt"] = Time.get_unix_time_from_system()


func _s() -> Dictionary:
	return _store.data["settings"]

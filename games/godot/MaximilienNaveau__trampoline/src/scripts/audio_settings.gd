# The player's sound settings: a volume level and a mute switch for each
# audio bus — "Master" (everything), "Music" and "Effects" (see
# default_bus_layout.tres). An audio bus is a channel of Godot's mixer,
# like a fader on a mixing desk: the music players send their sound to
# "Music", the sound effects to "Effects", and both end up in "Master".
# Pure settings: sound_panel.gd shows them, `apply` hands them to Godot's
# mixer (the AudioServer singleton), `save`/`read` keep them between runs.
# RefCounted: a plain object freed automatically once nothing refers to
# it (like a Python object), not a node in the scene tree.
class_name AudioSettings
extends RefCounted

# The buses, in the order the sound menu lists them.
const BUSES: Array[String] = ["Master", "Music", "Effects"]
# Levels go from 0 (silent) to STEPS (full volume), one step per press.
const STEPS := 10
# Where the settings are kept. `user://` is Godot's per-user data folder
# (e.g. ~/.local/share/godot/app_userdata/... on Linux, the app's private
# storage on Android).
const PATH := "user://audio_settings.cfg"

# Bus name -> level, 0..STEPS. The music and effects start a little under
# full, so turning them up is possible.
var levels := {"Master": STEPS, "Music": 8, "Effects": 8}
# Bus name -> muted. Muting keeps the level, so unmuting restores it.
var muted := {"Master": false, "Music": false, "Effects": false}


# One step up (`delta` 1) or down (-1), kept within 0..STEPS. Turning a
# muted bus up unmutes it: the player clearly wants to hear it.
func change_level(bus: String, delta: int) -> void:
	levels[bus] = clampi(levels[bus] + delta, 0, STEPS)
	if delta > 0:
		muted[bus] = false


func toggle_mute(bus: String) -> void:
	muted[bus] = not muted[bus]


# Whether every bus is muted ("Tout couper" is on).
func all_muted() -> bool:
	for bus in BUSES:
		if not muted[bus]:
			return false
	return true


# Mutes every bus, or, if they all are already, unmutes them all.
func toggle_all() -> void:
	var mute := not all_muted()
	for bus in BUSES:
		muted[bus] = mute


# Whether `bus` makes no sound: muted, or turned all the way down.
func is_silent(bus: String) -> bool:
	return muted[bus] or levels[bus] == 0


# Whether nothing at all can be heard (for the speaker button's icon).
func is_all_silent() -> bool:
	return is_silent("Master") or (is_silent("Music") and is_silent("Effects"))


# The bus volume in decibels for its level. Squared, because loudness is
# heard on a roughly logarithmic scale: each step down sounds about as
# big as the last (half volume, level 5, is -12 dB rather than -6 dB).
func volume_db(bus: String) -> float:
	var fraction := float(levels[bus]) / STEPS
	return linear_to_db(fraction * fraction)


# Hands the settings to Godot's mixer. A bus at level 0 is muted rather
# than set to -inf dB.
func apply() -> void:
	for bus in BUSES:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_mute(index, is_silent(bus))
		if levels[bus] > 0:
			AudioServer.set_bus_volume_db(index, volume_db(bus))


# ConfigFile reads and writes an INI-style text file ("[section]" then
# "key=value" lines), like Python's configparser.
func save(path := PATH) -> void:
	var config := ConfigFile.new()
	for bus in BUSES:
		config.set_value("levels", bus, levels[bus])
		config.set_value("muted", bus, muted[bus])
	config.save(path)


# The settings saved at `path`, or the defaults if there are none yet (or
# the file is unreadable). `static`: called on the class itself,
# `AudioSettings.read()`, like a Python @staticmethod.
static func read(path := PATH) -> AudioSettings:
	var settings := AudioSettings.new()
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return settings
	for bus in BUSES:
		settings.levels[bus] = clampi(
			config.get_value("levels", bus, settings.levels[bus]), 0, STEPS
		)
		settings.muted[bus] = bool(config.get_value("muted", bus, settings.muted[bus]))
	return settings

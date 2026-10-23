class_name Settings
extends RefCounted
## The player's settings: graphics, audio and gameplay. Kept in a file in the player's data
## folder, so they're the same next time, and applied to the window, the audio buses and the run.

const PATH := "user://settings.cfg"
## The audio buses, under the master: the settings set each one's volume.
const BUSES: Array[String] = ["Music", "Effects", "Interface"]
const AIM_MODES: Array[String] = ["nearest", "toughest", "crowd"]
const WINDOW_SCALES: Array[int] = [1, 2, 3, 4]

## Every setting, its section, and its default. Volumes are 0 to 10.
const DEFAULTS := {
	"graphics": {"full_screen": false, "window_scale": 2, "vsync": true},
	"audio": {"master": 8, "music": 7, "effects": 8, "interface": 6},
	"gameplay": {"aim": "nearest", "blood": true, "story_waits": false},
}

var values := {}


func _init() -> void:
	values = DEFAULTS.duplicate(true)


func get_value(section: String, key: String) -> Variant:
	return values[section][key]


func set_value(section: String, key: String, value: Variant) -> void:
	values[section][key] = value


## Steps a setting to its next or previous value: a switch flips, a choice moves along its list,
## a volume moves by one, within 0 to 10.
func step(section: String, key: String, direction: int) -> void:
	var value: Variant = values[section][key]
	if value is bool:
		values[section][key] = not value
	elif key == "aim":
		values[section][key] = AIM_MODES[wrapi(AIM_MODES.find(value) + direction, 0, AIM_MODES.size())]
	elif key == "window_scale":
		values[section][key] = WINDOW_SCALES[clampi(WINDOW_SCALES.find(value) + direction, 0, WINDOW_SCALES.size() - 1)]
	else:
		values[section][key] = clampi(int(value) + direction, 0, 10)


## A volume from 0 to 10 as the decibels a bus takes: 0 is silence, 10 is full.
static func volume_db(volume: int) -> float:
	return -80.0 if volume <= 0 else linear_to_db(volume / 10.0)


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	for section: String in values:
		for key: String in values[section]:
			file.set_value(section, key, values[section][key])
	return file.save(path) == OK


## Reads the settings back, keeping the default for anything missing or of the wrong kind, so an
## older or hand-edited file still loads.
func load_from(path := PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for section: String in DEFAULTS:
		for key: String in DEFAULTS[section]:
			var saved: Variant = file.get_value(section, key, DEFAULTS[section][key])
			if typeof(saved) == typeof(DEFAULTS[section][key]):
				values[section][key] = saved


## Puts the graphics and audio settings into effect. The gameplay ones are read by the run.
func apply() -> void:
	var full := bool(get_value("graphics", "full_screen"))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)
		if not full:
			var scale: int = get_value("graphics", "window_scale")
			DisplayServer.window_set_size(Vector2i(640, 360) * scale)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if get_value("graphics", "vsync") else DisplayServer.VSYNC_DISABLED)
	ensure_buses()
	AudioServer.set_bus_volume_db(0, volume_db(get_value("audio", "master")))
	for bus in BUSES:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volume_db(get_value("audio", bus.to_lower())))


## The audio buses, made in code so they live in one readable place: music, effects and the
## interface, each sending to the master.
static func ensure_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")

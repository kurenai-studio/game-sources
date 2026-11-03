extends Node
## Plays procedurally generated SFX on a voice pool and loops generated music.
## Bus layout (Master > Music, SFX, UI) lives in default_bus_layout.tres.

const BUSES: Array[String] = ["Music", "SFX", "UI"]
const VOICES := 14

var library: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	library = SfxSynth.build_library()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_voices.append(p)
	_ui = AudioStreamPlayer.new()
	_ui.bus = &"UI"
	add_child(_ui)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.volume_db = -6.0
	add_child(_music)


static func ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


func has_sound(sound: StringName) -> bool:
	return library.has(sound)


## Plays a pooled SFX with slight pitch variation. Rate-limited per sound to avoid stacking.
func play(sound: StringName, pitch_jitter: float = 0.08, volume_db: float = 0.0) -> void:
	if not library.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -1000)) < 35:
		return
	_last_played[sound] = now
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = library[sound]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db
	p.play()


func play_ui(sound: StringName) -> void:
	if library.has(sound):
		_ui.stream = library[sound]
		_ui.play()


func play_music() -> void:
	if _music.playing:
		return
	if _music.stream == null:
		_music.stream = SfxSynth.build_music()
	_music.play()


func stop_music() -> void:
	_music.stop()

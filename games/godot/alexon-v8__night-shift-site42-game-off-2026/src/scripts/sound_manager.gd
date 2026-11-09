extends Node
class_name FacilitySoundManager

static var instance: FacilitySoundManager

var sounds = {}
var ambient_player: AudioStreamPlayer

func _enter_tree():
	instance = self
	_load_sound("polaroid_snap", "res://audio/polaroid_snap.wav")
	_load_sound("valve_turn", "res://audio/valve_turn.wav")
	_load_sound("power_cell_insert", "res://audio/power_cell_insert.wav")
	_load_sound("room_shift_distant", "res://audio/room_shift_distant.wav")
	_load_sound("terminal_beep", "res://audio/terminal_beep.wav")
	_load_sound("footstep_metal", "res://audio/footstep_metal.wav")
	_load_sound("ambient_hum", "res://audio/ambient_hum.wav")

func _ready():
	# Start looping ambient hum
	if sounds.has("ambient_hum"):
		ambient_player = AudioStreamPlayer.new()
		ambient_player.stream = sounds["ambient_hum"]
		ambient_player.volume_db = -12.0
		add_child(ambient_player)
		ambient_player.play()

func _load_sound(sound_name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		sounds[sound_name] = stream

func play(sound_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not sounds.has(sound_name):
		return
	var player = AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())

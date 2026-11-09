extends Node
class_name SoundManager

static var instance: SoundManager

var sounds = {}

func _enter_tree():
	instance = self
	_load_sound("shift_ortho", "res://audio/shift_ortho.wav")
	_load_sound("shift_persp", "res://audio/shift_persp.wav")
	_load_sound("grab", "res://audio/grab.wav")
	_load_sound("drop", "res://audio/drop.wav")
	_load_sound("button_click", "res://audio/button_click.wav")
	_load_sound("door_open", "res://audio/door_open.wav")
	_load_sound("portal_enter", "res://audio/portal_enter.wav")
	_load_sound("footstep", "res://audio/footstep.wav")

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

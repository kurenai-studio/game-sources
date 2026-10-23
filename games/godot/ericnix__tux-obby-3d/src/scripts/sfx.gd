extends Node
## Autoload de áudio: pool de efeitos + trilha em loop, ambos gerados por tools/generate_audio.py.

const SOUND_NAMES := [
	"jump", "double_jump", "bounce", "land", "death",
	"checkpoint", "fish", "win", "click",
]
const POOL_SIZE := 12
const MUSIC_VOLUME := -11.0
const MUSIC_DUCKED := -19.0

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name in SOUND_NAMES:
		var path := "res://assets/audio/%s.wav" % sound_name
		if ResourceLoader.exists(path):
			_streams[sound_name] = load(path)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_pool.append(player)

	_music = AudioStreamPlayer.new()
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.volume_db = MUSIC_VOLUME
	add_child(_music)
	_setup_music()


func _setup_music() -> void:
	var stream := load("res://assets/audio/music.wav") as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * float(wav.mix_rate))
		_music.stream = wav
	else:
		_music.stream = stream


func play(sound_name: String, volume_db := -6.0, pitch := 1.0) -> void:
	if not _streams.has(sound_name) or _pool.is_empty():
		return
	var player := _free_player()
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()


func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	var fallback := _pool[_next_player % _pool.size()]
	_next_player += 1
	return fallback


func start_music() -> void:
	if _music.stream == null:
		return
	if not _music.playing:
		_music.volume_db = MUSIC_VOLUME
		_music.play()
	else:
		set_music_volume(MUSIC_VOLUME, 0.5)


func set_music_volume(db: float, duration := 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", db, duration)


func duck_music() -> void:
	set_music_volume(MUSIC_DUCKED, 0.25)


func unduck_music() -> void:
	set_music_volume(MUSIC_VOLUME, 0.4)


func fade_out_music(duration := 1.5) -> void:
	if _music.playing:
		var tween := create_tween()
		tween.tween_property(_music, "volume_db", -60.0, duration)
		tween.tween_callback(_music.stop)


func _exit_tree() -> void:
	# Libera os playbacks antes do desligamento para nao deixar recursos pendurados.
	if _music != null:
		_music.stop()
		_music.stream = null
	for player in _pool:
		player.stop()
		player.stream = null
	_streams.clear()

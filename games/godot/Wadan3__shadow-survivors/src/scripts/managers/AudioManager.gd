extends Node

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.volume_db = -11.0
		add_child(player)
		_players.append(player)

func play_shoot() -> void:
	play_tone("shoot", 620.0, 0.055, 0.18, -14.0)

func play_hit() -> void:
	play_tone("hit", 150.0, 0.07, 0.45, -13.0)

func play_enemy_death() -> void:
	play_tone("death", 105.0, 0.13, 0.7, -12.0)

func play_pickup() -> void:
	play_tone("pickup", 880.0, 0.14, 0.1, -9.0)

func play_player_damage() -> void:
	play_tone("damage", 72.0, 0.18, 0.65, -8.0)

func play_ui() -> void:
	play_tone("ui", 440.0, 0.045, 0.08, -18.0)

func play_level_up() -> void:
	play_tone("level", 1040.0, 0.22, 0.08, -8.0)

func play_tone(key: String, frequency: float, duration: float, noise: float, volume_db: float) -> void:
	var stream: AudioStreamWAV = _cache.get(key) as AudioStreamWAV
	if stream == null:
		stream = _make_tone(frequency, duration, noise)
		_cache[key] = stream
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = _rng.randf_range(0.96, 1.04)
			player.play()
			return

func _make_tone(frequency: float, duration: float, noise: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / sample_rate
		var envelope := pow(1.0 - float(i) / count, 2.0)
		var wave := sin(TAU * frequency * t) * (1.0 - noise)
		wave += _rng.randf_range(-1.0, 1.0) * noise
		var sample := int(clamp(wave * envelope, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav


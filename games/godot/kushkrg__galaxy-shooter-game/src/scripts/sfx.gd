extends Node
## Sfx (autoload) — tiny procedural sound effects. No audio files:
## every effect is synthesised into an AudioStreamWAV at startup,
## so the repo stays text-only and the game sounds alive anywhere.

var _players: Array[AudioStreamPlayer] = []
var _next := 0
const POOL := 8

func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _make_stream(samples: PackedByteArray, mix_rate: int = 22050) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = mix_rate
	stream.data = samples
	return stream

func _tone(freq_from: float, freq_to: float, duration: float, volume: float = 0.5, noise: bool = false) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in count:
		var t := float(i) / count
		var freq := lerpf(freq_from, freq_to, t)
		phase += freq / rate
		var wave: float = sign(sin(phase * TAU)) * 0.6 + sin(phase * TAU) * 0.4
		if noise:
			wave = rng.randf_range(-1.0, 1.0)
		var env := 1.0 - t
		var value := clampf(wave * volume * env, -1.0, 1.0)
		data[i] = int((value * 0.5 + 0.5) * 255.0)
	return _make_stream(data, rate)

func _play(stream: AudioStreamWAV) -> void:
	if not Session.sound:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL
	p.stream = stream
	p.play()

var _shoot: AudioStreamWAV
var _explosion: AudioStreamWAV
var _powerup: AudioStreamWAV
var _hit: AudioStreamWAV

func _ensure() -> void:
	if _shoot == null:
		_shoot = _tone(920.0, 340.0, 0.09, 0.32)
		_explosion = _tone(160.0, 40.0, 0.35, 0.6, true)
		_powerup = _tone(520.0, 1180.0, 0.16, 0.45)
		_hit = _tone(220.0, 90.0, 0.18, 0.55)

func play_shoot() -> void:
	_ensure()
	_play(_shoot)

func play_explosion() -> void:
	_ensure()
	_play(_explosion)

func play_powerup() -> void:
	_ensure()
	_play(_powerup)

func play_hit() -> void:
	_ensure()
	_play(_hit)

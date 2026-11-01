extends Node
## Sound effects, synthesised at start-up so the game ships no audio files.
## Autoloaded as `Sfx`.

const RATE := 22050
const VOICES := 10
## Shortest gap between two plays of the same sound, in seconds.
const MIN_GAP := {"clash": 0.09, "volley": 0.12, "boom": 0.08, "death": 0.05, "musket": 0.1}

var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}
var _next := 0


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams = {
		"boom": _boom(),
		"volley": _volley(),
		"musket": _musket(),
		"clash": _clash(),
		"horn": _horn(220.0, 1.3),
		"rout": _horn(147.0, 0.7),
		"flag": _bell(),
		"win": _tune([523.3, 659.3, 784.0, 1046.5], 0.16),
		"lose": _tune([392.0, 349.2, 311.1, 261.6], 0.22),
		"click": _click(),
		"charge": _charge(),
	}


func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if muted or not _streams.has(name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last.get(name, -10.0) < MIN_GAP.get(name, 0.0):
		return
	_last[name] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


# --- synthesis ------------------------------------------------------------

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w


func _buffer(seconds: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(seconds * RATE))
	return s


func _boom() -> AudioStreamWAV:
	var s := _buffer(0.9)
	var low := 0.0
	for i in s.size():
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.06)
		var body := sin(TAU * (55.0 - 25.0 * t) * t) * exp(-t * 5.0)
		s[i] = (low * 2.2 * exp(-t * 4.0) + body * 0.9) * 0.8
	return _wav(s)


func _volley() -> AudioStreamWAV:
	var s := _buffer(0.45)
	var prev := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var n := randf_range(-1.0, 1.0)
		var hi := n - prev
		prev = n
		var env := sin(PI * clampf(t / 0.45, 0.0, 1.0))
		s[i] = hi * env * 0.25
	return _wav(s)


## A ragged crackle: a dozen shots a few hundredths of a second apart.
func _musket() -> AudioStreamWAV:
	var s := _buffer(0.6)
	for k in 12:
		var start := int(randf_range(0.0, 0.3) * RATE)
		var low := 0.0
		for i in range(start, s.size()):
			var t := float(i - start) / RATE
			if t > 0.15:
				break
			low = lerpf(low, randf_range(-1.0, 1.0), 0.3)
			s[i] += low * exp(-t * 45.0) * 0.22
	return _wav(s)


func _clash() -> AudioStreamWAV:
	var s := _buffer(0.16)
	var f1 := randf_range(1800.0, 2400.0)
	var f2 := f1 * 1.47
	for i in s.size():
		var t := float(i) / RATE
		var ring := (sin(TAU * f1 * t) + 0.6 * sin(TAU * f2 * t)) * exp(-t * 30.0)
		s[i] = (ring * 0.35 + randf_range(-1.0, 1.0) * exp(-t * 80.0) * 0.4) * 0.6
	return _wav(s)


func _horn(freq: float, seconds: float) -> AudioStreamWAV:
	var s := _buffer(seconds)
	for i in s.size():
		var t := float(i) / RATE
		var f := freq * (1.0 + 0.008 * sin(TAU * 5.0 * t))
		var env := minf(1.0, t / 0.08) * minf(1.0, (seconds - t) / 0.25)
		var v := 0.0
		for h in range(1, 6):
			v += sin(TAU * f * h * t) / (h * 1.3)
		s[i] = v * env * 0.22
	return _wav(s)


func _bell() -> AudioStreamWAV:
	var s := _buffer(0.8)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = (sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t) + 0.25 * sin(TAU * 2210.0 * t)) * exp(-t * 5.0) * 0.25
	return _wav(s)


func _tune(notes: Array, step: float) -> AudioStreamWAV:
	var s := _buffer(step * notes.size() + 0.5)
	for i in s.size():
		var t := float(i) / RATE
		var n := mini(int(t / step), notes.size() - 1)
		var local := t - n * step
		var f: float = notes[n]
		var env := exp(-local * (3.0 if n == notes.size() - 1 else 7.0))
		s[i] = (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * env * 0.25
	return _wav(s)


func _click() -> AudioStreamWAV:
	var s := _buffer(0.04)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = sin(TAU * 1400.0 * t) * exp(-t * 120.0) * 0.3
	return _wav(s)


func _charge() -> AudioStreamWAV:
	var s := _buffer(0.6)
	var low := 0.0
	for i in s.size():
		var t := float(i) / RATE
		low = lerpf(low, randf_range(-1.0, 1.0), 0.15)
		var gallop := 0.5 + 0.5 * sin(TAU * 9.0 * t)
		s[i] = low * gallop * minf(1.0, (0.6 - t) * 4.0) * 0.9
	return _wav(s)

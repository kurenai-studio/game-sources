extends Node
class_name SoundSynth
## Semua suara disintesis prosedural ke AudioStreamWAV (16-bit PCM)
## saat pertama dipakai, lalu di-cache — tanpa file audio sama sekali.
## Nada dibuat dari gelombang sinus (atau kotak untuk bunyi gagal)
## dengan envelope decay; sapuan frekuensi dipakai untuk suara tuang.

const MIX_RATE := 22050

var muted: bool = false
var _cache: Dictionary = {}


func play(sound_name: String) -> void:
	if muted:
		return
	if not _cache.has(sound_name):
		_cache[sound_name] = _build(sound_name)
	var stream: AudioStreamWAV = _cache[sound_name]
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.finished.connect(p.queue_free)
	add_child(p)
	p.play()


func _build(sound_name: String) -> AudioStreamWAV:
	match sound_name:
		"select":
			return _make_wav([[700.0, 700.0]], 0.07, "sine", 0.5)
		"click":
			return _make_wav([[880.0, 880.0]], 0.05, "sine", 0.4)
		"pour":
			return _make_wav([[620.0, 340.0]], 0.28, "sine", 0.55)
		"complete":
			return _make_wav([[784.0, 784.0], [1047.0, 1047.0]], 0.09, "sine", 0.5)
		"invalid":
			return _make_wav([[150.0, 120.0]], 0.16, "square", 0.4)
		"win":
			return _make_wav([[523.0, 523.0], [659.0, 659.0], [784.0, 784.0], [1047.0, 1047.0]], 0.13, "sine", 0.55)
	return null


func _make_wav(notes: Array, note_dur: float, wave: String, volume: float) -> AudioStreamWAV:
	var count := int(MIX_RATE * note_dur)
	var total := count * notes.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	for n in range(notes.size()):
		var f0: float = notes[n][0]
		var f1: float = notes[n][1]
		var phase := 0.0
		for i in range(count):
			var frac := float(i) / float(count)
			var freq := lerpf(f0, f1, frac)
			var env := exp(-3.0 * frac)
			var s := 0.0
			if wave == "square":
				s = 0.6 if sin(phase) >= 0.0 else -0.6
			else:
				s = sin(phase)
			phase += TAU * freq / MIX_RATE
			var v := int(clampf(s * env * volume, -1.0, 1.0) * 32767.0)
			data.encode_s16((n * count + i) * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav

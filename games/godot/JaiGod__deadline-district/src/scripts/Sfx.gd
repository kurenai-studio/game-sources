extends Node
## Procedural audio: every sound effect and music loop is synthesised at runtime.

const RATE := 22050
const MRATE := 11025
var _cache := {}
var _music_cache := {}
var _players: Array = []
var _music: AudioStreamPlayer
var _music_id := ""
var _next := 0
var _last := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p = AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -13.0
	add_child(_music)

func play(id: String, pitch := 1.0, vol := 0.0) -> void:
	if not Data.save.sound:
		return
	var now = Time.get_ticks_msec()
	if _last.has(id) and now - int(_last[id]) < 45:
		return
	_last[id] = now
	if not _cache.has(id):
		var s = _make(id)
		if s == null:
			return
		_cache[id] = s
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _cache[id]
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.volume_db = -4.0 + vol
	p.play()

func music(id: String) -> void:
	if id == _music_id and _music.playing:
		return
	_music_id = id
	if not Data.save.sound or id == "":
		_music.stop()
		return
	if not _music_cache.has(id):
		_music_cache[id] = _make_music(id)
	_music.stream = _music_cache[id]
	_music.play()

func refresh() -> void:
	var id = _music_id
	_music_id = ""
	if Data.save.sound:
		music(id)
	else:
		_music.stop()
		_music_id = id

# ------------------------------------------------------------------ synthesis
func _osc(wave: int, ph: float) -> float:
	match wave:
		0: return sin(ph * TAU)
		1: return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		2: return 2.0 * absf(2.0 * fmod(ph, 1.0) - 1.0) - 1.0
		3: return 2.0 * fmod(ph, 1.0) - 1.0
	return randf() * 2.0 - 1.0

func _tone(buf: PackedFloat32Array, rate: int, start: float, dur: float, f0: float, f1: float, wave: int, vol: float, attack := 0.003) -> void:
	var i0 = int(start * rate)
	var n = int(dur * rate)
	var ph = 0.0
	for i in n:
		var idx = i0 + i
		if idx >= buf.size():
			break
		var t = float(i) / n
		var f = lerpf(f0, f1, t)
		ph += f / rate
		var env = minf(1.0, float(i) / (attack * rate + 1.0)) * pow(1.0 - t, 1.8)
		buf[idx] += _osc(wave, ph) * vol * env

func _to_wav(buf: PackedFloat32Array, rate: int, loop := false) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w

func _buf(sec: float, rate := RATE) -> PackedFloat32Array:
	var b = PackedFloat32Array()
	b.resize(int(sec * rate))
	return b

func _make(id: String) -> AudioStreamWAV:
	var b: PackedFloat32Array
	match id:
		"click":
			b = _buf(0.06); _tone(b, RATE, 0, 0.05, 900, 1000, 1, 0.15)
		"pistol":
			b = _buf(0.16); _tone(b, RATE, 0, 0.12, 900, 120, 4, 0.45); _tone(b, RATE, 0, 0.08, 300, 80, 1, 0.25)
		"smg":
			b = _buf(0.09); _tone(b, RATE, 0, 0.07, 1200, 200, 4, 0.35); _tone(b, RATE, 0, 0.05, 260, 90, 1, 0.2)
		"shotgun":
			b = _buf(0.4); _tone(b, RATE, 0, 0.35, 600, 40, 4, 0.6); _tone(b, RATE, 0, 0.25, 120, 40, 1, 0.35)
		"rifle":
			b = _buf(0.35); _tone(b, RATE, 0, 0.3, 1500, 60, 4, 0.55); _tone(b, RATE, 0, 0.18, 200, 50, 3, 0.3)
		"minigun":
			b = _buf(0.06); _tone(b, RATE, 0, 0.05, 1400, 300, 4, 0.3)
		"flame":
			b = _buf(0.12); _tone(b, RATE, 0, 0.12, 300, 200, 4, 0.16, 0.03)
		"bow":
			b = _buf(0.2); _tone(b, RATE, 0, 0.15, 500, 160, 2, 0.35); _tone(b, RATE, 0, 0.06, 2200, 900, 4, 0.12)
		"rocket":
			b = _buf(0.5); _tone(b, RATE, 0, 0.45, 220, 900, 4, 0.3, 0.05); _tone(b, RATE, 0, 0.2, 120, 60, 1, 0.3)
		"tesla":
			b = _buf(0.25)
			for i in 5:
				_tone(b, RATE, i * 0.03, 0.08, 2400 - i * 300, 600, 3, 0.16)
			_tone(b, RATE, 0, 0.2, 90, 60, 1, 0.18)
		"slash":
			b = _buf(0.18); _tone(b, RATE, 0, 0.16, 2600, 500, 4, 0.3, 0.02); _tone(b, RATE, 0.02, 0.12, 1400, 900, 2, 0.12)
		"reload":
			b = _buf(0.3); _tone(b, RATE, 0, 0.05, 1800, 1500, 1, 0.16); _tone(b, RATE, 0.18, 0.06, 1300, 1700, 1, 0.18)
		"empty":
			b = _buf(0.08); _tone(b, RATE, 0, 0.04, 2000, 1900, 1, 0.12)
		"hit":
			b = _buf(0.1); _tone(b, RATE, 0, 0.08, 260, 90, 4, 0.3)
		"shield":
			b = _buf(0.14); _tone(b, RATE, 0, 0.1, 2400, 2200, 1, 0.12); _tone(b, RATE, 0, 0.12, 1700, 1500, 2, 0.12)
		"zdie":
			b = _buf(0.35); _tone(b, RATE, 0, 0.3, 160, 50, 3, 0.3); _tone(b, RATE, 0, 0.18, 400, 90, 4, 0.2)
		"groan":
			b = _buf(0.7); _tone(b, RATE, 0, 0.65, 110, 80, 3, 0.18, 0.15); _tone(b, RATE, 0, 0.6, 113, 84, 2, 0.14, 0.15)
		"explode":
			b = _buf(0.9); _tone(b, RATE, 0, 0.85, 200, 25, 4, 0.75); _tone(b, RATE, 0, 0.5, 70, 30, 1, 0.45)
		"hurt":
			b = _buf(0.25); _tone(b, RATE, 0, 0.2, 400, 120, 1, 0.3); _tone(b, RATE, 0, 0.15, 300, 80, 4, 0.2)
		"coin":
			b = _buf(0.16); _tone(b, RATE, 0, 0.05, 1320, 1320, 1, 0.1); _tone(b, RATE, 0.05, 0.1, 1760, 1760, 1, 0.1)
		"buy":
			b = _buf(0.35)
			for i in 3:
				_tone(b, RATE, i * 0.07, 0.15, [660, 880, 1320][i], [660, 880, 1320][i], 1, 0.14)
		"deny":
			b = _buf(0.2); _tone(b, RATE, 0, 0.08, 200, 190, 1, 0.16); _tone(b, RATE, 0.09, 0.1, 160, 150, 1, 0.16)
		"build":
			b = _buf(0.3); _tone(b, RATE, 0, 0.08, 300, 120, 4, 0.4); _tone(b, RATE, 0.12, 0.08, 280, 110, 4, 0.4)
		"turret":
			b = _buf(0.07); _tone(b, RATE, 0, 0.06, 1600, 500, 1, 0.12)
		"dash":
			b = _buf(0.2); _tone(b, RATE, 0, 0.18, 300, 1200, 4, 0.18, 0.04)
		"spit":
			b = _buf(0.25); _tone(b, RATE, 0, 0.2, 500, 200, 4, 0.2); _tone(b, RATE, 0, 0.15, 300, 600, 0, 0.15)
		"scream":
			b = _buf(0.8); _tone(b, RATE, 0, 0.75, 900, 1500, 3, 0.18, 0.08); _tone(b, RATE, 0, 0.7, 930, 1450, 2, 0.15, 0.08)
		"wave":
			b = _buf(1.2)
			for i in 3:
				_tone(b, RATE, i * 0.28, 0.5, 220, 210, 1, 0.16, 0.02)
				_tone(b, RATE, i * 0.28, 0.5, 330, 320, 2, 0.12, 0.02)
		"clear":
			b = _buf(0.8)
			for i in 4:
				_tone(b, RATE, i * 0.1, 0.3, [523, 659, 784, 1046][i], [523, 659, 784, 1046][i], 1, 0.12)
		"boss":
			b = _buf(1.6); _tone(b, RATE, 0, 1.5, 70, 50, 3, 0.4, 0.2); _tone(b, RATE, 0, 1.4, 73, 52, 1, 0.2, 0.2)
			for i in 4:
				_tone(b, RATE, i * 0.35, 0.3, 140, 130, 4, 0.2)
		"slam":
			b = _buf(0.7); _tone(b, RATE, 0, 0.65, 90, 30, 4, 0.7); _tone(b, RATE, 0, 0.5, 60, 30, 0, 0.5)
		"victory":
			b = _buf(1.6)
			var mel = [523, 659, 784, 1046, 784, 1046]
			for i in mel.size():
				_tone(b, RATE, i * 0.14, 0.6 if i == 5 else 0.16, mel[i], mel[i], 1, 0.13)
				_tone(b, RATE, i * 0.14, 0.6 if i == 5 else 0.16, mel[i] / 2.0, mel[i] / 2.0, 2, 0.12)
		"defeat":
			b = _buf(1.5)
			var mel = [392, 370, 330, 262]
			for i in mel.size():
				_tone(b, RATE, i * 0.3, 0.5, mel[i], mel[i] * 0.97, 2, 0.2)
		_:
			return null
	return _to_wav(b, RATE)

func _midi(n: int) -> float:
	return 440.0 * pow(2.0, (n - 69) / 12.0)

func _make_music(id: String) -> AudioStreamWAV:
	var bpm = 92.0
	var prog = [45, 41, 43, 40]
	var drums = false
	var lead = 2
	match id:
		"title": bpm = 76.0; prog = [45, 41, 38, 40]
		"calm": bpm = 84.0; prog = [45, 43, 41, 43]
		"wave": bpm = 132.0; prog = [40, 41, 40, 38]; drums = true; lead = 1
		"boss": bpm = 150.0; prog = [38, 39, 38, 36]; drums = true; lead = 3
	var beat = 60.0 / bpm
	var b = _buf(beat * 16.0, MRATE)
	for bar in 4:
		var root: int = prog[bar]
		var chord = [root, root + 3, root + 7, root + 10]
		var t0 = bar * 4 * beat
		for q in 8:
			_tone(b, MRATE, t0 + q * beat * 0.5, beat * 0.45, _midi(root - 12), _midi(root - 12), 2, 0.2 if q % 2 == 0 else 0.12)
		for e in 8:
			if not drums and e % 2 == 1:
				continue
			var n: int = chord[[0, 2, 1, 3, 2, 1, 3, 2][e]] + 12
			_tone(b, MRATE, t0 + e * beat * 0.5, beat * 0.4, _midi(n), _midi(n), lead, 0.05)
		_tone(b, MRATE, t0, beat * 4.0, _midi(chord[1] + 12), _midi(chord[1] + 12), 0, 0.04, 0.5)
		if drums:
			for q in 8:
				if q % 2 == 0:
					_tone(b, MRATE, t0 + q * beat * 0.5, 0.14, 130, 40, 0, 0.4)
				else:
					_tone(b, MRATE, t0 + q * beat * 0.5, 0.06, 3000, 3000, 4, 0.07)
	return _to_wav(b, MRATE, true)

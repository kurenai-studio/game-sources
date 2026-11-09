class_name SfxBus
extends AudioStreamPlayer
## ביפים סינתטיים. בלי wav מהרשת — גם ככה זה נשמע כמו משחק קז'ואל.

var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback


var muted: bool = false


func _ready() -> void:
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.75
	stream = _gen
	volume_db = -8.0
	play()
	_playback = get_stream_playback()


func set_muted(v: bool) -> void:
	muted = v
	volume_db = -80.0 if muted else -8.0


func beep(hz: float, ms: float, vol: float = 0.18) -> void:
	if muted:
		return
	if _playback == null:
		_playback = get_stream_playback()
	if _playback == null:
		return
	var n := int(_gen.mix_rate * ms / 1000.0)
	for i in range(n):
		var t := float(i) / _gen.mix_rate
		var env := 1.0 - float(i) / float(maxi(n, 1))
		var s := sin(TAU * hz * t) * vol * env
		_playback.push_frame(Vector2(s, s))


func select_piece() -> void:
	beep(640.0, 45.0, 0.10)


func place() -> void:
	beep(420.0, 70.0, 0.12)
	beep(560.0, 40.0, 0.07)


func clear_lines(n: int) -> void:
	beep(520.0 + n * 80.0, 120.0, 0.2)
	beep(780.0 + n * 40.0, 70.0, 0.10)


func supernova() -> void:
	beep(160.0, 90.0, 0.16)
	beep(420.0, 80.0, 0.12)
	beep(880.0, 180.0, 0.16)


func rotate_tick() -> void:
	beep(500.0, 40.0, 0.09)
	beep(720.0, 35.0, 0.08)


func bomb() -> void:
	beep(90.0, 140.0, 0.22)
	beep(210.0, 90.0, 0.16)
	beep(640.0, 50.0, 0.10)


func game_over() -> void:
	beep(140.0, 280.0, 0.2)

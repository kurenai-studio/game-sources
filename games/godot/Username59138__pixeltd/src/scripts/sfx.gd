extends Node
## Small pooled sound player with per-sound rate limiting.

const NAMES := ["shot", "slash", "flame", "hit", "pop", "boss_die", "place", "click", "upgrade", "sell", "wave",
	"leak", "heal", "win", "lose", "unlock", "error", "boom", "honk", "snipe", "rattle", "spray"]
const MIN_GAP := {"shot": 0.05, "slash": 0.06, "flame": 0.12, "hit": 0.04, "pop": 0.04, "heal": 0.2, "leak": 0.1, "boom": 0.08, "honk": 0.3, "snipe": 0.08, "rattle": 0.15, "spray": 0.12}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}
var _next := 0
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in NAMES:
		_streams[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, pitch_var := 0.0) -> void:
	if muted or not _streams.has(sound):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var gap: float = MIN_GAP.get(sound, 0.0)
	if gap > 0.0 and now - float(_last.get(sound, -1.0)) < gap:
		return
	_last[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.volume_db = linear_to_db(maxf(0.001, Game.sfx_volume))
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

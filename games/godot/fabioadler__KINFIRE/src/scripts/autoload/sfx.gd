extends Node
## Efeitos sonoros com pool de players (vários sons simultâneos).

const SOUNDS := {
	&"swing1": "res://assets/audio/swing1.ogg", &"swing2": "res://assets/audio/swing2.ogg",
	&"draw": "res://assets/audio/draw.ogg", &"coins": "res://assets/audio/coins.ogg",
	&"ui_open": "res://assets/audio/ui_open.ogg", &"ui_close": "res://assets/audio/ui_close.ogg",
	&"cloth": "res://assets/audio/cloth.ogg", &"click": "res://assets/audio/click.ogg",
	&"equip": "res://assets/audio/equip.ogg", &"door": "res://assets/audio/door.ogg",
	&"drop": "res://assets/audio/drop.ogg", &"step": "res://assets/audio/step.ogg",
	&"chop": "res://assets/audio/chop.ogg", &"potion": "res://assets/audio/potion.ogg",
	&"hit_heavy": "res://assets/audio/hit_heavy.ogg", &"hit": "res://assets/audio/hit.ogg",
	&"hurt": "res://assets/audio/hurt.ogg", &"block": "res://assets/audio/block.ogg",
	&"magic": "res://assets/audio/magic.ogg", &"levelup": "res://assets/audio/levelup.ogg",
	&"explode": "res://assets/audio/explode.ogg", &"pickup": "res://assets/audio/pickup.ogg",
	&"death": "res://assets/audio/death.ogg",
}
const POOL_SIZE := 16

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for k in SOUNDS:
		_streams[k] = load(SOUNDS[k])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)


func play(id: StringName, volume_db: float = 0.0, pitch_var: float = 0.08) -> void:
	if not _streams.has(id):
		return
	# Evita empilhar o mesmo som no mesmo frame (hordas)
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(id, -1000)) < 40:
		return
	_last_played[id] = now
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[id]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p.play()

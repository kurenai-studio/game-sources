extends Node
## Sound: the ball and the feet. Ball sounds are real recordings sampled from one
## live match (see sounds/CREDITS.md), cut into single impacts with a natural decay
## and sorted in sounds/real: hard / normal racket hits and table bounces;
## footsteps are studio recordings on a wooden floor (Kenney, CC0) and shoe
## squeals are cut whole from a sneaker foley recording (Pixabay). Each play
## picks a random clip from its group with pitch / volume jitter so nothing
## repeats exactly. Net and floor contacts reuse table bounces pitched down.
## Positional sounds play in the 3D world so they pan and fade. No crowd or
## voices: the match recording has commentary behind them. The music (a menu
## and a match loop) and the skill sounds are little chiptunes made by
## tools/make_audio.py.

const POOL := 14
const GROUPS := {"hit_hard": 10, "hit": 10, "table": 10, "step": 5, "squeak": 8}
const EXT := {"step": "ogg"}     # everything else is .wav

var world: Node3D
var _rng := RandomNumberGenerator.new()
var _pool: Array[AudioStreamPlayer3D] = []
var _next := 0
var _clips := {}         # group -> Array[AudioStream]
var _ui: Array[AudioStreamPlayer] = []   # skill sounds, jingles, clicks: not in the 3D world
var _ui_next := 0
var _fx := {}            # name -> AudioStream (sounds/fx)
var _music: AudioStreamPlayer
var _tracks := {}        # "menu" | "match" -> AudioStreamOggVorbis
var _track := ""
var last := {"name": "", "t": 0}   # the last named sound and when (ms), for debug screenshots
const FX := ["blink", "flip", "gravity", "view", "cast", "shift", "click", "win", "lose"]
const MUSIC_DB := -13.0


func setup(world_node: Node3D) -> void:
	world = world_node
	_rng.seed = 1234
	_make_buses()
	for g in GROUPS:
		_clips[g] = []
		for i in GROUPS[g]:
			_clips[g].append(load("res://sounds/real/%s_%d.%s" % [g, i, EXT.get(g, "wav")]))
	for k in FX:
		_fx[k] = load("res://sounds/fx/%s.wav" % k)
	for i in 4:
		var u := AudioStreamPlayer.new()
		u.bus = "SFX"
		add_child(u)
		_ui.append(u)
	for k in ["menu", "match"]:
		var st: AudioStreamOggVorbis = load("res://sounds/music/%s.ogg" % k)
		st.loop = true
		_tracks[k] = st
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for i in POOL:
		var p := AudioStreamPlayer3D.new()
		p.bus = "SFX"
		p.unit_size = 9.0
		p.max_db = 4.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		world.add_child(p)
		_pool.append(p)


# ------------------------------------------------------------------ game hooks

## A stroke. `kind`: "block", "loop", "push", "smash", "serve"; `speed` m/s of the
## outgoing ball. Hard clips for smashes and drives, quieter normal ones for touches.
func hit(at: Vector3, kind: String, speed: float, _spin: float, _heavy: bool) -> void:
	var loud := clampf(-6.0 + speed * 0.6, -9.0, 3.0)
	if kind == "push" or kind == "serve" or speed < 5.0:
		loud -= 4.0
	var group := "hit_hard" if kind == "smash" or speed > 11.0 else "hit"
	_play(group, at, loud, 0.97 + speed * 0.003)


func table(at: Vector3, speed: float) -> void:
	_play("table", at, clampf(-10.0 + speed * 0.9, -12.0, 2.0), 0.98 + speed * 0.004)


func net(at: Vector3) -> void:
	_play("table", at, -10.0, 0.7)


## Ball bouncing on the floor: the crisp "tik" of a bounce, quieter and a touch
## higher as each bounce gets smaller, so a dropped ball goes tik-tik-tik-tiktiktik.
func floor_bounce(at: Vector3, speed: float) -> void:
	if speed > 0.15:
		_play("table", at, clampf(-24.0 + speed * 4.0, -28.0, -6.0), 1.0 + (1.0 - minf(speed / 4.0, 1.0)) * 0.15)


## Sneaker sole squealing on the court on a hard stop or change of direction;
## `brake` is how hard (m/s²), so sharper stops squeal louder and a bit higher.
func squeak(at: Vector3, brake: float) -> void:
	var k := clampf((brake - 25.0) / 50.0, 0.0, 1.0)
	_play("squeak", at, lerpf(-14.0, -3.0, k), lerpf(0.95, 1.1, k))


## Footstep on the wooden court; heavier when running.
func step(at: Vector3, speed: float) -> void:
	_play("step", at, clampf(-20.0 + speed * 3.0, -20.0, -8.0), 1.0)


## A soft tick by your racket: the hold has reached the right strength.
func tick(at: Vector3) -> void:
	_play("table", at, -22.0, 1.8)


## Focus card: everything muffled and slowed until it ends.
func focus(on: bool) -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_effect_enabled(master, 0, on)
	AudioServer.playback_speed_scale = 0.75 if on else 1.0


## A skill, jingle or click by name (see FX), at the same loudness everywhere.
func fx(name: String, db := -4.0) -> void:
	var u := _ui[_ui_next]
	_ui_next = (_ui_next + 1) % _ui.size()
	u.stream = _fx[name]
	last = {"name": name, "t": Time.get_ticks_msec()}
	u.volume_db = db
	u.play()


## Switches to the "menu" or "match" loop ("" for silence), fading across.
func music(name: String) -> void:
	if name == _track:
		return
	_track = name
	var tw := _music.create_tween()
	tw.tween_property(_music, "volume_db", -40.0, 0.35)
	tw.tween_callback(func():
		if _track == "":
			_music.stop()
			return
		_music.stream = _tracks[_track]
		_music.play()
		_music.volume_db = -40.0)
	tw.tween_property(_music, "volume_db", MUSIC_DB, 0.6)


# ------------------------------------------------------------------ playback

func _play(group: String, at: Vector3, db: float, pitch: float) -> void:
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	var v: Array = _clips[group]
	p.stream = v[_rng.randi() % v.size()]
	p.position = at
	p.volume_db = db + _rng.randf_range(-1.5, 1.5)
	p.pitch_scale = pitch * _rng.randf_range(0.96, 1.04)
	p.play()


## The SFX and Music buses and the focus-card muffle on Master (off) come from
## default_bus_layout.tres: buses added from code at runtime never reach the
## speakers in the web build. This only fills in if that file is missing.
func _make_buses() -> void:
	for b in ["SFX", "Music"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var lp := AudioEffectLowPassFilter.new()   # focus card muffle, off by default
		lp.cutoff_hz = 900.0
		AudioServer.add_bus_effect(master, lp, 0)
		AudioServer.set_bus_effect_enabled(master, 0, false)

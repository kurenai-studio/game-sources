extends Node
## Music and sound (autoload "Sound").
##
## Music comes in sets (title, stadium, events, ceremony), each a shuffled
## playlist with a short quiet gap between tracks (data/music.json). A track
## in the events set carries its beat map: tempo, where its first downbeat is,
## and where in it to start a race. While an event plays, the song clock says
## where in the track we are as it is heard, and every bounce in the game is
## timed against it. With no track, the song clock simply keeps time.
##
## Sound effects are families of takes (a bounce is any of several), picked at
## random and pitched a hair either way. They are soft, real instruments
## (tools/gen_audio.py) so that the taps sound like part of the music.
##
## A tablet that has joined another's game (ui/mirror.gd) follows its music:
## the same track, at the same place as it is heard there, and its sounds.

const SFX_DIR := "res://assets/audio/sfx/"

var music_volume := 0.8:
	set(v):
		music_volume = v
		_apply_volume()
var sfx_volume := 0.9

var _sets: Dictionary = {}
var _streams: Dictionary = {}
var _families: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _on: AudioStreamPlayer
var _set := ""
var _track: Dictionary = {}
var _gap := 0.0
var _gap_range := Vector2(2.0, 6.0)
var _duck := 1.0
var _fade_out := 0.0
var credits: Array = []

# the song clock
var _clock := 0.0
var _clock_on := false
var _clock_track := false      ## following a playing track (else free-running)
var _last_pos := -1.0
var _stalled := 0.0
var _paused := false
var _clock_was_on := false
var _following := false
var _fades := {}                 ## music player -> the tween turning it up or down
var _beat_path := ""             ## the last event's track (the next event has another)

const GO_ROOM := 50.0            ## seconds of track a go wants in front of it


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	add_child(_a)
	add_child(_b)
	_on = _a
	_a.finished.connect(func(): _track_done(_a))
	_b.finished.connect(func(): _track_done(_b))
	_load()
	get_tree().node_added.connect(_on_node_added)
	print("sound: output latency %.0fms" % (AudioServer.get_output_latency() * 1000.0))
	if Engine.has_singleton("Profile") or get_node_or_null("/root/Profile"):
		music_volume = Profile.music_volume
		sfx_volume = Profile.sfx_volume


func _load() -> void:
	var d := Catalog.music()
	_sets = {}
	for k in d.get("sets", {}):
		var list: Array = []
		for item in d.sets[k]:
			var entry: Dictionary = item if item is Dictionary else {"path": String(item)}
			if ResourceLoader.exists(String(entry.path)):
				list.append(entry)
		_sets[k] = list
	credits = d.get("credits", [])
	var g: Array = d.get("gap", [2.0, 6.0])
	_gap_range = Vector2(float(g[0]), float(g[1]))
	# sound effect families: <name>_<n>.ogg|wav
	var dir := DirAccess.open(SFX_DIR)
	if dir:
		for f in dir.get_files():
			var file := f.trim_suffix(".import")
			if not (file.ends_with(".ogg") or file.ends_with(".wav")):
				continue
			var base := file.get_basename()
			var fam := base
			var us := base.rfind("_")
			if us > 0 and base.substr(us + 1).is_valid_int():
				fam = base.substr(0, us)
			var list: Array = _families.get(fam, [])
			var path := SFX_DIR + file
			if not path in list:
				list.append(path)
			_families[fam] = list


func has_sound(name: String) -> bool:
	return _families.has(name)


func tracks(set_name: String) -> Array:
	return _sets.get(set_name, [])


func _stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[path] = s
	return s


# -- sound effects -----------------------------------------------------------------

func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("quiet"):
		(n as BaseButton).pressed.connect(func(): play("click", 0.7))


func play(name: String, volume := 1.0, pitch := 1.0) -> void:
	if Remote.running:
		Remote.sfx(name, volume, pitch)
	var fam: Array = _families.get(name, [])
	if fam.is_empty() or sfx_volume <= 0.0 or volume <= 0.01:
		return
	var s := _stream(String(fam[randi() % fam.size()]))
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.volume_db = linear_to_db(clampf(volume * sfx_volume, 0.0001, 2.0))
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


# -- music -------------------------------------------------------------------------

func _apply_volume() -> void:
	if _on:
		_on.volume_db = linear_to_db(maxf(0.0001, music_volume * _duck))


## Play a set (crossfading from whatever's on); if it's already playing, carry on.
func music(set_name: String, fade := 1.2) -> void:
	_clock_track = false
	_following = false
	if set_name == _set and (_on.playing or _gap > 0.0):
		return
	var list := tracks(set_name)
	_set = set_name
	if list.is_empty():
		_fade(fade)
		return
	_gap = 0.0
	_start(_pick(list), 0.0, fade)


func stop_music(fade := 0.8) -> void:
	_set = ""
	_fade(fade)


## A track from the list, not the one playing (nor `not_this`, if there's a choice).
func _pick(list: Array, not_this := "") -> Dictionary:
	if list.size() == 1:
		return list[0]
	var p: Dictionary = _track
	var guard := 0
	while (p.is_empty() or p.path == _track.get("path", "") or (p.path == not_this and list.size() > 2)) and guard < 40:
		guard += 1
		p = list[randi() % list.size()]
	return p


func _start(track: Dictionary, from: float, fade: float) -> void:
	var s := _stream(String(track.path))
	if s == null:
		return
	var old := _on
	_on = _b if _on == _a else _a
	_tween_for(_on)                    # (a fade still going on this player would stop the new track)
	_on.stream = s
	_on.volume_db = -60.0
	_on.play(from)
	_track = track
	_tween_for(_on).tween_property(_on, "volume_db", linear_to_db(maxf(0.0001, music_volume * _duck)), fade)
	if old.playing:
		var tw := _tween_for(old)
		tw.tween_property(old, "volume_db", -60.0, fade)
		tw.tween_callback(old.stop)


func _fade(fade: float) -> void:
	for p in [_a, _b]:
		if p.playing:
			var tw := _tween_for(p)
			tw.tween_property(p, "volume_db", -60.0, fade)
			tw.tween_callback(p.stop)


## A fresh tween for a music player, stopping the one it had.
func _tween_for(p: AudioStreamPlayer) -> Tween:
	var was: Tween = _fades.get(p)
	if was and was.is_valid():
		was.kill()
	var tw := create_tween()
	_fades[p] = tw
	return tw


func _track_done(p: AudioStreamPlayer) -> void:
	if p != _on or _set == "":
		return
	if _clock_on:
		# an event's track ran out mid-event: keep time from here, and don't
		# start another (it wouldn't be on this beat); the next go starts one
		_clock_track = false
		return
	_gap = randf_range(_gap_range.x, _gap_range.y)


## Turn the music down under something (a result being read out) and back.
func duck(amount: float, time := 0.4) -> void:
	_duck = amount
	if _on and _on.playing:
		create_tween().tween_property(_on, "volume_db", linear_to_db(maxf(0.0001, music_volume * _duck)), time)


func _process(delta: float) -> void:
	if _gap > 0.0 and not _paused and not _clock_on:
		_gap -= delta
		if _gap <= 0.0 and _set != "":
			var list := tracks(_set)
			if not list.is_empty():
				_start(_pick(list), 0.0, 0.8)
	if _clock_on:
		_clock += delta
		if _clock_track and _on.playing:
			var heard := _on.get_playback_position() + AudioServer.get_time_since_last_mix() \
				- AudioServer.get_output_latency()
			var err := heard - _clock
			if absf(err) > 0.08:
				_clock = heard
			else:
				_clock += err * 0.12


# -- the song clock, for events ------------------------------------------------------

## Start an event's music: a track from `set_name` with a beat map, begun a
## little before one of its downbeats. Returns the Beat to bounce to; the song
## clock then runs on that track's time. With no such track, a steady beat at
## `fallback_bpm` and a free-running clock.
##
## `again` (the next go in the same event): the same track. It carries on
## from where it's got to if there's a go's worth left, else starts again at
## the top; a new tune every go was too much.
func begin_beat(set_name: String, fallback_bpm := 90.0, again := false) -> Beat:
	_clock_on = true
	_gap = 0.0
	var list: Array = []
	for tr in tracks(set_name):
		if tr.has("bpm"):
			list.append(tr)
	if list.is_empty():
		_set = ""
		_fade(0.6)
		if not again:
			_clock = 0.0
		_clock_track = false
		return Beat.new(fallback_bpm, 0.0)
	var same := again and list.any(func(tr): return String(tr.path) == String(_track.get("path", "")))
	var track: Dictionary = _track if same else _pick(list, _beat_path)
	_set = set_name
	_beat_path = String(track.path)
	var beat := Beat.new(float(track.bpm), float(track.get("offset", 0.0)))
	beat.beats_per_bar = int(track.get("bar", 4))
	if carry_on(same, _on.playing, float(track.get("duration", 0.0)), _clock):
		return beat                    # the clock is still on this track
	# begin a bar before a downbeat somewhere the drums are in: for an event's
	# first go not always the top of the track; for its next goes the top
	var start := float(track.get("start", beat.offset))
	var room := float(track.get("duration", 0.0)) - start - GO_ROOM
	if room > beat.bar_len() and not same:
		start += floorf(randf() * room / beat.bar_len()) * beat.bar_len()
	start = maxf(0.0, beat.next_bar(start) - beat.bar_len())
	_start(track, start, 0.25)
	_clock = start
	_clock_track = DisplayServer.get_name() != "headless"
	_last_pos = -1.0
	_stalled = 0.0
	return beat


## Whether the next go in an event carries on with the track where it's got
## to (`at` seconds in): it's the event's track, still playing, with a go's
## worth left.
static func carry_on(same: bool, playing: bool, duration: float, at: float) -> bool:
	return same and playing and duration - at >= GO_ROOM


func song_time() -> float:
	return _clock


## The time a tap happened at, in song time: the clock, less the player's
## calibration (taps on a laggy screen land late).
func tap_time() -> float:
	return _clock - Profile.calibration


## Pause the music and the song clock (the pause menu), and carry on.
func pause_beat() -> void:
	if _paused:
		return
	_paused = true
	_clock_was_on = _clock_on
	_clock_on = false
	for p in [_a, _b]:
		p.stream_paused = true


func resume_beat() -> void:
	if not _paused:
		return
	_paused = false
	for p in [_a, _b]:
		p.stream_paused = false
	_clock_on = _clock_was_on
	_last_pos = -1.0
	_stalled = 0.0


func end_beat() -> void:
	_clock_on = false
	_clock_track = false
	if _set != "" and not _on.playing and _gap <= 0.0:
		_gap = 0.5


## Where the music is as it's heard here: its track and the second it's at
## (for a joined tablet to follow), or no path between tracks.
func heard() -> Dictionary:
	if _on == null:
		return {"path": "", "pos": 0.0, "paused": false}
	if _paused and _on.stream_paused:
		return {"path": String(_track.get("path", "")), "pos": _on.get_playback_position(), "paused": true}
	if not _on.playing:
		return {"path": "", "pos": 0.0, "paused": false}
	var pos := _on.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return {"path": String(_track.get("path", "")), "pos": pos, "paused": false}


## A joined tablet plays the host's music: this track, heard at `pos` seconds
## now (or nothing, with no path). Nudged back into step if it drifts.
func follow(path: String, pos: float, is_paused: bool) -> void:
	_following = true
	if _on == null:
		return
	_set = ""
	_gap = 0.0
	if path == "" or not ResourceLoader.exists(path):
		if _on.playing or _on.stream_paused:
			_on.stream_paused = false
			_fade(0.6)
		_track = {}
		return
	var want := maxf(0.0, pos + AudioServer.get_output_latency())
	var same := String(_track.get("path", "")) == path and (_on.playing or _on.stream_paused)
	if not same:
		_start({"path": path}, want, 0.3)
	elif not is_paused and not _on.stream_paused:
		var at := _on.get_playback_position() + AudioServer.get_time_since_last_mix()
		if absf(at - want) > 0.045:
			_on.seek(want)
	_on.stream_paused = is_paused


func unfollow() -> void:
	if _following and _on:
		_following = false
		_on.stream_paused = false
		stop_music(0.5)


func following() -> bool:
	return _following


## For tests and the bot: drive the clock by hand.
func set_clock(t: float, running := true) -> void:
	_clock = t
	_clock_on = running
	_clock_track = false

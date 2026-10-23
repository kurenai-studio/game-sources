extends Node
## Background music: one playlist that keeps playing across the menu and battles, a boss track while a boss
## wave is on, and a victory jingle. Tracks are CC0, see assets/music/SOURCES.txt.

const PLAYLIST := [
	{"title": "Title Screen", "author": "Juhani Junkala", "path": "res://assets/music/title_screen.ogg"},
	{"title": "Level 1", "author": "Juhani Junkala", "path": "res://assets/music/level_1.ogg"},
	{"title": "Level 2", "author": "Juhani Junkala", "path": "res://assets/music/level_2.ogg"},
	{"title": "Level 3", "author": "Juhani Junkala", "path": "res://assets/music/level_3.ogg"},
	{"title": "Stage 1", "author": "Juhani Junkala", "path": "res://assets/music/stage_1.ogg"},
	{"title": "Stage 2", "author": "Juhani Junkala", "path": "res://assets/music/stage_2.ogg"},
]
const BOSS := {"title": "Boss Fight", "author": "Juhani Junkala", "path": "res://assets/music/boss_fight.ogg"}
const WIN := {"title": "Ending", "author": "Juhani Junkala", "path": "res://assets/music/ending.ogg"}
const MIN_PLAY := 60.0   # short loops repeat until a track has played about this long, then the next one starts

signal track_changed

var index := 0
var mode := "playlist"   # "playlist", "boss" or "jingle"
var _player: AudioStreamPlayer
var _repeats := 0
var _enabled := false
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = DisplayServer.get_name() != "headless"
	if not _enabled:
		return
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)
	apply_volume()
	_start_playlist_track()


## The track playing now: {"title", "author"}.
func current() -> Dictionary:
	match mode:
		"boss":
			return BOSS
		"jingle":
			return WIN
	return PLAYLIST[index]


func apply_volume() -> void:
	if _player:
		_player.volume_db = linear_to_db(maxf(0.001, Game.music_volume))


func next() -> void:
	_skip(1)


func prev() -> void:
	_skip(-1)


## Boss waves get their own track; when the boss wave is over the playlist goes on.
func set_boss(on: bool) -> void:
	if not _enabled:
		return
	if on and mode != "boss":
		mode = "boss"
		_play(BOSS)
	elif not on and mode == "boss":
		_start_playlist_track()


func play_victory() -> void:
	if not _enabled:
		return
	mode = "jingle"
	_play(WIN)


## After a loss the music fades out; back_to_playlist() (menu, restart) brings it back.
func fade_out() -> void:
	if not _enabled or not _player.playing:
		return
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", -40.0, 1.5)
	_fade.tween_callback(_player.stop)


func back_to_playlist() -> void:
	if not _enabled:
		return
	var fading := _fade != null and _fade.is_running()
	if fading:
		_fade.kill()
	if mode != "playlist" or not _player.playing or fading:
		_start_playlist_track()


func _skip(step: int) -> void:
	index = posmod(index + step, PLAYLIST.size())
	if _enabled:
		_start_playlist_track()
	else:
		track_changed.emit()


func _start_playlist_track() -> void:
	mode = "playlist"
	var t: Dictionary = PLAYLIST[index]
	_play(t)
	var length: float = _player.stream.get_length() if _player.stream else MIN_PLAY
	_repeats = maxi(1, ceili(MIN_PLAY / maxf(1.0, length)))


func _play(t: Dictionary) -> void:
	var s: AudioStream = load(t["path"])
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = t == BOSS   # the boss track loops on its own, the rest we sequence
	_player.stream = s
	apply_volume()
	_player.play()
	track_changed.emit()


func _on_finished() -> void:
	match mode:
		"playlist":
			_repeats -= 1
			if _repeats > 0:
				_player.play()
			else:
				_skip(1)
		"jingle":
			_start_playlist_track()

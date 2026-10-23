extends Node
## Klänge (Autoload "Sfx"): Sfx.play(&"click") oder Sfx.play_at(&"arrow", position) für Geräusche auf der
## Karte, die nur zu hören sind, wenn die Stelle im Bild ist. Häufige Klänge werden begrenzt, damit viele
## Türme nicht zu einem Dauerrauschen werden. Ton an/aus wird in user://settings.cfg gespeichert.

const SETTINGS := "user://settings.cfg"
const VOICES := 24
## Lautstärke in dB je Klang (alle Dateien sind auf gleiche Spitze angeglichen).
const VOLUME := {
	&"arrow": -11.0, &"bolt": -9.0, &"throw": -8.0, &"fire": -12.0, &"magic": -13.0, &"lightning": -10.0,
	&"stab": -10.0, &"hit": -16.0, &"crash": -7.0, &"burst": -9.0,
	&"die": -12.0, &"bones": -11.0, &"ghost": -11.0, &"boss": -3.0, &"boss_die": -3.0, &"keep_hit": -5.0,
	&"build": -6.0, &"upgrade": -5.0, &"spec": -5.0, &"sell": -6.0, &"coins": -6.0, &"error": -8.0,
	&"click": -10.0, &"wave": -6.0, &"victory": -3.0, &"defeat": -3.0,
}
## Höchstens so viele gleiche Klänge gleichzeitig (sonst 2).
const MAX_SAME := {&"arrow": 3, &"hit": 3, &"die": 3, &"bones": 3, &"magic": 2, &"crash": 2}
## Mindestabstand in Sekunden Echtzeit zwischen zwei gleichen Klängen.
const MIN_GAP := 0.07
## Ohne Tonhöhen-Streuung (Musik und Oberfläche).
const STEADY: Array[StringName] = [&"wave", &"victory", &"defeat", &"click", &"error"]

var muted := false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: StringName in VOLUME:
		_streams[id] = load("res://assets/audio/%s.ogg" % id)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	var config := ConfigFile.new()
	if config.load(SETTINGS) == OK:
		muted = config.get_value("audio", "muted", false)
	_apply_mute()


func play(id: StringName) -> void:
	if muted or not _streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(id, -1.0)) < MIN_GAP:
		return
	var same := 0
	var free: AudioStreamPlayer = null
	for player in _players:
		if player.playing:
			if player.stream == _streams[id]:
				same += 1
		elif free == null:
			free = player
	if free == null or same >= int(MAX_SAME.get(id, 2)):
		return
	_last[id] = now
	free.stream = _streams[id]
	free.volume_db = VOLUME[id]
	free.pitch_scale = 1.0 if id in STEADY else randf_range(0.9, 1.1)
	free.play()


## Geräusch auf der Karte: nur, wenn die Stelle gerade zu sehen ist.
func play_at(id: StringName, at: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and not camera.is_position_in_frustum(at):
		return
	play(id)


func set_muted(value: bool) -> void:
	muted = value
	_apply_mute()
	var config := ConfigFile.new()
	config.load(SETTINGS)
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)
	if muted:
		for player in _players:
			player.stop()


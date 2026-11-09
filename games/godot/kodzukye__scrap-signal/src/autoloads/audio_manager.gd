extends Node

const AMBIANCE_VOLUME_DB: float = -12.0
const SFX_VOLUME_DB: float = -8.0

const AMBIANCES: Dictionary = {
	"entrepot": preload("res://assets/audio/music/entrepot.ogg"),
	"atelier":  preload("res://assets/audio/music/atelier.ogg"),
	"cour":     preload("res://assets/audio/music/cour.ogg"),
}

const SFX: Dictionary = {
	"item_pickup":    preload("res://assets/audio/sfx/item_pickup.ogg"),
	"interact":       preload("res://assets/audio/sfx/interact.ogg"),
	"door_unlock":    preload("res://assets/audio/sfx/door_unlocking.ogg"),
	"repair_success": preload("res://assets/audio/sfx/succesful_repair.ogg"),
}

var music_player : AudioStreamPlayer
var sfx_player   : AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Ambient"
	music_player.volume_db = AMBIANCE_VOLUME_DB
	add_child(music_player)
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	sfx_player.bus = "SFX"
	sfx_player.volume_db = SFX_VOLUME_DB
	add_child(sfx_player)
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS

func play_ambiance(zone: String) -> void:
	if not AMBIANCES.has(zone):
		return
	if music_player.stream == AMBIANCES[zone] and music_player.playing:
		return

	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, 0.8)
	tween.tween_callback(func():
		music_player.stream = AMBIANCES[zone]
		music_player.play()
	)
	tween.tween_property(music_player, "volume_db", AMBIANCE_VOLUME_DB, 1.2)

func stop_ambiance() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, 1.0)
	tween.tween_callback(music_player.stop)

func play_sfx(sfx_name: String) -> void:
	if not SFX.has(sfx_name):
		push_warning("SFX introuvable : " + sfx_name)
		return
	sfx_player.stream = SFX[sfx_name]
	sfx_player.play()

func _on_music_finished() -> void:
	music_player.play()

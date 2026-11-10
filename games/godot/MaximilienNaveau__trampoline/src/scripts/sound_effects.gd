# The game's sound effects (made by tools/audio/make_sfx.py), played by
# name: `_sound_effects.play("tile_drop")`. Purely presentation — nothing
# here knows the rules; main.gd decides when each one fits.
class_name SoundEffects
extends Node

# Every effect quieter than the files themselves (normalised to full
# loudness), so they sit under the music rather than on top of it. In
# decibels: -6 dB is about half the amplitude.
const VOLUME_DB := -14.0

# Name -> sound file. `preload` loads each file once, when this script
# itself is loaded (like a Python module-level import), not on every play.
const SOUNDS := {
	"bounce": preload("res://assets/audio/sfx/bounce.wav"),
	"bounce_small": preload("res://assets/audio/sfx/bounce_small.wav"),
	"tile_pick": preload("res://assets/audio/sfx/tile_pick.wav"),
	"tile_drop": preload("res://assets/audio/sfx/tile_drop.wav"),
	"tile_flip": preload("res://assets/audio/sfx/tile_flip.wav"),
	"word_valid": preload("res://assets/audio/sfx/word_valid.wav"),
	"word_invalid": preload("res://assets/audio/sfx/word_invalid.wav"),
	"line_complete": preload("res://assets/audio/sfx/line_complete.wav"),
	"word_bonus": preload("res://assets/audio/sfx/word_bonus.wav"),
	"game_end": preload("res://assets/audio/sfx/game_end.wav"),
}

# Name -> the AudioStreamPlayer node playing that sound (see main.gd's
# GameMusic for what an AudioStreamPlayer is). One player per sound, so
# two different sounds can overlap — a player only plays one at a time.
var _players := {}


func _ready() -> void:
	for sound_name: String in SOUNDS:
		var player := AudioStreamPlayer.new()
		player.stream = SOUNDS[sound_name]
		player.volume_db = VOLUME_DB
		# Lets the same sound overlap itself too, e.g. quick tile drops.
		player.max_polyphony = 3
		# Sent to the "Effects" bus (see audio_settings.gd), so the sound
		# menu can set its volume apart from the music.
		player.bus = &"Effects"
		# A node made in code joins the scene tree like one from a .tscn.
		add_child(player)
		_players[sound_name] = player


# Plays the sound called `sound_name` (a key of SOUNDS) from the top.
func play(sound_name: String) -> void:
	_players[sound_name].play()

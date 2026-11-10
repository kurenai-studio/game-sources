# A music player (an AudioStreamPlayer, see main.gd's GameMusic) that
# fades in from silence when it starts and out to silence before it stops,
# instead of cutting in and out. Going from the menu to a game, one fades
# out while the other fades in: a crossfade.
class_name FadingMusic
extends AudioStreamPlayer

const FADE_SECONDS := 2.0
# Quiet enough to be silence: each -6 dB halves the amplitude.
const SILENT_DB := -60.0

# The volume set on the node in scenes/main.tscn, reached at the end of a
# fade in.
var _full_db: float
# The fade under way, if any (see `_fade_to`).
var _tween: Tween


func _ready() -> void:
	_full_db = volume_db


# Starts the music from silence, or, if it's still fading out, turns it
# back up from where it is. Given another tune (`new_stream`), switches to
# it first, from silence: setting `stream` stops the one playing.
func fade_in(new_stream: AudioStream = stream) -> void:
	if new_stream != stream:
		stream = new_stream
	if not playing:
		volume_db = SILENT_DB
		play()
	_fade_to(_full_db)


# Fades the music out, then stops it. Nothing to do if it isn't playing.
func fade_out() -> void:
	if playing:
		# `tween_callback` queues a function to run once the fade is done.
		_fade_to(SILENT_DB).tween_callback(stop)


# A Tween (made by `create_tween`) animates a property over time — here
# `volume_db`, from its current value to `target_db`. Any fade still under
# way is stopped first, so two never pull the volume opposite ways.
func _fade_to(target_db: float) -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "volume_db", target_db, FADE_SECONDS)
	return _tween

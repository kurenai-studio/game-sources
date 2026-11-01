class_name AudioService extends Node
## Plays the click (docs/ARCHITECTURE.md section 9, GDD D-36 and section 16).
##
## The App adds one AudioService to the tree and passes it to whoever needs
## it. The App calls set_enabled from Settings at start and on every change.
## The board calls play_click for every tile added to a chain and once when a
## commit is accepted. Sound is on by default. When it is off, nothing plays.
##
## Fast drags. A click that starts less than MIN_GAP_USEC after the last one
## would blur into it anyway, so that request is counted but does not start a
## second click. With that gap, a 65 ms click overlaps at most one other, and
## POLYPHONY 2 lets the earlier click ring out instead of being cut off.
## ClickSynth keeps each click at -8 dBFS, so even two clicks that start on
## the same sample stay below -1 dBFS and never clip.

## Clicks that may sound at once.
const POLYPHONY: int = 2
## Shortest time between the starts of two clicks, microseconds.
const MIN_GAP_USEC: int = 35000

## TH20: every play_click call, with sound on or off.
var click_requests: int = 0

var _enabled: bool = true
var _player: AudioStreamPlayer = AudioStreamPlayer.new()
## When the last click started (Time.get_ticks_usec), or -1 for none yet.
var _last_start_usec: int = -1
## Clicks that passed the sound check and the gap. The tests read it, since a
## headless run cannot hear anything.
var _clicks_started: int = 0


func _init() -> void:
	_player.name = &"ClickPlayer"
	_player.stream = ClickSynth.build(_output_mix_rate())
	_player.max_polyphony = POLYPHONY
	add_child(_player)


func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		_player.stop()
		_last_start_usec = -1


func is_enabled() -> bool:
	return _enabled


## Does nothing audible when sound is off. Always counts the request.
func play_click() -> void:
	click_requests += 1
	if _accept_click(Time.get_ticks_usec()) and _player.is_inside_tree():
		_player.play()


## True when a click may start at now_usec: sound is on and the last click
## started at least MIN_GAP_USEC earlier. Records the start when true.
func _accept_click(now_usec: int) -> bool:
	if not _enabled:
		return false
	if _last_start_usec >= 0 and now_usec - _last_start_usec < MIN_GAP_USEC:
		return false
	_last_start_usec = now_usec
	_clicks_started += 1
	return true


## The rate the audio server mixes at, so the click plays without resampling.
static func _output_mix_rate() -> int:
	var rate: int = roundi(AudioServer.get_mix_rate())
	if rate < ClickSynth.MIN_MIX_RATE or rate > ClickSynth.MAX_MIX_RATE:
		return ClickSynth.DEFAULT_MIX_RATE
	return rate

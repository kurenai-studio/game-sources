# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name SettingsPanel
extends Modal
## Settings: sound effects on or off, music on or off, and a row that opens About (playbook
## 6.4). Sound effects is the master switch: music plays only while both are on. The Music
## row keeps its own setting while sound effects are off, so turning sound effects back on
## brings the music back as it was.

signal sound_changed(on: bool)
signal music_changed(on: bool)
signal about_requested()

var sound_on: bool = true
var music_on: bool = true
var sound_button: TapButton
var music_button: TapButton


func _init(initial_sound_on: bool, initial_music_on: bool = true) -> void:
	super("Settings")
	sound_on = initial_sound_on
	music_on = initial_music_on
	sound_button = UiKit.button("")
	sound_button.tapped.connect(_toggle_sound)
	body.add_child(sound_button)
	music_button = UiKit.button("")
	music_button.tapped.connect(_toggle_music)
	body.add_child(music_button)
	var about: TapButton = UiKit.button("About")
	about.tapped.connect(func() -> void: about_requested.emit())
	body.add_child(about)
	var done: TapButton = UiKit.button("Close", &"PrimaryButton")
	done.tapped.connect(request_close)
	body.add_child(done)
	_show_rows()


func _toggle_sound() -> void:
	sound_on = not sound_on
	_show_rows()
	sound_changed.emit(sound_on)


func _toggle_music() -> void:
	music_on = not music_on
	_show_rows()
	music_changed.emit(music_on)


func _show_rows() -> void:
	sound_button.text = "Sound effects: On" if sound_on else "Sound effects: Off"
	music_button.text = "Music: On" if music_on else "Music: Off"

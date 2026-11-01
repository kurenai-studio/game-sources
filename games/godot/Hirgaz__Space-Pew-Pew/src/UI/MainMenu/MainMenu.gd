extends Control


const SETTINGS_FILE_PATH = "user://settings.cfg"


signal continue_pressed()
signal restart_pressed()
signal help_pressed()
signal credits_pressed()
signal quit_pressed()


@onready var music_enabled := %MusicVolumeEnabled
@onready var music_text := %MusicVolumeText
@onready var music_display := %MusicVolumeDisplay
@onready var music_slider := %MusicVolumeSlider

@onready var voice_enabled := %VoiceVolumeEnabled
@onready var voice_text := %VoiceVolumeText
@onready var voice_display := %VoiceVolumeDisplay
@onready var voice_slider := %VoiceVolumeSlider

@onready var effects_enabled := %EffectsVolumeEnabled
@onready var effects_text := %EffectsVolumeText
@onready var effects_display := %EffectsVolumeDisplay
@onready var effects_slider := %EffectsVolumeSlider

@onready var ui_enabled := %UIVolumeEnabled
@onready var ui_text := %UIVolumeText
@onready var ui_display := %UIVolumeDisplay
@onready var ui_slider := %UIVolumeSlider

@onready var main_enabled := %MainVolumeEnabled
@onready var main_text := %MainVolumeText
@onready var main_display := %MainVolumeDisplay
@onready var main_slider := %MainVolumeSlider

@onready var continue_button := %ContinueButton
@onready var quit_vbox := %QuitVBoxContainer
@onready var quit_button := %QuitButton


var music_bus_index: int
var voice_bus_index: int
var effects_bus_index: int
var ui_bus_index: int

var config_file := ConfigFile.new()


func _ready() -> void:
	# Disable quit button on Web.
	if OS.has_feature("web"):
		quit_vbox.visible = false

	_load_settings()

	# Get bus indices.
	music_bus_index = AudioServer.get_bus_index(&"Music")
	voice_bus_index = AudioServer.get_bus_index(&"Voice")
	effects_bus_index = AudioServer.get_bus_index(&"Effects")
	ui_bus_index = AudioServer.get_bus_index(&"UI")

	# Update volumes and mute.
	var is_enabled : bool = config_file.get_value("audio", "music_enabled", true)
	AudioServer.set_bus_mute(music_bus_index, not is_enabled)
	music_enabled.set_pressed_no_signal(is_enabled)
	var volume : float = config_file.get_value("audio", "music_volume", 100.0)
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(volume / 100.0))
	music_slider.set_value_no_signal(volume)
	music_display.text = "%d%%" % volume

	is_enabled = config_file.get_value("audio", "voice_enabled", true)
	AudioServer.set_bus_mute(voice_bus_index, not is_enabled)
	voice_enabled.set_pressed_no_signal(is_enabled)
	volume = config_file.get_value("audio", "voice_volume", 100.0)
	AudioServer.set_bus_volume_db(voice_bus_index, linear_to_db(volume / 100.0))
	voice_slider.set_value_no_signal(volume)
	voice_display.text = "%d%%" % volume

	is_enabled = config_file.get_value("audio", "effects_enabled", true)
	AudioServer.set_bus_mute(effects_bus_index, not is_enabled)
	effects_enabled.set_pressed_no_signal(is_enabled)
	volume = config_file.get_value("audio", "effects_volume", 100.0)
	AudioServer.set_bus_volume_db(effects_bus_index, linear_to_db(volume / 100.0))
	effects_slider.set_value_no_signal(volume)
	effects_display.text = "%d%%" % volume

	is_enabled = config_file.get_value("audio", "ui_enabled", true)
	AudioServer.set_bus_mute(ui_bus_index, not is_enabled)
	ui_enabled.set_pressed_no_signal(is_enabled)
	volume = config_file.get_value("audio", "ui_volume", 100.0)
	AudioServer.set_bus_volume_db(ui_bus_index, linear_to_db(volume / 100.0))
	ui_slider.set_value_no_signal(volume)
	ui_display.text = "%d%%" % volume

	is_enabled = config_file.get_value("audio", "main_enabled", true)
	AudioServer.set_bus_mute(0, not is_enabled)
	main_enabled.set_pressed_no_signal(is_enabled)
	volume = config_file.get_value("audio", "main_volume", 100.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(volume / 100.0))
	main_slider.set_value_no_signal(volume)
	main_display.text = "%d%%" % volume


func _update_volume_sizes() -> void:
	# Compute minimum width, to compensate for translations.
	var minimum_width : float = max(
			music_text.get_minimum_size().x,
			voice_text.get_minimum_size().x,
			effects_text.get_minimum_size().x,
			ui_text.get_minimum_size().x,
			main_text.get_minimum_size().x,
			80.0
		)
	music_text.custom_minimum_size.x = minimum_width
	voice_text.custom_minimum_size.x = minimum_width
	effects_text.custom_minimum_size.x = minimum_width
	ui_text.custom_minimum_size.x = minimum_width
	main_text.custom_minimum_size.x = minimum_width


func _on_visibility_changed() -> void:
	if visible:
		_update_volume_sizes()
		continue_button.grab_focus()


func _load_settings() -> void:
	# Only load if the user filesystem is persistent.
	if OS.is_userfs_persistent():
		# Try to load the settings.
		config_file.load(SETTINGS_FILE_PATH)

		# Fill defaults if missing.
		if not config_file.has_section_key("audio", "main_enabled"):
			config_file.set_value("audio", "main_enabled", true)
		if not config_file.has_section_key("audio", "main_volume"):
			config_file.set_value("audio", "main_volume", 100.0)

		if not config_file.has_section_key("audio", "music_enabled"):
			config_file.set_value("audio", "music_enabled", true)
		if not config_file.has_section_key("audio", "music_volume"):
			config_file.set_value("audio", "music_volume", 100.0)

		if not config_file.has_section_key("audio", "voice_enabled"):
			config_file.set_value("audio", "voice_enabled", true)
		if not config_file.has_section_key("audio", "voice_volume"):
			config_file.set_value("audio", "voice_volume", 100.0)

		if not config_file.has_section_key("audio", "effects_enabled"):
			config_file.set_value("audio", "effects_enabled", true)
		if not config_file.has_section_key("audio", "effects_volume"):
			config_file.set_value("audio", "effects_volume", 100.0)

		if not config_file.has_section_key("audio", "ui_enabled"):
			config_file.set_value("audio", "ui_enabled", true)
		if not config_file.has_section_key("audio", "ui_volume"):
			config_file.set_value("audio", "ui_volume", 100.0)


func _save_settings() -> void:
	# Only save if the user filesystem is persistent.
	if OS.is_userfs_persistent():
		# Write volumes.
		config_file.save(SETTINGS_FILE_PATH)


# Volume Controls.

func _on_music_volume_enabled_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(music_bus_index, not toggled_on)
	config_file.set_value("audio", "music_enabled", toggled_on)


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value / 100.0))
	music_display.text = "%d%%" % value
	config_file.set_value("audio", "music_volume", value)

func _on_voice_volume_enabled_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(voice_bus_index, not toggled_on)
	config_file.set_value("audio", "voice_enabled", toggled_on)


func _on_voice_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(voice_bus_index, linear_to_db(value / 100.0))
	voice_display.text = "%d%%" % value
	config_file.set_value("audio", "voice_volume", value)


func _on_effects_volume_enabled_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(effects_bus_index, not toggled_on)
	config_file.set_value("audio", "effects_enabled", toggled_on)


func _on_effects_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(effects_bus_index, linear_to_db(value / 100.0))
	effects_display.text = "%d%%" % value
	config_file.set_value("audio", "effects_volume", value)


func _on_ui_volume_enabled_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(ui_bus_index, not toggled_on)
	config_file.set_value("audio", "ui_enabled", toggled_on)


func _on_ui_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(ui_bus_index, linear_to_db(value / 100.0))
	ui_display.text = "%d%%" % value
	config_file.set_value("audio", "ui_volume", value)


func _on_main_volume_enabled_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, not toggled_on)
	config_file.set_value("audio", "main_enabled", toggled_on)


func _on_main_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
	main_display.text = "%d%%" % value
	config_file.set_value("audio", "main_volume", value)


func _on_continue_button_pressed() -> void:
	_save_settings()
	continue_pressed.emit()


func _on_restart_button_pressed() -> void:
	_save_settings()
	restart_pressed.emit()


func _on_help_button_pressed() -> void:
	_save_settings()
	help_pressed.emit()


func _on_credits_button_pressed() -> void:
	_save_settings()
	credits_pressed.emit()


func _on_quit_button_pressed() -> void:
	_save_settings()
	quit_pressed.emit()

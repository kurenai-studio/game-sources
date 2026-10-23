extends Control

const GAME_SCENE_PATH: String = "res://scenes/galaxy.tscn"
const OPTIONS_MODAL_SCRIPT: Script = preload("res://scripts/ui/options_modal.gd")
const INTRO_TEXT: String = "The galaxy is unobserved and awaits conquest.\nUse Beacon Artifacts to reach and colonize distant planets.\nWhen every world belongs to you, victory is yours."
const BLACK_FADE_DURATION: float = 0.8
const TYPEWRITER_DURATION: float = 5.0
const PROMPT_FADE_DURATION: float = 0.85

@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var start_button: Button = $StartButton
@onready var _options_button: Button = $OptionsButton
@onready var _exit_button: Button = $ExitButton
@onready var logo: TextureRect = $Logo
@onready var version_label: Label = $VersionLabel
@onready var intro_fade: ColorRect = $IntroFade
@onready var intro_text: Label = $IntroText
@onready var prompt_label: Label = $PromptLabel
@onready var copyright_text: RichTextLabel = $CopyrightText
@onready var credits_modal: ColorRect = $CreditsModal
@onready var credits_text: RichTextLabel = $CreditsModal/CreditsPanel/MarginContainer/VBoxContainer/CreditsText
@onready var credits_close_button: Button = $CreditsModal/CreditsPanel/MarginContainer/VBoxContainer/CloseButton

var _intro_started: bool = false
var _ready_to_start: bool = false
var _loading_game: bool = false
var _prompt_tween: Tween
var _options_modal: OptionsModal


func _ready() -> void:
	_configure_music_bus()
	_play_background_music_when_ready()
	_ensure_options_controls()
	start_button.pressed.connect(_on_start_button_pressed)
	_options_button.pressed.connect(_on_options_button_pressed)
	_exit_button.pressed.connect(_on_exit_button_pressed)
	if OS.has_feature("web"):
		_exit_button.hide()
	copyright_text.meta_clicked.connect(_on_copyright_text_meta_clicked)
	credits_text.meta_clicked.connect(_on_credits_text_meta_clicked)
	credits_close_button.pressed.connect(_on_credits_close_button_pressed)
	version_label.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	start_button.grab_focus()
	credits_modal.visible = false
	intro_fade.modulate.a = 0.0
	intro_text.text = INTRO_TEXT
	intro_text.visible_characters = 0
	intro_text.modulate.a = 0.0
	prompt_label.modulate.a = 0.0


func _unhandled_key_input(event: InputEvent) -> void:
	if _options_modal != null and _options_modal.visible:
		return
	if not _ready_to_start or _loading_game:
		return

	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	_loading_game = true
	get_viewport().set_input_as_handled()
	_start_game()


func _on_start_button_pressed() -> void:
	if _intro_started:
		return

	_intro_started = true
	credits_modal.visible = false
	start_button.disabled = true
	start_button.release_focus()
	if _options_button != null:
		_options_button.disabled = true
		_options_button.release_focus()
		_options_button.hide()
	if _exit_button != null:
		_exit_button.disabled = true
		_exit_button.release_focus()
		_exit_button.hide()
	_play_intro_sequence()


func _on_copyright_text_meta_clicked(meta: Variant) -> void:
	if _intro_started:
		return
	if str(meta) != "credits":
		return

	credits_modal.visible = true
	credits_close_button.grab_focus()


func _on_credits_close_button_pressed() -> void:
	credits_modal.visible = false
	start_button.grab_focus()


func _on_options_button_pressed() -> void:
	if _intro_started or _options_modal == null:
		return

	credits_modal.visible = false
	_options_modal.open()


func _on_exit_button_pressed() -> void:
	_exit_game()


func _exit_game() -> void:
	get_tree().quit()


func _on_credits_text_meta_clicked(meta: Variant) -> void:
	var url := str(meta)
	if not url.begins_with("https://"):
		return

	var error := OS.shell_open(url)
	if error != OK:
		push_warning("Could not open credits URL: %s" % url)


func _play_intro_sequence() -> void:
	var fade_tween := create_tween()
	fade_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(intro_fade, "modulate:a", 1.0, BLACK_FADE_DURATION)
	await fade_tween.finished

	logo.visible = false
	start_button.visible = false
	intro_text.modulate.a = 1.0

	var typewriter_tween := create_tween()
	typewriter_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	typewriter_tween.tween_property(intro_text, "visible_characters", INTRO_TEXT.length(), TYPEWRITER_DURATION)
	await typewriter_tween.finished

	_ready_to_start = true
	_start_prompt_loop()


func _start_prompt_loop() -> void:
	if _prompt_tween != null:
		_prompt_tween.kill()

	_prompt_tween = create_tween()
	_prompt_tween.set_loops()
	_prompt_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, PROMPT_FADE_DURATION)
	_prompt_tween.tween_property(prompt_label, "modulate:a", 0.18, PROMPT_FADE_DURATION)


func _start_game() -> void:
	if _prompt_tween != null:
		_prompt_tween.kill()

	var error := get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error != OK:
		push_error("Could not start game scene: %s" % GAME_SCENE_PATH)


func _configure_music_bus() -> void:
	var audio_settings := get_node_or_null("/root/AudioSettings")
	if audio_settings != null and audio_settings.has_method("ensure_audio_buses"):
		audio_settings.call("ensure_audio_buses")
	if background_music != null:
		background_music.bus = "Music"


func _play_background_music_when_ready() -> void:
	var audio_settings := get_node_or_null("/root/AudioSettings")
	if audio_settings != null and audio_settings.has_method("play_music_when_ready"):
		audio_settings.call("play_music_when_ready", background_music)
		return

	if background_music != null and not background_music.playing:
		background_music.play()


func _ensure_options_controls() -> void:
	_options_modal = OPTIONS_MODAL_SCRIPT.new() as OptionsModal
	_options_modal.name = "OptionsModal"
	_options_modal.z_index = 1200
	add_child(_options_modal)

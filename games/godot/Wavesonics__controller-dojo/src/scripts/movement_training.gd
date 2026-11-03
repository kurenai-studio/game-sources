extends Control

const Sfx := preload("res://scripts/sfx.gd")
const UiInput := preload("res://scripts/ui_input.gd")
const CheerPopup := preload("res://scripts/cheer_popup.gd")
const Haptics := preload("res://scripts/haptics.gd")

const SMALL_CHEERS := ["Yay!", "Nice!", "Wow!", "Perfect!", "So good!"]
const BIG_CHEERS := ["AMAZING!", "SUPERSTAR!", "YOU DID IT!"]
const HOLD_RUMBLE_INTERVAL := 0.15
const HOLD_RUMBLE_STRENGTH := 0.10

@onready var _field: Control = %Field
@onready var _mini_stick: Control = %MiniStick
@onready var _stars: Control = %ScoreStars
@onready var _cheer: Label = %Cheer
@onready var _back: Button = %BackButton

var _device: int = -1
var _cheer_tween: Tween
var _coin_player: AudioStreamPlayer
var _fanfare_player: AudioStreamPlayer
var _holding: bool = false
var _hold_rumble_accum: float = 0.0


func _ready() -> void:
	_coin_player = _build_player(Sfx.coin(), -4.0)
	_fanfare_player = _build_player(Sfx.fanfare(), -3.0)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_field.stars_changed.connect(_on_stars_changed)
	_field.star_won.connect(_on_star_won)
	_field.round_complete.connect(_on_round_complete)
	_field.holding_changed.connect(_on_holding_changed)
	_cheer.modulate.a = 0.0
	_pick_device()


func _process(delta: float) -> void:
	if not _holding or _device < 0:
		return
	_hold_rumble_accum += delta
	if _hold_rumble_accum >= HOLD_RUMBLE_INTERVAL:
		_hold_rumble_accum = 0.0
		Haptics.rumble(_device, HOLD_RUMBLE_STRENGTH, 0.0, HOLD_RUMBLE_INTERVAL * 1.4)


func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			if UiInput.activate_focused(viewport):
				viewport.set_input_as_handled()
			return
		if event.button_index in UiInput.MENU_BUTTONS:
			UiInput.toggle_back(_back)
			viewport.set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _pick_device() -> void:
	Haptics.forget_devices()
	var pads := Input.get_connected_joypads()
	_device = pads[0] if not pads.is_empty() else -1
	_field.device = _device
	_mini_stick.device = _device


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	_pick_device()


func _on_stars_changed(stars: int) -> void:
	_stars.filled = stars


func _on_star_won(_total: int) -> void:
	_coin_player.play()
	_show_cheer(SMALL_CHEERS.pick_random(), 44, Color(0.45, 0.95, 0.6), 1.1)
	if _device >= 0:
		Haptics.rumble(_device, 0.35, 0.45, 0.18)


func _on_round_complete() -> void:
	_coin_player.stop()
	_fanfare_player.play()
	_show_cheer(BIG_CHEERS.pick_random(), 84, Color(1.0, 0.8, 0.28), 2.2)
	if _device >= 0:
		Haptics.rumble(_device, 0.55, 0.75, 0.5)


func _on_holding_changed(active: bool) -> void:
	_holding = active
	_hold_rumble_accum = 0.0
	if not active and _device >= 0:
		Haptics.stop(_device)


func _build_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _show_cheer(text: String, font_size: int, color: Color, hold: float) -> void:
	_cheer_tween = CheerPopup.show(_cheer, _cheer_tween, text, font_size, color, hold)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

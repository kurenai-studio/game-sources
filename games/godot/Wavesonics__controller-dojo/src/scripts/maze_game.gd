extends Control

const Sfx := preload("res://scripts/sfx.gd")
const UiInput := preload("res://scripts/ui_input.gd")
const CheerPopup := preload("res://scripts/cheer_popup.gd")
const GameSettings := preload("res://scripts/game_settings.gd")
const Haptics := preload("res://scripts/haptics.gd")

const GOAL := 5
const CELEBRATE_TIME := 1.4
const ROUND_CELEBRATE_TIME := 2.6
const SMALL_CHEERS := ["Yay!", "You found it!", "Nice!", "Wow!", "So good!"]
const BIG_CHEERS := ["AMAZING!", "SUPERSTAR!", "YOU DID IT!"]
const PLAY_ORIGIN := Vector2(16.0, 96.0)
const PLAY_INSET := Vector2(32.0, 172.0)

const STRIKE_LIMIT := 3
const STRIKE_GRACE := 0.9
const STRIKE_FLASH := 0.55
const RESET_TIME := 1.5

@onready var _world = %World
@onready var _mini_stick: Control = %MiniStick
@onready var _score: Control = %ScoreStars
@onready var _strikes_meter = %StrikeMeter
@onready var _cheer: Label = %Cheer
@onready var _back: Button = %BackButton

var _device: int = -1
var _stars: int = 0
var _hard: bool = false
var _strikes: int = 0
var _grace: float = 0.0
var _celebrating: bool = false
var _resetting: bool = false
var _laid_out: bool = false
var _cheer_tween: Tween
var _coin_player: AudioStreamPlayer
var _fanfare_player: AudioStreamPlayer
var _bump_player: AudioStreamPlayer
var _strike_player: AudioStreamPlayer


func _ready() -> void:
	_coin_player = _build_player(Sfx.coin(), -4.0)
	_fanfare_player = _build_player(Sfx.fanfare(), -3.0)
	_bump_player = _build_player(Sfx.blip(180.0), -16.0)
	_strike_player = _build_player(Sfx.blip(110.0), -6.0)
	_hard = GameSettings.maze_hard_mode
	_world.hard_mode = _hard
	_strikes_meter.visible = _hard
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_world.goal_reached.connect(_on_goal_reached)
	_world.avatar.bumped.connect(_on_bumped)
	resized.connect(_on_resized)
	_cheer.modulate.a = 0.0
	_pick_device()
	_on_resized()


func _process(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)


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


func _on_resized() -> void:
	if _laid_out or size.x <= 0.0 or size.y <= 0.0:
		return
	_laid_out = true
	_lay_out_maze()


func _lay_out_maze() -> void:
	var area := size - PLAY_INSET
	_world.build(area)
	_world.position = PLAY_ORIGIN + (area - _world.bounds) * 0.5
	_strikes = 0
	_strikes_meter.used = 0
	_grace = STRIKE_GRACE


func _pick_device() -> void:
	Haptics.forget_devices()
	var pads := Input.get_connected_joypads()
	_device = pads[0] if not pads.is_empty() else -1
	_world.avatar.device = _device
	_mini_stick.device = _device


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	_pick_device()


func _on_bumped(normal: Vector2, at: Vector2) -> void:
	if _celebrating or _resetting:
		return
	if not _hard:
		_bump_player.play()
		if _device >= 0:
			Haptics.rumble(_device, 0.12, 0.0, 0.09)
		return
	if _grace > 0.0:
		return

	_grace = STRIKE_GRACE
	_strikes += 1
	_strikes_meter.used = _strikes
	_world.flash_wall(at)
	_world.avatar.hurt(STRIKE_FLASH)
	_world.avatar.knock_back(normal)
	_strike_player.play()
	if _device >= 0:
		Haptics.rumble(_device, 0.7, 0.9, 0.3)
	if _strikes >= STRIKE_LIMIT:
		_restart_maze()


func _restart_maze() -> void:
	_resetting = true
	_world.avatar.frozen = true
	_show_cheer("Try again!", 60, Color(1.0, 0.42, 0.46), 1.1)
	await get_tree().create_timer(RESET_TIME).timeout
	if not is_inside_tree():
		return
	_strikes = 0
	_strikes_meter.used = 0
	_grace = STRIKE_GRACE
	_world.reset_avatar()
	_world.avatar.frozen = false
	_resetting = false


func _on_goal_reached() -> void:
	if _celebrating or _resetting:
		return
	_celebrating = true
	_world.avatar.frozen = true
	_stars += 1
	_score.filled = _stars

	var wait := CELEBRATE_TIME
	if _stars >= GOAL:
		wait = ROUND_CELEBRATE_TIME
		_world.burst(_world.avatar.position, 180)
		_fanfare_player.play()
		_show_cheer(BIG_CHEERS.pick_random(), 84, Color(1.0, 0.8, 0.28), 2.2)
		if _device >= 0:
			Haptics.rumble(_device, 0.55, 0.75, 0.5)
	else:
		_world.burst(_world.avatar.position, 80)
		_coin_player.play()
		_show_cheer(SMALL_CHEERS.pick_random(), 44, Color(0.45, 0.95, 0.6), 1.1)
		if _device >= 0:
			Haptics.rumble(_device, 0.35, 0.45, 0.18)

	await get_tree().create_timer(wait).timeout
	if not is_inside_tree():
		return
	if _stars >= GOAL:
		_stars = 0
		_score.filled = 0
	_lay_out_maze()
	_world.avatar.frozen = false
	_celebrating = false


func _build_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _show_cheer(text: String, font_size: int, color: Color, hold: float) -> void:
	_cheer_tween = CheerPopup.show(_cheer, _cheer_tween, text, font_size, color, hold)


func _on_back_pressed() -> void:
	if _device >= 0:
		Haptics.stop(_device)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

class_name TitleScreen
extends Node2D
## Main menu: the cave floor scrolls by while the warrior and the mage
## walk side by side. Play starts a run, Settings opens the shared panel,
## Quit closes the game (hidden on web, where tabs close themselves).

const RUN_SCENE := "res://scenes/main.tscn"
const ARENA_GRID := preload("res://scripts/arena_grid.gd")
const WARRIOR_FRAMES := preload("res://assets/sprite_frames/warrior.tres")
const MAGE_FRAMES := preload("res://assets/sprite_frames/mage.tres")
const DARKNESS := Color(0.58, 0.56, 0.68)
const SCROLL_SPEED := 24.0
const HERO_SCALE := Vector2(3.0, 3.0)
const HERO_GAP := 32.0
const HERO_AREA_HEIGHT := 64.0
const HINT_MARGIN := 8.0
const SUBTITLE := "Shift between warrior and mage"
const CONTROLS_HINT := "WASD / Stick move   Space / A shift   Esc / Start pause   M mute"

var _camera: Camera2D
var _buttons: VBoxContainer
var _settings: SettingsPanel
var _achievements: AchievementsPanel
## Hidden while the achievements page is open, which needs the room.
var _heroes: Control
var _hint: Label
var _play_button: Button


func _ready() -> void:
	GameSettings.current()
	if Run.BOSS_FLAG in OS.get_cmdline_user_args():
		start_run.call_deferred()
		return
	_build_world()
	_build_ui()
	AudioManager.play_music(AudioManager.TITLE_MUSIC)
	UiKit.grab_focus_quietly(_play_button)


func _process(delta: float) -> void:
	if _camera != null:
		_camera.position.x += SCROLL_SPEED * delta


func start_run() -> void:
	AudioManager.play(&"card_pick")
	ScreenFade.go_to(get_tree(), RUN_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if _settings != null and _settings.visible:
		get_viewport().set_input_as_handled()
		_settings.go_back()
	elif _achievements != null and _achievements.visible:
		get_viewport().set_input_as_handled()
		_show_buttons()


func _show_settings() -> void:
	_buttons.visible = false
	_settings.visible = true
	_settings.focus_first()


func _show_achievements() -> void:
	_buttons.visible = false
	_heroes.visible = false
	_hint.visible = false
	_achievements.visible = true
	_achievements.focus_first()


func _show_buttons() -> void:
	_settings.visible = false
	_achievements.visible = false
	_heroes.visible = true
	_hint.visible = true
	_buttons.visible = true
	UiKit.grab_focus_quietly(_play_button)


## Same signal the window's close button sends, so the AudioManager
## shuts the audio down before quitting.
func _quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _build_world() -> void:
	var darkness := CanvasModulate.new()
	darkness.color = DARKNESS
	add_child(darkness)
	var grid := Node2D.new()
	grid.set_script(ARENA_GRID)
	add_child(grid)
	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var column := UiKit.column()
	center.add_child(column)
	column.add_child(UiKit.label("Shiftborn", UiKit.TITLE_FONT_SIZE, UiKit.ACCENT_COLOR))
	column.add_child(UiKit.label(SUBTITLE, UiKit.SMALL_FONT_SIZE, UiKit.TEXT_COLOR))
	var best := Progress.current().best_score
	if best > 0:
		column.add_child(UiKit.label("Best score %d" % best, UiKit.SMALL_FONT_SIZE, UiKit.ACCENT_COLOR))
	_heroes = _hero_area()
	column.add_child(_heroes)
	_buttons = UiKit.column()
	_play_button = _add_button("Play", start_run)
	_add_button("Settings", _show_settings)
	_add_button("Achievements", _show_achievements)
	if not OS.has_feature("web"):
		_add_button("Quit", _quit)
	column.add_child(_buttons)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.back_pressed.connect(_show_buttons)
	column.add_child(_settings)
	_achievements = AchievementsPanel.new()
	_achievements.visible = false
	_achievements.back_pressed.connect(_show_buttons)
	column.add_child(_achievements)
	_hint = _corner_label(CONTROLS_HINT, Control.PRESET_CENTER_BOTTOM)
	layer.add_child(_hint)
	var version := "v%s" % ProjectSettings.get_setting("application/config/version", "")
	layer.add_child(_corner_label(version, Control.PRESET_BOTTOM_RIGHT))


## Warrior and mage walking in place; the scrolling floor makes them move.
func _hero_area() -> Control:
	var area := Control.new()
	area.custom_minimum_size = Vector2(0, HERO_AREA_HEIGHT)
	var warrior := _hero(WARRIOR_FRAMES)
	var mage := _hero(MAGE_FRAMES)
	area.add_child(warrior)
	area.add_child(mage)
	area.resized.connect(func() -> void:
		var middle := area.size * 0.5
		warrior.position = middle + Vector2(-HERO_GAP, 0)
		mage.position = middle + Vector2(HERO_GAP, 0))
	return area


func _hero(frames: SpriteFrames) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = HERO_SCALE
	sprite.play(&"walk_right")
	return sprite


func _add_button(text: String, on_press: Callable) -> Button:
	var button := UiKit.button(text)
	button.pressed.connect(on_press)
	_buttons.add_child(button)
	return button


func _corner_label(text: String, preset: Control.LayoutPreset) -> Label:
	var label := UiKit.label(text, UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR)
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, int(HINT_MARGIN))
	return label

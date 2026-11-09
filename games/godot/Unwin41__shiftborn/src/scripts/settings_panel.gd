class_name SettingsPanel
extends VBoxContainer
## Music and sound sliders, a fullscreen toggle and a back button. Edits
## [method GameSettings.current] live and saves when the player goes back.
## Used by the title screen and the pause menu.

signal back_pressed

const SLIDER_SIZE := Vector2(112, 16)
const NAME_WIDTH := 56.0
const VALUE_WIDTH := 32.0
const SLIDER_STEP := 0.05

var _settings: GameSettings
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_button: Button
var _tutorial_button: Button
var _back_button: Button


func _init() -> void:
	_settings = GameSettings.current()
	add_theme_constant_override(&"separation", UiKit.SEPARATION)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(UiKit.label("Settings", UiKit.HEADER_FONT_SIZE, UiKit.ACCENT_COLOR))
	_music_slider = _add_slider_row("Music", _settings.music_volume, _settings.set_music_volume)
	_sfx_slider = _add_slider_row("Sound", _settings.sfx_volume, _settings.set_sfx_volume)
	_sfx_slider.drag_ended.connect(func(_changed: bool) -> void: AudioManager.play(&"card_pick"))
	_fullscreen_button = UiKit.button(_fullscreen_text())
	_fullscreen_button.pressed.connect(_toggle_fullscreen)
	add_child(_center(_fullscreen_button))
	_tutorial_button = UiKit.button(_tutorial_text())
	_tutorial_button.pressed.connect(_toggle_tutorial)
	add_child(_center(_tutorial_button))
	_back_button = UiKit.button("Back")
	_back_button.pressed.connect(go_back)
	add_child(_center(_back_button))


func focus_first() -> void:
	if _music_slider.is_inside_tree():
		UiKit.grab_focus_quietly(_music_slider)


## Saves and tells the owner to close the panel.
func go_back() -> void:
	_settings.save()
	back_pressed.emit()


func _toggle_fullscreen() -> void:
	_settings.set_fullscreen(not _settings.fullscreen)
	_fullscreen_button.text = _fullscreen_text()


## On means the next run starts with the guided tutorial.
func _toggle_tutorial() -> void:
	_settings.tutorial_done = not _settings.tutorial_done
	_tutorial_button.text = _tutorial_text()


func _tutorial_text() -> String:
	return ("Tutorial: %s" % ("Off" if _settings.tutorial_done else "On")).to_upper()


func _fullscreen_text() -> String:
	return ("Fullscreen: %s" % ("On" if _settings.fullscreen else "Off")).to_upper()


func _add_slider_row(title: String, value: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiKit.SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label := UiKit.label(title)
	name_label.custom_minimum_size.x = NAME_WIDTH
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = SLIDER_STEP
	slider.value = value
	slider.custom_minimum_size = SLIDER_SIZE
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	_style_slider(slider)
	row.add_child(slider)
	var value_label := UiKit.label(GameSettings.percent_text(value))
	value_label.custom_minimum_size.x = VALUE_WIDTH
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(new_value: float) -> void:
		on_change.call(new_value)
		value_label.text = GameSettings.percent_text(new_value))
	slider.mouse_entered.connect(slider.grab_focus)
	add_child(row)
	return slider


func _style_slider(slider: HSlider) -> void:
	var track := UiKit.box_style(UiKit.PANEL_COLOR, UiKit.BORDER_COLOR)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override(&"slider", track)
	var fill := UiKit.box_style(UiKit.MUTED_COLOR, UiKit.MUTED_COLOR)
	slider.add_theme_stylebox_override(&"grabber_area", fill)
	var fill_focus := UiKit.box_style(UiKit.ACCENT_COLOR, UiKit.ACCENT_COLOR)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", fill_focus)
	slider.add_theme_stylebox_override(&"focus", UiKit.focus_style())


func _center(control: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.add_child(control)
	return center

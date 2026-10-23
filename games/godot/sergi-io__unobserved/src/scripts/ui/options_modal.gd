class_name OptionsModal
extends ColorRect

signal close_requested
signal main_menu_requested
signal exit_game_requested

const MUSIC_LABEL_TEXT: String = "Music Volume"
const SFX_LABEL_TEXT: String = "SFX Volume"
const PANEL_MINIMUM_SIZE: Vector2 = Vector2(640.0, 360.0)

var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_value_label: Label
var _sfx_value_label: Label
var _close_button: Button
var _main_menu_button: Button
var _exit_game_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	color = Color(0.0, 0.0, 0.0, 0.68)
	hide()
	_build_content()
	_sync_from_audio_settings()


func open() -> void:
	_sync_from_audio_settings()
	show()
	if _close_button != null:
		_close_button.grab_focus()


func close() -> void:
	hide()


func set_main_menu_button_visible(is_visible: bool) -> void:
	if _main_menu_button == null:
		return

	_main_menu_button.visible = is_visible
	if _exit_game_button != null:
		_exit_game_button.visible = is_visible and not OS.has_feature("web")


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_request_close()


func _build_content() -> void:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "OptionsPanel"
	panel.custom_minimum_size = PANEL_MINIMUM_SIZE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 28)
	margin.add_child(content)

	var title := Label.new()
	title.name = "Title"
	title.text = "Options"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.9, 0.976471, 1.0, 1.0))
	content.add_child(title)

	var sliders := VBoxContainer.new()
	sliders.name = "VolumeSliders"
	sliders.add_theme_constant_override("separation", 22)
	sliders.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sliders)

	_music_slider = _create_volume_row(sliders, MUSIC_LABEL_TEXT)
	_music_value_label = sliders.get_child(sliders.get_child_count() - 1).get_node("Value") as Label
	_sfx_slider = _create_volume_row(sliders, SFX_LABEL_TEXT)
	_sfx_value_label = sliders.get_child(sliders.get_child_count() - 1).get_node("Value") as Label

	var button_row := HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_row.add_theme_constant_override("separation", 14)
	content.add_child(button_row)

	_close_button = _create_footer_button("Close")
	_close_button.name = "CloseButton"
	_close_button.custom_minimum_size = Vector2(130.0, 46.0)
	_close_button.pressed.connect(_request_close)
	button_row.add_child(_close_button)

	_main_menu_button = _create_footer_button("Return to main menu")
	_main_menu_button.name = "MainMenuButton"
	_main_menu_button.custom_minimum_size = Vector2(220.0, 46.0)
	_main_menu_button.visible = false
	_main_menu_button.pressed.connect(_request_main_menu)
	button_row.add_child(_main_menu_button)

	_exit_game_button = _create_footer_button("Exit Game")
	_exit_game_button.name = "ExitGameButton"
	_exit_game_button.custom_minimum_size = Vector2(160.0, 46.0)
	_exit_game_button.visible = false
	_exit_game_button.pressed.connect(_request_exit_game)
	button_row.add_child(_exit_game_button)

	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)


func _create_volume_row(parent: VBoxContainer, label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	row.custom_minimum_size = Vector2(0.0, 54.0)
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := Label.new()
	label.name = "Label"
	label.custom_minimum_size = Vector2(174.0, 0.0)
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(280.0, 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.custom_minimum_size = Vector2(70.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	row.add_child(value_label)

	return slider


func _create_footer_button(button_text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(160.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.text = button_text
	button.add_theme_font_size_override("font_size", 20)
	return button


func _sync_from_audio_settings() -> void:
	var music_volume := _get_audio_volume("get_music_volume", 0.75)
	var sfx_volume := _get_audio_volume("get_sfx_volume", 1.0)
	if _music_slider != null:
		_music_slider.set_value_no_signal(music_volume)
	if _sfx_slider != null:
		_sfx_slider.set_value_no_signal(sfx_volume)
	_update_volume_labels()


func _on_music_volume_changed(value: float) -> void:
	_set_audio_volume("set_music_volume", value)
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	_set_audio_volume("set_sfx_volume", value)
	_update_volume_labels()


func _update_volume_labels() -> void:
	if _music_value_label != null and _music_slider != null:
		_music_value_label.text = "%d%%" % roundi(_music_slider.value * 100.0)
	if _sfx_value_label != null and _sfx_slider != null:
		_sfx_value_label.text = "%d%%" % roundi(_sfx_slider.value * 100.0)


func _get_audio_volume(method_name: StringName, fallback: float) -> float:
	var audio_settings := get_node_or_null("/root/AudioSettings")
	if audio_settings != null and audio_settings.has_method(method_name):
		return float(audio_settings.call(method_name))

	return fallback


func _set_audio_volume(method_name: StringName, value: float) -> void:
	var audio_settings := get_node_or_null("/root/AudioSettings")
	if audio_settings != null and audio_settings.has_method(method_name):
		audio_settings.call(method_name, value)


func _request_close() -> void:
	close()
	close_requested.emit()


func _request_main_menu() -> void:
	main_menu_requested.emit()


func _request_exit_game() -> void:
	exit_game_requested.emit()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.027451, 0.0431373, 0.0745098, 0.96)
	style.border_color = Color(0.262745, 0.67451, 1.0, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

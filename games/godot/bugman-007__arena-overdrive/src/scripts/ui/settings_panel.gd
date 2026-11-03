class_name SettingsPanel
extends Control
## Settings screen used from both the main menu and the pause menu.

signal closed

const ACTION_KEYS := {
	&"move_up": "ACTION_MOVE_UP", &"move_down": "ACTION_MOVE_DOWN", &"move_left": "ACTION_MOVE_LEFT",
	&"move_right": "ACTION_MOVE_RIGHT", &"dash": "ACTION_DASH", &"ability": "ACTION_ABILITY", &"pause": "ACTION_PAUSE",
}

var _listening: StringName = &""
var _bind_buttons: Dictionary = {}
var _first: Control


func _ready() -> void:
	UiKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var center := CenterContainer.new()
	UiKit.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1000, 0)
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	panel.add_child(root)
	root.add_child(UiKit.label("SETTINGS", "HeaderLabel"))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 40)
	root.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	cols.add_child(right)

	left.add_child(UiKit.label("SECTION_AUDIO", "AccentLabel"))
	_first = _slider(left, "MASTER_VOLUME", "master_volume")
	_slider(left, "MUSIC_VOLUME", "music_volume")
	_slider(left, "SFX_VOLUME", "sfx_volume")
	_slider(left, "UI_VOLUME", "ui_volume")
	left.add_child(UiKit.label("SECTION_VIDEO", "AccentLabel"))
	_toggle(left, "FULLSCREEN", "fullscreen")
	_toggle(left, "VSYNC", "vsync")
	left.add_child(UiKit.label("SECTION_GAMEPLAY", "AccentLabel"))
	_toggle(left, "SCREEN_SHAKE", "screen_shake")
	var lang_row := _row(left, "LANGUAGE")
	var lang := OptionButton.new()
	lang.custom_minimum_size = Vector2(200, 44)
	lang.add_item("English")
	lang.add_item("Español")
	lang.selected = maxi(0, Settings.LOCALES.find(String(Settings.get_value("locale"))))
	lang.item_selected.connect(func(i: int) -> void: Settings.set_value("locale", Settings.LOCALES[i]))
	UiKit.wire_feedback(lang, 1.02)
	lang_row.add_child(lang)

	right.add_child(UiKit.label("SECTION_CONTROLS", "AccentLabel"))
	for action: StringName in Settings.REBINDABLE:
		var row := _row(right, ACTION_KEYS[action])
		var b := UiKit.button("", Vector2(150, 40))
		b.pressed.connect(_start_listen.bind(action))
		row.add_child(b)
		_bind_buttons[action] = b
	right.add_child(UiKit.label("CONTROLS_HINT", "MutedLabel"))
	var reset := UiKit.button("RESET_BINDINGS", Vector2(220, 44))
	reset.pressed.connect(func() -> void:
		Settings.reset_bindings()
		_refresh_bindings())
	right.add_child(reset)

	var back := UiKit.button("BACK", Vector2(220, 52))
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(_close)
	root.add_child(back)
	_refresh_bindings()


func open() -> void:
	show()
	UiKit.animate_in(self, 0.0, 0.96)
	_first.grab_focus.call_deferred()


func _close() -> void:
	_listening = &""
	hide()
	closed.emit()


func _row(parent: Control, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := UiKit.label(key)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	parent.add_child(row)
	return row


func _slider(parent: Control, key: String, setting: String) -> HSlider:
	var row := _row(parent, key)
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(220, 28)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Settings.get_value(setting))
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pct := UiKit.label("%d%%" % int(s.value * 100), "MutedLabel")
	pct.custom_minimum_size = Vector2(52, 0)
	s.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(v * 100)
		Settings.set_value(setting, v)
		AudioManager.play(&"pickup", 0.0))
	s.focus_entered.connect(func() -> void: AudioManager.play_ui(&"ui_hover"))
	row.add_child(s)
	row.add_child(pct)
	return s


func _toggle(parent: Control, key: String, setting: String) -> CheckButton:
	var row := _row(parent, key)
	var c := CheckButton.new()
	c.button_pressed = bool(Settings.get_value(setting))
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(setting, on))
	UiKit.wire_feedback(c, 1.02)
	row.add_child(c)
	return c


func _refresh_bindings() -> void:
	for action: StringName in _bind_buttons:
		(_bind_buttons[action] as Button).text = Settings.key_label(action)


func _start_listen(action: StringName) -> void:
	_listening = action
	(_bind_buttons[action] as Button).text = tr("PRESS_KEY")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if _listening != &"" and event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.physical_keycode != KEY_ESCAPE or _listening == &"pause":
			Settings.rebind(_listening, key.physical_keycode)
		_listening = &""
		_refresh_bindings()
		get_viewport().set_input_as_handled()
	elif _listening == &"" and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

extends McpTestSuite

const SETTINGS_PATH: String = "user://test_window_shortcuts.cfg"


func suite_name() -> String:
	return "window_shortcuts"


func teardown() -> void:
	for action: StringName in WindowShortcuts.ACTIONS:
		var name: StringName = StringName(WindowShortcuts.PREFIX + String(action))
		if InputMap.has_action(name):
			InputMap.erase_action(name)
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _key(code: int) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = (code & KEY_CODE_MASK) as Key
	event.shift_pressed = (code & KEY_MASK_SHIFT) != 0
	event.ctrl_pressed = (code & KEY_MASK_CTRL) != 0
	event.alt_pressed = (code & KEY_MASK_ALT) != 0
	event.meta_pressed = (code & KEY_MASK_META) != 0
	event.pressed = true
	return event


func test_default_window_actions_and_all_size_aliases() -> void:
	var shortcuts: WindowShortcuts = WindowShortcuts.new()
	shortcuts.install()
	for index: int in WindowShortcuts.ACTIONS.size():
		for code: int in WindowShortcuts.DEFAULTS[index]:
			assert_eq(shortcuts.action_for(_key(code)), WindowShortcuts.ACTIONS[index])
	assert_eq(shortcuts.action_for(_key(KEY_BRACKETLEFT)), &"", "Speed stays developer-only")
	assert_eq(shortcuts.action_for(_key(KEY_B)), &"", "No bot shortcut")


func test_disabled_shortcuts_releases_echoes_and_unbound_chords_do_nothing() -> void:
	var shortcuts: WindowShortcuts = WindowShortcuts.new()
	shortcuts.install()
	var key: InputEventKey = _key(KEY_1)
	key.pressed = false
	assert_eq(shortcuts.action_for(key), &"")
	key.pressed = true
	key.echo = true
	assert_eq(shortcuts.action_for(key), &"")
	assert_eq(shortcuts.action_for(_key(KEY_MASK_CTRL | KEY_1)), &"")
	shortcuts.enabled = false
	for index: int in WindowShortcuts.ACTIONS.size():
		for code: int in WindowShortcuts.DEFAULTS[index]:
			assert_eq(shortcuts.action_for(_key(code)), &"")


func test_rebinding_replaces_aliases_and_reset_restores_them() -> void:
	var shortcuts: WindowShortcuts = WindowShortcuts.new()
	assert_eq(shortcuts.rebind(&"scale:up", KEY_MASK_CTRL | KEY_U), "")
	shortcuts.install()
	assert_eq(shortcuts.action_for(_key(KEY_EQUAL)), &"")
	assert_eq(shortcuts.action_for(_key(KEY_KP_ADD)), &"")
	assert_eq(shortcuts.action_for(_key(KEY_U)), &"")
	assert_eq(shortcuts.action_for(_key(KEY_MASK_CTRL | KEY_U)), &"scale:up")
	assert_eq(shortcuts.label_for(&"scale:up"), OS.get_keycode_string(KEY_MASK_CTRL | KEY_U))
	shortcuts.reset()
	shortcuts.install()
	assert_eq(shortcuts.action_for(_key(KEY_EQUAL)), &"scale:up")
	assert_eq(shortcuts.action_for(_key(KEY_MASK_CTRL | KEY_U)), &"")


func test_conflicts_and_reserved_keys_leave_bindings_unchanged() -> void:
	var shortcuts: WindowShortcuts = WindowShortcuts.new()
	for code: int in [
		KEY_2, KEY_ESCAPE, KEY_Q, KEY_A, KEY_TAB, KEY_ENTER, KEY_BRACKETLEFT, KEY_SHIFT, KEY_NONE,
	]:
		assert_false(shortcuts.rebind(&"mode:strip", code).is_empty())
	assert_eq(shortcuts.bindings[&"mode:strip"], PackedInt64Array([KEY_1]))
	assert_eq(shortcuts.rebind(&"mode:strip", KEY_1), "", "Keeping the same key is allowed")


func test_bindings_and_enabled_setting_round_trip_with_window_preferences() -> void:
	var settings: UserSettings = UserSettings.new()
	settings.shortcuts.enabled = false
	assert_eq(settings.shortcuts.rebind(&"mode:strip", KEY_MASK_CTRL | KEY_U), "")
	settings = settings.changed_by(&"mode:corner").changed_by(&"scale:up")
	assert_true(settings.save_to(SETTINGS_PATH))
	var loaded: UserSettings = UserSettings.load_from(SETTINGS_PATH)
	assert_false(loaded.shortcuts.enabled)
	assert_eq(loaded.shortcuts.bindings, settings.shortcuts.bindings)
	assert_eq(loaded.mode, &"corner")
	assert_eq(loaded.pixel_scale, 3)
	var enabled: UserSettings = loaded.changed_by(&"shortcuts:on")
	assert_true(enabled.shortcuts.enabled)
	assert_false(loaded.shortcuts.enabled, "Changing a setting does not mutate the source")
	assert_eq(enabled.shortcuts.bindings, loaded.shortcuts.bindings)


func test_old_settings_files_receive_default_shortcuts() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("window", "mode", "corner")
	assert_eq(file.save(SETTINGS_PATH), OK)
	var settings: UserSettings = UserSettings.load_from(SETTINGS_PATH)
	assert_true(settings.shortcuts.enabled)
	assert_eq(settings.shortcuts.bindings[&"mode:strip"], PackedInt64Array([KEY_1]))


func test_bad_or_conflicting_saved_bindings_fall_back_as_a_whole() -> void:
	for bad: Variant in ["not keys", PackedInt64Array(), PackedInt64Array([KEY_2])]:
		var file: ConfigFile = ConfigFile.new()
		file.set_value("shortcuts", "mode:strip", bad)
		assert_eq(file.save(SETTINGS_PATH), OK)
		var settings: UserSettings = UserSettings.load_from(SETTINGS_PATH)
		assert_eq(settings.shortcuts.bindings, WindowShortcuts.new().bindings)


func test_shortcuts_panel_reports_edit_toggle_reset_and_back_actions() -> void:
	var shortcuts: WindowShortcuts = WindowShortcuts.new()
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_shortcuts(shortcuts, "Press a key; Esc cancels.")
	assert_eq(panel.mode(), &"shortcuts")
	for node: Node in panel.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.visible and button.text != "x":
			button.pressed.emit()
	for action: StringName in [
		&"shortcuts:on", &"shortcuts:off", &"shortcuts:reset", &"settings",
		&"rebind:mode:strip", &"rebind:mode:corner", &"rebind:mode:window",
		&"rebind:scale:down", &"rebind:scale:up",
	]:
		assert_true(picked.has(action), "%s is reachable" % action)
	panel.free()

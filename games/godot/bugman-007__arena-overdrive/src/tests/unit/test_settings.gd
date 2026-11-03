extends GutTest

const PATH := "user://test_settings.cfg"
var SettingsScript := preload("res://autoload/settings.gd")
var s: Node


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	s = autofree(SettingsScript.new())
	s.path = PATH
	s.load_settings()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Settings.apply()


func test_defaults() -> void:
	assert_eq(s.get_value("screen_shake"), true)
	assert_eq(s.get_value("locale"), "en")
	assert_eq(int(s.bindings[&"dash"]), KEY_SPACE)


func test_persists_values() -> void:
	s.set_value("music_volume", 0.25)
	s.set_value("screen_shake", false)
	var other: Node = autofree(SettingsScript.new())
	other.path = PATH
	other.load_settings()
	assert_almost_eq(float(other.get_value("music_volume")), 0.25, 0.001)
	assert_eq(other.get_value("screen_shake"), false)


func test_rebind_updates_input_map() -> void:
	s.rebind(&"dash", KEY_F)
	var found := false
	for ev in InputMap.action_get_events(&"dash"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_F:
			found = true
	assert_true(found)


func test_rebind_conflict_swaps() -> void:
	s.rebind(&"dash", KEY_E)
	assert_eq(int(s.bindings[&"dash"]), KEY_E)
	assert_eq(int(s.bindings[&"ability"]), KEY_SPACE)


func test_rebind_persists() -> void:
	s.rebind(&"move_up", KEY_I)
	var other: Node = autofree(SettingsScript.new())
	other.path = PATH
	other.load_settings()
	assert_eq(int(other.bindings[&"move_up"]), KEY_I)


func test_reset_bindings() -> void:
	s.rebind(&"move_up", KEY_I)
	s.reset_bindings()
	assert_eq(int(s.bindings[&"move_up"]), KEY_W)


func test_gamepad_events_registered() -> void:
	s.apply_input()
	var has_pad := false
	for ev in InputMap.action_get_events(&"dash"):
		if ev is InputEventJoypadButton:
			has_pad = true
	assert_true(has_pad)


func test_volume_applies_to_bus() -> void:
	s.set_value("sfx_volume", 0.5)
	var idx := AudioServer.get_bus_index("SFX")
	assert_almost_eq(AudioServer.get_bus_volume_db(idx), linear_to_db(0.5), 0.01)


func test_locale_applies() -> void:
	s.set_value("locale", "es")
	assert_eq(TranslationServer.get_locale(), "es")

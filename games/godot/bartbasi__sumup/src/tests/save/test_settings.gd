extends "res://tests/base_test.gd"
## Settings (docs/ARCHITECTURE.md section 10, GDD 15.1 and 18).

var _sound_events: Array[bool] = []
var _skin_events: Array[StringName] = []


func before_each() -> void:
	_sound_events = []
	_skin_events = []


func _on_sound(on: bool) -> void:
	_sound_events.append(on)


func _on_skin(skin_id: StringName) -> void:
	_skin_events.append(skin_id)


func _watched() -> Settings:
	var settings: Settings = Settings.new()
	settings.sound_changed.connect(_on_sound)
	settings.skin_changed.connect(_on_skin)
	return settings


func test_at_94_defaults_sound_on_and_gumdrop() -> void:
	var settings: Settings = Settings.new()
	assert_true(settings.sound_on, "SOUND_DEFAULT is on")
	assert_eq(settings.skin_id, &"gumdrop", "default skin")


func test_set_sound_on_emits_only_on_change() -> void:
	var settings: Settings = _watched()
	settings.set_sound_on(true)
	assert_eq(_sound_events.size(), 0, "same value emits nothing")
	settings.set_sound_on(false)
	settings.set_sound_on(false)
	settings.set_sound_on(true)
	assert_eq(_sound_events, [false, true] as Array[bool], "one signal per real change")
	assert_true(settings.sound_on, "value follows")
	assert_eq(_skin_events.size(), 0, "sound never emits skin_changed")


func test_set_skin_id_emits_only_on_change() -> void:
	var settings: Settings = _watched()
	settings.set_skin_id(&"gumdrop")
	assert_eq(_skin_events.size(), 0, "same value emits nothing")
	settings.set_skin_id(&"slate")
	settings.set_skin_id(&"slate")
	settings.set_skin_id(&"nova")
	assert_eq(_skin_events, [&"slate", &"nova"] as Array[StringName], "one signal per real change")
	assert_eq(settings.skin_id, &"nova", "value follows")
	assert_eq(_sound_events.size(), 0, "skin never emits sound_changed")

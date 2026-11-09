extends TestCase
## GameSettings is used here without the autoload: values, clamping and
## the config file round trip. Files go to user:// under a test name.

const TEST_PATH := "user://test_settings.cfg"


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_defaults_are_audible_and_windowed() -> void:
	var settings := GameSettings.new()
	assert_almost_eq(settings.music_volume, GameSettings.DEFAULT_VOLUME)
	assert_almost_eq(settings.sfx_volume, GameSettings.DEFAULT_VOLUME)
	assert_false(settings.fullscreen, "fullscreen should be off by default")


func test_volume_setters_clamp_to_zero_one() -> void:
	var settings := GameSettings.new()
	settings.set_music_volume(1.7)
	settings.set_sfx_volume(-0.3)
	assert_almost_eq(settings.music_volume, 1.0)
	assert_almost_eq(settings.sfx_volume, 0.0)


func test_volume_db_is_zero_at_full_and_silent_at_zero() -> void:
	assert_almost_eq(GameSettings.volume_db(1.0), 0.0)
	assert_almost_eq(GameSettings.volume_db(0.0), GameSettings.SILENT_DB)
	assert_true(GameSettings.volume_db(0.5) < 0.0, "half volume should be below 0 dB")


func test_percent_text_rounds_to_whole_percent() -> void:
	assert_eq(GameSettings.percent_text(0.804), "80%")
	assert_eq(GameSettings.percent_text(0.0), "0%")


func test_save_then_load_round_trips() -> void:
	_cleanup()
	var saved := GameSettings.new()
	saved.set_music_volume(0.25)
	saved.set_sfx_volume(0.6)
	saved.fullscreen = true
	assert_eq(saved.save_to(TEST_PATH), OK)
	var loaded := GameSettings.new()
	loaded.load_from(TEST_PATH)
	assert_almost_eq(loaded.music_volume, 0.25)
	assert_almost_eq(loaded.sfx_volume, 0.6)
	assert_true(loaded.fullscreen, "fullscreen should load back")
	_cleanup()


func test_load_from_missing_file_keeps_defaults() -> void:
	_cleanup()
	var settings := GameSettings.new()
	settings.load_from(TEST_PATH)
	assert_almost_eq(settings.music_volume, GameSettings.DEFAULT_VOLUME)


func test_current_without_autoload_returns_defaults() -> void:
	var settings := GameSettings.current()
	assert_true(settings != null, "current() should never be null")

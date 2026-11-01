extends GutTest
## Settings: defaults, validation, step timing, and taking newer synced settings.

const PATH := "user://test_settings.json"

var _store: ProgressStore


func before_each() -> void:
	_remove_all()
	_store = ProgressStore.new(PATH)
	_store.load_data()


func after_each() -> void:
	_remove_all()


func _remove_all() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_defaults_are_on_normal_and_system() -> void:
	var s := _store.settings
	assert_true(s.sound())
	assert_true(s.music())
	assert_true(s.vibration())
	assert_false(s.reduce_motion())
	assert_eq(s.run_speed(), "normal")
	assert_eq(s.theme(), "system")
	assert_false(s.tutorial_done())


func test_choices_are_validated() -> void:
	_store.settings.set_run_speed("warp")
	assert_eq(_store.settings.run_speed(), "normal")
	_store.settings.set_run_speed("fast")
	assert_eq(_store.settings.run_speed(), "fast")


func test_no_run_speed_exceeds_the_animation_limit() -> void:
	for speed in Settings.RUN_SPEEDS:
		_store.settings.set_run_speed(speed)
		assert_true(_store.settings.step_seconds() <= 0.25, speed)
	_store.settings.set_run_speed("slow")
	var slow := _store.settings.step_seconds()
	_store.settings.set_run_speed("fast")
	assert_true(_store.settings.step_seconds() < slow)


func test_settings_survive_a_restart() -> void:
	_store.settings.set_sound(false)
	_store.settings.set_music(false)
	_store.settings.set_vibration(false)
	_store.settings.set_run_speed("slow")
	_store.settings.set_tutorial_done(true)
	assert_true(_store.save())
	var again := ProgressStore.new(PATH)
	again.load_data()
	assert_false(again.settings.sound())
	assert_false(again.settings.music())
	assert_false(again.settings.vibration())
	assert_eq(again.settings.run_speed(), "slow")
	assert_true(again.settings.tutorial_done())


func test_changing_a_synced_setting_stamps_the_time() -> void:
	assert_eq(_store.settings.settings_updated_at(), 0.0)
	_store.settings.set_sound(false)
	assert_gt(_store.settings.settings_updated_at(), 0.0)


func test_the_coach_flag_is_not_synced() -> void:
	assert_false(_store.settings.synced_settings().has("tutorialDone"))
	_store.settings.set_tutorial_done(true)
	assert_eq(_store.settings.settings_updated_at(), 0.0)


func test_newer_remote_settings_win_and_older_ones_do_not() -> void:
	_store.settings.set_music(false)
	var mine := _store.settings.settings_updated_at()
	assert_false(_store.settings.apply_synced_settings({"music": true}, mine - 10.0))
	assert_false(_store.settings.music())
	assert_true(
		_store.settings.apply_synced_settings({"music": true, "runSpeed": "fast"}, mine + 10.0)
	)
	assert_true(_store.settings.music())
	assert_eq(_store.settings.run_speed(), "fast")
	assert_eq(_store.settings.settings_updated_at(), mine + 10.0)


func test_remote_settings_with_bad_values_are_ignored_one_by_one() -> void:
	var applied := _store.settings.apply_synced_settings(
		{"sound": "yes", "theme": "neon", "runSpeed": "fast", "vibration": false}, 100.0
	)
	assert_true(applied)
	assert_true(_store.settings.sound(), "a non-boolean is dropped")
	assert_eq(_store.settings.theme(), "system", "an unknown theme is dropped")
	assert_eq(_store.settings.run_speed(), "fast")
	assert_false(_store.settings.vibration())

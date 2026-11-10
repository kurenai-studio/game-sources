# Standalone checks for audio_settings.gd, runnable via:
#   godot4 --headless --path . --script tests/test_audio_settings.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_levels_stay_in_range()
	_test_turning_up_unmutes()
	_test_toggle_all()
	_test_silence()
	_test_volume_curve()
	_test_save_and_read()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _test_levels_stay_in_range() -> void:
	var settings := AudioSettings.new()
	settings.change_level("Master", 1)
	_check(settings.levels["Master"] == AudioSettings.STEPS, "Master can't go above full")
	for i in range(20):
		settings.change_level("Music", -1)
	_check(settings.levels["Music"] == 0, "Music can't go below silent")


func _test_turning_up_unmutes() -> void:
	var settings := AudioSettings.new()
	settings.toggle_mute("Effects")
	settings.change_level("Effects", -1)
	_check(settings.muted["Effects"], "turning a muted bus down keeps it muted")
	settings.change_level("Effects", 1)
	_check(not settings.muted["Effects"], "turning a muted bus up unmutes it")


func _test_toggle_all() -> void:
	var settings := AudioSettings.new()
	settings.toggle_mute("Music")
	settings.toggle_all()
	_check(settings.all_muted(), "Tout couper mutes every bus, even if one already was")
	settings.toggle_all()
	_check(not settings.muted["Master"] and not settings.muted["Music"] and not settings.muted["Effects"],
		"pressing it again unmutes every bus")


func _test_silence() -> void:
	var settings := AudioSettings.new()
	_check(not settings.is_all_silent(), "the defaults can be heard")
	settings.toggle_mute("Music")
	_check(not settings.is_all_silent(), "the effects alone can still be heard")
	for i in range(AudioSettings.STEPS):
		settings.change_level("Effects", -1)
	_check(settings.is_all_silent(), "music muted and effects at 0: silence")
	settings = AudioSettings.new()
	settings.toggle_mute("Master")
	_check(settings.is_all_silent(), "Master muted: silence")


func _test_volume_curve() -> void:
	var settings := AudioSettings.new()
	_check(is_equal_approx(settings.volume_db("Master"), 0.0), "full level is 0 dB")
	settings.levels["Music"] = 5
	_check(absf(settings.volume_db("Music") + 12.04) < 0.01, "half level is -12 dB")


func _test_save_and_read() -> void:
	var path := "user://test_audio_settings.cfg"
	var settings := AudioSettings.new()
	settings.change_level("Music", -3)
	settings.toggle_mute("Effects")
	settings.save(path)
	var again := AudioSettings.read(path)
	_check(again.levels["Music"] == 5 and again.muted["Effects"] and not again.muted["Music"],
		"settings come back as they were saved")
	DirAccess.remove_absolute(path)
	var fresh := AudioSettings.read(path)
	_check(fresh.levels["Music"] == 8 and not fresh.muted["Effects"], "no file: the defaults")

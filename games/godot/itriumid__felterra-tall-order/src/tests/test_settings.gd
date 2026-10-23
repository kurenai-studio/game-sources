extends TestCase
## Settings: they keep their defaults, step within their limits, and come back from the file
## they're saved in, even an older or hand-edited one.

const TEST_PATH := "user://test_settings.cfg"


func test_settings_come_back_as_they_were_saved() -> void:
	var settings := Settings.new()
	settings.set_value("audio", "music", 3)
	settings.set_value("gameplay", "aim", "crowd")
	settings.set_value("gameplay", "blood", false)
	check(settings.save(TEST_PATH), "couldn't save")
	var loaded := Settings.new()
	loaded.load_from(TEST_PATH)
	check(loaded.get_value("audio", "music") == 3, "music came back as %s" % loaded.get_value("audio", "music"))
	check(loaded.get_value("gameplay", "aim") == "crowd", "aim came back as %s" % loaded.get_value("gameplay", "aim"))
	check(loaded.get_value("gameplay", "blood") == false, "blood came back on")
	DirAccess.remove_absolute(TEST_PATH)


func test_a_missing_or_wrong_setting_keeps_its_default() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "music", "loud")
	file.save(TEST_PATH)
	var loaded := Settings.new()
	loaded.load_from(TEST_PATH)
	check(loaded.get_value("audio", "music") == Settings.DEFAULTS.audio.music, "a word for a volume was taken")
	check(loaded.get_value("graphics", "vsync") == Settings.DEFAULTS.graphics.vsync, "a missing setting lost its default")
	DirAccess.remove_absolute(TEST_PATH)


func test_steps_stay_within_their_limits() -> void:
	var settings := Settings.new()
	for step in 20:
		settings.step("audio", "effects", 1)
	check(settings.get_value("audio", "effects") == 10, "a volume went past 10")
	for step in 20:
		settings.step("audio", "effects", -1)
	check(settings.get_value("audio", "effects") == 0, "a volume went below 0")
	for step in 10:
		settings.step("graphics", "window_scale", 1)
	check(settings.get_value("graphics", "window_scale") == Settings.WINDOW_SCALES[-1], "the window grew past its largest")
	var aim: String = settings.get_value("gameplay", "aim")
	for step in Settings.AIM_MODES.size():
		settings.step("gameplay", "aim", 1)
	check(settings.get_value("gameplay", "aim") == aim, "aim didn't come round")
	settings.step("gameplay", "blood", 1)
	check(settings.get_value("gameplay", "blood") == false, "blood didn't switch off")


func test_a_volume_of_nothing_is_silence() -> void:
	check(Settings.volume_db(0) <= -79.0, "volume 0 is %.1f decibels" % Settings.volume_db(0))
	check(is_equal_approx(Settings.volume_db(10), 0.0), "volume 10 is %.1f decibels" % Settings.volume_db(10))
	check(Settings.volume_db(5) < 0.0 and Settings.volume_db(5) > -10.0, "volume 5 is %.1f decibels" % Settings.volume_db(5))


func test_the_audio_buses_exist() -> void:
	Settings.ensure_buses()
	for bus in Settings.BUSES:
		check(AudioServer.get_bus_index(bus) != -1, "no %s bus" % bus)


func test_the_game_shows_the_version_it_is() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	check(not version.is_empty(), "the project has no version")
	check(Overlay.version_text() == "Version " + version, "the game shows %s, not version %s" % [Overlay.version_text(), version])

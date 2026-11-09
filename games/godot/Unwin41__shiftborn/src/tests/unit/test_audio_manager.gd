extends TestCase


func test_every_sound_has_all_its_variant_files() -> void:
	for id: StringName in AudioManager.SOUNDS:
		var variants: int = AudioManager.SOUNDS[id].variants
		for i in variants:
			var path := AudioManager.sfx_path(id, i)
			assert_true(ResourceLoader.exists(path), "missing %s" % path)


func test_music_tracks_exist() -> void:
	for path: String in [AudioManager.RUN_MUSIC, AudioManager.TITLE_MUSIC, AudioManager.BOSS_MUSIC]:
		assert_true(ResourceLoader.exists(path), "missing %s" % path)


func test_rate_limit_blocks_rapid_repeats() -> void:
	assert_true(AudioManager.should_play(-1, 0, 50), "first play is always allowed")
	assert_false(AudioManager.should_play(1000, 1030, 50), "30 ms later is too soon")
	assert_true(AudioManager.should_play(1000, 1050, 50), "50 ms later is fine")


func test_bus_layout_has_music_and_sfx_buses() -> void:
	assert_true(AudioServer.get_bus_index(AudioManager.MUSIC_BUS) > 0, "Music bus missing")
	assert_true(AudioServer.get_bus_index(AudioManager.SFX_BUS) > 0, "SFX bus missing")


func test_play_without_the_autoload_is_a_no_op() -> void:
	# Must not crash when the autoload is absent, e.g. in isolated tests.
	AudioManager.play(&"axe_hit")
	AudioManager.play(&"does_not_exist")
	assert_true(true)


func test_variant_pick_never_repeats_the_last_one() -> void:
	for roll in 20:
		assert_true(AudioManager.pick_variant(3, 1, roll) != 1, "repeated variant 1 with roll %d" % roll)
		var pick := AudioManager.pick_variant(3, 1, roll)
		assert_true(pick >= 0 and pick < 3, "out of range")
	assert_eq(AudioManager.pick_variant(1, 0, 7), 0)
	assert_true(AudioManager.pick_variant(2, -1, 5) < 2)

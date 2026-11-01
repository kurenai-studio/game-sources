# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Settings and Progress: defaults per field, ceilings, saturation, and the unlock
## rules of RULES 16 (docs/ARCHITECTURE.md 3.5, 5.5).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")


## A four region campaign with the real rules: 6, 12 and 18 stars, runs at 12.
func _four_regions() -> GameData:
	var game: GameData = Fx.game()
	game.campaign.clear()
	for r: int in 4:
		var ids: Array[StringName] = []
		for l: int in 6:
			ids.append(StringName("r%d_l%d" % [r + 1, l + 1]))
		game.campaign.append({"id": StringName("region_%d" % r), "name": "Region", "levels": ids})
	return game


func _clear_region(progress: Progress, region: int, bits: int) -> void:
	for l: int in 6:
		progress.record_level(StringName("r%d_l%d" % [region + 1, l + 1]), bits)


func test_settings_defaults_and_round_trip() -> void:
	assert_true(Settings.new().sound_on)
	var settings: Settings = Settings.new()
	settings.sound_on = false
	assert_eq(settings.to_data(), {"format": 1, "sound": false, "music": true})
	assert_false(Settings.from_data(JSON.parse_string(JSON.stringify(settings.to_data()))).sound_on)
	for bad: Variant in [null, [], "x", 3.0, {"sound": "false"}, {"sound": 0.0}, {"sound": null}, {"sound": {}}]:
		assert_true(Settings.from_data(bad).sound_on, str(bad))


func test_music_setting_round_trip() -> void:
	assert_true(Settings.new().music_on)
	for pair: Array in [[true, false], [false, true], [false, false], [true, true]]:
		var settings: Settings = Settings.new()
		settings.sound_on = pair[0]
		settings.music_on = pair[1]
		assert_eq(settings.to_data(), {"format": 1, "sound": pair[0], "music": pair[1]})
		var back: Settings = Settings.from_data(JSON.parse_string(JSON.stringify(settings.to_data())))
		assert_eq([back.sound_on, back.music_on], pair, str(pair))


func test_settings_file_without_music_loads_with_music_on() -> void:
	# A settings.json written before the music setting existed.
	var old: Settings = Settings.from_data(JSON.parse_string('{"format": 1, "sound": false}'))
	assert_false(old.sound_on)
	assert_true(old.music_on)
	assert_true(Settings.from_data(JSON.parse_string('{"format": 1, "sound": true}')).music_on)


func test_hostile_music_values_fall_back_to_on() -> void:
	var hostile: Array = ["false", "", 0, 0.0, 1, -1, 1e308, null, [], [false], {}, {"music": false}, "true"]
	for value: Variant in hostile:
		var settings: Settings = Settings.from_data({"format": 1, "sound": false, "music": value})
		assert_true(settings.music_on, "music %s" % str(value))
		assert_false(settings.sound_on, "a bad music value leaves sound alone: %s" % str(value))
	# A bad sound value does not touch music either.
	var both: Settings = Settings.from_data({"format": 1, "sound": "off", "music": false})
	assert_true(both.sound_on)
	assert_false(both.music_on)


func test_progress_round_trip() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 1)
	progress.record_level(&"r1_l1", 4)
	progress.record_level(&"r1_l2", 3)
	progress.record_twist(&"r1_l1")
	progress.mark_seen(&"scamp")
	progress.mark_seen(&"scamp")
	progress.bump(&"runs_won", 2)
	progress.raise(&"best_run_wave", 9)
	progress.raise(&"best_run_wave", 4)
	assert_eq(progress.levels[&"r1_l1"], 5, "stars from different wins add up")
	assert_eq(progress.seen.size(), 1)
	assert_eq(progress.counters[&"best_run_wave"], 9)
	var back: Progress = Progress.from_data(JSON.parse_string(JSON.stringify(progress.to_data())))
	assert_eq(JSON.stringify(back.to_data()), JSON.stringify(progress.to_data()))
	assert_eq(back.stars(), 4)


func test_progress_bad_fields_fall_back_one_by_one() -> void:
	var data: Dictionary = {
		"format": 1,
		"levels": {"r1_l1": 7, "r1_l2": 8, "r1_l3": -1, "r1_l4": 2.5, "r1_l5": "7", "Bad Id": 3, "r1_l6": 1e999, "later_level": 2},
		"twists": ["r1_l1", "r1_l1", 5, "../x", "r1_l2"],
		"seen": "scamp",
		"counters": {"runs_won": 3, "risky_wins": 1000000001, "dailies_finished": -1, "best_run_wave": 1.5, "unknown": 4},
		"extra": [1, 2],
	}
	var progress: Progress = Progress.from_data(data)
	assert_eq(progress.levels.size(), 2)
	assert_eq(progress.levels[&"r1_l1"], 7)
	assert_eq(progress.levels[&"later_level"], 2, "unknown but well formed ids are kept")
	assert_eq(progress.twists, [&"r1_l1", &"r1_l2"] as Array[StringName])
	assert_eq(progress.seen.size(), 0)
	assert_eq(progress.counters[&"runs_won"], 3)
	assert_eq(progress.counters[&"risky_wins"], 0)
	assert_eq(progress.counters[&"dailies_finished"], 0)
	assert_eq(progress.counters[&"best_run_wave"], 0)
	assert_false(progress.counters.has(&"unknown"))
	assert_eq(progress.counters.size(), 5)


func test_progress_entry_ceilings() -> void:
	var levels: Dictionary = {}
	var ids: Array = []
	for i: int in Progress.MAX_ENTRIES + 1:
		levels["l%d" % i] = 1
		ids.append("l%d" % i)
	var progress: Progress = Progress.from_data({"format": 1, "levels": levels, "twists": ids, "seen": ids})
	assert_eq(progress.levels.size(), 0, "over 512 entries is refused")
	assert_eq(progress.twists.size(), 0)
	assert_eq(progress.seen.size(), 0)
	# The game never grows a list past what its own check accepts.
	var full: Progress = Progress.new()
	for i: int in Progress.MAX_ENTRIES + 10:
		var id: StringName = StringName("a%s" % str(i).lpad(31, "0"))
		full.record_level(id, 7)
		full.record_twist(id)
		full.mark_seen(id)
	assert_eq(full.levels.size(), Progress.MAX_ENTRIES)
	assert_eq(full.twists.size(), Progress.MAX_ENTRIES)
	var back: Progress = Progress.from_data(JSON.parse_string(JSON.stringify(full.to_data())))
	assert_eq(back.levels.size(), Progress.MAX_ENTRIES)
	assert_eq(back.seen.size(), Progress.MAX_ENTRIES)
	assert_true(JsonFile.to_text(full.to_data()).length() <= SaveStore.PROGRESS_CAP, "a full progress file fits its cap")


func test_bad_calls_change_nothing() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 8)
	progress.record_level(&"r1_l1", -1)
	progress.record_level(&"Not An Id", 1)
	progress.mark_seen(&"")
	progress.bump(&"stars", 5)
	progress.bump(&"runs_won", -5)
	progress.raise(&"nothing", 5)
	assert_eq(progress.levels.size(), 0)
	assert_eq(progress.seen.size(), 0)
	assert_eq(progress.counters[&"runs_won"], 0)
	assert_false(progress.counters.has(&"stars"))


func test_counters_saturate() -> void:
	var progress: Progress = Progress.new()
	progress.bump(&"runs_won", Progress.COUNTER_MAX - 1)
	progress.bump(&"runs_won", 5)
	assert_eq(progress.counters[&"runs_won"], Progress.COUNTER_MAX)
	progress.bump(&"runs_won", 9223372036854775807)
	assert_eq(progress.counters[&"runs_won"], Progress.COUNTER_MAX)
	progress.raise(&"best_run_wave", 9223372036854775807)
	assert_eq(progress.counters[&"best_run_wave"], Progress.COUNTER_MAX)
	var back: Progress = Progress.from_data(JSON.parse_string(JSON.stringify(progress.to_data())))
	assert_eq(back.counters[&"runs_won"], Progress.COUNTER_MAX, "a saturated counter loads back")


func test_stars_count_star_marks() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 7)
	progress.record_level(&"r1_l2", 1)
	progress.record_level(&"r1_l3", 5)
	progress.record_level(&"r1_l4", 0)
	assert_eq(progress.stars(), 6)
	assert_true(progress.cleared(&"r1_l2"))
	assert_false(progress.cleared(&"r1_l4"))
	assert_false(progress.cleared(&"r1_l5"))


func test_levels_open_in_order() -> void:
	var game: GameData = Fx.game()
	var progress: Progress = Progress.new()
	assert_true(progress.level_open(game, &"r1_l1"), "1-1 is open from the start")
	assert_false(progress.level_open(game, &"r1_l2"))
	progress.record_level(&"r1_l1", 1)
	assert_true(progress.level_open(game, &"r1_l2"))
	assert_false(progress.level_open(game, &"r1_l3"))
	progress.record_level(&"r1_l3", 7)
	assert_false(progress.level_open(game, &"r1_l3"), "stars on a later level open nothing earlier")
	assert_false(progress.level_open(game, &"zz_unknown"))
	assert_false(progress.level_open(null, &"r1_l1"))


func test_regions_need_the_boss_level_and_stars() -> void:
	var game: GameData = _four_regions()
	var progress: Progress = Progress.new()
	assert_true(progress.region_open(game, 0))
	assert_false(progress.region_open(game, 1))
	assert_false(progress.region_open(game, 4))
	assert_false(progress.region_open(game, -1))
	# Five of region 1 at 3 stars: 15 stars, but 1-6 is not cleared.
	for l: int in 5:
		progress.record_level(StringName("r1_l%d" % (l + 1)), 7)
	assert_false(progress.region_open(game, 1))
	assert_false(progress.level_open(game, &"r2_l1"))
	progress.record_level(&"r1_l6", 1)
	assert_true(progress.region_open(game, 1))
	assert_true(progress.level_open(game, &"r2_l1"))
	assert_false(progress.level_open(game, &"r2_l2"))


func test_one_star_player_reaches_every_region() -> void:
	var game: GameData = _four_regions()
	var progress: Progress = Progress.new()
	for region: int in 4:
		assert_true(progress.region_open(game, region), "region %d" % (region + 1))
		_clear_region(progress, region, 1)
		if region < 3:
			assert_eq(progress.stars(), 6 * (region + 1))
	assert_eq(progress.stars(), 24)


func test_region_star_counts_are_enforced() -> void:
	var game: GameData = _four_regions()
	var progress: Progress = Progress.new()
	_clear_region(progress, 0, 1)
	# Region 2's boss level only, so 7 stars: region 3 needs 12.
	progress.record_level(&"r2_l6", 1)
	assert_true(progress.region_open(game, 1))
	assert_false(progress.region_open(game, 2))
	for l: int in 5:
		progress.record_level(StringName("r2_l%d" % (l + 1)), 1)
	assert_eq(progress.stars(), 12)
	assert_true(progress.region_open(game, 2))
	assert_false(progress.region_open(game, 3), "region 4 needs 3-6 cleared")
	progress.record_level(&"r3_l6", 7)
	assert_eq(progress.stars(), 15)
	assert_false(progress.region_open(game, 3), "region 4 needs 18 stars")
	progress.record_level(&"r3_l1", 7)
	assert_true(progress.region_open(game, 3))


func test_runs_open_at_twelve_stars() -> void:
	var game: GameData = Fx.game()
	var progress: Progress = Progress.new()
	assert_false(progress.runs_open(game))
	for l: int in 5:
		progress.record_level(StringName("r1_l%d" % (l + 1)), 3)
	assert_eq(progress.stars(), 10)
	assert_false(progress.runs_open(game))
	progress.record_level(&"r1_l6", 3)
	assert_true(progress.runs_open(game), "two stars a level in region 1 opens runs")
	assert_false(progress.runs_open(null))


func test_twist_needs_three_stars_on_that_level() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 3)
	assert_false(progress.twist_open(&"r1_l1"))
	progress.record_level(&"r1_l1", 4)
	assert_true(progress.twist_open(&"r1_l1"), "the three stars can come from different wins")
	assert_false(progress.twist_open(&"r1_l2"))


func test_unlock_counters() -> void:
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 7)
	progress.record_twist(&"r1_l1")
	progress.bump(&"dailies_finished", 2)
	var counters: Dictionary = progress.unlock_counters()
	assert_eq(counters[&"stars"], 3)
	assert_eq(counters[&"twists_cleared"], 1)
	assert_eq(counters[&"dailies_finished"], 2)
	assert_eq(counters.size(), 7)

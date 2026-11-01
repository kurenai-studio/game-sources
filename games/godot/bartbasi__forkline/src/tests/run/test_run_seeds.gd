# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunSeeds: derived seeds, day keys and the daily seed (docs/ARCHITECTURE.md 3.4).


## The numbers were also worked out outside Godot (djb2 over the text), so a change to
## String.hash() or to the text format is caught here.
func test_derived_seeds_are_pinned() -> void:
	assert_eq(RunSeeds.derive(12345, "map", 0), 3983007462)
	assert_eq(RunSeeds.derive(12345, "boss", 0), 2176511199)
	assert_eq(RunSeeds.derive(12345, "pack", 1), 2707220104)
	assert_eq(RunSeeds.derive(12345, "pack", 6), 2707220109)
	assert_eq(RunSeeds.derive(12345, "draft", 17), 1892935121)
	assert_eq(RunSeeds.derive(0, "map", 0), 31570391)
	assert_eq(RunSeeds.derive(4294967295, "draft", 1), 2039635540)
	assert_eq(RunSeeds.derive(20261023, "boss", 0), 3834860112)
	assert_eq(RunSeeds.derive(20261023, "map", 0), 3642808887)


func test_each_tag_and_index_gives_its_own_seed() -> void:
	var seen: Dictionary = {}
	for tag: String in ["map", "boss", "pack", "draft"]:
		for index: int in range(0, 18):
			seen[RunSeeds.derive(777, tag, index)] = true
	assert_eq(seen.size(), 4 * 18, "no two generators of one run share a seed")
	assert_ne(RunSeeds.derive(1, "map", 0), RunSeeds.derive(2, "map", 0))


## The first draws of a few generators. They depend on the engine's generator, so a
## Godot change that moves them is caught here, before it changes every saved run.
func test_generator_draws_are_pinned() -> void:
	var expected: Array = [
		[12345, "map", 0, [41, 61, 78]],
		[12345, "boss", 0, [5, 63, 85]],
		[12345, "pack", 1, [50, 41, 15]],
		[12345, "pack", 6, [65, 19, 98]],
		[12345, "draft", 17, [61, 94, 16]],
		[0, "map", 0, [30, 28, 15]],
		[20261023, "map", 0, [0, 49, 40]],
	]
	for item: Array in expected:
		var rng: RandomNumberGenerator = MapAssembler.generator(item[0], item[1], item[2])
		var draws: Array = [rng.randi_range(0, 99), rng.randi_range(0, 99), rng.randi_range(0, 99)]
		assert_eq(draws, item[3], "%s" % [item.slice(0, 3)])


func test_the_same_derived_seed_repeats_draws() -> void:
	var first: RandomNumberGenerator = MapAssembler.generator(99, "draft", 4)
	var second: RandomNumberGenerator = MapAssembler.generator(99, "draft", 4)
	for i: int in 50:
		assert_eq(first.randi_range(0, 1000), second.randi_range(0, 1000))


func test_day_key_from_a_date_dictionary() -> void:
	assert_eq(RunSeeds.day_key({"year": 2026, "month": 10, "day": 23}), "2026-10-23")
	assert_eq(RunSeeds.day_key({"year": 2026, "month": 1, "day": 5, "weekday": 1, "dst": false}), "2026-01-05")
	assert_eq(RunSeeds.day_key({"year": 2026, "month": 10}), "", "a missing day")
	assert_eq(RunSeeds.day_key({"year": 2026.0, "month": 10, "day": 3}), "", "a float year")
	assert_eq(RunSeeds.day_key({}), "")
	assert_eq(RunSeeds.day_key({"year": 99999, "month": 1, "day": 1}), "", "too many digits")
	assert_eq(RunSeeds.day_key({"year": -5, "month": 1, "day": 1}), "")


func test_a_date_before_the_range_still_gives_text_that_is_not_a_day_key() -> void:
	var text: String = RunSeeds.day_key({"year": 2025, "month": 12, "day": 31})
	assert_eq(text, "2025-12-31")
	assert_false(RunSeeds.is_day_key(text))


func test_is_day_key_accepts_real_dates_in_range() -> void:
	for text: String in ["2026-01-01", "2026-10-23", "2026-12-31", "2028-02-29", "2200-12-31", "2100-02-28"]:
		assert_true(RunSeeds.is_day_key(text), text)


func test_is_day_key_refuses_everything_else() -> void:
	var bad: Array = [
		"", "2026-1-1", "2026/10/23", "20261023", "2026-10-23 ", " 2026-10-23", "2026-10-2",
		"2025-12-31", "2201-01-01", "2026-00-10", "2026-13-01", "2026-10-00", "2026-10-32",
		"2026-02-29", "2100-02-29", "2027-04-31", "2026-06-31", "2026-1O-23", "2026-10-+3",
		"2026-10-23\n", char(0x662) + "026-10-23", "abcd-ef-gh", "2026-10-23-01", "-2026-10-2",
	]
	for text: String in bad:
		assert_false(RunSeeds.is_day_key(text), text.c_escape())
	assert_true(RunSeeds.is_day_key("2028-02-29"), "a leap year")
	assert_false(RunSeeds.is_day_key("2200-02-29"), "2200 is not a leap year")


func test_daily_seed_is_the_date_as_a_number() -> void:
	assert_eq(RunSeeds.daily_seed("2026-10-23"), 20261023)
	assert_eq(RunSeeds.daily_seed("2026-01-01"), 20260101)
	assert_eq(RunSeeds.daily_seed("2200-12-31"), 22001231)
	assert_eq(RunSeeds.daily_seed("2026-02-30"), -1)
	assert_eq(RunSeeds.daily_seed(""), -1)
	assert_eq(RunSeeds.daily_seed("1999-01-01"), -1)


func test_a_daily_seed_is_a_valid_run_seed() -> void:
	for day: String in ["2026-01-01", "2026-10-23", "2200-12-31"]:
		var value: int = RunSeeds.daily_seed(day)
		assert_true(value >= 0 and value <= RunSeeds.SEED_MAX, day)


func test_day_numbers_count_days() -> void:
	assert_eq(RunSeeds.day_number("2026-01-01"), 20454)
	assert_eq(RunSeeds.day_number("2026-10-23"), 20749)
	assert_eq(RunSeeds.day_number("2026-10-24"), 20750)
	assert_eq(RunSeeds.day_number("2027-02-28"), 20877)
	assert_eq(RunSeeds.day_number("2028-02-29"), 21243)
	assert_eq(RunSeeds.day_number("2200-12-31"), 84370)
	assert_eq(RunSeeds.day_number("not a day"), -1)


func test_the_day_after_is_one_more_across_month_year_and_leap_edges() -> void:
	var pairs: Array = [
		["2026-10-31", "2026-11-01"], ["2026-12-31", "2027-01-01"], ["2028-02-28", "2028-02-29"],
		["2028-02-29", "2028-03-01"], ["2027-02-28", "2027-03-01"], ["2099-12-31", "2100-01-01"],
		["2100-02-28", "2100-03-01"],
	]
	for pair: Array in pairs:
		assert_eq(RunSeeds.day_number(pair[1]), RunSeeds.day_number(pair[0]) + 1, "%s" % [pair])


func test_the_source_never_reads_the_clock() -> void:
	for path: String in ["res://src/run/run_seeds.gd", "res://src/run/daily.gd"]:
		var text: String = FileAccess.get_file_as_string(path)
		for word: String in ["Time.", "OS.get_", "randi()", "randf", "randomize"]:
			assert_false(text.contains(word), "%s uses %s" % [path, word])

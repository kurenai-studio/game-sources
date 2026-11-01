# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The daily record in daily.json: the best result of a day and the streak
## (docs/ARCHITECTURE.md 3.5, 5.1, 5.4, 5.5; RULES 15).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

const DAY: String = "2026-10-23"
const NEXT: String = "2026-10-24"
const EARLIER: String = "2026-10-20"
const LOSS_12: Dictionary = {"won": false, "waves": 12, "lives": 0}
const LOSS_9: Dictionary = {"won": false, "waves": 9, "lives": 0}
const WIN_3: Dictionary = {"won": true, "waves": 18, "lives": 3}
const WIN_8: Dictionary = {"won": true, "waves": 18, "lives": 8}

var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


func _record(day: String, result: Dictionary) -> DailyRecord:
	var record: DailyRecord = DailyRecord.new()
	record.record_finish(day, result)
	return record


func test_a_new_record_is_empty() -> void:
	var record: DailyRecord = DailyRecord.new()
	assert_eq(record.day, "")
	assert_eq(record.best, {})
	assert_eq(record.streak, 0)
	assert_eq(record.streak_day, "")
	assert_eq(store.load_daily().to_data(), record.to_data(), "a missing file gives the empty record")


func test_the_first_finish_sets_the_best_and_starts_the_streak() -> void:
	var record: DailyRecord = _record(DAY, LOSS_12)
	assert_eq(record.day, DAY)
	assert_eq(record.best, LOSS_12)
	assert_eq(record.streak, 1)
	assert_eq(record.streak_day, DAY)


func test_the_same_day_keeps_the_better_result() -> void:
	var record: DailyRecord = _record(DAY, LOSS_12)
	record.record_finish(DAY, LOSS_9)
	assert_eq(record.best, LOSS_12, "fewer waves does not replace more")
	record.record_finish(DAY, LOSS_12)
	assert_eq(record.best, LOSS_12, "a tie keeps the old one")
	record.record_finish(DAY, WIN_8)
	assert_eq(record.best, WIN_8, "a win beats a loss")
	record.record_finish(DAY, WIN_3)
	assert_eq(record.best, WIN_8, "fewer lives does not replace more")
	record.record_finish(DAY, LOSS_12)
	assert_eq(record.best, WIN_8, "a loss never beats a win")
	assert_eq(record.day, DAY)
	assert_eq(record.streak, 1, "the same day never adds to the streak")
	assert_eq(record.streak_day, DAY)


func test_a_later_day_replaces_the_best_even_when_worse() -> void:
	var record: DailyRecord = _record(DAY, WIN_8)
	record.record_finish(NEXT, LOSS_9)
	assert_eq(record.day, NEXT)
	assert_eq(record.best, LOSS_9)
	assert_eq(record.streak, 2, "the day after adds 1")
	assert_eq(record.streak_day, NEXT)
	record.record_finish("2026-10-30", WIN_3)
	assert_eq(record.day, "2026-10-30")
	assert_eq(record.best, WIN_3)
	assert_eq(record.streak, 1, "a gap starts again at 1")
	assert_eq(record.streak_day, "2026-10-30")


func test_an_earlier_day_leaves_the_best_and_the_streak_alone() -> void:
	# A daily that started before a later one and was finished after it (RULES 15).
	var record: DailyRecord = _record(DAY, LOSS_9)
	record.record_finish(NEXT, LOSS_9)
	record.record_finish(EARLIER, WIN_8)
	assert_eq(record.day, NEXT)
	assert_eq(record.best, LOSS_9)
	assert_eq(record.streak, 2)
	assert_eq(record.streak_day, NEXT)
	record.record_finish(DAY, WIN_8)
	assert_eq(record.best, LOSS_9, "yesterday's daily finished today is not today's best")
	assert_eq(record.streak, 2)


func test_a_day_that_is_not_a_day_key_changes_nothing() -> void:
	var record: DailyRecord = _record(DAY, LOSS_12)
	var before: Dictionary = record.to_data()
	for bad: String in ["", "2025-12-31", "2201-01-01", "2026-02-29", "2026-13-01", "20261023", "../x", "2026-10-23 "]:
		record.record_finish(bad, WIN_8)
		assert_eq(record.to_data(), before, bad)


func test_results_are_stored_as_three_ints_and_a_bool() -> void:
	var record: DailyRecord = _record(DAY, {"won": false, "waves": 12.0, "lives": 0, "reached": 13, "risks": 2})
	assert_eq(record.best, LOSS_12, "only won, waves and lives are kept")
	assert_eq(typeof(record.best["waves"]), TYPE_INT)
	var odd: DailyRecord = _record(DAY, {"won": "yes", "waves": -5, "lives": 1e300})
	assert_eq(odd.best, {"won": false, "waves": 0, "lives": 0}, "bad fields count as false or 0")
	var high: DailyRecord = _record(DAY, {"won": true, "waves": 5000, "lives": 2000})
	assert_eq(high.best, {"won": true, "waves": 1000, "lives": 1000}, "numbers stay within the ceiling")


func test_the_record_round_trips_with_ints() -> void:
	var record: DailyRecord = _record(DAY, WIN_3)
	record.record_finish(NEXT, LOSS_12)
	assert_true(store.save_daily(record))
	assert_eq(Fx.read_text("daily.json"), "{\"best\":{\"lives\":0,\"waves\":12,\"won\":false},\"day\":\"2026-10-24\",\"format\":1,\"streak\":2,\"streak_day\":\"2026-10-24\",\"tier\":0}")
	var loaded: DailyRecord = SaveStore.new(Fx.WORK).load_daily()
	assert_eq(JSON.stringify(loaded.to_data()), JSON.stringify(record.to_data()))
	for key: String in ["waves", "lives"]:
		assert_eq(typeof(loaded.best[key]), TYPE_INT, key)
	assert_eq(typeof(loaded.streak), TYPE_INT)
	# Daily.is_better counts a number of any other type as 0, so a loaded best must still win ties right.
	loaded.record_finish(NEXT, {"won": false, "waves": 11, "lives": 0})
	assert_eq(loaded.best, LOSS_12)
	loaded.record_finish(NEXT, {"won": false, "waves": 13, "lives": 0})
	assert_eq(loaded.best["waves"], 13)


func test_the_second_write_keeps_the_first_as_backup() -> void:
	var record: DailyRecord = _record(DAY, LOSS_9)
	assert_true(store.save_daily(record))
	var first: String = Fx.read_text("daily.json")
	record.record_finish(DAY, LOSS_12)
	assert_true(store.save_daily(record))
	assert_eq(Fx.read_text("daily.json.bak"), first)
	assert_false(Fx.exists("daily.json.tmp"))


func test_tmp_then_file_then_bak() -> void:
	Fx.write_text("daily.json", JSON.stringify(_record(DAY, LOSS_9).to_data()))
	Fx.write_text("daily.json.tmp", JSON.stringify(_record(DAY, LOSS_12).to_data()))
	assert_eq(store.load_daily().best, LOSS_12, "the .tmp is the newest attempt")
	assert_false(Fx.exists("daily.json.tmp"), "and moves into place")
	Fx.write_text("daily.json", "{\"format\": 1, \"day\": ")
	Fx.write_text("daily.json.bak", JSON.stringify(_record(DAY, WIN_3).to_data()))
	assert_eq(SaveStore.new(Fx.WORK).load_daily().best, WIN_3, "a broken file falls back to the .bak")


func test_a_newer_format_is_left_alone() -> void:
	var newer: String = "{\"format\": 2, \"day\": \"2026-10-23\", \"best\": {}, \"streak\": 9, \"medals\": 3}"
	Fx.write_text("daily.json", newer)
	var loaded: DailyRecord = store.load_daily()
	assert_eq(loaded.streak, 0, "defaults in memory")
	assert_true(store.is_locked(SaveStore.DAILY_FILE))
	assert_false(store.save_daily(_record(DAY, WIN_3)), "never overwritten by an older build")
	assert_eq(Fx.read_text("daily.json"), newer)


func test_bad_fields_fall_back_one_by_one() -> void:
	var cases: Dictionary = {
		"day not a date": [{"day": "2026-02-30"}, "", {}, 4, DAY],
		"day before 2026": [{"day": "2025-12-31"}, "", {}, 4, DAY],
		"day as number": [{"day": 20261023}, "", {}, 4, DAY],
		"best with an extra key": [{"best": {"won": true, "waves": 18, "lives": 3, "cheat": 1}}, "", {}, 4, DAY],
		"best missing a key": [{"best": {"won": true, "waves": 18}}, "", {}, 4, DAY],
		"best past the ceiling": [{"best": {"won": true, "waves": 18, "lives": 1001}}, "", {}, 4, DAY],
		"best negative": [{"best": {"won": false, "waves": -1, "lives": 0}}, "", {}, 4, DAY],
		"best fraction": [{"best": {"won": false, "waves": 2.5, "lives": 0}}, "", {}, 4, DAY],
		"won as number": [{"best": {"won": 1, "waves": 18, "lives": 3}}, "", {}, 4, DAY],
		"streak past the ceiling": [{"streak": 100001}, DAY, WIN_3, 0, DAY],
		"streak negative": [{"streak": -1}, DAY, WIN_3, 0, DAY],
		"streak fraction": [{"streak": 3.5}, DAY, WIN_3, 0, DAY],
		"streak day not a date": [{"streak_day": "yesterday"}, DAY, WIN_3, 4, ""],
		"streak at the ceiling": [{"streak": 100000}, DAY, WIN_3, 100000, DAY],
		"unknown key": [{"medals": 3}, DAY, WIN_3, 4, DAY],
	}
	var base: Dictionary = {"format": 1, "day": DAY, "best": WIN_3, "streak": 4, "streak_day": DAY}
	for name: String in cases:
		var item: Array = cases[name]
		var data: Dictionary = base.duplicate(true)
		data.merge(item[0], true)
		var loaded: DailyRecord = DailyRecord.from_data(JSON.parse_string(JSON.stringify(data)))
		assert_eq(loaded.day, item[1], "%s: day" % name)
		assert_eq(loaded.best, item[2], "%s: best" % name)
		assert_eq(loaded.streak, item[3], "%s: streak" % name)
		assert_eq(loaded.streak_day, item[4], "%s: streak_day" % name)
	for junk: Variant in [null, [], "daily", 7]:
		assert_eq(DailyRecord.from_data(junk).to_data(), DailyRecord.new().to_data(), str(junk))


func test_the_streak_saturates_at_its_ceiling() -> void:
	var record: DailyRecord = DailyRecord.from_data({"format": 1, "day": "", "best": {}, "streak": Daily.STREAK_MAX, "streak_day": DAY})
	record.record_finish(NEXT, LOSS_9)
	assert_eq(record.streak, Daily.STREAK_MAX, "never a value its own check refuses")
	assert_true(store.save_daily(record))
	assert_eq(SaveStore.new(Fx.WORK).load_daily().streak, Daily.STREAK_MAX)


# The daily's content tier (docs/ARCHITECTURE.md 14.7, 14.8; RULES 15)

func test_the_first_finish_of_a_day_fixes_its_tier() -> void:
	var record: DailyRecord = DailyRecord.new()
	assert_eq(record.tier, 0, "a new record is tier 0")
	record.record_finish(DAY, LOSS_9, 2)
	assert_eq(record.tier, 2)
	record.record_finish(DAY, WIN_8, 3)
	assert_eq(record.best, WIN_8, "a better result of the same day")
	assert_eq(record.tier, 2, "the same day keeps its tier, even with a better result")
	record.record_finish(DAY, LOSS_9, 0)
	assert_eq(record.tier, 2, "and with a worse one")
	record.record_finish(EARLIER, WIN_8, 4)
	assert_eq([record.day, record.tier], [DAY, 2], "an earlier day leaves the tier alone")
	record.record_finish(NEXT, LOSS_12, 3)
	assert_eq([record.day, record.tier], [NEXT, 3], "a later day replaces the tier along with the best")
	record.record_finish("2026-10-25", LOSS_12)
	assert_eq(record.tier, 0, "the tier defaults to 0, as before the expansion")


func test_a_tier_outside_the_range_counts_as_0() -> void:
	for bad: int in [-1, RunData.MAX_TIERS + 1, 1000000000, -9223372036854775807]:
		var record: DailyRecord = DailyRecord.new()
		record.record_finish(DAY, WIN_3, bad)
		assert_eq(record.tier, 0, str(bad))
	var top: DailyRecord = DailyRecord.new()
	top.record_finish(DAY, WIN_3, RunData.MAX_TIERS)
	assert_eq(top.tier, RunData.MAX_TIERS)
	var nothing: DailyRecord = DailyRecord.new()
	nothing.record_finish("not a day", WIN_3, 3)
	assert_eq(nothing.tier, 0, "a finish that changes nothing leaves the tier at 0")


func test_the_tier_round_trips_through_daily_json() -> void:
	var record: DailyRecord = DailyRecord.new()
	record.record_finish(DAY, WIN_3, 4)
	assert_true(store.save_daily(record))
	assert_true(Fx.read_text("daily.json").contains("\"tier\":4"), "always written")
	var loaded: DailyRecord = SaveStore.new(Fx.WORK).load_daily()
	assert_eq(loaded.tier, 4)
	assert_eq(typeof(loaded.tier), TYPE_INT)
	assert_eq(JSON.stringify(loaded.to_data()), JSON.stringify(record.to_data()))
	loaded.record_finish(DAY, WIN_8, 1)
	assert_eq(loaded.tier, 4, "a loaded day keeps its tier")


func test_daily_json_without_a_tier_is_tier_0() -> void:
	# The daily.json of the build before the expansion.
	Fx.write_text("daily.json", "{\"best\":{\"lives\":3,\"waves\":18,\"won\":true},\"day\":\"2026-10-23\",\"format\":1,\"streak\":4,\"streak_day\":\"2026-10-23\"}")
	var loaded: DailyRecord = store.load_daily()
	assert_eq([loaded.day, loaded.best, loaded.streak], [DAY, WIN_3, 4], "the rest still loads")
	assert_eq(loaded.tier, 0)
	assert_eq(loaded.to_data()["tier"], 0, "and is written from then on")


func test_a_bad_tier_falls_back_to_0_and_keeps_the_rest() -> void:
	var base: Dictionary = {"format": 1, "day": DAY, "best": WIN_3, "streak": 4, "streak_day": DAY}
	for bad: Variant in [null, -1, RunData.MAX_TIERS + 1, 1.5, "2", true, [], {}, [2], {"t": 2}, 1e18, -1e18, 1e999, 2147483648]:
		var data: Dictionary = base.duplicate(true)
		data["tier"] = bad
		var loaded: DailyRecord = DailyRecord.from_data(JSON.parse_string(JSON.stringify(data)))
		assert_eq(loaded.tier, 0, "tier %s" % str(bad))
		assert_eq([loaded.day, loaded.best, loaded.streak, loaded.streak_day], [DAY, WIN_3, 4, DAY], "tier %s: the rest" % str(bad))
	for good: int in RunData.MAX_TIERS + 1:
		var data: Dictionary = base.duplicate(true)
		data["tier"] = good
		assert_eq(DailyRecord.from_data(JSON.parse_string(JSON.stringify(data))).tier, good, "tier %d" % good)
	var whole: Dictionary = base.duplicate(true)
	whole["tier"] = 3.0
	assert_eq(DailyRecord.from_data(whole).tier, 3, "a whole float is read as an int")


func test_a_record_with_no_day_has_tier_0() -> void:
	for data: Dictionary in [
		{"format": 1, "day": "", "best": {}, "streak": 4, "streak_day": DAY, "tier": 3},
		{"format": 1, "day": DAY, "best": {}, "streak": 4, "streak_day": DAY, "tier": 3},
		{"format": 1, "day": "2026-02-30", "best": WIN_3, "streak": 4, "streak_day": DAY, "tier": 3},
		{"format": 1, "best": WIN_3, "tier": 3},
	]:
		var loaded: DailyRecord = DailyRecord.from_data(data)
		assert_eq(loaded.day, "")
		assert_eq(loaded.tier, 0, str(data))


func test_hostile_daily_json_with_a_tier_never_crashes() -> void:
	var cases: Dictionary = {
		"tier huge": "{\"format\": 1, \"day\": \"2026-10-23\", \"best\": {\"won\": true, \"waves\": 18, \"lives\": 3}, \"tier\": 1e999}",
		"tier nested": "{\"format\": 1, \"day\": \"2026-10-23\", \"best\": {\"won\": true, \"waves\": 18, \"lives\": 3}, \"tier\": [[[[1]]]]}",
		"tier text": "{\"format\": 1, \"day\": \"2026-10-23\", \"best\": {\"won\": true, \"waves\": 18, \"lives\": 3}, \"tier\": \"../x\"}",
		"tier negative zero": "{\"format\": 1, \"day\": \"2026-10-23\", \"best\": {\"won\": true, \"waves\": 18, \"lives\": 3}, \"tier\": -0.0}",
	}
	for name: String in cases:
		Fx.fresh()
		Fx.write_text("daily.json", cases[name])
		var loaded: DailyRecord = SaveStore.new(Fx.WORK).load_daily()
		assert_eq(loaded.day, DAY, name)
		assert_eq(loaded.tier, 0, name)

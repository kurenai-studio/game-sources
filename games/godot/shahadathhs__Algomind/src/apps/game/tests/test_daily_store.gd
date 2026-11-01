extends GutTest
## The daily cache: dates, "today", the schedule on disk, levels saved for offline play.

const FILE := "user://test_daily.json"
const DIR := "user://test_daily_content"

var _store: DailyStore


func before_each() -> void:
	_clean()
	_store = DailyStore.new(FILE, DIR)


func after_each() -> void:
	_clean()


func _clean() -> void:
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(FILE + suffix):
			DirAccess.remove_absolute(FILE + suffix)
	ContentStore.new(DIR).clear()


func test_dates() -> void:
	assert_eq(DailyDates.utc(0.0), "1970-01-01")
	assert_eq(DailyDates.shift("2026-10-30", 3), "2026-11-02")
	assert_eq(DailyDates.shift("2026-03-01", -1), "2026-02-28")
	assert_eq(DailyDates.shift("2028-02-28", 1), "2028-02-29")
	assert_true(DailyDates.is_valid("2026-10-20"))
	for bad in ["2026-13-01", "2026-02-30", "26-10-20", "2026/10/20", "tomorrow", ""]:
		assert_false(DailyDates.is_valid(bad), bad)


func test_today_is_the_device_utc_date_until_the_server_says_otherwise() -> void:
	var late_night := float(DailyDates.to_unix("2026-10-20") + 23 * 3600 + 3599)
	assert_eq(_store.today(late_night), "2026-10-20")
	assert_eq(_store.today(late_night + 2.0), "2026-10-21")
	_store.online_date = "2026-10-19"
	assert_eq(_store.today(late_night), "2026-10-19", "the server's date wins while online")


func test_refresh_saves_the_schedule_and_every_level() -> void:
	var calls: Array = []
	var result := await _store.refresh(SocialFixtures.fetcher("2026-10-20", calls))
	assert_eq(result["status"], "updated")
	assert_eq(_store.today(), "2026-10-20")
	assert_eq(_store.days.size(), 4)
	for date in ["2026-10-20", "2026-10-21", "2026-10-23"]:
		assert_true(_store.is_playable(date), date)
	assert_eq(_store.upcoming("2026-10-20").size(), 3)


func test_the_cache_plays_offline_after_a_restart() -> void:
	await _store.refresh(SocialFixtures.fetcher("2026-10-20", []))
	var again := DailyStore.new(FILE, DIR)
	again.load_data()
	var calls: Array = []
	var result := await again.refresh(ContentFixtures.offline(calls))
	assert_eq(result["status"], "offline")
	assert_eq(again.online_date, "")
	assert_true(again.is_playable("2026-10-22"))
	assert_eq(again.level("2026-10-20")["levelVersion"], 1)


func test_a_second_refresh_downloads_no_level_again() -> void:
	await _store.refresh(SocialFixtures.fetcher("2026-10-20", []))
	var calls: Array = []
	var result := await _store.refresh(SocialFixtures.fetcher("2026-10-20", calls))
	assert_eq(calls, ["daily"])
	assert_eq(result["status"], "unchanged")


func test_old_days_are_dropped_and_new_ones_added() -> void:
	await _store.refresh(SocialFixtures.fetcher("2026-10-20", []))
	await _store.refresh(SocialFixtures.fetcher("2026-10-23", []))
	assert_false(_store.days.has("2026-10-20"))
	assert_true(_store.days.has("2026-10-22"), "yesterday is kept for the turn of the day")
	assert_true(_store.days.has("2026-10-26"))


func test_a_level_that_fails_validation_is_not_stored() -> void:
	var fetch := func(path: String) -> Dictionary:
		if path == "daily":
			return AccountFixtures.ok(SocialFixtures.schedule("2026-10-20"))
		return AccountFixtures.ok({"levelVersion": 1, "content": {"slug": "daily-elm"}})
	var result := await _store.refresh(fetch)
	assert_false(_store.is_playable("2026-10-20"))
	assert_gt((result["errors"] as Array).size(), 0)


func test_an_unreadable_schedule_changes_nothing() -> void:
	await _store.refresh(SocialFixtures.fetcher("2026-10-20", []))
	var fetch := func(_path: String) -> Dictionary: return AccountFixtures.ok({"serverDate": "x"})
	var result := await _store.refresh(fetch)
	assert_eq(result["status"], "invalid")
	assert_eq(_store.days.size(), 4)


func test_the_daily_entry_has_the_shape_the_play_screen_needs() -> void:
	await _store.refresh(SocialFixtures.fetcher("2026-10-20", []))
	var entry := DailyPlay.entry(_store, "2026-10-20")
	assert_eq(entry["id"], "daily-elm")
	assert_eq(entry["daily"], "2026-10-20")
	assert_eq(entry["level"]["slug"], "daily-elm")
	assert_eq(entry["par"]["commands"], 3)
	assert_eq(DailyPlay.entry(_store, "2030-01-01"), {})

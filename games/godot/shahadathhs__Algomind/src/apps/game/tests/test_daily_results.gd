extends GutTest
## A daily solve: queued with its date, kept best per day, sent with dailyDate at the next sync.

const ACCOUNT_PATH := "user://test_dres_account.json"
const PROGRESS_PATH := "user://test_dres_progress.json"

var _server: AccountFixtures
var _account: Account
var _client: AccountClient
var _progress: ProgressStore


func before_each() -> void:
	_remove()
	_server = AccountFixtures.new()
	_account = Account.new(ACCOUNT_PATH)
	_client = AccountClient.new(_account, _server.send)
	_progress = ProgressStore.new(PROGRESS_PATH)
	_progress.load_data()
	_account.start("a@example.com", "ref1")
	_server.on("POST", "auth/refresh", AccountFixtures.session("a@example.com", "acc1", "ref1b"))
	_server.on("POST", "me/progress/sync", AccountFixtures.ok({"completed": [], "settings": null}))


func after_each() -> void:
	_remove()


func _remove() -> void:
	for base in [ACCOUNT_PATH, PROGRESS_PATH, PROGRESS_PATH.get_basename() + "_results.json"]:
		for suffix in ["", ".tmp", ".bak", ".corrupt"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(base + suffix)


func _program(count: int) -> Array:
	var program: Array = []
	for i in count:
		program.append({"op": "MOVE_FORWARD"})
	return program


func _queue(date: String, slots: int) -> void:
	_progress.results.queue_daily(date, "daily-elm", 1, _program(slots), slots)


func _answer(streak: int, badges: Array = []) -> Dictionary:
	return (
		AccountFixtures
		. ok(
			{
				"duplicate": false,
				"stars": 3,
				"points": 30,
				"awarded": 30,
				"total": 60,
				"daily": {"accepted": true, "streak": {"current": streak, "best": streak}},
				"achievements": badges,
			}
		)
	)


func test_the_best_program_per_day_is_kept() -> void:
	_queue("2026-10-20", 7)
	_queue("2026-10-20", 9)
	_queue("2026-10-20", 5)
	_queue("2026-10-21", 8)
	assert_eq(_progress.results.daily_queue["2026-10-20"]["slots"], 5)
	assert_eq(_progress.results.daily_best["2026-10-20"]["slots"], 5)
	assert_eq(_progress.results.pending_dailies(), ["2026-10-20", "2026-10-21"])


func test_the_queue_survives_a_restart() -> void:
	_queue("2026-10-20", 4)
	_progress.results.streak = {"current": 2, "best": 3}
	_progress.results.badges = ["First clear"]
	assert_true(_progress.results.save())
	var again := PlayerResults.new(_progress.results.path)
	again.load_data()
	assert_eq(again.daily_queue["2026-10-20"]["program"].size(), 4)
	assert_eq(again.daily_best["2026-10-20"]["slots"], 4)
	assert_eq(again.streak["best"], 3)
	assert_eq(again.badges, ["First clear"])


func test_signed_out_a_daily_is_never_sent() -> void:
	_account.clear()
	_queue("2026-10-20", 4)
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "signed_out")
	assert_eq(_server.calls.size(), 0)
	assert_true(
		_progress.results.daily_queue.has("2026-10-20"), "kept for when the player signs in"
	)


func test_a_queued_daily_is_sent_with_its_date_and_the_answer_is_kept() -> void:
	_queue("2026-10-20", 4)
	_server.on(
		"POST", "me/submissions", _answer(3, [{"slug": "daily-first", "title": "Daily start"}])
	)
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "synced")
	var body: Dictionary = _server.calls[_server.calls.size() - 1]["body"]
	assert_eq(body["dailyDate"], "2026-10-20")
	assert_eq(body["levelSlug"], "daily-elm")
	assert_false(body.has("points") or body.has("stars"))
	assert_true(_progress.results.daily_queue.is_empty())
	assert_eq(_progress.results.streak["current"], 3)
	assert_eq(_progress.results.total, 60)
	assert_eq(_progress.results.take_badges(), ["Daily start"])
	assert_eq(_progress.results.take_badges(), [], "shown once")
	assert_eq(_progress.results.daily_best["2026-10-20"]["slots"], 4, "the local result stays")


func test_losing_the_connection_keeps_the_daily_and_touches_nothing_else() -> void:
	_queue("2026-10-20", 4)
	_server.on("POST", "me/submissions", AccountFixtures.offline())
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "offline")
	assert_true(_progress.results.daily_queue.has("2026-10-20"))
	assert_true(_progress.results.streak.is_empty())


func test_a_daily_the_server_refuses_is_dropped() -> void:
	_queue("2026-10-20", 4)
	_server.on("POST", "me/submissions", AccountFixtures.fail(422, "PROGRAM_DID_NOT_SOLVE"))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "synced")
	assert_true(_progress.results.daily_queue.is_empty())


func test_levels_and_dailies_are_both_sent() -> void:
	_progress.results.queue_result("stairs", 1, _program(2), 2)
	_queue("2026-10-20", 4)
	_server.on("POST", "me/submissions", _answer(1))
	await ProgressSync.run(_client, _progress)
	assert_eq(_server.count("me/submissions"), 2)
	assert_true(_progress.results.queue.is_empty() and _progress.results.daily_queue.is_empty())

extends GutTest
## Sending the programs waiting for the server: only when signed in, only by the sync, and a
## failure of the connection loses nothing.

const ACCOUNT_PATH := "user://test_rsync_account.json"
const PROGRESS_PATH := "user://test_rsync_progress.json"

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


func _queue(slug: String, slots: int) -> void:
	_progress.results.queue_result(slug, 1, [{"op": "MOVE_FORWARD"}], slots)


func _accepted(total: int) -> Dictionary:
	return AccountFixtures.ok(
		{"duplicate": false, "stars": 3, "points": 35, "awarded": 35, "total": total}
	)


func test_signed_out_play_sends_no_program() -> void:
	_account.clear()
	_queue("a", 1)
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "signed_out")
	assert_eq(_server.calls.size(), 0)
	assert_true(_progress.results.queue.has("a"), "kept for when the player signs in")


func test_a_queued_program_is_sent_without_any_score_and_the_answer_is_kept() -> void:
	_queue("a", 1)
	_server.on("POST", "me/submissions", _accepted(35))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "synced")
	var body: Dictionary = _server.calls[_server.calls.size() - 1]["body"]
	assert_eq(body["levelSlug"], "a")
	assert_eq(body["program"], [{"op": "MOVE_FORWARD"}])
	assert_false(body.has("points") or body.has("stars") or body.has("score"), "no score is sent")
	assert_true(_progress.results.queue.is_empty(), "sent, so no longer waiting")
	assert_eq(_progress.results.total, 35)
	assert_eq(_progress.results.stars_for("a"), 3)


func test_losing_the_connection_keeps_the_program_for_the_next_sync() -> void:
	_queue("a", 1)
	_server.on("POST", "me/submissions", AccountFixtures.offline())
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "offline", "the sync retries with its usual waits")
	assert_true(_progress.results.queue.has("a"))
	assert_eq(_progress.results.total, -1)


func test_a_program_the_server_will_never_accept_is_dropped() -> void:
	_queue("a", 1)
	_queue("b", 1)
	_server.on("POST", "me/submissions", AccountFixtures.fail(422, "PROGRAM_DID_NOT_SOLVE"))
	_server.on("POST", "me/submissions", _accepted(35))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "synced")
	assert_true(_progress.results.queue.is_empty(), "the refused one is gone, the other was sent")
	assert_eq(_progress.results.total, 35)


func test_a_server_error_keeps_the_program() -> void:
	_queue("a", 1)
	_server.on("POST", "me/submissions", AccountFixtures.fail(500))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "failed")
	assert_true(_progress.results.queue.has("a"))

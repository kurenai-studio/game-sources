extends GutTest
## The only code that uploads progress: signed out it sends nothing, a failure changes nothing
## on the device, and a success merges what the server answered.

const ACCOUNT_PATH := "user://test_sync_account.json"
const PROGRESS_PATH := "user://test_sync_progress.json"

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


func after_each() -> void:
	_remove()


func _remove() -> void:
	for base in [ACCOUNT_PATH, PROGRESS_PATH]:
		for suffix in ["", ".tmp", ".bak", ".corrupt"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(base + suffix)


func _sign_in() -> void:
	_account.start("a@example.com", "ref1")
	_server.on("POST", "auth/refresh", AccountFixtures.session("a@example.com", "acc1", "ref1b"))


func _answer(completed: Array, settings: Variant = null) -> Dictionary:
	return AccountFixtures.ok({"completed": completed, "settings": settings})


func test_signed_out_play_uploads_nothing() -> void:
	_progress.record_completion("a", 1, 4)
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "signed_out")
	assert_eq(_server.calls.size(), 0, "no request of any kind")


func test_sync_sends_local_progress_and_applies_the_merged_answer() -> void:
	_sign_in()
	_progress.record_completion("a", 1, 4)
	(
		_server
		. on(
			"POST",
			"me/progress/sync",
			_answer(
				[
					{"levelSlug": "a", "levelVersion": 1, "bestCommands": 3, "completedAt": 100.0},
					{"levelSlug": "b", "levelVersion": 1, "bestCommands": 7, "completedAt": 200.0},
				]
			)
		)
	)
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "synced")
	var sent: Dictionary = _server.calls[1]["body"]
	assert_eq(sent["completed"][0]["levelSlug"], "a")
	assert_eq(sent["completed"][0]["bestCommands"], 4)
	assert_eq(_progress.best_commands("a", 1), 3, "the better remote result is kept")
	assert_true(_progress.is_completed("b"), "a level solved elsewhere appears here")
	assert_gt(_account.last_sync_at, 0.0)


func test_offline_sync_changes_nothing_locally() -> void:
	_sign_in()
	_progress.record_completion("a", 1, 4)
	var before := JSON.stringify(_progress.completions())
	_server.on("POST", "me/progress/sync", AccountFixtures.offline())
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "offline")
	assert_eq(JSON.stringify(_progress.completions()), before)
	assert_eq(_account.last_sync_at, 0.0)


func test_a_server_error_changes_nothing_locally() -> void:
	_sign_in()
	_progress.record_completion("a", 1, 4)
	_server.on("POST", "me/progress/sync", AccountFixtures.fail(500, "SERVER"))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "failed")
	assert_eq(_progress.completions().size(), 1)
	assert_true(_account.signed_in(), "a server error does not sign the player out")


func test_a_malformed_answer_is_refused_and_changes_nothing() -> void:
	_sign_in()
	_progress.record_completion("a", 1, 4)
	_server.on("POST", "me/progress/sync", AccountFixtures.ok({"nonsense": true}))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "failed")
	assert_eq(_progress.best_commands("a", 1), 4)


func test_syncing_twice_gives_the_same_result() -> void:
	_sign_in()
	_progress.record_completion("a", 1, 4)
	_server.on(
		"POST",
		"me/progress/sync",
		_answer([{"levelSlug": "a", "levelVersion": 1, "bestCommands": 4, "completedAt": 100.0}])
	)
	await ProgressSync.run(_client, _progress)
	var once := JSON.stringify(_progress.completions())
	await ProgressSync.run(_client, _progress)
	assert_eq(JSON.stringify(_progress.completions()), once)


func test_newer_settings_from_another_device_are_applied() -> void:
	_sign_in()
	_progress.settings.set_sound(true)
	var mine := _progress.settings.settings_updated_at()
	_server.on(
		"POST",
		"me/progress/sync",
		_answer([], {"settings": {"sound": false, "runSpeed": "fast"}, "updatedAt": mine + 100.0})
	)
	await ProgressSync.run(_client, _progress)
	assert_false(_progress.settings.sound())
	assert_eq(_progress.settings.run_speed(), "fast")


func test_settings_are_sent_only_after_they_were_changed() -> void:
	_sign_in()
	_server.on("POST", "me/progress/sync", _answer([]))
	await ProgressSync.run(_client, _progress)
	assert_false(_server.calls[1]["body"].has("settings"), "untouched settings are not uploaded")
	_progress.settings.set_music(false)
	await ProgressSync.run(_client, _progress)
	assert_true(_server.calls[2]["body"].has("settings"))
	assert_eq(_server.calls[2]["body"]["settings"]["settings"]["music"], false)


func test_a_rejected_session_ends_the_account_but_keeps_progress() -> void:
	_account.start("a@example.com", "ref1")
	_progress.record_completion("a", 1, 4)
	_server.on("POST", "auth/refresh", AccountFixtures.fail(401, "INVALID_REFRESH_TOKEN"))
	var result := await ProgressSync.run(_client, _progress)
	assert_eq(result["status"], "signed_out")
	assert_false(_account.signed_in())
	assert_true(_progress.is_completed("a"), "local progress is never touched")


func test_a_sync_that_cannot_be_saved_does_not_claim_success() -> void:
	_sign_in()
	var unwritable := ProgressStore.new("/dev/null/progress.json")
	unwritable.record_completion("a", 1, 4)
	_server.on(
		"POST",
		"me/progress/sync",
		_answer([{"levelSlug": "a", "levelVersion": 1, "bestCommands": 4, "completedAt": 100.0}])
	)
	var result := await ProgressSync.run(_client, unwritable)
	assert_eq(result["status"], "failed", "the merged state could not be written to the device")

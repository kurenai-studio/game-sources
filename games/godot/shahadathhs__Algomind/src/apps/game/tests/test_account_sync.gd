extends GutTest
## When syncs run: a request made during a sync is kept, not dropped.

const ACCOUNT_PATH := "user://test_account_sync_account.json"
const PROGRESS_PATH := "user://test_account_sync_progress.json"

var _server: AccountFixtures
var _sync: AccountSync


func before_each() -> void:
	_remove()
	_server = AccountFixtures.new()
	var account := Account.new(ACCOUNT_PATH)
	account.start("a@example.com", "ref1")
	var client := AccountClient.new(account, _server.send)
	var progress := ProgressStore.new(PROGRESS_PATH)
	progress.load_data()
	_sync = AccountSync.new(client, progress)
	_sync.debounce_seconds = 0.05
	add_child_autofree(_sync)
	var session := AccountFixtures.session("a@example.com", "acc1", "ref1b")
	_server.on("POST", "auth/refresh", session)
	var slow := AccountFixtures.ok({"completed": [], "settings": null})
	slow["delay_frames"] = 5
	_server.on("POST", "me/progress/sync", slow)


func after_each() -> void:
	_remove()


func _remove() -> void:
	for base in [ACCOUNT_PATH, PROGRESS_PATH]:
		for suffix in ["", ".tmp", ".bak"]:
			if FileAccess.file_exists(base + suffix):
				DirAccess.remove_absolute(base + suffix)


func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func test_a_request_made_during_a_sync_is_not_dropped() -> void:
	_sync.request()
	await get_tree().create_timer(0.15).timeout  # the first sync starts and is slow
	_sync.request()  # arrives while it runs
	await get_tree().create_timer(0.6).timeout
	assert_eq(_server.count("me/progress/sync"), 2, "the change made mid-sync was sent too")


func test_requests_close_together_become_one_sync() -> void:
	_sync.request()
	_sync.request()
	_sync.request()
	await get_tree().create_timer(0.5).timeout
	assert_eq(_server.count("me/progress/sync"), 1)


func test_signed_out_requests_do_nothing() -> void:
	var account := Account.new("user://test_account_sync_out.json")
	account.clear()
	var quiet := AccountSync.new(
		AccountClient.new(account, _server.send), ProgressStore.new(PROGRESS_PATH)
	)
	add_child_autofree(quiet)
	quiet.request()
	await get_tree().create_timer(0.2).timeout
	assert_eq(_server.calls.size(), 0)
	DirAccess.remove_absolute("user://test_account_sync_out.json")

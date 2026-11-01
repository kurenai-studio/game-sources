extends GutTest
## Signing in, token refresh and rotation, and how failures end (or keep) a session.

const PATH := "user://test_account_client.json"

var _server: AccountFixtures
var _account: Account
var _client: AccountClient


func before_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	_server = AccountFixtures.new()
	_account = Account.new(PATH)
	_client = AccountClient.new(_account, _server.send)


func after_each() -> void:
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_sign_in_stores_the_session() -> void:
	_server.on("POST", "auth/login", AccountFixtures.session("a@example.com", "acc1", "ref1"))
	var result := await _client.sign_in(" a@example.com ", "a-long-enough-password")
	assert_true(result["ok"])
	assert_true(_account.signed_in())
	assert_eq(_account.email, "a@example.com")
	assert_eq(_account.refresh_token, "ref1")
	assert_eq(_server.calls[0]["body"]["email"], "a@example.com", "the email is trimmed")


func test_wrong_password_says_so_and_stores_nothing() -> void:
	_server.on("POST", "auth/login", AccountFixtures.fail(401, "INVALID_CREDENTIALS"))
	var result := await _client.sign_in("a@example.com", "nope")
	assert_false(result["ok"])
	assert_eq(result["message"], "THE EMAIL OR PASSWORD IS INCORRECT")
	assert_false(_account.signed_in())


func test_register_reports_a_taken_email() -> void:
	_server.on("POST", "auth/register", AccountFixtures.fail(409, "EMAIL_TAKEN"))
	var result := await _client.register("a@example.com", "a-long-enough-password")
	assert_eq(result["message"], "AN ACCOUNT WITH THIS EMAIL ALREADY EXISTS")


func test_offline_sign_in_asks_to_try_again_online() -> void:
	_server.on("POST", "auth/login", AccountFixtures.offline())
	var result := await _client.sign_in("a@example.com", "a-long-enough-password")
	assert_false(result["ok"])
	assert_string_contains(result["message"], "NO CONNECTION")


func test_a_fresh_access_token_is_reused_without_refreshing() -> void:
	_server.on("POST", "auth/login", AccountFixtures.session("a@example.com", "acc1", "ref1"))
	_server.on("GET", "me/progress", AccountFixtures.ok({"completed": []}))
	await _client.sign_in("a@example.com", "a-long-enough-password")
	await _client.call_authed("GET", "me/progress")
	await _client.call_authed("GET", "me/progress")
	assert_eq(_server.count("auth/refresh"), 0)
	assert_eq(_server.calls[1]["bearer"], "acc1")


func test_an_expired_access_token_is_refreshed_and_the_refresh_token_rotates() -> void:
	_server.on("POST", "auth/login", AccountFixtures.session("a@example.com", "acc1", "ref1", 1))
	_server.on("POST", "auth/refresh", AccountFixtures.session("a@example.com", "acc2", "ref2"))
	_server.on("GET", "me/progress", AccountFixtures.ok({"completed": []}))
	await _client.sign_in("a@example.com", "a-long-enough-password")
	await _client.call_authed("GET", "me/progress")
	assert_eq(_server.count("auth/refresh"), 1)
	assert_eq(_server.calls[1]["body"]["refreshToken"], "ref1")
	assert_eq(_account.refresh_token, "ref2", "the new refresh token replaces the spent one")
	var again := Account.new(PATH)
	again.load_data()
	assert_eq(again.refresh_token, "ref2", "and it is on disk")


func _call_into(results: Array, index: int) -> void:
	results[index] = await _client.call_authed("GET", "me/progress")


func test_overlapping_calls_share_one_refresh_and_the_session_survives() -> void:
	_account.start("a@example.com", "ref1")
	var slow := AccountFixtures.session("a@example.com", "acc2", "ref2")
	slow["delay_frames"] = 3
	_server.on("POST", "auth/refresh", slow)
	_server.on("GET", "me/progress", AccountFixtures.ok({"completed": []}))
	# Both calls start in the same frame, so they overlap.
	var results: Array = [null, null]
	call_deferred("_call_into", results, 0)
	call_deferred("_call_into", results, 1)
	for i in 60:
		if results[0] != null and results[1] != null:
			break
		await get_tree().process_frame
	var one: Dictionary = results[0]
	var two: Dictionary = results[1]
	assert_true(one["ok"] and two["ok"], "both calls succeed")
	assert_eq(_server.count("auth/refresh"), 1, "the refresh token was spent exactly once")
	assert_true(_account.signed_in(), "the session was not destroyed by a second refresh")
	assert_eq(_account.refresh_token, "ref2")


func test_a_refresh_the_server_rejects_ends_the_session_here() -> void:
	_account.start("a@example.com", "ref1")
	_server.on("POST", "auth/refresh", AccountFixtures.fail(401, "INVALID_REFRESH_TOKEN"))
	var result := await _client.call_authed("GET", "me/progress")
	assert_false(result["ok"])
	assert_false(_account.signed_in())


func test_a_refresh_that_cannot_reach_the_server_keeps_the_session() -> void:
	_account.start("a@example.com", "ref1")
	_server.on("POST", "auth/refresh", AccountFixtures.offline())
	var result := await _client.call_authed("GET", "me/progress")
	assert_false(result["ok"])
	assert_eq(result["error"], "offline")
	assert_true(_account.signed_in(), "being offline must not sign the player out")


func test_a_401_on_a_call_refreshes_once_and_retries() -> void:
	_server.on("POST", "auth/login", AccountFixtures.session("a@example.com", "acc1", "ref1"))
	_server.on("POST", "auth/refresh", AccountFixtures.session("a@example.com", "acc2", "ref2"))
	_server.on("GET", "me/progress", AccountFixtures.fail(401, "UNAUTHORIZED"))
	_server.on("GET", "me/progress", AccountFixtures.ok({"completed": []}))
	await _client.sign_in("a@example.com", "a-long-enough-password")
	var result := await _client.call_authed("GET", "me/progress")
	assert_true(result["ok"])
	assert_eq(_server.count("auth/refresh"), 1)


func test_calls_while_signed_out_make_no_request() -> void:
	var result := await _client.call_authed("GET", "me/progress")
	assert_eq(result["error"], "signed_out")
	assert_eq(_server.calls.size(), 0)


func test_sign_out_forgets_the_session_even_when_offline() -> void:
	_account.start("a@example.com", "ref1")
	_server.on("POST", "auth/logout", AccountFixtures.offline())
	await _client.sign_out()
	assert_false(_account.signed_in())
	assert_eq(_server.count("auth/logout"), 1, "the server is told when it can be")


func test_deleting_the_account_needs_the_right_password() -> void:
	_server.on("POST", "auth/login", AccountFixtures.session("a@example.com", "acc1", "ref1"))
	_server.on("DELETE", "me", AccountFixtures.fail(422, "PASSWORD_INCORRECT"))
	_server.on("DELETE", "me", AccountFixtures.ok(null, 204))
	await _client.sign_in("a@example.com", "a-long-enough-password")
	var wrong := await _client.delete_account("wrong")
	assert_false(wrong["ok"])
	assert_eq(wrong["message"], "THE PASSWORD IS INCORRECT")
	assert_true(_account.signed_in(), "a failed delete keeps the session")
	var right := await _client.delete_account("a-long-enough-password")
	assert_true(right["ok"])
	assert_false(_account.signed_in())

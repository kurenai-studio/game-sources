extends GutTest
## The social client over a scripted server: paths, bodies, parsing, and error mapping.

const ACCOUNT_PATH := "user://test_social_account.json"

var _server: AccountFixtures
var _social: SocialClient
var _account: Account


func before_each() -> void:
	_server = AccountFixtures.new()
	_account = Account.new(ACCOUNT_PATH)
	_account.start("a@example.com", "ref1")
	_social = SocialClient.new(AccountClient.new(_account, _server.send))
	_server.on("POST", "auth/refresh", AccountFixtures.session("a@example.com", "acc1", "ref1b"))


func after_each() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(ACCOUNT_PATH + suffix):
			DirAccess.remove_absolute(ACCOUNT_PATH + suffix)


func _last() -> Dictionary:
	return _server.calls[_server.calls.size() - 1]


func test_board_paths() -> void:
	assert_eq(
		SocialClient.board_path("points", "week"),
		"leaderboards/points?period=week&limit=20&offset=0"
	)
	assert_eq(
		SocialClient.board_path("level", "around-the-wall", 20),
		"leaderboards/levels/around-the-wall?limit=20&offset=20"
	)
	assert_eq(
		SocialClient.board_path("daily", "2026-10-20"),
		"leaderboards/daily/2026-10-20?limit=20&offset=0"
	)
	assert_eq(SocialClient.board_path("points", "year"), "")
	assert_eq(SocialClient.board_path("level", "../me"), "")
	assert_eq(SocialClient.board_path("daily", "tomorrow"), "")


func test_profile_is_read_with_the_bearer_token() -> void:
	_server.on("GET", "me/profile", AccountFixtures.ok(SocialFixtures.profile()))
	var result := await _social.profile()
	assert_true(result["ok"])
	assert_eq(result["data"]["total"], 120)
	assert_eq(_last()["bearer"], "acc1")


func test_saving_sends_only_what_is_given_and_reports_a_taken_name() -> void:
	_server.on("PUT", "me/profile", AccountFixtures.fail(409, "NAME_TAKEN"))
	var result := await _social.save_profile({"displayName": "Marlo", "hideName": false})
	assert_false(result["ok"])
	assert_eq(result["message"], "THAT NAME IS TAKEN. CHOOSE ANOTHER")
	assert_eq(_last()["body"], {"displayName": "Marlo", "hideName": false})


func test_a_board_is_parsed_and_an_unreadable_one_is_an_error() -> void:
	var raw := {"total": 1, "entries": [SocialFixtures.entry(1, "Ines")], "me": null}
	_server.on("GET", "leaderboards/points?period=all&limit=20&offset=0", AccountFixtures.ok(raw))
	var result := await _social.board("points", "all")
	assert_eq(result["data"]["entries"].size(), 1)
	_server.on(
		"GET", "leaderboards/daily/2026-10-20?limit=20&offset=0", AccountFixtures.ok({"nope": 1})
	)
	result = await _social.board("daily", "2026-10-20")
	assert_false(result["ok"])
	assert_eq(result["error"], "parse")


func test_an_invalid_board_makes_no_request() -> void:
	var result := await _social.board("level", "Bad Slug")
	assert_false(result["ok"])
	assert_eq(_server.calls.size(), 0)


func test_report_and_share_bodies() -> void:
	_server.on("POST", "leaderboards/report", AccountFixtures.ok({}, 201))
	var reported := await _social.report("p-9")
	assert_true(reported["ok"])
	assert_eq(_last()["body"]["publicId"], "p-9")
	assert_gt(str(_last()["body"]["reason"]).length(), 2)
	_server.on("POST", "me/share", AccountFixtures.ok({"code": "abcd1234", "path": "/s/abcd1234"}))
	var shared := await _social.share("daily-elm", "2026-10-20")
	assert_eq(_last()["body"], {"kind": "daily", "levelSlug": "daily-elm", "date": "2026-10-20"})
	assert_eq(shared["data"]["code"], "abcd1234")
	await _social.share("stairs")
	assert_eq(_last()["body"], {"kind": "level", "levelSlug": "stairs"})


func test_share_without_a_result_and_offline_are_plain_errors() -> void:
	_server.on("POST", "me/share", AccountFixtures.fail(409, "NO_RESULT"))
	var refused := await _social.share("stairs")
	assert_true(refused["message"].contains("NO SOLVED RESULT"))
	_server.routes.erase("POST me/share")
	_server.on("POST", "me/share", AccountFixtures.offline())
	var lost := await _social.share("stairs")
	assert_eq(lost["error"], "offline")


func test_signed_out_makes_no_request() -> void:
	_account.clear()
	var result := await _social.achievements()
	assert_false(result["ok"])
	assert_eq(result["error"], "signed_out")
	assert_eq(_server.calls.size(), 0)

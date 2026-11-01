extends GutTest
## Reading the social answers and wording their errors.


func test_profile_with_and_without_a_name_or_next_rank() -> void:
	var parsed := SocialParse.profile(SocialFixtures.profile("Marlo"))
	assert_eq(parsed["displayName"], "Marlo")
	assert_eq(parsed["rank"]["next"], {"name": "Tinkerer", "at": 200})
	var raw := SocialFixtures.profile(null, false)
	raw["rank"]["next"] = null
	parsed = SocialParse.profile(raw)
	assert_eq(parsed["displayName"], "")
	assert_false(parsed["optIn"])
	assert_true(parsed["rank"]["next"].is_empty())


func test_malformed_answers_parse_to_nothing() -> void:
	assert_eq(SocialParse.profile(null), {})
	assert_eq(SocialParse.profile({"rank": 3}), {})
	assert_eq(SocialParse.board({"entries": [{"name": "x"}]}), {})
	assert_eq(SocialParse.board([]), {})
	assert_eq(SocialParse.achievements({"items": [1]}), {})
	assert_eq(SocialParse.daily({"serverDate": "yesterday"}), {})
	assert_eq(SocialParse.share({"path": "/s/x"}), {})


func test_board_entries_and_the_players_place() -> void:
	var mine := SocialFixtures.entry(27, "Marlo", true)
	var raw := {
		"total": 48,
		"entries": [SocialFixtures.entry(1, "Ines")],
		"me": {"entry": mine, "around": [SocialFixtures.entry(26, "Kay"), mine]},
	}
	var parsed := SocialParse.board(raw)
	assert_eq(parsed["total"], 48)
	assert_eq(parsed["entries"][0]["points"], 99)
	assert_true(parsed["me"]["entry"]["you"])
	assert_eq(parsed["me"]["around"].size(), 2)
	raw["me"] = null
	assert_true(SocialParse.board(raw)["me"].is_empty())


func test_level_and_daily_board_rows_carry_slots_and_steps() -> void:
	var raw := {
		"total": 1,
		"entries": [{"rank": 1, "publicId": "a", "name": "X", "slots": 7, "steps": 9, "you": false}]
	}
	var row: Dictionary = SocialParse.board(raw)["entries"][0]
	assert_eq([row["slots"], row["steps"]], [7, 9])
	assert_false(row.has("points"))


func test_achievements_mark_earned_and_locked() -> void:
	var raw := {
		"items":
		[
			{"slug": "a", "title": "A", "description": "d", "earnedAt": "2026-10-19T10:00:00.000Z"},
			{"slug": "b", "title": "B", "description": "e", "earnedAt": null},
		]
	}
	var items: Array = SocialParse.achievements(raw)["items"]
	assert_eq(items[0]["earnedAt"], "2026-10-19T10:00:00.000Z")
	assert_eq(items[1]["earnedAt"], "")


func test_daily_schedule_lists_today_first_and_drops_bad_days() -> void:
	var raw := SocialFixtures.schedule("2026-10-20")
	raw["upcoming"].append({"date": "bad", "levelSlug": "x"})
	var parsed := SocialParse.daily(raw)
	assert_eq(parsed["serverDate"], "2026-10-20")
	assert_eq(parsed["days"].size(), 4)
	assert_eq(parsed["days"][0]["date"], "2026-10-20")


func test_my_daily_result_and_streak() -> void:
	var raw := {"date": "d", "levelSlug": "s", "result": null, "streak": {"current": 2, "best": 4}}
	var parsed := SocialParse.daily_me(raw)
	assert_true(parsed["result"].is_empty())
	assert_eq(parsed["streak"], {"current": 2, "best": 4})
	raw["result"] = {"slots": 7, "steps": 9, "stars": 3}
	assert_eq(SocialParse.daily_me(raw)["result"]["stars"], 3)


func test_error_messages_use_the_servers_reason_for_names() -> void:
	var failed := AccountFixtures.fail(422, "NAME_NOT_ALLOWED")
	failed["json"]["message"] = "That name is not allowed."
	assert_eq(SocialParse.message(failed), "THAT NAME IS NOT ALLOWED")
	assert_eq(
		SocialParse.message(AccountFixtures.fail(409, "NAME_TAKEN")),
		"THAT NAME IS TAKEN. CHOOSE ANOTHER"
	)
	var bare := {"status": 422, "json": {"code": "NAME_REQUIRED"}, "error": "http"}
	assert_true(SocialParse.message(bare).contains("HIDE YOUR NAME"))
	assert_true(
		SocialParse.message(AccountFixtures.fail(409, "NO_RESULT")).contains("NO SOLVED RESULT")
	)
	assert_true(
		SocialParse.message(AccountFixtures.fail(404, "NOT_FOUND")).contains("NOT AVAILABLE")
	)
	assert_true(SocialParse.message(AccountFixtures.offline()).contains("NO CONNECTION"))

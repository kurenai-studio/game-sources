extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func near(a: float, b: float, tolerance: float = 0.000001) -> bool:
	return absf(a - b) < tolerance

func _initialize() -> void:
	var required := ["random_stream", "race_engine", "track_geometry", "odds_model"]
	for module in required:
		check(ResourceLoader.exists("res://core/" + module + ".gd"), "required module: " + module)
	if not failures.is_empty():
		finish()
		return
	test_racing()
	test_geometry()
	test_odds()
	test_accounts()
	test_settings()
	test_persistence()
	finish()

func finish() -> void:
	print("CHECKS: %d | FAILURES: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func test_racing() -> void:
	var engine = load("res://core/race_engine.gd")
	var a = engine.new(12345)
	var b = engine.new(12345)
	var c = engine.new(98765)
	check(a.run() == b.run(), "same seed yields identical result and timing")
	check(a.snapshot() != c.run(), "different seeds produce different races")
	for seed_value in range(1, 21):
		var race = engine.new(seed_value)
		var previous: Dictionary = race.snapshot()
		while not race.finished:
			race.advance_event()
			var current: Dictionary = race.snapshot()
			check(current.positions.size() == 5, "exactly five horses")
			var changed := 0
			for horse in range(5):
				check(current.positions[horse] > previous.positions[horse], "every horse moves every event")
				var difference: int = absi(current.levels[horse] - previous.levels[horse])
				check(difference <= 1, "speed transitions are adjacent")
				changed += int(difference > 0)
			check(changed <= 1, "at most one speed changes in an event")
			previous = current
		var result: Dictionary = race.result()
		check(result.first != result.second, "distinct first and second")
		check(result.first_time <= result.second_time, "crossing times ordered")
		check(near(result.positions[result.second], 1000.0), "snapshot frozen exactly at second crossing")
		var post: Array = race.post_positions(8.5)
		for rank in range(2):
			var h1: int = result.order[rank]
			var h2: int = result.order[rank + 1]
			check(near(post[h1] - post[h2], result.positions[h1] - result.positions[h2]), "top three gaps frozen")
		for horse in result.order.slice(3):
			check(post[horse] < post[result.order[2]], "trailing horses cannot overtake top three")
		var events: Array = race.replay_events()
		check(events.size() == 10, "recorded ten-event replay window")
		check(events.back().end_positions == result.positions, "replay ends at actual second crossing")
		var original := result.duplicate(true)
		result.positions[0] = -9
		race.advance_event()
		check(race.result() == original, "returned result cannot mutate official outcome")
	# Deterministic constant-speed fixture proves sub-event timing, not frame order.
	var exact = engine.new(5, {"finish_steps": 10.0, "speeds": [1.0, 2.0, 3.0, 4.0, 5.0], "initial_levels": [4, 3, 2, 1, 0], "adjustment_chance": 0.0})
	var result: Dictionary = exact.run()
	check(near(result.first_time, 2.0), "winner crossing interpolated")
	check(near(result.second_time, 2.5), "second crossing interpolated within event")
	check(near(result.positions[2], 7.5), "third position evaluated at second crossing")
	check(near(result.margin, 2.5), "photo margin is exact logical gap")
	check(near(exact.post_positions(3.0)[1] - exact.post_positions(3.0)[2], 2.5), "post-finish cannot erase third-place gap")

func test_geometry() -> void:
	var geometry = load("res://core/track_geometry.gd").new()
	for progress in [0.0, 0.13, 0.25, 0.39, 0.5, 0.66, 0.75, 0.91, 1.0]:
		var inner: Vector2 = geometry.point(progress, 0)
		var outer: Vector2 = geometry.point(progress, 4)
		check(near(inner.distance_to(outer), 4.0 * geometry.lane_width, 0.001), "lane spacing independent of progress")
	check(geometry.point(0.0, 0).is_equal_approx(geometry.point(1.0, 0)), "closed oval path")
	check(geometry.lane_length(4) > geometry.lane_length(0), "outer path physically longer")
	check(near(geometry.point(0.1, 0).x, geometry.point(0.1, 4).x), "straight alignment")
	var center: Vector2 = geometry.curve_center(0.35)
	var radius1: Vector2 = geometry.point(0.35, 0) - center
	var radius2: Vector2 = geometry.point(0.35, 4) - center
	check(near(radius1.normalized().dot(radius2.normalized()), 1.0), "radial alignment on bends")

func test_odds() -> void:
	var odds = load("res://core/odds_model.gd").new()
	var targets: Dictionary = odds.targets()
	check(targets.ordered.size() == 20, "twenty ordered target outcomes")
	check(targets.pairs.size() == 10, "ten unordered target outcomes")
	var pair_sum := 0.0
	for probability in targets.pairs.values():
		pair_sum += probability
	check(near(pair_sum, 1.0), "pair targets sum to one")
	for horse in range(5):
		var first_sum := 0.0
		for second in range(5):
			if horse != second:
				first_sum += targets.ordered["%d-%d" % [horse + 1, second + 1]]
		check(near(first_sum, [0.35,0.27,0.20,0.13,0.05][horse]), "ordered targets reproduce first-place targets")
	var board: Dictionary = odds.board(90, [4,3,2,1,0])
	check(board.payouts.size() == 10, "all ten payouts present")
	check(board.calibrated == false, "no calibration claim")
	check(near(board.pair_targets["4-5"], targets.pairs["1-2"]), "whole horse permutation remaps pair targets")
	for payout in board.payouts.values():
		check(payout >= 2 and payout <= 200, "integer payout range")
	check(odds.encoded_version(90, false) == "V2.109054", "factory encoded version")
	check(odds.encoded_version(125, true) == "V2.212554", "custom encoded version")

func test_accounts() -> void:
	if not ResourceLoader.exists("res://core/game_session.gd"):
		check(false, "account state machine exists")
		return
	var session = load("res://core/game_session.gd").new()
	check(session.players.size() == 8, "eight independent player stations")
	check(not session.can_start(), "no READY account cannot start")
	check(session.configure_pins("1234", "4321"), "separate operator and RTP PIN setup")
	check(not session.authorize("operator", "4321"), "RTP PIN cannot authorize operator")
	check(not session.adjust_balance(0, 20, "set", "wrong"), "wrong PIN cannot add credits")
	check(session.adjust_balance(0, 20, "set", "1234"), "operator credits account")
	var audit_before: int = session.audit.size()
	session.rename_player(0,"Player 1")
	check(session.audit.size() == audit_before,"unchanged nickname is not meaningful activity")
	check(not session.edit_bet(0,"1-2",21), "pair maximum is 20")
	check(not session.edit_bet(0,"1-1",1), "invalid pair rejected")
	check(not session.edit_bet(0,"1-2",1.5), "fractional credits rejected")
	check(session.edit_bet(0,"1-2",20), "all-in wager accepted")
	check(session.available(0) == 0, "stake reserved")
	check(not session.edit_bet(0,"1-3",1), "overdraft rejected")
	check(session.set_ready(0,true), "all-in player can be ready")
	check(session.can_start(), "READY plus seven OUT can start")
	check(session.edit_bet(0,"1-2",10), "ready wager editable before lock")
	check(session.players[0].state == "BETTING", "editing wager clears READY")
	check(session.available(0) == 10, "changed stake released")
	check(session.set_ready(0,true), "ready again")
	var result: Dictionary = load("res://core/race_engine.gd").new(100).run()
	check(not session.finish_race(result), "cannot finish without start")
	check(session.start_race(100), "manual race start locks round")
	result = session.create_visual_race().run()
	check(not session.edit_bet(0,"1-2",0), "locked wager immutable")
	check(not session.adjust_balance(0,10,"add","1234"), "operator blocked during race")
	check(session.finish_race(result), "accept own seeded race result")
	check(session.phase == "RESULTS", "results gate")
	check(session.players[0].balance == 10, "no payment before announcement")
	check(not session.adjust_balance(0,10,"add","1234"), "operator blocked during results")
	check(session.announce_result(), "announced result pays once")
	var balance_after: int = session.players[0].balance
	check(not session.announce_result(), "duplicate announcement cannot pay twice")
	check(session.players[0].balance == balance_after, "no duplicate credit")
	check(session.next_round(), "next round after settlement")
	check(session.adjust_balance(1,40,"set","1234"), "second player funded")
	check(session.edit_bet(1,"2-3",8), "wager before cash-out")
	check(session.request_cash_out(1), "cash-out request separate from confirmation")
	check(session.players[1].state != "PENDING PAYOUT", "request alone does not freeze")
	check(session.confirm_cash_out(1), "cash-out confirmed")
	check(session.players[1].pending == 40, "cash-out cancels unlocked wagers and reserves full balance")
	check(not session.edit_bet(1,"1-2",1), "pending payout freezes player")
	check(not session.adjust_balance(1,20,"set","1234"), "operator cannot adjust frozen account")
	check(not session.resolve_cash_out(1,true,"4321"), "settlement requires operator PIN")
	check(session.resolve_cash_out(1,false,"1234"), "operator can cancel pending settlement")
	check(session.players[1].balance == 40, "cancel retains credits")
	check(not session.confirm_cash_out(1), "old confirmation cannot be reused")
	check(session.request_cash_out(1) and session.confirm_cash_out(1), "request again")
	check(session.resolve_cash_out(1,true,"1234"), "operator completes virtual settlement")
	check(session.players[1].balance == 0 and session.players[1].state == "OUT", "settled account is OUT")
	check(session.audit.size() > 10, "adjustments bets wins and settlements audited")
	check(session.validate_state().is_empty(), "accounts and audit reconcile")
	var capacity = load("res://core/game_session.gd").new()
	capacity.configure_pins("1234","4321")
	capacity.adjust_balance(0,capacity.MAX_BALANCE,"set","1234")
	check(not capacity.edit_bet(0,"1-2",20),"reject stake whose possible win exceeds balance capacity")
	capacity.adjust_balance(0,100,"set","1234")
	capacity.edit_bet(0,"1-2",20)
	check(not capacity.adjust_balance(0,capacity.MAX_BALANCE,"set","1234"),"operator cannot create potential settlement overflow")

func test_settings() -> void:
	if not ResourceLoader.exists("res://core/game_settings.gd"):
		check(false, "customization settings model exists")
		return
	var settings = load("res://core/game_settings.gd").new()
	check(settings.catalog.size() >= 60, "broad customization catalog")
	check(settings.set_value("race_seconds", 45.0), "race playback adjustable")
	check(not settings.set_value("race_seconds", -2), "invalid duration rejected")
	check(not settings.set_value("horse_count", 6), "core five-horse rule protected")
	check(not settings.set_value("rtp", 200), "RTP absent from general settings")
	check(settings.set_value("race_mute", true), "independent race announcer mute")
	check(not settings.values.house_mute, "house announcer independent")
	check(settings.save_profile("Quiet"), "save named profile")
	check(settings.set_value("race_mute", false), "change saved setting")
	check(settings.load_profile("Quiet") and settings.values.race_mute, "restore profile")
	settings.reset_category("Audio")
	check(not settings.values.race_mute, "category reset")
	check(settings.export_data().profiles.has("Quiet"), "profiles persist in export")
	for method in ["rename_profile","export_profile","import_profile","delete_profile"]:
		check(settings.has_method(method),"profile operation exists: " + method)
	if not settings.has_method("rename_profile"):
		return
	check(settings.rename_profile("Quiet","Evening"),"rename settings profile")
	check(not settings.profiles.has("Quiet") and settings.profiles.has("Evening"),"profile renamed without duplication")
	var exported: Dictionary = settings.export_profile("Evening")
	check(not exported.has("credentials") and not exported.has("players"),"profile export excludes account credentials and balances")
	check(settings.import_profile("Imported",exported),"import validated profile")
	check(settings.delete_profile("Imported") and not settings.profiles.has("Imported"),"delete profile")
	var before: Dictionary = settings.export_data()
	var broken := before.duplicate(true)
	broken.values.race_seconds = 81.0
	broken.profiles["Broken"] = {"race_seconds":900.0}
	check(not settings.restore(broken),"malformed profile collection rejected")
	check(settings.export_data() == before,"failed settings import leaves all current preferences unchanged")
	var unknown: Dictionary = before.values.duplicate(true)
	unknown["rtp"] = 200
	check(not settings.import_values(unknown),"general settings cannot import unknown protected parameters")

func test_persistence() -> void:
	if not ResourceLoader.exists("res://core/session_store.gd"):
		check(false,"transactional session store exists")
		return
	var store = load("res://core/session_store.gd").new()
	var game = load("res://core/game_session.gd").new()
	var settings = load("res://core/game_settings.gd").new()
	game.configure_pins("1234","4321")
	game.adjust_balance(0,100,"set","1234")
	game.edit_bet(0,"1-2",12)
	settings.set_value("race_seconds",44.0)
	settings.save_profile("Test")
	var path := "user://persistence-test.json"
	check(store.save(game,settings,path),"save audited balances and preferences")
	var loaded: Dictionary = store.load_session(path)
	check(loaded.ok,"valid save loads")
	if not loaded.ok:
		return
	check(loaded.session.players == game.players,"accounts round-trip without numeric conversion")
	check(loaded.settings.values.race_seconds == 44.0,"settings round-trip")
	check(loaded.settings.profiles.has("Test"),"profiles round-trip")
	game.set_ready(0,true)
	game.start_race(91)
	check(store.save(game,settings,path),"save locked round")
	var injected: Dictionary = game.export_data()
	injected.players[0].bets["1-2"] = 20
	injected.locked_bets[0]["1-2"] = 20
	check(not load("res://core/game_session.gd").new().restore(injected),"recovery cannot refund wagers that were never debited")
	loaded = store.load_session(path)
	check(loaded.ok,"interrupted race recovered")
	check(loaded.session.players[0].balance == 100,"interrupted locked stake refunded")
	check(loaded.session.players[0].bets.is_empty(),"interrupted wagers cleared")
	check(loaded.session.phase == "BETTING","recovery opens next round")
	check(store.save(loaded.session,loaded.settings,path),"recovery persisted")
	var recovered: Dictionary = store.load_session(path)
	check(recovered.session.players[0].balance == 100,"reload cannot refund twice")
	var original: Dictionary = recovered.session.export_data()
	var bad := original.duplicate(true)
	bad.players[0].balance += 1
	check(not load("res://core/game_session.gd").new().restore(bad),"unlogged credit injection rejected")
	bad = original.duplicate(true)
	bad.board.payouts["1-2"] = 999
	check(not load("res://core/game_session.gd").new().restore(bad),"tampered payout board rejected")
	check(not load("res://core/game_session.gd").new().restore({"schema":1,"players":[],"audit":[],"board":{}}),"malformed state safely rejected")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("damaged file")
	file.close()
	loaded = store.load_session(path)
	check(not loaded.ok,"corruption blocks play instead of silently rolling accounts back")
	check(FileAccess.file_exists(path+".bak"),"previous snapshot retained for explicit recovery")

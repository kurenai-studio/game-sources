extends SceneTree

var failures := 0
var checks := 0
const Access = preload("res://core/operator_access.gd")
const Session = preload("res://core/game_session.gd")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var access = Access.new()
	check(access.valid_pin("0042"), "four-digit PIN retains leading zeroes")
	for invalid in ["", "123", "12345", "12a4", " 1234", "1234 "]:
		check(not access.valid_pin(invalid), "reject invalid new PIN: " + invalid)
	if not access.has_method("set_pin") or not ResourceLoader.exists("res://core/player_identity.gd"):
		check(false, "new credential and identity support available")
		finish()
		return
	check(access.set_pin("operator", "0042"), "set four-digit manager credential")
	check(access.verify("operator", "0042"), "authenticate four-digit credential")
	check(not access.verify("operator", "0043"), "wrong credential rejected")
	check(not access.set_pin("operator", "999"), "invalid reset cannot destroy credential")
	check(access.verify("operator", "0042"), "old credential retained after invalid reset")
	var salt = PackedByteArray([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
	access.credentials.operator = {"salt":salt.hex_encode(), "hash":access.derive("913247",salt).hex_encode(), "iterations":Access.ITERATIONS}
	check(access.verify("operator", "913247"), "legacy six-digit credential still unlocks for migration")
	check(access.set_pin("operator", "4321"), "legacy credential can migrate")
	check(not access.verify("operator", "913247") and access.verify("operator", "4321"), "only replacement works after migration")
	var identity = load("res://core/player_identity.gd")
	var profiles: Array = identity.defaults()
	check(profiles.size() == 8 and identity.validate(profiles).is_empty(), "eight valid distinct player identities")
	profiles[4].color = profiles[3].color
	check(not identity.validate(profiles).is_empty(), "duplicate player colors rejected")
	var game = Session.new()
	check(game.configure_pins("1234", "4321"), "new session setup")
	check(game.adjust_balance(3,123,"set","1234"), "fund existing player")
	check(game.edit_bet(3,"1-2",7), "reserve existing wager")
	var old: Dictionary = game.export_data()
	old.schema = 1
	old.board=load("res://core/odds_model.gd").new().board(90)
	for key in ["player_profiles", "manager_only_start", "start_countdown", "next_rtp", "deck_mode", "next_deck_mode", "card_history"]:
		old.erase(key)
	var migrated = Session.new()
	check(migrated.restore(old), "legacy account snapshot migrates")
	check(migrated.players[3].balance == 123 and migrated.wager_total(3) == 7, "migration preserves balance and reserved bets")
	check(identity.validate(migrated.player_profiles).is_empty(), "migration provides distinct identities")
	var restored = Session.new()
	check(restored.restore(migrated.export_data()), "new schema round trip")
	check(restored.player_profiles == migrated.player_profiles, "identities remain stable after reload")
	var image := Image.create(320,80,false,Image.FORMAT_RGBA8)
	image.fill(Color("ff4400"))
	var image_path := "user://avatar-fixture-%d.png" % OS.get_process_id()
	check(image.save_png(image_path) == OK,"create avatar upload fixture")
	var upload: Dictionary = identity.image_from_file(image_path)
	check(upload.ok,"avatar upload accepted")
	if upload.ok:
		var normalized: Image = identity.decode_image(upload.image)
		check(normalized != null and normalized.get_size() == Vector2i(128,32),"avatar resized without changing proportions")
		restored.player_profiles[3].image = upload.image
		var with_avatar = Session.new()
		check(with_avatar.restore(restored.export_data()) and with_avatar.player_profiles[3].image == upload.image,"uploaded avatar survives session reload")
	check(identity.decode_image("not-a-png") == null,"invalid avatar payload rejected")
	DirAccess.remove_absolute(image_path)
	check(restored.set_out(3), "funded player can sit out")
	check(restored.players[3].state == "OUT" and restored.wager_total(3) == 0 and restored.players[3].balance == 123, "Out releases reservations without changing credits")
	var funded = Session.new()
	check(funded.fund_demo(), "first launch can fund virtual balances")
	check(not funded.fund_demo(), "demo grant cannot repeat")
	check(funded.players[0].balance == 100 and funded.validate_state().is_empty(), "initial credits are audited")
	flow_checks()
	finish()

func flow_checks() -> void:
	if not ResourceLoader.exists("res://core/player_flow.gd"):
		check(false,"player interaction controller is available")
		return
	var game = Session.new()
	game.fund_demo()
	game.access.set_pin("operator","1234")
	game.access.set_pin("player_3","4444")
	game.edit_bet(3,"1-2",5)
	game.set_ready(3,true)
	var settings = load("res://core/game_settings.gd").new()
	var flow = load("res://core/player_flow.gd").new(game,settings)
	check(flow.select_player(3) and flow.screen == "pin", "Player 4 selection requests its PIN")
	check(game.players[3].state == "READY", "prompt alone preserves readiness")
	flow.back()
	check(flow.screen == "overview" and game.players[3].state == "READY", "Back preserves readiness")
	check(flow.select_player(5) and flow.screen == "betting", "Player 6 without PIN opens its console")
	flow.ready()
	flow.select_player(3)
	check(not flow.enter_pin("0000") and flow.screen == "pin", "wrong PIN cannot edit wagers")
	check(not flow.begin_settings("0000") and not flow.settings_open, "incorrect manager PIN cannot enter settings")
	check(flow.begin_settings("1234") and flow.settings_player == 3, "settings recognizes Player 4's prompt")
	flow.drafts[3].pin = "0042"
	flow.drafts[3].confirm = "0043"
	flow.drafts[3].nickname = "Avery"
	var board: Dictionary = game.board.duplicate(true)
	check(not flow.finish_settings(), "mismatched PIN prevents return")
	check(game.players[3].nickname == "Player 4" and game.access.verify("player_3","4444"), "invalid settings commit is atomic")
	flow.drafts[3].confirm = "0042"
	settings.set_value("race_mute",true)
	check(flow.finish_settings(), "matching replacement permits return")
	check(flow.screen == "pin" and flow.active_player == 3, "return remains at Player 4 despite other settings")
	check(game.players[3].nickname == "Avery" and game.players[3].state == "READY", "identity edit preserves Ready")
	check(game.board == board and game.wager_total(3) == 5 and game.players[3].balance == 100, "recovery preserves current round and money")
	check(flow.enter_pin("0042") and flow.screen == "betting" and game.players[3].state == "BETTING", "new PIN opens console and clears Ready")
	flow.begin_settings("1234")
	check(flow.settings_player == -1, "settings from console opens home")
	flow.drafts[3].profile.color = 0
	check(not flow.finish_settings(), "occupied color cannot be assigned")
	settings.set_value("race_mute",false)
	flow.revert_settings()
	check(settings.values.race_mute and flow.drafts[3].profile.color == 3, "Revert restores entry preferences and identity")
	check(flow.finish_settings() and flow.screen == "betting", "general settings returns to prior console")
	flow.ready()
	for i in range(8):
		game.set_ready(i,true)
	check(flow.can_start(), "all ready enables start")
	flow.begin_settings("1234")
	check(not flow.can_start(), "settings blocks starting")
	flow.manager_pins.start = {"pin":"5678","confirm":"5678","remove":false}
	flow.manager_only = true
	check(flow.finish_settings(), "manager-only setting and start PIN commit together")
	check(not flow.authorize_start("0000"), "wrong Start PIN cannot start")
	check(flow.authorize_start("5678"), "correct Start PIN authorizes")
	check(not flow.authorize_start(""), "Start permission not cached")
	flow.begin_settings("1234")
	flow.drafts[3].pin = "9999"
	flow.drafts[3].confirm = "9999"
	flow.revert_settings()
	flow.finish_settings()
	check(game.access.verify("player_3","0042"), "Revert cancels pending PIN replacement")
	game.set_rtp(85,"4321") # Unconfigured payout credential must reject.
	check(game.board == board,"unauthorized payout edit cannot change card")
	game.access.set_pin("rtp","4321")
	check(game.set_rtp(85,"4321") and game.board == board, "authorized payback queues without repricing open card")
	check(game.start_race(42), "ready game starts after flow approval")
	game.finish_race(game._race.run())
	game.announce_result()
	game.next_round()
	check(game.board.requested_rtp == 85, "queued payback applies to next card")

func finish() -> void:
	print("PLAYER FLOW: %s | %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

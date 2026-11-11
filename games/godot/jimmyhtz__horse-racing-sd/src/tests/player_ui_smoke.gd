extends SceneTree
var failed := false

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func node(app: Node, named: String) -> Node:
	return app.find_child(named,true,false)

func run() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://player-ui-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	await process_frame
	check(node(app,"PlayerSummary3") != null,"eight right-side summaries replace pair-first menu")
	if node(app,"PlayerSummary3") == null:
		app.queue_free()
		await process_frame
		print("PLAYER UI: FAIL")
		quit(1)
		return
	check(app.session.players[0].balance == 100,"fresh launch has demonstration credits without PIN setup")
	check(app.session.access.credentials.is_empty(),"fresh launch does not require PINs")
	check(node(app,"SummaryAvatar3") != null,"player summaries display identity avatars")
	for i in range(8):
		app.session.set_out(i)
	app.show_betting()
	check(node(app,"ReadyLight").text == "ALL PLAYERS READY OR OUT" and node(app,"StartRace").disabled,"all Out lights readiness but cannot start an empty race")
	node(app,"PlayerSummary3").pressed.emit()
	await process_frame
	check(app.flow.active_player == 3 and app.flow.screen == "betting","right Player 4 opens its left console")
	check(app.find_children("Wager_*","SpinBox",true,false).size() == 10,"one player's ten combination controls")
	node(app,"Wager_1_2").value = 5
	await process_frame
	await process_frame
	check(app.session.wager_total(3) == 5,"wager belongs to selected player")
	node(app,"PlayerReady").pressed.emit()
	await process_frame
	check(app.session.players[3].state == "READY" and app.flow.active_player == -1,"Ready closes left panel")
	app.session.access.set_pin("operator","1234")
	app.session.access.set_pin("player_3","4444")
	app.select_player(3)
	await process_frame
	check(node(app,"PlayerPin").secret,"player PIN is masked")
	check(app.session.players[3].state == "READY","PIN prompt preserves Ready")
	await capture("player-pin")
	node(app,"PlayerBack").pressed.emit()
	await process_frame
	check(app.flow.screen == "overview" and app.session.players[3].state == "READY","Back changes no readiness")
	app.select_player(3)
	app.show_settings()
	await process_frame
	check(node(app,"SettingsPin") != null and node(app,"SettingsPin").secret,"settings requires masked manager PIN")
	type_text(app,"SettingsPin","1234")
	node(app,"SettingsUnlock").confirmed.emit()
	await process_frame
	await process_frame
	check(app.flow.settings_open and app.flow.settings_player == 3,"context opens Player 4 settings")
	check(node(app,"NewPin3").has_focus(),"new Player 4 PIN field initially focused")
	type_text(app,"NewPin3","0042")
	type_text(app,"ConfirmPin3","0043")
	type_text(app,"PlayerName3","Avery")
	app.settings_panel.return_to_game()
	check(app.flow.settings_open and app.session.players[3].nickname == "Player 4","invalid form stays open without partial commit")
	# Window close/Escape hides the dialog before delivering canceled.
	app.settings_panel.hide()
	app.settings_panel.canceled.emit()
	await process_frame
	await process_frame
	check(app.flow.settings_open and app.settings_panel.visible,"closing invalid settings cannot discard validation or unlock the game")
	type_text(app,"NewPin3","0042")
	type_text(app,"ConfirmPin3","0042")
	app.settings_panel.navigate(3)
	app.preferences.set_value("race_mute",true)
	app.settings_panel.return_to_game()
	await process_frame
	await process_frame
	check(app.flow.screen == "pin" and app.flow.active_player == 3,"other settings pages retain Player 4 return")
	check(node(app,"PlayerPin").text.is_empty() and node(app,"PlayerPin").has_focus(),"normal PIN prompt empty and focused on return")
	type_text(app,"PlayerPin","0042")
	await process_frame
	check(app.flow.screen == "betting" and app.session.players[3].nickname == "Avery","replacement PIN opens named player's console")
	check(app.session.wager_total(3) == 5 and app.session.players[3].balance == 100,"recovery preserves bets and balance")
	app.change_bet(2,"1-2",9)
	check(app.session.wager_total(2) == 0,"stale callback cannot wager for another player")
	await capture("player-console")
	app.flow.ready()
	for i in range(8):
		app.session.set_ready(i,true)
	app.session.access.set_pin("start","5678")
	app.session.manager_only_start = true
	app.show_betting()
	node(app,"StartRace").pressed.emit()
	await process_frame
	check(app.flow.screen == "start_pin" and app.session.phase == "BETTING","manager-only button requests Start PIN")
	type_text(app,"StartPin","5678")
	await process_frame
	check(app.display_phase == "RACING","fourth correct Start digit starts immediately")
	app.change_bet(3,"1-2",9)
	check(app.session.wager_total(3) == 5,"delayed callback cannot alter locked wagers")
	app._process(130.0)
	app._process(4.0)
	app._process(100.0)
	app._process(20.0)
	check(app.session.phase == "SETTLED" and not app.blocked,"race settles with valid persistence")
	check(app.session.validate_state().is_empty(),"player UI accounting reconciles")
	app.session.next_round()
	var avatar_image := Image.create(128,32,false,Image.FORMAT_RGBA8)
	avatar_image.fill(Color("f0ac4f"))
	app.session.player_profiles[0].image = Marshalls.raw_to_base64(avatar_image.save_png_to_buffer())
	app.flow.screen = "overview"
	app.show_betting()
	app.select_player(0)
	app.preferences.set_value("ui_scale",1.75)
	app.preferences.set_value("large_text",true)
	app.preferences.set_value("resolution","1280 x 720")
	app.apply_settings()
	app.show_betting()
	await process_frame
	await capture("player-console-large")
	check(node(app,"BettingMini3").get_child(0).text.begins_with("WIN %d " % app.session.race_logs.back().accounting[3]),"previous-win preference displays settled return")
	app.preferences.set_value("show_last_win",false)
	app.preferences.set_value("ready_highlight",false)
	app.flow.ready()
	app.show_betting()
	check(not node(app,"BettingMini3").get_child(0).text.begins_with("WIN "),"previous-win display can be hidden")
	check(node(app,"PlayerSummary0").get_theme_stylebox("normal").border_width_left == 2,"ready highlight can be disabled")
	app.preferences.set_value("ready_highlight",true)
	app.show_betting()
	check(node(app,"PlayerSummary0").get_theme_stylebox("normal").border_width_left == 4,"ready highlight can be enabled")
	app.show_settings()
	await process_frame
	type_text(app,"SettingsPin","1234")
	node(app,"SettingsUnlock").confirmed.emit()
	await process_frame
	check(app.flow.settings_player == -1,"settings from console starts at home")
	app.settings_panel.navigate(1)
	await process_frame
	await capture("players-settings-large")
	check(app.find_children("NewPin*","LineEdit",true,false).size() == 8,"eight player PIN blocks")
	app.settings_panel.return_to_game()
	app.save_state()
	check(app.storage.load_session(app.save_path).ok,"new player data reloads")
	app.queue_free()
	await process_frame
	await process_frame
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0,"UI releases all nodes")
	print("PLAYER UI: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func capture(caption: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	DirAccess.make_dir_recursive_absolute("res://test-results")
	check(root.get_texture().get_image().save_png("res://test-results/"+caption+".png") == OK,"capture "+caption)

func type_text(app: Node, field_name: String, value: String) -> void:
	var field: LineEdit = node(app,field_name)
	field.text = value
	# Assignment alone does not emit LineEdit's user-edit signal.
	field.text_changed.emit(value)

func label_text(parent: Node) -> String:
	var result := ""
	for label in parent.find_children("*","Label",true,false):
		result += label.text + "\n"
	return result

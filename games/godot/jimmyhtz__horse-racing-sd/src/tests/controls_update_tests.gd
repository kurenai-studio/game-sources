extends SceneTree
const Session = preload("res://core/game_session.gd")
const Settings = preload("res://core/game_settings.gd")
const Flow = preload("res://core/player_flow.gd")
var checks := 0
var failures := 0

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + caption)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var expected_save_dir := OS.get_environment("APPDATA").path_join("Godot/app_userdata/Superpuppy Sigma Derby").replace("\\","/").simplify_path()
	check(OS.get_user_data_dir().replace("\\","/").simplify_path() == expected_save_dir,"working-name change preserves the original saved-game directory")
	var game := Session.new()
	game.fund_demo()
	var flow := Flow.new(game,Settings.new())
	if not flow.has_method("request_out_toggle"):
		check(false,"summary Out toggle has a participation flow")
	else:
		check(flow.request_out_toggle(1) and game.players[1].state == "BETTING" and flow.screen == "overview","Out toggle joins without opening another console")
		game.edit_bet(1,"1-2",3)
		game.set_ready(1,true)
		game.access.set_pin("player_1","0123")
		check(flow.request_out_toggle(1) and flow.screen == "overview" and game.players[1].state == "OUT" and game.wager_total(1) == 0 and game.players[1].balance == 100,"Out needs no PIN and releases wagers without changing balance")
		check(flow.request_out_toggle(1) and game.players[1].state == "BETTING" and flow.screen == "overview","rejoining needs no PIN and does not open betting")
		flow.select_player(1)
		check(flow.screen == "pin" and not flow.enter_pin("9999"),"participation toggle does not bypass the betting PIN")
		flow.enter_pin("0123")
		game.edit_bet(1,"1-2",3)
		check(flow.screen == "betting" and game.wager_total(1) == 3,"correct PIN opens betting normally")
		check(flow.request_out_toggle(2) and game.players[2].state == "BETTING" and flow.active_player == 1,"another seat can join without changing the active player")
		check(flow.request_out_toggle(2) and game.players[2].state == "OUT","another seat can sit out without changing the active player")
		flow.ready()
		flow.request_out_toggle(1)
		check(game.players[1].state == "OUT" and game.wager_total(1) == 0,"Ready player can sit out immediately without PIN")
		game.phase = "RACING"
		check(not flow.request_out_toggle(1),"Out toggle locked during race")
		game.phase = "BETTING"
		game.players[2].balance = 0
		check(not flow.request_out_toggle(2) and game.players[2].state == "OUT","empty seat cannot join without credits")
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://controls-update-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	app.select_player(0)
	await process_frame
	var left = app.find_child("PlayerConsole",true,false)
	var right = app.find_child("PlayerSummaries",true,false)
	for caption in ["PlayerReady","PlayerOut","PlayerClear","PlayerCashOut"]:
		var action = app.find_child(caption,true,false)
		check(action != null and left.is_ancestor_of(action),caption + " belongs to selected player's left console")
	check(app.find_children("OutToggle*","Button",true,false).size() == 8,"right summaries have eight Out toggles")
	check(right.is_ancestor_of(app.find_child("StartRace",true,false)),"manager start remains on right")
	for button in app.find_children("*","Button",true,false):
		check(not button.text.begins_with("Race voice") and not button.text.begins_with("House voice"),"voice shortcuts removed")
	var up = app.find_child("BetUp_1_2",true,false)
	var down = app.find_child("BetDown_1_2",true,false)
	check(up != null and down != null,"bet adjustment has separate up and down buttons")
	if up != null and down != null:
		app.preferences.set_value("bet_increment",5)
		up.pressed.emit()
		await process_frame
		check(app.session.wager_total(0) == 5,"up uses chosen increment")
		app.find_child("BetDown_1_2",true,false).pressed.emit()
		await process_frame
		check(app.session.wager_total(0) == 0,"down removes chosen increment")
		app.find_child("BetDown_1_2",true,false).pressed.emit()
		check(app.session.wager_total(0) == 0,"down cannot create a negative wager")
		await process_frame
		app.change_bet(0,"1-2",19)
		await process_frame
		app.find_child("BetUp_1_2",true,false).pressed.emit()
		await process_frame
		check(app.session.wager_total(0) == 20,"up clamps to wager limit")
		var pair = app.find_child("Pair_1_2",true,false)
		var payout = app.find_child("Payout_1_2",true,false)
		var wager = app.find_child("Wager_1_2",true,false)
		var adjust = app.find_child("Adjust_1_2",true,false)
		if pair != null and payout != null and adjust != null:
			check(absf(pair.get_global_rect().get_center().y-payout.get_global_rect().get_center().y)<2 and absf(wager.get_global_rect().get_center().y-adjust.get_global_rect().get_center().y)<2,"pair payout wager and controls share one row")
		app.change_bet(0,"1-2",1)
		await process_frame
	await process_frame
	await capture("stigma-console")
	app.flow.ready()
	app.show_betting()
	var toggle = app.find_child("OutToggle1",true,false)
	if toggle != null:
		await process_frame
		click_control(toggle)
		await process_frame
		check(app.session.players[1].state == "BETTING" and app.flow.screen == "overview","right button joins without selecting another player")
		click_control(app.find_child("OutToggle1",true,false))
		await process_frame
		check(app.session.players[1].state == "OUT","right button toggles back Out")
	app.start_race()
	app._process(12)
	await process_frame
	var previous_positions: Array = app.track.positions.duplicate()
	var previous_phase: String = app.display_phase
	app.set_process(false)
	root.size = Vector2i(1920,1080)
	await process_frame
	await process_frame
	check(absf(root.get_visible_rect().size.aspect()-Vector2(1920,1080).aspect()) < 0.01,"race viewport uses the window's aspect ratio")
	app.preferences.set_value("show_clock",true)
	app.apply_settings()
	check(root.size == Vector2i(1920,1080),"unrelated preference does not undo manual resize")
	check(app.track.positions == previous_positions and app.display_phase == previous_phase,"resize preserves recorded race and phase")
	check(app.has_method("toggle_fullscreen"),"main game has a fullscreen shortcut")
	if app.has_method("toggle_fullscreen") and DisplayServer.get_name() != "headless":
		app.toggle_fullscreen()
		await process_frame
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,"main fullscreen toggle enters fullscreen")
		app.preferences.set_value("resolution","1280 x 720")
		app.apply_settings()
		app.toggle_fullscreen()
		await process_frame
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED,"main fullscreen toggle returns to window")
		check(root.size == Vector2i(1280,720),"resolution chosen in fullscreen applies on return to window")
		app.preferences.set_value("window_mode","Maximized")
		app.apply_settings()
		app.preferences.set_value("resolution","1440 x 900")
		app.apply_settings()
		app.preferences.set_value("window_mode","Windowed")
		app.apply_settings()
		await process_frame
		check(root.size == Vector2i(1440,900),"resolution chosen while maximized applies on return to window")
		root.size = Vector2i(1920,1080)
		await process_frame
	await capture("stigma-race-wide")
	app.queue_free()
	await process_frame
	await process_frame
	var lab = load("res://ui/movement_lab.tscn").instantiate()
	lab.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(lab)
	await process_frame
	lab.start_seed(123)
	lab.seek_to(0.57)
	var recorded: Dictionary = lab.outcome.duplicate(true)
	check(lab.ticks.selected == 0 and lab.model._config.round_seconds == 0.005,"10x movement remains the default")
	check(lab.has_method("toggle_fullscreen"),"movement preview has a fullscreen control")
	if lab.has_method("toggle_fullscreen") and DisplayServer.get_name() != "headless":
		lab.toggle_fullscreen()
		await process_frame
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,"preview fullscreen control works")
		await capture("stigma-preview-fullscreen")
		lab.toggle_fullscreen()
		await process_frame
	check(lab.outcome == recorded,"preview display changes preserve recorded outcome")
	lab.queue_free()
	await process_frame
	print("CONTROLS UPDATE: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func capture(caption: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	DirAccess.make_dir_recursive_absolute("res://test-results")
	check(root.get_texture().get_image().save_png("res://test-results/"+caption+".png") == OK,"capture "+caption)

func click_control(control: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = control.get_global_rect().get_center()
		root.push_input(event,true)

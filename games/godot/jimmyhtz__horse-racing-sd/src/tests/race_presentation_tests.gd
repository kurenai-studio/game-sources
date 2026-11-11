extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	call_deferred("run")
func click_control(control: Control) -> void:
	var previous := Rect2()
	var stable := 0
	for frame in range(12):
		await process_frame
		var current := control.get_global_rect()
		stable = stable+1 if current==previous else 0
		previous=current
		if stable>=2: break
	check(stable>=2,"control layout settles before simulated pointer input")
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = control.get_global_rect().get_center()
		root.push_input(event,true)
func capture(caption: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	DirAccess.make_dir_recursive_absolute("res://test-results")
	check(root.get_texture().get_image().save_png("res://test-results/"+caption+".png") == OK,"capture "+caption)
func run() -> void:
	root.size=Vector2i(1440,900)
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://presentation-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.find_child("IdleConsole",true,false) != null,"unselected console shows welcome and selection instructions")
	await click_control(app.find_child("PlayerSummary0",true,false))
	await process_frame
	check(app.flow.screen == "betting" and app.flow.active_player == 0,"real summary click opens the working player panel")
	var bet = app.find_child("BetUp_1_2",true,false)
	check(bet.text == "BET","original round button keeps BET wording")
	check(app.find_child("BetArrowUp_1_2",true,false) != null,"increase arrow is inside BET")
	await click_control(bet)
	await process_frame
	await process_frame
	check(app.session.wager_total(0) == 1,"real BET click changes selected player's wager")
	await click_control(app.find_child("BetDown_1_2",true,false))
	await process_frame
	check(app.session.wager_total(0) == 0,"real down click removes a wager")
	var action_size: Vector2 = app.find_child("PlayerOut",true,false).size
	check(app.find_child("PlayerReady",true,false).size.x>action_size.x,"Ready is wider than secondary actions")
	for action_name in ["PlayerOut","PlayerClear","PlayerCashOut"]:
		check(app.find_child(action_name,true,false).size == action_size,"bottom actions share a size")
	check(app.find_child("BetUp_1_2",true,false).get_global_rect().encloses(app.find_child("BetDown_1_2",true,false).get_global_rect()),"down region is inside the round BET button")
	check(app.find_child("PlayerSummaries",true,false).find_children("MiniWager*","",true,false).size() == 80,"all eight betting summaries show ten wager amounts")
	check(app.marquee.is_ancestor_of(app.preview_note),"preview notice is inside yellow banner")
	app.change_bet(0,"1-2",3)
	await process_frame
	for i in range(8):
		var summary = app.find_child("PlayerSummary%d" % i,true,false)
		check(summary.get_global_rect().encloses(app.find_child("BettingMini%d" % i,true,false).get_global_rect()),"miniature stays inside its player card")
	await capture("sd-console-09")
	app.flow.ready()
	app.show_betting()
	await process_frame
	var ready = app.find_child("ReadyToggle0",true,false)
	check(ready != null,"right player summary has a Ready toggle")
	if ready != null:
		check(ready.button_pressed,"Ready lights when ready")
		await click_control(ready)
		await process_frame
		check(app.session.players[0].state == "BETTING" and app.session.wager_total(0) == 3,"Ready off retains wagers")
		await click_control(app.find_child("ReadyToggle0",true,false))
		await process_frame
		check(app.session.players[0].state == "READY","Ready on works without opening betting")
	check(app.find_child("OutToggle0",true,false).text == "IN","participating button says IN")
	check(app.find_child("OutToggle1",true,false).text == "OUT","sitting-out button says OUT")
	app.session.access.set_pin("player_0","1234")
	if app.flow.has_method("request_ready_toggle"):
		app.flow.request_ready_toggle(0)
		check(app.flow.screen == "overview" and app.session.wager_total(0) == 3,"readiness changes cannot unlock a protected console or change bets")
		app.flow.request_ready_toggle(0)
		check(not app.flow.request_ready_toggle(1),"Out player cannot be readied without joining")
	app.session.access.set_pin("operator","9132")
	check(app.session.adjust_balance(1,0,"set","9132"),"empty-seat test uses a valid audited balance adjustment")
	app.select_player(1)
	await process_frame
	check(app.flow.screen=="inactive" and app.find_child("BetUp_1_2",true,false)==null and app.find_child("PlayerVirtual",true,false)!=null,"bust seat has V/Reload controls without editable wagers")
	for i in range(1,8):
		app.session.adjust_balance(i,100,"set","9132")
		app.session.set_ready(i,false)
		for pair in app.session.board.payouts: app.session.edit_bet(i,pair,i)
		app.session.set_ready(i,true)
	app.start_race()
	app._process(10)
	app._process(app.start_signal.duration+0.25) # The call finishes before the horses move.
	app.set_process(false)
	await process_frame
	await process_frame
	check(app.find_child("RacePayoutStrip",true,false) != null,"payout strip appears over race")
	check(not app.flow.request_ready_toggle(0),"Ready cannot change after race start")
	var sidebar = app.find_child("RacePlayerSummaries",true,false)
	check(sidebar != null,"race has compact read-only player wagers")
	check(app.track.get_parent().get_parent().winning_pair == "","no winning combination revealed during race")
	if sidebar != null:
		for i in range(1,8):
			var mini = app.find_child("RaceMini%d" % i,true,false)
			for amount in mini.find_children("MiniWager*","",true,false):
				check(amount.value == i,"each race miniature retains its player's actual wager")
		check(sidebar.find_children("*","Button",true,false).is_empty(),"race summaries cannot change locked bets")
	check(sidebar.get_global_rect().end.y <= sidebar.get_parent().get_global_rect().end.y,"all eight race miniatures fit without scrolling")
	check(app.track.size.y >= root.get_visible_rect().size.y*0.76,"track uses most of screen height")
	if app.track.has_method("horse_bounce"):
		app.track._animation_clock = 0.18
		check(absf(app.track.horse_bounce(0)) > 1.0,"pre-finish bouncing is visible")
		var saved_position: float = app.track.positions[0]
		app.track.positions[0] = 1000.0
		check(app.track.horse_bounce(0) == 0.0,"horse stops bouncing after crossing finish")
		app.track.positions[0] = saved_position
	else:
		check(false,"horse bounce is separately controlled")
	await capture("sd-race-09")
	for i in range(8):
		if app.session.phase == "SETTLED": break
		app._process(130)
	check(app.session.phase == "SETTLED","presentation retains actual settlement flow")
	check(app.track.get_parent().get_parent().race_bets[0].get("1-2",0) == 3,"finished-race sidebar retains that race's wagers")
	var cabinet = app.track.get_parent().get_parent()
	check(cabinet.winning_pair == app.visual_result.pair,"only official winning pair flashes after settlement")
	cabinet.flash_clock = 0.0
	cabinet.update_flash()
	var bright: Color = cabinet.payout_panels[cabinet.winning_pair].get_theme_stylebox("panel").bg_color
	cabinet.flash_clock = 0.7
	cabinet.update_flash()
	check(cabinet.payout_panels[cabinet.winning_pair].get_theme_stylebox("panel").bg_color != bright,"winning pair banner flashes")
	cabinet.prefs.reduce_flashing = true
	cabinet.update_flash()
	check(cabinet.payout_panels[cabinet.winning_pair].get_theme_stylebox("panel").bg_color == bright,"reduced flashing keeps winning pair steady")
	cabinet.prefs.reduce_flashing = false
	check(sidebar.find_children("MiniWager*","",true,false).size() == 80,"race shows all ten choices for all eight players")
	check(sidebar.get_global_rect().end.y <= sidebar.get_parent().get_global_rect().end.y,"all eight finished-race miniatures fit without scrolling")
	check(app.track.number_font_size() >= 30,"official winning numbers are enlarged")
	app.track._highlight_clock = 0.0
	await process_frame
	await capture("sd-finish-09")
	app.track.photo_hold = true
	app.track.highlights.clear()
	app.track.highlight = -1
	if app.track.has_method("horse_number_font_size"):
		check(app.track.horse_number_font_size(0) >= 30 and app.track.horse_number_font_size(4) >= 30,"photo enlargement applies to each drawn number without a highlighted horse")
	else:
		check(false,"drawn horse-number size preserves photo enlargement")
	app.session.next_round()
	check(app.session.request_cash_out(0) and app.session.confirm_cash_out(0),"cash-out fixture is confirmed through accounting")
	app.flow.active_player = -1
	app.flow.screen = "overview"
	app.show_betting()
	await process_frame
	var pending = app.find_child("BettingMini0",true,false)
	check(pending.get_child(0).text == "PENDING PAYOUT: %d" % app.session.players[0].pending,"frozen balance remains explained by pending amount")
	app.queue_free()
	await process_frame
	var lab = load("res://ui/movement_lab.tscn").instantiate()
	lab.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(lab)
	await process_frame
	await process_frame
	check(not lab.spread_input.is_visible_in_tree() and not lab.ticks.is_visible_in_tree(),"preview hides laboratory adjustments by default")
	check(lab.track.size.y >= root.get_visible_rect().size.y*0.76,"race preview track uses most of screen height")
	lab.start_seed(123)
	check(lab.model._config.round_seconds == 0.005,"exact 10x tick setting preserved")
	lab.seek_to(0.57)
	await process_frame
	await capture("sd-preview-09")
	lab.queue_free()
	await process_frame
	print("RACE PRESENTATION: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

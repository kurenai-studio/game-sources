extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void: call_deferred("run")
func click(control: Control) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = control.get_global_rect().get_center()
		root.push_input(event,true)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://test-results/"+name+"-10.png")
func run() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://payout-ui-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.session.access.set_pin("player_1","1234")
	app.select_player(0)
	app.change_bet(0,"1-2",3)
	await process_frame
	await process_frame
	var other = app.find_child("OutToggle1",true,false)
	check(not other.disabled,"other player can toggle participation during an active turn")
	click(other)
	await process_frame
	await process_frame
	check(app.session.players[1].state == "BETTING","real nested IN click joins another player")
	check(app.flow.active_player == 0 and app.flow.screen == "betting" and app.session.wager_total(0) == 3,"other IN click preserves active console and wagers")
	app.session.edit_bet(1,"1-3",2)
	click(app.find_child("OutToggle1",true,false))
	await process_frame
	await process_frame
	check(app.session.players[1].state == "OUT" and app.session.wager_total(1) == 0 and app.session.players[1].balance == 100,"other OUT click releases only that player's wagers without a PIN")
	var wager = app.find_child("Wager_1_2",true,false)
	var outline = wager.find_child("PlacedBetOutline",true,false)
	check(outline != null and outline.visible,"positive left wager has a distinct outline")
	if outline != null:
		check(outline.border_color == Color("fff52e") and outline.border_width >= 3,"placed wager uses a thick bright yellow border")
		wager.get_line_edit().grab_focus()
		await process_frame
		check(outline.is_visible_in_tree(),"outline remains while typing a wager")
		root.gui_release_focus()
		capture("bet-outline")
	app.change_bet(0,"1-2",0)
	await process_frame
	await process_frame
	outline = app.find_child("Wager_1_2",true,false).find_child("PlacedBetOutline",true,false)
	check(outline != null and not outline.visible,"zero left wager loses its border")
	app.flow.ready()
	app.select_player(1)
	check(app.flow.screen == "pin","participation toggle never unlocks protected betting")
	app.flow.back()
	app.flow.screen = "start_pin"
	check(app.flow.request_out_toggle(1) and app.flow.screen == "overview","participation change cancels an open Start PIN prompt")
	app.session.phase = "RACING"
	check(not app.flow.request_out_toggle(1),"started race participation stays locked")
	app.session.phase = "BETTING"
	app.queue_free()
	await process_frame
	check(ResourceLoader.exists("res://ui/payout_screen.gd"),"payout screen is available")
	if ResourceLoader.exists("res://ui/payout_screen.gd"):
		await payout_checks()
		await lifecycle_checks()
		await queued_completion_checks()
	print("PAYOUT AND ACCESSIBILITY: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func payout_checks() -> void:
	var game = load("res://core/game_session.gd").new()
	game.fund_demo()
	var before: Dictionary = game.export_data()
	var prefs: Dictionary = load("res://core/game_settings.gd").new().values
	prefs.master_volume = 0.0
	for kind in ["small","jackpot","none"]:
		var awards: Array = [12,0,0,0,0,0,0,0] if kind == "small" else ([2400,600,1200,240,360,120,480,840] if kind == "jackpot" else [0,0,0,0,0,0,0,0])
		var log_entry := {"pair":"1-2","odds":{"payouts":{"1-2":120 if kind == "jackpot" else 6}},"accounting":awards}
		var panel = load("res://ui/payout_screen.gd").new()
		root.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.configure(log_entry,game.players,game.player_profiles,prefs)
		var completions := [0]
		panel.completed.connect(func(): completions[0] += 1)
		await process_frame
		await process_frame
		check(panel.kind == kind,"result presentation classifies "+kind)
		check(panel.audio.player.volume_linear == 0.0,"master mute applies to "+kind)
		if kind == "none":
			check(panel.heading.text == "No winners this race" and panel.counters.is_empty(),"no-winner result is explicit without invented winners")
		else:
			check(panel.counters[0].value == 0,"winning counter starts at zero")
			panel.advance(panel.count_seconds*0.4)
			for index in panel.counters:
				check(panel.counters[index].value > 0 and panel.counters[index].value < awards[index],"each winner counts toward its actual award")
			panel.advance(panel.count_seconds*0.6)
			for index in panel.counters:
				check(panel.counters[index].value == awards[index],"final displayed award is exact")
		check(completions[0] == 0,"final amounts stay visible before automatic return")
		await process_frame
		await process_frame
		for card in panel.grid.get_children():
			check(panel.find_child("PayoutScroll",true,false).get_global_rect().encloses(card.get_global_rect()),"all winner cards fit at default size")
		capture("payout-"+kind)
		if kind == "jackpot":
			panel.size = Vector2(1000,600)
			await process_frame
			await process_frame
			var scroll: ScrollContainer = panel.find_child("PayoutScroll",true,false)
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			await process_frame
			check(scroll.get_global_rect().encloses(panel.grid.get_child(7).get_global_rect()),"smaller payout layout can scroll to the final winner")
		panel.advance(100.0)
		panel.advance(100.0)
		check(completions[0] == 1,"result completes once even with repeated advances")
		check(game.export_data() == before,"payout presentation cannot modify accounts")
		panel.queue_free()
		await process_frame
	var audio_type = load("res://ui/result_audio.gd")
	for kind in ["small","jackpot","none"]:
		var wave: AudioStreamWAV = audio_type.synthesize(kind)
		var peak := 0
		for i in range(wave.data.size()/2): peak = maxi(peak,absi(wave.data.decode_s16(i*2)))
		check(wave.loop_mode == AudioStreamWAV.LOOP_DISABLED and peak > 1000 and peak < 30000,"bounded non-looping original sound: "+kind)
		check(wave.data == audio_type.synthesize(kind).data,"result audio is deterministic and independent of race randomness")
	var quiet = load("res://ui/payout_screen.gd").new()
	root.add_child(quiet)
	quiet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prefs.reduced_motion = true
	prefs.reduce_flashing = true
	quiet.configure({"pair":"1-2","odds":{"payouts":{"1-2":100}},"accounting":[200,0,0,0,0,0,0,0]},game.players,game.player_profiles,prefs)
	check(quiet.counters[0].value == 200 and quiet.elapsed == quiet.count_seconds,"reduced motion shows final winnings without count animation")
	prefs.master_volume = 0.5
	prefs.win_volume = 0.2
	quiet.update_preferences(prefs)
	check(is_equal_approx(quiet.audio.player.volume_linear,0.1),"live result volume multiplies master and celebration sliders")
	quiet.queue_free()
	await process_frame

func lifecycle_checks() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://payout-lifecycle-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.preferences.values.master_volume = 0.0
	# Cover every pair, so the naturally generated result pays a real wager.
	app.select_player(0)
	for pair in app.session.board.payouts: app.session.edit_bet(0,pair,1)
	app.flow.ready()
	app.show_betting()
	app.start_race()
	for i in range(8):
		if app.session.phase == "SETTLED": break
		app._process(130.0)
	check(app.session.phase == "SETTLED","actual race settles before the payout animation")
	var after_award: Dictionary = app.session.export_data()
	app.present_result()
	check(app.session.export_data() == after_award and not app.blocked,"duplicate announcement cannot repay or block the settled game")
	for i in range(15):
		if app.display_phase=="PAYOUT": break
		app._process(1.0)
	await process_frame
	check(app.display_phase == "PAYOUT" and app.race_screen.payout_started,"official finish leads into payout screen")
	var saved = app.storage.load_session(app.save_path)
	check(saved.ok and saved.session.players[0].balance == app.session.players[0].balance,"reload during celebration preserves already-paid balance")
	check(saved.session.phase == "BETTING" and saved.session.round_number == app.session.round_number+1,"reload opens the next round without replaying settlement")
	app.show_settings()
	check(not app.flow.settings_open and app.find_child("SettingsUnlock",true,false)==null,"settings and its PIN prompt are unavailable during payout")
	app._process(100.0)
	await process_frame
	check(app.display_phase == "PAYOUT","completion holds for manual return")
	app._process(10.0)
	app.return_to_betting()
	check(app.display_phase == "BETTING" and app.session.round_number == after_award.round+1,"manual return opens next round")
	check(app.session.players[0].balance == after_award.players[0].balance,"automatic return changes no credited winnings")
	var round_after: int = app.session.round_number
	app.return_to_betting()
	check(app.session.round_number == round_after,"duplicate completion cannot skip another round")
	# A second actual round exercises manual skip and save-failure guards.
	app.select_player(0)
	app.flow.ready()
	app.show_betting()
	app.start_race()
	for i in range(8):
		if app.session.phase == "SETTLED": break
		app._process(130.0)
	app.show_payouts()
	await process_frame
	await process_frame
	check(app.race_screen.payout_kind == "none","actual unwagered race shows no-winner result")
	capture("payout-live")
	var before_skip: Dictionary = app.session.export_data()
	app.blocked = true
	app.return_to_betting()
	check(app.session.export_data() == before_skip,"blocked persistence cannot advance a payout")
	app.blocked = false
	app._process(100.0)
	app._process(100.0)
	click(app.find_child("ReturnToBetting",true,false))
	await process_frame
	check(app.session.round_number == before_skip.round+1 and app.session.players[0].balance == before_skip.players[0].balance,"real skip button advances once without changing winnings")
	app.queue_free()
	await process_frame

func queued_completion_checks() -> void:
	for mode in ["settings","pin"]:
		var app = load("res://ui/main.tscn").instantiate()
		app.save_path = "user://payout-queued-%s-%d.json" % [mode,OS.get_process_id()]
		app.instance_guard.acquire(0)
		root.add_child(app)
		await process_frame
		app.set_process(false)
		app.preferences.values.master_volume = 0.0
		if mode == "pin": app.session.access.set_pin("operator","1234")
		app.select_player(0)
		app.flow.ready()
		app.show_betting()
		app.start_race()
		for i in range(8):
			if app.session.phase == "SETTLED": break
			app._process(130.0)
		app.show_payouts()
		var round_before: int = app.session.round_number
		app._process(100.0) # Completion now holds for a manual Return.
		app.show_settings()
		check(not app.flow.settings_open and app.find_child("SettingsUnlock",true,false)==null,"payout cannot open "+mode)
		app._process(10.0)
		app.return_to_betting()
		check(app.display_phase=="BETTING" and app.session.round_number==round_before+1,"manual return works with payout controls locked")
		app.queue_free()
		await process_frame

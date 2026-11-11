extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func capture(view: Viewport, name: String) -> void:
	await process_frame; await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://test-results/"+name+"-16.png")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate(); app.save_path="user://capture16-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); await process_frame; app.set_process(false)
	root.size=Vector2i(1440,900)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true; app.preferences.values.master_volume=0
	app.apply_settings()
	app.select_player(0); app.change_bet(0,"1-2",2); await process_frame; await process_frame
	app.cycle_virtual(1); await process_frame; await process_frame
	app.session.set_virtual_choice(2,11); app.session.set_virtual_choice(3,12); app.show_betting()
	await capture(root,"human-and-v")
	app.select_player(1)
	await capture(root,"virtual-console")
	for i in range(8):
		var summary=app.find_child("PlayerSummary%d" % i,true,false)
		var v=app.find_child("VirtualToggle%d" % i,true,false)
		check(summary.get_global_rect().encloses(v.get_global_rect()),"V button fits its player card")
	var protected_balance: int=app.session.players[1].balance
	app.flow.back(); app.open_settings("")
	for i in range(app.settings_panel.navigation.item_count):
		if app.settings_panel.navigation.get_item_text(i)=="Virtual player styles": app.settings_panel.navigate(i)
	await capture(app.settings_panel,"virtual-styles")
	app.settings_panel.return_to_game()
	for i in range(8): app.session.set_virtual_choice(i,1+i%10)
	app.show_betting(); app.select_player(0)
	check(not app.find_child("StartRace",true,false).disabled,"all-V race can start with virtual console open")
	app.start_race(); app._process(40.0); app._process(18.0)
	app.set_process(true)
	var begin:=Time.get_ticks_msec()
	for i in range(120): await process_frame
	var elapsed:=Time.get_ticks_msec()-begin
	app.set_process(false)
	await capture(root,"race")
	app.playback.photo_threshold=10000.0; app.announcers.close_finish=true
	for i in range(3): app._process(60.0)
	await capture(root,"photo")
	check(not app.race_screen.audio.hoofs.playing,"photo hoofs are silent in actual scene")
	for i in range(4): app._process(10.0)
	await capture(root,"payout")
	check(app.session.players[1].balance==protected_balance,"native race preserves human balance under V")
	print("RENDER16 ",JSON.stringify({"phase":app.display_phase,"sample_frames":120,"elapsed_ms":elapsed,"fps":120000.0/maxf(1,elapsed),"diagnostic_error":app.diagnostics.error,"failures":failures}))
	app.queue_free(); await process_frame; quit(1 if failures else 0)

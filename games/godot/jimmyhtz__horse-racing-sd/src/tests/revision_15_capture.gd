extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(view: Viewport, name: String) -> void:
	await process_frame; await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://test-results/"+name+"-15.png")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://capture15-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app)
	await process_frame
	app.set_process(false)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true; app.preferences.values.master_volume=0
	app.apply_settings(); root.size=Vector2i(1600,1000)
	app.open_settings("")
	await capture(app.settings_panel,"settings-home")
	var panel=app.settings_panel
	for i in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(i)=="Virtual player styles": panel.navigate(i)
	await capture(panel,"virtual-styles")
	panel.find_child("VirtualStyleMode",true,false).item_selected.emit(1)
	await capture(panel,"random-hidden")
	panel.return_to_game()
	for i in range(1,8): app.session.virtual_config.seats[i].enabled=true
	app.show_betting(); app.select_player(0); app.change_bet(0,"1-2",2)
	await capture(root,"betting")
	app.player_ready(); app.start_race(); app._process(40.0); app._process(18.0)
	app.set_process(true)
	var begin:=Time.get_ticks_msec()
	for i in range(120): await process_frame
	var elapsed:=Time.get_ticks_msec()-begin
	app.set_process(false)
	await capture(root,"race")
	app.playback.photo_threshold=10000.0; app.announcers.close_finish=true
	for i in range(3): app._process(60.0)
	await capture(root,"photo")
	for i in range(4): app._process(10.0)
	await capture(root,"payout")
	print("RENDER15 ",JSON.stringify({"phase":app.display_phase,"sample_frames":120,"elapsed_ms":elapsed,"fps":120000.0/maxf(1,elapsed),"diagnostic_error":app.diagnostics.error}))
	app.queue_free(); await process_frame; quit()

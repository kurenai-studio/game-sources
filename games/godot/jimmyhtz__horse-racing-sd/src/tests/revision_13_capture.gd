extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://test-results/"+name+".png")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://capture-13-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.preferences.values.race_mute=true
	app.preferences.values.house_mute=true
	app.preferences.values.master_volume=0.0
	app.announcers.configure(app.preferences.values)
	root.size=Vector2i(1600,1000)
	app.open_settings("")
	var panel=app.settings_panel
	for i in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(i)=="Announcers": panel.navigate(i)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	panel.get_texture().get_image().save_png("res://test-results/settings-13.png")
	panel.return_to_game()
	await process_frame
	app.select_player(0)
	for pair in app.session.board.payouts: app.session.edit_bet(0,pair,1)
	app.show_betting()
	await capture("betting-13")
	app.player_ready()
	app.start_race()
	app._process(0.1)
	app._process(20.0)
	await capture("race-13")
	app.playback.photo_threshold=10000.0
	app.announcers.close_finish=true
	app._process(60.0)
	app._process(20.0)
	app._process(20.0)
	app._process(10.0)
	await capture("photo-13")
	app._process(10.0)
	app._process(10.0)
	await capture("payout-13")
	print("CAPTURE phase=",app.display_phase," size=",root.size)
	app.queue_free()
	await process_frame
	quit()

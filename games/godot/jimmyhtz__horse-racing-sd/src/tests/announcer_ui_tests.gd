extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900)
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://announcer-ui-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.preferences.values.master_volume=0.0
	app.apply_settings()
	var original: Dictionary=app.session.export_data()
	app.open_settings("")
	var panel=app.settings_panel
	for i in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(i)=="Announcers": panel.navigate(i)
	check(panel.find_child("Setting_race_voice",true,false).get_index()==2,"working voice controls remain first after category navigation")
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://test-results/announcer-settings-12.png")
	for key in ["race_voice","house_voice","race_mute","house_mute","race_volume","house_volume","race_talk","house_talk","subtitles","subtitle_size","speech_gap"]:
		check(panel.implemented(key),"first-level control active: "+key)
	for key in ["race_humor","house_sarcasm"]:
		check(panel.implemented(key),"personality blend is active: "+key)
	check(not panel.implemented("history_comments"),"unimplemented history commentary remains Planned")
	panel.find_child("TestRaceVoice",true,false).pressed.emit()
	check(app.announcers.caption.begins_with("Race:"),"sample button invokes race role")
	panel.find_child("Setting_subtitle_size",true,false).get_child(1).value=30
	check(app.subtitles.get_theme_font_size("font_size")==30,"subtitle size applies immediately")
	panel.find_child("Setting_subtitles",true,false).get_child(1).button_pressed=false
	check(not app.subtitles.visible,"subtitle toggle hides caption")
	check(app.session.export_data()==original,"voice tests and settings do not mutate accounts or outcome configuration")
	panel.return_to_game()
	await process_frame
	app.select_player(0)
	app.flow.ready()
	app.show_betting()
	app.start_race()
	check(app.session.phase=="RACING","real game starts with announcers installed")
	app._process(10)
	app._process(0.1)
	check(app.announcers.phase=="RACING","director follows race presentation")
	for step in range(8):
		if app.session.phase=="SETTLED": break
		app._process(130)
	check(app.session.phase=="SETTLED","announcers preserve actual race settlement")
	for i in range(12):
		if app.display_phase=="PAYOUT": break
		app._process(1.0)
	check(app.display_phase=="PAYOUT","silent speech cannot block payout flow")
	app.queue_free()
	await process_frame
	print("ANNOUNCER UI: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

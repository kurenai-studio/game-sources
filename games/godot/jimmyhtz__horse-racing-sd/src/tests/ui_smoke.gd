extends SceneTree

var failed := false

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://ui-smoke-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	await process_frame
	for child in app.get_children():
		if child is Window:
			child.hide()
			child.queue_free()
	check(app.session.configure_pins("9132","7423"),"UI setup")
	for i in range(8):
		app.session.adjust_balance(i,100,"set","9132")
	app.session.edit_bet(0,"1-2",4)
	app.show_betting()
	await process_frame
	await capture("betting")
	await open_preferences(app)
	await process_frame
	await process_frame
	check(app.settings_panel.tabs.get_tab_count() >= 12,"settings categories rendered")
	check(app.settings_panel.navigation.item_count == app.settings_panel.tabs.get_tab_count(),"all categories reachable from section selector")
	check(app.settings_panel.size.y <= 800,"settings dialog fits configured 900px viewport")
	app.inactivity = 61.0
	app.reminded = false
	app._process(0.1)
	check(not app.reminded,"open settings suspend overdue reminders")
	app.inactivity = 0.0
	await capture("settings")
	app.settings_panel.return_to_game()
	app.protected_panel(true)
	await process_frame
	var authentication: Array = app.find_children("ProtectedUnlock","AcceptDialog",true,false)
	check(authentication.size() == 1,"protected configuration requires an unlock dialog")
	check(app.find_children("ProtectedConsole","AcceptDialog",true,false).is_empty(),"protected values are hidden before authorization")
	if authentication.size() == 1:
		var pin_fields: Array = authentication[0].find_children("AccessPin","LineEdit",true,false)
		pin_fields[0].text = "9132"
		authentication[0].confirmed.emit()
		check(app.find_children("ProtectedConsole","AcceptDialog",true,false).is_empty(),"operator PIN cannot reveal RTP console")
		pin_fields[0].text = "7423"
		authentication[0].confirmed.emit()
		await process_frame
		check(app.find_children("ProtectedConsole","AcceptDialog",true,false).size() == 1,"correct configuration PIN opens console")
	for child in app.get_children():
		if child is Window:
			child.hide()
			child.queue_free()
	app.select_player(0)
	app.preferences.set_value("bet_increment",5)
	app.show_betting()
	var wager_fields: Array = app.find_children("Wager*","SpinBox",true,false)
	check(wager_fields.size() == 10,"ten accessible wager fields for the selected player")
	if wager_fields.size() == 10:
		check(wager_fields[0].step == 1 and wager_fields[0].custom_arrow_step == 5,"typed whole credits independent of arrow increment")
	app.preferences.set_value("ui_scale",1.5)
	app.preferences.set_value("large_text",true)
	app.apply_settings()
	app.show_betting()
	await process_frame
	await process_frame
	check(app.body.get_parent() is ScrollContainer,"large interface can scroll without losing controls")
	check(app.footer_row.get_parent() == app.root_box,"start and result actions stay outside scrolling content")
	await capture("large-interface")
	var scroll: ScrollContainer = app.body.get_parent()
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	await process_frame
	for action_name in ["PlayerReady","PlayerOut","PlayerClear","PlayerCashOut"]:
		var action: Button = app.find_child(action_name,true,false)
		check(action != null and scroll.get_global_rect().encloses(action.get_global_rect()),"enlarged layout can reach " + action_name)
	await capture("large-actions")
	app.preferences.set_value("ui_scale",1.75)
	app.preferences.set_value("resolution","1280 x 720")
	app.apply_settings()
	app.show_betting()
	await open_preferences(app)
	await process_frame
	await process_frame
	check(app.settings_panel.size.x <= 1390 and app.settings_panel.size.y <= 820,"maximum accessibility settings remain inside viewport")
	await capture("large-settings")
	app.settings_panel.return_to_game()
	app.preferences.reset_all()
	app.apply_settings()
	app.show_betting()
	app.flow.ready()
	for i in range(8):
		app.session.set_ready(i,true)
	app.start_race()
	check(app.display_phase == "RACING","manual start creates race view")
	app._process(15.0)
	await process_frame
	await capture("race")
	app._process(130.0)
	check(app.session.phase == "RESULTS","race finishes without paying")
	for i in range(8):
		if app.session.phase == "SETTLED": break
		app._process(130.0)
	check(app.session.phase == "SETTLED","UI result announcement settles credits")
	check(not app.blocked,"UI persistence succeeds")
	check(app.session.validate_state().is_empty(),"UI accounting reconciles")
	check(app.session.next_round(),"next race available")
	app.show_betting()
	app.save_state()
	check(app.storage.load_session(app.save_path).ok,"UI saved data reloads")
	app.queue_free()
	await process_frame
	await process_frame
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0,"all UI nodes released after closing")
	print("UI SMOKE: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	var directory := "res://test-results"
	DirAccess.make_dir_recursive_absolute(directory)
	var image := root.get_texture().get_image()
	check(image.save_png(directory+"/"+name+".png") == OK,"capture " + name)

func open_preferences(app: Node) -> void:
	app.show_settings()
	await process_frame
	var unlock := app.find_child("SettingsUnlock",true,false)
	if unlock != null:
		unlock.find_child("SettingsPin",true,false).text = "9132"
		unlock.confirmed.emit()
	await process_frame

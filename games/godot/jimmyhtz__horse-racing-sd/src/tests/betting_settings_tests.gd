extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,900)
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://betting-settings-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	check(app.find_child("IdleConsole",true,false) != null,"idle console explains player selection")
	var banner = app.find_child("BettingPayoutBanner",true,false)
	check(banner != null and banner.get_child_count() == 10,"all ten odds share a betting banner")
	var mini = app.find_child("BettingMini0",true,false)
	check(not mini.cells["1-2"].amount.quiet,"unfinished player's zero is visible")
	app.select_player(0)
	await process_frame
	var zero: Color = app.find_child("Wager_1_2",true,false).readout.ink
	check(zero == Color("ff2452"),"left zero brightness is unchanged")
	app.change_bet(0,"1-2",3)
	await process_frame
	check(app.find_child("Wager_1_2",true,false).readout.ink.get_luminance() > zero.get_luminance(),"left positive wager is brighter")
	var down = app.find_child("BetDown_1_2",true,false)
	var up = app.find_child("BetUp_1_2",true,false)
	check(down.size.x == up.size.x,"subtract region covers the whole bottom cap")
	check(app.body_scroll.get_global_rect().encloses(app.find_child("PlayerCashOut",true,false).get_global_rect()),"default window shows bottom actions without scrolling")
	check(app.marquee.get_global_rect().encloses(banner.get_global_rect()),"all ten payouts fit inside the marquee")
	for region in [0,1]:
		var motion := InputEventMouseMotion.new()
		motion.position = up.global_position+Vector2(up.size.x*0.5,up.size.y*(0.35 if region == 0 else 0.83))
		root.push_input(motion,true)
		await process_frame
		check(up.hover_region == region,"pointer highlights only region %d" % region)
		if DisplayServer.get_name() != "headless":
			RenderingServer.force_draw()
			var frame := root.get_texture().get_image()
			frame.save_png("res://test-results/bet-hover-%d-09.png" % region)
			for area in [0,1]:
				var pixel: Vector2i = Vector2i(up.global_position+Vector2(15,22 if area == 0 else 49))
				check(frame.get_pixelv(pixel).to_html(false) == ("ffdf76" if area == region else "efbd31"),"only hovered face area %d lights in rendered region %d" % [area,region])
	# Click the far side of each region, beyond the narrow arrow glyphs.
	for subtract in [false,true]:
		for pressed in [true,false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = pressed
			event.position = up.global_position+Vector2(up.size.x*0.15,up.size.y*(0.9 if subtract else 0.4))
			root.push_input(event,true)
		await process_frame
		await process_frame
		check(app.session.players[0].bets["1-2"] == (3 if subtract else 4),"full face region changes wager correctly")
		up = app.find_child("BetUp_1_2",true,false)
		check(up.focus_mode == Control.FOCUS_ALL,"BET remains keyboard accessible")
	app.flow.ready()
	app.show_betting()
	await process_frame
	mini = app.find_child("BettingMini0",true,false)
	check(mini.cells["1-3"].amount.quiet,"ready player's unused zeros dim")
	check(mini.cells["1-2"].amount.ink.get_luminance() > zero.get_luminance(),"ready player's actual wager stays bright")
	app.flow.request_ready_toggle(0)
	app.show_betting()
	await process_frame
	check(not app.find_child("BettingMini0",true,false).cells["1-3"].amount.quiet,"reopening readiness restores zero visibility")
	app.show_settings()
	await process_frame
	var panel = app.settings_panel
	check(panel.navigation is ItemList,"fixed left section menu stays visible")
	check(panel.get_theme_color("font_hovered_color","ItemList").get_luminance() < 0.3,"hover text stays dark")
	check(panel.get_theme_stylebox("hover","PopupMenu").bg_color.get_luminance() > 0.7,"submenu hover stays light")
	check(panel.find_child("DefaultsCategory",true,false) != null,"reset controls live on Home")
	var entry: Dictionary = app.preferences.values.duplicate(true)
	app.preferences.set_value("light_intensity",0.2)
	app.preferences.set_value("master_volume",0.3)
	panel.confirm_reset("Display")
	var confirmation = panel.find_child("ResetConfirmation",true,false)
	check(confirmation != null and app.preferences.values.light_intensity == 0.2,"reset waits for explicit confirmation")
	var details: String = confirmation.find_children("*","Label",true,false).reduce(func(text,node): return text+node.text,"")
	check("Cabinet light intensity" in details and "20% -> 70%" in details,"reset explains exact value changes")
	await process_frame
	var summary_label = confirmation.find_child("ResetSummary",true,false)
	if summary_label == null: summary_label = confirmation.get_label()
	var detail_scroll = confirmation.find_children("*","ScrollContainer",true,false)[0]
	check(detail_scroll.get_global_rect().position.y >= summary_label.get_global_rect().end.y,"reset changes appear below the explanation without overlap")
	check(confirmation.size.y <= root.size.y-32,"reset dialog fits the window with visible confirmation buttons")
	if DisplayServer.get_name() != "headless":
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://test-results/settings-reset-09.png")
	confirmation.canceled.emit()
	await process_frame
	check(app.preferences.values.light_intensity == 0.2,"cancel preserves settings")
	panel.confirm_reset("Display")
	panel.find_child("ResetConfirmation",true,false).confirmed.emit()
	await process_frame
	check(app.preferences.values.light_intensity == 0.7 and app.preferences.values.master_volume == 0.3,"section reset changes only its section")
	app.flow.revert_settings()
	check(app.preferences.values == entry,"visit revert still restores opening values")
	var editor = panel.find_child("NewPin0",true,false).get_parent().get_parent().get_parent().get_parent()
	var avatar = load("res://ui/player_avatar.gd").new()
	root.add_child(avatar)
	var dialog = editor.create_image_picker(0,avatar)
	var desktop := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if DirAccess.open(desktop) != null:
		check(dialog.current_dir.replace("\\","/").trim_suffix("/") == desktop.replace("\\","/").trim_suffix("/"),"image picker starts at Desktop")
	else:
		print("SKIP: Desktop folder is not readable in this execution environment; native picker start requires an interactive check.")
	check(dialog.use_native_dialog == (OS.get_name() == "Windows"),"Windows uses the native file picker")
	var image := Image.create(40,20,false,Image.FORMAT_RGBA8)
	image.fill(Color("3a82c4"))
	var path := "user://avatar-checkpoint-%d.png" % OS.get_process_id()
	image.save_png(path)
	dialog.file_selected.emit(ProjectSettings.globalize_path(path))
	check(not app.flow.drafts[0].profile.image.is_empty() and app.session.player_profiles[0].image.is_empty(),"image selection updates the draft before Return to Game")
	avatar.queue_free()
	app.queue_free()
	await process_frame
	print("BETTING AND SETTINGS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate(); app.save_path="user://ui16-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true
	check(app.find_child("VirtualToggle0",true,false)!=null,"right panel has V control")
	if not app.has_method("cycle_virtual"):
		check(false,"V button handler exists"); app.queue_free(); await process_frame; quit(1); return
	app.select_player(0)
	check(app.find_child("PlayerVirtual",true,false)!=null,"left panel has V control")
	app.cycle_virtual(0); await process_frame; await process_frame
	check(app.flow.screen=="virtual" and app.find_child("BetUp_1_2",true,false)==null,"virtual console is read-only")
	check(app.find_child("VirtualMini",true,false).get_child(0).text.find("CREDITS")==-1,"V shows no credit account")
	var ready=app.find_child("ReadyToggle0",true,false); var inside=app.find_child("OutToggle0",true,false)
	check(ready.disabled and ready.button_pressed,"V always ready")
	check(ready.custom_minimum_size.x<60 and inside.custom_minimum_size.x<48,"right Ready/In are smaller")
	check(ready.size.y<=26 and inside.size.y<=26,"right buttons do not stretch to avatar height")
	check(inside.get_theme_stylebox("pressed").bg_color!=app.find_child("OutToggle2",true,false).get_theme_stylebox("pressed").bg_color,"virtual In has distinct color")
	var previous: int=app.flow.active_player
	app.cycle_virtual(2); await process_frame; await process_frame
	check(app.flow.active_player==previous,"changing another V seat preserves selected console")
	app.toggle_player_out(0); await process_frame; await process_frame
	check(app.session.virtual_choice(0)==0 and app.session.players[0].state=="OUT","Out cancels V")
	app.open_settings("")
	check(app.settings_panel.find_child("VirtualPlayer0",true,false)==null,"settings no longer activates V")
	check(app.settings_panel.find_child("VirtualFactor_balance_fraction",true,false)==null and app.settings_panel.find_child("VirtualFactor_sit_out",true,false)==null,"removed virtual credit and sit-out sliders")
	app.settings_panel.return_to_game()
	app.session.access.set_pin("player_0","2468")
	app.select_player(0)
	check(app.flow.screen=="pin" and app.find_child("PlayerVirtual",true,false)!=null,"V available on protected console without unlocking human wagers")
	app.cycle_virtual(0); await process_frame; await process_frame
	for i in range(12): app.cycle_virtual(0)
	await process_frame; await process_frame
	check(app.flow.screen=="overview" or app.flow.screen=="pin","exiting V cannot bypass a human PIN")
	app.toggle_player_out(0); await process_frame; await process_frame
	app.select_player(0); app.cycle_virtual(0)
	await process_frame; await process_frame
	for i in range(12): app.cycle_virtual(0)
	await process_frame; await process_frame
	check(app.flow.screen=="pin" and app.find_child("BetUp_1_2",true,false)==null,"In human seat still requires its PIN after V")
	app.flow.back()
	app.session.phase="RACING"; app.display_phase="RACING"
	app.open_settings("")
	check(not app.flow.settings_open,"settings locked during race")
	app.session.phase="BETTING"; app.display_phase="PAYOUT"
	app.cycle_virtual(0); app.open_settings("")
	check(app.session.virtual_choice(0)==0 and not app.flow.settings_open,"display payout also locks controls")
	app.display_phase="BETTING"
	var screen=load("res://ui/race_display.gd").new(); root.add_child(screen); screen.configure(app.session,app.preferences.values)
	screen.track.moving=true; screen.track.close_up=false; screen._process(0.01)
	check(screen.audio.hoofs.playing,"hoof loop plays during ordinary race")
	screen.track.close_up=true; screen._process(0.01)
	check(not screen.audio.hoofs.playing,"moving photo replay has no hoof loop")
	screen.track.moving=false; screen._process(0.01)
	check(not screen.audio.hoofs.playing,"frozen photo finish stays silent")
	screen.track.close_up=false; screen.track.moving=true; screen._process(0.01)
	check(screen.audio.hoofs.playing,"hoof loop resumes for a normal race")
	screen.queue_free(); app.queue_free(); await process_frame
	print("UI 16 failures: ",failures); quit(1 if failures else 0)

extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.gd").new()
	app.save_path="user://checkpoint15-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true
	app.playback=app.preferences.values.duplicate(true)
	app.visual_result={"first":0,"second":4,"positions":[1002.2,989.4,992.7,991.5,1000.0]}
	check(not app.needs_photo_finish(),"20 percent target avoids replaying the old broad 7.3-unit gap")
	app.visual_result.positions[2]=999.7
	check(app.needs_photo_finish(),"much closer second/third gap still replays")
	app.visual_result={"first":0,"second":1,"positions":[1000.1,1000.0,970.0,950.0,940.0]}
	check(not app.needs_photo_finish(),"close first/second alone does not replay")
	app.open_settings("")
	check(app.settings_panel.find_child("SaveGame",true,false)!=null,"Save Game alongside PIN controls")
	check(app.settings_panel.find_child("LoadGame",true,false)!=null,"Load Game alongside PIN controls")
	check(app.settings_panel.find_child("ExportLog",true,false)!=null,"cumulative export available")
	app.settings_panel.return_to_game()
	var s=app.session
	s.edit_bet(0,"1-2",3)
	var store=load("res://core/session_store.gd").new()
	check(store.save(s,app.preferences,"user://manual15.sdgame"),"manual save succeeds")
	var loaded=store.load_session("user://manual15.sdgame")
	check(loaded.ok and loaded.session.game_id==s.game_id and loaded.session.board==s.board and loaded.session.players==s.players,"save restores game identity, card and wagers")
	var broken=FileAccess.open("user://broken15.sdgame",FileAccess.WRITE)
	broken.store_string("invalid saved game"); broken.close()
	var snapshot: Dictionary=s.export_data().duplicate(true)
	check(not app.load_named_game("user://broken15.sdgame") and app.session.export_data()==snapshot,"corrupt manual load preserves current game")
	var alternate=load("res://core/game_session.gd").new(); alternate.fund_demo(); alternate.edit_bet(0,"2-4",2)
	check(store.save(alternate,app.preferences,"user://alternate15.sdgame") and app.load_named_game("user://alternate15.sdgame"),"valid manual game switch succeeds")
	check(app.session.game_id==alternate.game_id and app.diagnostics.game_id==alternate.game_id,"game switch attaches loaded diagnostic identity")
	var archived=store.load_session("user://games/"+s.game_id+".sdgame")
	check(archived.ok and archived.session.players==s.players and archived.session.board==s.board,"prior game archived without account or card changes")
	app.queue_free(); await process_frame
	print("Checkpoint 15 failures: ",failures); quit(1 if failures else 0)

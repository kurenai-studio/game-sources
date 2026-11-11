extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.gd").new()
	check(app.instance_guard.acquire(0),"isolated ephemeral test launch lock")
	app.save_path="user://game-flow20-%d.json" % Time.get_ticks_usec()
	app.game_library.directory="user://game-flow20-%d" % Time.get_ticks_usec()
	root.add_child(app); await process_frame
	var original: String=app.session.game_id
	app.session.edit_bet(0,"1-2",2)
	app.open_settings(""); await process_frame
	app.flow.drafts[0].nickname="Friday player"
	app.preferences.values.hoof_volume=.15
	check(app.start_new_game(),"New Game commits current settings and archives current game")
	await process_frame
	check(app.session.game_id!=original and app.session.players[0].nickname=="Friday player","new session identity and committed name")
	check(app.preferences.values.hoof_volume==.15 and app.session.wager_total(0)==0,"current preferences retained with fresh wagers")
	check(FileAccess.file_exists(app.game_library.path_for(original)),"previous game is available in library")
	app.preferences.values.hoof_volume=.9; app.preferences.save_profile("New favorite")
	app.open_settings(""); await process_frame
	app.game_file_action("Load Game"); await process_frame
	var library=app.settings_panel.find_child("SavedGames",true,false)
	check(library!=null and library.rows.get_child_count()==2,"load UI shows old and current games")
	if library!=null: library.hide(); library.queue_free()
	check(app.load_named_game(app.game_library.path_for(original)),"load archived game from settings")
	await process_frame
	check(app.session.game_id==original and app.session.wager_total(0)==2,"restore game identity and wagers")
	check(app.preferences.values.hoof_volume==.15 and app.preferences.profiles.has("New favorite"),"restore game preferences without losing newer profile library")
	var import_path: String="user://older-import20-%d.sdgame" % Time.get_ticks_usec()
	check(app.storage.save(app.session,app.preferences,import_path),"export snapshot for same-identity import")
	app.session.edit_bet(0,"1-2",4)
	app.open_settings(""); await process_frame
	check(app.load_named_game(import_path,true),"import an older same-ID snapshot as separate game")
	await process_frame
	check(app.session.game_id!=original and app.session.wager_total(0)==2,"import keeps old progress in an independent game")
	var newest: Dictionary=app.storage.load_session(app.game_library.path_for(original),false)
	check(newest.ok and newest.session.wager_total(0)==4,"newer game remains separately selectable with its wagers")
	app.open_settings(""); await process_frame
	app.flow.drafts[0].pin="1234"; app.flow.drafts[0].confirm="5678"
	var before: String=app.session.game_id
	check(not app.start_new_game() and app.session.game_id==before and app.flow.settings_open,"invalid PIN draft blocks game switch")
	app.flow.revert_settings(); app.settings_panel.return_to_game(); await process_frame
	app.session.phase="RACING"
	check(not app.start_new_game(),"new game blocked during a race")
	app.session.phase="BETTING"
	check(app.session.validate_state().is_empty(),"game switch preserves valid accounting")
	app.queue_free(); await process_frame
	print("Game flow 20 failures: ",failures); quit(1 if failures else 0)

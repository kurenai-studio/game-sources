extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://core/game_library.gd"):
		check(false,"managed game library exists"); quit(1); return
	var library=load("res://core/game_library.gd").new()
	library.directory="user://games-test20-%d" % Time.get_ticks_usec()
	var game=load("res://core/game_session.gd").new(); game.fund_demo(); game.access.set_pin("operator","1234")
	game.players[0].nickname="Alex"; game.player_profiles[0].avatar="Owl"
	game.virtual_config.styles[2].appetite=.9; game.set_virtual_choice(3,3)
	game.edit_bet(0,"1-2",3)
	var prefs=load("res://core/game_settings.gd").new(); prefs.values.hoof_volume=.2; prefs.save_profile("Quiet")
	check(library.save_game(game,prefs,"Friday game"),"save named complete game")
	check(library.games().size()==1 and library.games()[0].title=="Friday game","saved game appears by name")
	check(library.save_game(game,prefs) and library.title_for(game.game_id)=="Friday game","automatic archive preserves the existing game name")
	var factory=load("res://core/new_game.gd")
	var fresh: Dictionary=factory.from_current(game,prefs)
	check(fresh.ok,"new game from current configuration")
	if fresh.ok:
		check(fresh.session.game_id!=game.game_id and fresh.session.round_number==1,"independent game identity and rotation")
		check(fresh.session.players[0].balance==100 and fresh.session.wager_total(0)==0,"new game clears real wagers and starts fresh credits")
		check(fresh.settings.values==prefs.values and fresh.settings.profiles==prefs.profiles,"new game inherits current settings and profile library")
		check(fresh.session.players[0].nickname=="Alex" and fresh.session.player_profiles[0].avatar=="Owl","player identity carries into new game")
		check(fresh.session.access.verify("operator","1234") and fresh.session.virtual_choice(3)==3,"PINs and virtual selections carry into new game")
		check(fresh.session.virtual_config.styles[2].appetite==.9,"private virtual styles preserved")
		fresh.settings.values.hoof_volume=.8
		check(prefs.values.hoof_volume==.2,"new game settings are independent copies")
		check(library.save_game(fresh.session,fresh.settings,"Saturday game"),"second game remains alongside first")
	var restored: Dictionary=load("res://core/session_store.gd").new().load_session(library.path_for(game.game_id),false)
	check(restored.ok and restored.settings.values.hoof_volume==.2 and restored.session.wager_total(0)==3,"restore exact saved settings and wagers")
	var current=load("res://core/game_settings.gd").new(); current.save_profile("Latest"); current.save_profile("Same values, another name")
	library.keep_profile_library(restored.settings,current)
	check(restored.settings.profiles==current.profiles,"loading a game preserves the latest library with distinct names")
	check(not restored.settings.profiles.has("Quiet"),"restoring old game cannot resurrect a deleted profile")
	check(restored.settings.values.hoof_volume==.2,"keeping profile library does not change the loaded game's current settings")
	check(not library.remove_game(game.game_id,game.game_id),"cannot remove currently open game")
	check(not library.remove_game("../session",""),"deletion cannot escape managed game directory")
	check(library.remove_game(game.game_id,fresh.session.game_id),"delete another saved game")
	check(library.games().size()==1 and not FileAccess.file_exists(library.path_for(game.game_id)),"deleted game is absent from available list")
	check(fresh.session.validate_state().is_empty(),"new game accounting validates")
	print("Game library 20 failures: ",failures); quit(1 if failures else 0)

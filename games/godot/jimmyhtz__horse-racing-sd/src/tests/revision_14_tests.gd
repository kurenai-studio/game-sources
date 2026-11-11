extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+text)
class Voices extends RefCounted:
	func voices() -> Array:
		return [{"id":"david","name":"Microsoft David","language":"en_US"},{"id":"mark","name":"Microsoft Mark","language":"en_US"},{"id":"zira","name":"Microsoft Zira","language":"en_US"}]
	func stop() -> void: pass
class Events extends RefCounted:
	func replay_events() -> Array:
		return [{"start_time":9.0},{"start_time":9.1},{"start_time":9.2},{"start_time":9.3},{"start_time":9.4}]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.gd").new()
	app.save_path="user://revision14-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0)
	root.add_child(app)
	app.set_process(false)
	app.preferences.values.race_mute=true
	app.preferences.values.house_mute=true
	var s=app.session
	var f=app.flow
	check(f.select_player(0),"first player opens")
	check(s.edit_bet(0,"1-2",1),"first player reserves a wager")
	check(f.select_player(1),"switch unfinished seat without Ready")
	check(s.wager_total(0)==1 and s.players[0].state=="BETTING","switch preserves draft wager")
	check(f.request_ready_toggle(0),"another seat can mark Ready during active turn")
	check(f.active_player==1 and f.screen=="betting","other Ready preserves current seat")
	s.access.set_pin("player_2","2468")
	check(f.select_player(2) and f.screen=="pin","switch still enforces destination PIN")
	check(not f.enter_pin("0000") and f.screen=="pin","wrong PIN cannot edit")
	check(f.enter_pin("2468"),"correct PIN opens destination")
	f.select_player(1)
	app.show_betting()
	var reload=app.find_child("PlayerReload",true,false)
	var ready=app.find_child("PlayerReady",true,false)
	check(reload!=null and ready!=null and reload.get_parent()==ready.get_parent(),"Reload is in bottom action row")
	if ready!=null:
		check(ready.custom_minimum_size.x>=reload.custom_minimum_size.x*1.8,"Ready has dominant width")
	check(not app.find_child("PlayerSummary0",true,false).disabled,"other summary remains clickable")
	check(not app.find_child("ReadyToggle0",true,false).disabled,"other Ready remains clickable")
	var kept_console: Node=ready.get_parent()
	app.toggle_player_ready(0)
	await process_frame
	check(is_instance_valid(kept_console) and app.find_child("PlayerReady",true,false).get_parent()==kept_console,"other Ready preserves actual selected console controls")
	app.visual_result={"first":0,"second":1,"margin":0.1,"positions":[1000.1,1000.0,970.0,960.0,950.0],"second_time":10.0}
	app.playback=app.preferences.values.duplicate(true)
	check(not app.needs_photo_finish(),"close first-second alone does not replay")
	app.visual_result.positions=[1100.0,1000.0,999.5,990.0,980.0]
	check(app.needs_photo_finish(),"close second-third does replay")
	check(app.preferences.values.has("replay_seconds"),"replay has duration preference")
	app.visual_race=Events.new()
	app.playback.replay_seconds=7.5
	app.playback.replay_events=5
	check(app.replay_time_at(7.4)<10.0 and is_equal_approx(app.replay_time_at(7.5),10.0),"replay stops at selected time")
	check(app.replay_time_at(2.0)-app.replay_time_at(1.0)>app.replay_time_at(6.0)-app.replay_time_at(5.0),"replay progressively slows")
	var director=load("res://ui/announcer_director.gd").new()
	director.backend=Voices.new()
	director.configure(app.preferences.values)
	check(director.resolve_voice(app.preferences.values.race_voice)!=director.resolve_voice(app.preferences.values.house_voice),"default roles use distinct voices")
	check(director.resolve_voice(app.preferences.values.house_voice)=="zira","female default available for house")
	director.free()
	var settings=load("res://core/game_settings.gd").new()
	var profiles_ok:=true
	for i in range(40): profiles_ok=profiles_ok and settings.save_profile("Saved %d" % i)
	check(profiles_ok and settings.profiles.size()==40,"more than 32 named profiles")
	var restored=load("res://core/game_settings.gd").new()
	check(restored.restore(settings.export_data()) and restored.profiles.size()==40,"large profile collection survives restore")
	var old: Dictionary=settings.export_data()
	old.schema=4
	old.values.house_voice="Voice 1"
	old.values.race_voice="a-chosen-installed-voice"
	old.values.replay_events=10
	old.values.slow_motion=0.2
	for key in ["nose_guides","guide_opacity","replay_seconds"]: old.values.erase(key)
	old.profiles.clear()
	check(restored.restore(old) and restored.values.house_voice=="Automatic female","old default house voice migrates to female preference")
	check(restored.values.race_voice=="a-chosen-installed-voice" and restored.values.replay_seconds==5.0,"migration preserves explicit voice and adopts current timed replay")
	app.show_help("Announcers")
	check(app.help_panel.selected_id=="announcers","context help opens relevant section")
	app.help_panel.filter_topics("forgot")
	check(app.help_panel.visible_topics.size()==1 and app.help_panel.selected_id=="players","offline help search finds forgotten-PIN workflow")
	app.help_panel.queue_free()
	await process_frame
	var signal_node=load("res://ui/start_signal.gd").new()
	root.add_child(signal_node)
	check(signal_node.play_signal({"start_signal":"Horn","master_volume":0.0})>9.0,"traditional bugle recording has full call duration")
	signal_node.queue_free()
	var display=load("res://ui/race_display.gd").new()
	root.add_child(display)
	s.players[7].state="OUT"
	display.configure(s,settings.values)
	s.players[7].state="BETTING"
	display.refresh_players()
	check(display.cards[7].find_children("*","Label",true,false).any(func(label): return " OUT" in label.text),"sitting-out label survives later player state changes")
	display.queue_free()
	app.queue_free()
	await process_frame
	print("REVISION 14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
class Speech extends RefCounted:
	var seconds:=1.0
	func voices() -> Array: return [{"id":"fake","name":"fake","language":"en"}]
	func duration(_text: String,_voice: String,_rate: float) -> float: return seconds
	func stop() -> void: pass
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return true
	func say(_text: String,_voice: String,_volume: int,_rate: float) -> void: pass
	func speaking() -> bool: return false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://review15-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true
	app.select_player(0); app.cycle_virtual(0)
	await process_frame; await process_frame
	check(app.flow.screen=="virtual" and app.find_child("BetUp_1_2",true,false)==null,"human-to-virtual conversion closes editable console")
	var before: Dictionary=app.session.players[0].bets.duplicate()
	app.flow.screen="betting" # Simulate a stale callback from the old console.
	app.change_bet(0,"1-2",20)
	check(app.session.players[0].bets==before,"stale human callback cannot change virtual bets")
	app.preferences.values.confirm_clear=false
	app.clear_player_bets(0)
	check(app.session.players[0].bets==before,"stale Clear callback cannot remove virtual bets")
	var s=load("res://core/game_session.gd").new(); s.fund_demo()
	s.virtual_config.styles[1].appetite=0.0
	s.set_virtual_choice(1,2)
	var flow=load("res://core/player_flow.gd").new(s,load("res://core/game_settings.gd").new())
	check(s.players[1].state=="READY" and s.players[1].bets.is_empty(),"zero-appetite V remains Ready")
	check(not flow.request_ready_toggle(1),"virtual Ready cannot be unset through a stale callback")
	check(flow.request_out_toggle(1) and s.virtual_choice(1)==0 and s.players[1].state=="OUT","Out exits V without an inaccessible intermediate state")
	var director=load("res://ui/announcer_director.gd").new(); director.backend=Speech.new(); root.add_child(director)
	var prefs=load("res://core/game_settings.gd").new().values; prefs.race_talk=0.4
	director.configure(prefs); director.prepared={"start":"They are off"}
	var trace=[{"time":0.0,"positions":[100.0,50.0,30.0,20.0,10.0]},{"time":12.7,"positions":[100.0,50.0,30.0,20.0,10.0]},{"time":12.8,"positions":[100.0,110.0,30.0,20.0,10.0]},{"time":35.0,"positions":[200.0,210.0,130.0,120.0,110.0]}]
	var cues=load("res://ui/race_call_plan.gd").new().build(director,trace,{"second_time":35.0},35.0)
	director.backend.seconds=4.0
	var live_count:=0
	for cue in cues:
		if cue.get("historical",true): continue
		live_count+=1
		var fits: bool=cue.at+director.duration("race",cue.text)+0.25<=cue.deadline
		check(not fits or director.cue_valid(cue,director.record_position(trace,cue.at+4.0)),"actual longer speech cannot outlast verified position order")
	check(live_count>0,"speech regression exercises a live position cue")
	director.queue_free(); app.queue_free(); await process_frame
	print("Review 15 failures: ",failures); quit(1 if failures else 0)

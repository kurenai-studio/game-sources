extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
class Speech extends RefCounted:
	var now:=0.0
	var until:=-1.0
	var calls:=[]
	func voices() -> Array: return [{"id":"test","name":"Test","language":"en"}]
	func duration(text: String,_voice: String,rate: float) -> float: return text.split(" ").size()/(1.8*rate)+1.1
	func tick(delta: float) -> void: now+=delta
	func stop() -> void: until=-1.0
	func speaking() -> bool: return now<until
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return true
	func say(text: String,voice: String,_volume: int,rate: float) -> void:
		calls.append(text); until=now+duration(text,voice,rate)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var prefs=load("res://core/game_settings.gd").new().values
	var view=load("res://ui/track_view.gd").new(); view.preferences=prefs.duplicate(true); root.add_child(view)
	for viewport in [Vector2(800,600),Vector2(1400,900)]:
		view.size=viewport
		for horse_scale in [1.0,1.55,2.0]:
			view.preferences.horse_scale=horse_scale
			var live_size: float=horse_scale*clampf(view.view_scale(),0.4,1.25)
			var live_gap: float=view.project(view.display_point(0.0,2)).distance_to(view.project(view.display_point(-0.005,2)))
			var photo_gap: float=view.photo_nose(1000.0,2).distance_to(view.photo_nose(995.0,2))
			check(absf(live_gap/live_size-photo_gap/view.photo_scale())<0.01,"replay preserves gap in horse lengths")
			for spacing in [40.0,56.0,70.0]:
				view.geometry.lane_width=spacing; view.preferences.lane_spacing=spacing
				live_size=horse_scale*clampf(view.view_scale(),0.4,1.25)
				var live_lanes: float=view.project(view.display_finish_point(1)).distance_to(view.project(view.display_finish_point(2)))
				var photo_lanes: float=view.photo_nose(1000.0,1).distance_to(view.photo_nose(1000.0,2))
				check(absf(live_lanes/live_size-photo_lanes/view.photo_scale())<0.01,"replay preserves lane spacing relative to figures")
	view.queue_free()
	var director=load("res://ui/announcer_director.gd").new(); director.backend=Speech.new(); root.add_child(director)
	prefs.race_talk=1.0; director.configure(prefs); director.library.rng.seed=17
	var odds=load("res://core/calibrated_odds.gd").new()
	for race_id in range(2):
		var race=load("res://core/calibrated_race.gd").new(("revision17-%d" % race_id).sha256_text(),odds.board(90))
		var trace: Array=[race.snapshot()]
		while not race.finished: race.advance_event(); trace.append(race.snapshot())
		director.prepare_race(trace,race.result(),35.0,true,"small")
		director.observe("PREPARING",[],0.0,{})
		director.advance(1.0)
		var before: int=director.backend.calls.size()
		for frame in range(700):
			director.advance(0.05)
			director.observe("RACING",director.record_position(trace,race.result().second_time*frame/700.0),frame/700.0,{})
		var spoken: Array=director.backend.calls.slice(before)
		check(spoken.size()>=4,"maximum talk frequency delivers start and at least three action calls")
		var places:=0
		for cue in director.cues:
			if cue.text in spoken and ("second" in cue.text.to_lower() or cue.category in ["place_move","place_chase"]): places+=1
		check(places>0,"race calls include the battle for second")
	# A cached race with the start signal Off must not mistake phase transitions for speech.
	director.stop(); director.advance(10.0)
	prefs.speech_gap=3.0; director.configure(prefs)
	director.phase="BETTING"; director.next_cue=0
	director.cues=[{"at":0.15,"deadline":5.0,"category":"start","leader":-1,"text":"They're off!"}]
	var calls_before: int=director.backend.calls.size()
	director.observe("PREPARING",[],0.0,{})
	director.advance(0.2); director.observe("RACING",[1,1,1,1,1],0.2/35.0,{})
	check(director.backend.calls.size()==calls_before+1,"cached race without start signal still speaks opening call")
	director.queue_free()
	var app=load("res://ui/main.tscn").instantiate(); app.save_path="user://rev17-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	app.session.set_virtual_choice(0,11); app.session.set_virtual_choice(1,12); app.show_betting(); await process_frame
	check(app.find_child("VirtualToggle0",true,false).text=="VR1","fixed random button reads VR1")
	check(app.find_child("VirtualToggle1",true,false).text=="VR2","each-race random button reads VR2")
	app.queue_free(); await process_frame
	print("Revision 17 failures: ",failures); quit(1 if failures else 0)

extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
class Voice extends RefCounted:
	var now:=0.0
	var until:=-1.0
	var calls: Array=[]
	var cached: Dictionary={}
	func voices() -> Array: return [{"id":"race","name":"David","language":"en"}]
	func duration(text: String,_voice: String,rate: float) -> float:
		if text=="Opening sentence that takes longer than expected!": return 5.0/rate if cached.has(text) else 2.0
		return 1.3
	func prepare(clips: Array) -> void:
		for clip in clips: cached[clip.text]=true
	func preparing() -> bool: return false
	func tick(delta: float) -> void: now+=delta
	func stop() -> void: until=-1.0
	func speaking() -> bool: return now<until
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return true
	func say(text: String,_voice: String,_volume: int,rate: float) -> void:
		calls.append({"text":text,"at":now,"rate":rate}); until=now+duration(text,"race",rate)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var settings=load("res://core/game_settings.gd").new()
	var director=load("res://ui/announcer_director.gd").new(); director.backend=Voice.new(); root.add_child(director)
	settings.values.race_talk=1.0; settings.values.speech_gap=0.8; director.configure(settings.values)
	director.race_seconds=10.0
	director.cues=[{"at":0.15,"deadline":4.0,"text":"First call!","rate":1.2,"leader":-1},
		{"at":2.0,"deadline":5.0,"latest_start":2.65,"text":"Second call!","rate":1.2,"leader":-1}]
	for frame in range(160):
		director.advance(0.025); director.observe("RACING",[10,9,8,7,6],frame*0.025/10.0,{})
	check(director.backend.calls.size()==2,"a cue waits through the minimum inter-call gap while still timely")
	director.stop()
	director.cues=[{"at":0.15,"deadline":5.0,"text":"Opening sentence that takes longer than expected!","short_text":"They're off!","rate":1.2,"leader":-1},
		{"at":3.0,"deadline":5.0,"latest_start":3.65,"text":"Second call!","rate":1.2,"leader":-1}]
	director.backend.prepare([{"text":director.cues[0].text}]); director.fitting_pending=true; director.fitting_passes=0
	check(not director.preparing(),"cold-cache fitting terminates when the backend is ready")
	var first: Dictionary=director.cues[0]
	check(first.rate<=1.6,"cold-cache fitting respects the rate cap")
	check(first.at+director.duration("race",first.text,first.rate)+settings.values.speech_gap<director.cues[1].at,"measured opening fits before the next planned call")
	director.queue_free()
	var view=load("res://ui/track_view.gd").new(); root.add_child(view)
	for layout in [[Vector2(640,480),2.0,44.0,0.6],[Vector2(1600,800),1.0,70.0,1.5],[Vector2(900,1200),2.0,70.0,1.0]]:
		view.size=layout[0]; view.preferences=settings.values.duplicate()
		view.preferences.horse_scale=layout[1]; view.preferences.lane_spacing=layout[2]; view.preferences.camera_height=layout[3]
		view.geometry.lane_width=layout[2]
		for step in range(100):
			var progress: float=step/100.0
			view.positions=[progress*1000,progress*1000,progress*1000,progress*1000,progress*1000]
			for h in range(5):
				var line: PackedVector2Array=view.nose_guide(h)
				var nose: Vector2=view.horse_point(h)+view.nose_offset(h)
				check(Geometry2D.get_closest_point_to_segment(nose,line[0],line[-1]).distance_to(nose)<0.1,"nose guide stays aligned at large/small layouts")
				for edge in [0,1]:
					var point: Vector2=(line[edge]-Vector2(view.size.x*.5,view.size.y*.54))/view.view_scale()
					point.y/=0.87*view.preferences.camera_height
					var radius: float=view.geometry.inner_radius+(-.5 if edge==0 else 4.5)*view.geometry.lane_width
					var dist: float=Vector2(maxf(absf(point.x)-view.geometry.straight_half,0),point.y).length()
					check(dist<=radius+0.15 if edge==0 else dist>=radius-0.15,"full track width at size/curve extremes")
	view.queue_free(); await process_frame
	print("Revision 19 edge failures: ",failures); quit(1 if failures else 0)

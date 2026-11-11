extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
class TimedVoice extends RefCounted:
	var now:=0.0
	var until:=-1.0
	var calls: Array=[]
	var overlaps:=0
	func voices() -> Array: return [{"id":"race","name":"David","language":"en"},{"id":"house","name":"Zira","language":"en","gender":"female"}]
	func duration(text: String,_voice: String,rate: float) -> float: return text.split(" ",false).size()/(2.6*rate)+0.45
	func tick(delta: float) -> void: now+=delta
	func stop() -> void: until=-1.0
	func speaking() -> bool: return now<until
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return true
	func say(text: String,voice: String,_volume: int,rate: float) -> void:
		if now<until: overlaps+=1
		until=now+duration(text,voice,rate)
		calls.append({"text":text,"rate":rate,"start":now,"end":until})
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var totals: Array=[0,0]
	var details: Array=[]
	for seed_index in range(8):
		var race=load("res://core/calibrated_race.gd").new(("announcer19-%d" % seed_index).sha256_text(),load("res://core/calibrated_odds.gd").new().board(90),{"race_spread":0.75,"race_lead_changes":0.75})
		var trace: Array=[race.snapshot()]
		while not race.finished: race.advance_event(); trace.append(race.snapshot())
		for level in range(2):
			var director=load("res://ui/announcer_director.gd").new(); director.backend=TimedVoice.new(); root.add_child(director)
			var prefs=load("res://core/game_settings.gd").new().values
			prefs.race_talk=0.5 if level==0 else 1.0
			director.configure(prefs); director.library.rng.seed=800+seed_index
			director.prepare_race(trace,race.result(),35.0,false,"small")
			check(director.resolve_voice("Automatic female")!=director.resolve_voice("Automatic race"),"automatic voices remain distinct")
			for frame in range(1400):
				director.advance(0.025)
				var progress: float=frame/1400.0
				director.observe("RACING",director.record_position(trace,race.result().second_time*progress),progress,{})
			var spoken: Array=director.backend.calls
			var leader_mentions:=0
			var place_mentions:=0
			check(director.backend.overlaps==0,"speech never overlaps")
			for call in spoken:
				check(call.rate<=1.6,"hard rate ceiling respected")
				check(call.start>=0.15 and call.end<35.0,"spoken call fits before finish")
				var matching: Array=director.cues.filter(func(c): return c.text==call.text and c.at<=call.start+0.05 and c.get("latest_start",c.deadline)>=call.start-0.05)
				check(not matching.is_empty(),"spoken action belongs to the prepared plan")
				if not matching.is_empty():
					check(call.end<=matching[0].deadline+0.05,"spoken line ends within factual deadline")
					if matching[0].category in ["order","recent_order","lead_move","chase"]: leader_mentions+=1
					if matching[0].category in ["order","recent_order","second","recent_places","place_move","place_chase"]: place_mentions+=1
			check(leader_mentions>0,"running commentary identifies the leader")
			check(place_mentions>0,"running commentary covers second place")
			totals[level]+=spoken.size()
			details.append({"seed_index":seed_index,"talk":prefs.race_talk,"planned":director.cues.size(),"spoken":spoken.size()})
			director.queue_free(); await process_frame
	check(totals[1]>=totals[0]*1.25,"upper half delivers substantially more commentary")
	check(totals[1]>=8*7,"maximum delivers at least seven calls per race on average")
	FileAccess.open("res://test-results/announcer19.json",FileAccess.WRITE).store_string(JSON.stringify({"totals":totals,"races":details,"failures":failures},"  "))
	print("Announcer 19 totals: ",totals," failures: ",failures); quit(1 if failures else 0)

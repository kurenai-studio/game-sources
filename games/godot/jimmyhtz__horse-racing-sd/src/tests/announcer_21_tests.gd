extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
class MeasuredVoice extends RefCounted:
	func voices() -> Array: return [{"id":"race","name":"David","language":"en"}]
	func duration(text: String,_voice: String,_rate: float) -> float: return 2.5 if text.begins_with("The leading") else 2.8
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return true
	func preparing() -> bool: return false
	func prepare(_clips: Array) -> void: pass
	func speaking() -> bool: return false
	func stop() -> void: pass
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var director=load("res://ui/announcer_director.gd").new()
	director.backend=MeasuredVoice.new(); root.add_child(director)
	director.configure(load("res://core/game_settings.gd").new().values)
	# Native duration exceeds a live-order window even at the hard rate limit.
	# The fallback reports the verified earlier observation instead of going silent
	# or asserting that positions are still unchanged.
	var evidence={"positions":[980,970,990,960,950],"order":[2,0,1,3,4]}
	director.cues=[{"at":28.0,"deadline":30.29,"latest_start":28.65,"category":"order","leader":2,"second":0,"historical":false,"text":"The leading pair: 3, then 1!","short_text":"The leading pair: 3, then 1!","rate":1.6,"evidence":evidence,"historical_fallback":{"category":"recent_order","deadline":34.65,"text":"Horse 3 was leading Horse 1!","rate":1.282}}]
	var original: Dictionary=director.cues[0].duplicate(true)
	director.fitting_pending=true; director.fitting_passes=0
	check(not director.preparing(),"measured fallback finishes preparing")
	var cue: Dictionary=director.cues[0]
	check(cue.category=="recent_order" and cue.historical,"unfittable live call becomes a verified recent-action call")
	check(cue.evidence==evidence,"fallback keeps the original trace evidence")
	check(cue.deadline==34.65 and cue.rate<=1.6,"fallback respects the finish and hard rate cap")
	check(director.duration("race",cue.text,cue.rate)<cue.deadline-cue.at,"measured fallback fits the remaining race")
	director.preferences.speech_gap=0.8
	director.cues=[original,{"at":31.25,"deadline":34.65,"latest_start":31.9,"category":"recent_places","historical":true,"text":"Second place is being contested!","rate":1.6,"evidence":evidence}]
	director.fitting_pending=true; director.fitting_passes=0
	director.preparing()
	check(director.cues[0].deadline<=30.45,"fallback keeps the next cue's reserved time and speech gap")
	check(director.duration("race",director.cues[0].text,director.cues[0].rate)>director.cues[0].deadline-director.cues[0].at,"unfittable fallback remains outside its runtime deadline instead of stealing next cue")
	director.queue_free(); await process_frame
	print("Announcer 21 measured fallback failures: ",failures); quit(1 if failures else 0)

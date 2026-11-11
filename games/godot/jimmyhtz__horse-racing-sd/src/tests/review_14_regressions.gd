extends SceneTree
var failures:=0
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+text)
class Speech extends RefCounted:
	var now:=0.0
	var until:=-1.0
	var ready:=true
	var installed:=true
	var calls:=[]
	func tick(delta: float) -> void: now+=delta
	func voices() -> Array: return [{"id":"test","name":"Test","language":"en"}] if installed else []
	func duration(text: String,_voice: String,_rate: float) -> float: return text.split(" ").size()/2.5+0.4
	func speaking() -> bool: return now<until
	func stop() -> void: until=-1.0
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return ready
	func say(text: String,voice: String,_volume: int,rate: float) -> void:
		calls.append(text)
		until=now+duration(text,voice,rate)
func _initialize() -> void:
	var prefs=load("res://core/game_settings.gd").new()
	var director=load("res://ui/announcer_director.gd").new()
	var fake:=Speech.new()
	director.backend=fake
	director.configure(prefs.values)
	director.library.rng.seed=4
	var trace:=[]
	for i in range(101): trace.append({"time":float(i),"positions":[i*10.5,i*10.0,i*9.8,i*9.5,i*9.0]})
	director.prepare_race(trace,{"first":0,"second":1,"pair":"1-2","second_time":100.0},35.0,false,"small")
	for frame in range(700):
		director.advance(0.05)
		director.observe("RACING",[100,90,80,70,60],frame/700.0,{})
	var first_calls:=0
	var second_calls:=0
	for cue in director.cues:
		if cue.text in fake.calls:
			if cue.get("leader",-1)>=0: first_calls+=1
			if cue.get("second",-1)>=0: second_calls+=1
	check(first_calls>0 and second_calls>0,"default actually delivered commentary covers both paying positions")
	director.stop()
	fake.ready=false
	fake.installed=false
	var before: int=fake.calls.size()
	director.advance(1.0)
	director.speak("race","Two horses are fighting for second!")
	check(not director.caption.is_empty() and fake.calls.size()==before,"missing voice shows timely subtitle without queuing audio")
	director.advance(0.3)
	check(not director.caption.is_empty(),"fallback subtitle remains readable")
	director.stop()
	fake.installed=true
	director.advance(5.0)
	director.speak("race","Second place is changing!")
	check(not director.caption.is_empty() and fake.calls.size()==before,"missing clip shows subtitle without late synthesis")
	var library=load("res://ui/announcer_phrases.gd").new()
	library.rng.seed=11
	var dry:=false
	for i in range(100):
		var line: Dictionary=library.choose_traits("middle",{},{"humor":0.0,"sarcasm":1.0,"energy":0.5,"detail":0.5})
		dry=dry or line.sarcasm>0.0
	check(dry,"sarcasm remains available with humor at zero")
	director.free()
	print("REVIEW 14: 5 checks, %d failures" % failures)
	quit(1 if failures else 0)

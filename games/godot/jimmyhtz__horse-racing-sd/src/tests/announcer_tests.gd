extends SceneTree
var checks := 0
var failures := 0
class FakeSpeech extends RefCounted:
	var calls: Array=[]
	var active := false
	func voices() -> Array: return [{"id":"one","name":"First","language":"en_US"},{"id":"two","name":"Second","language":"en_US"}]
	func speaking() -> bool: return active
	func stop() -> void: active=false
	func say(text: String, voice: String, volume: int, rate: float) -> void:
		calls.append({"text":text,"voice":voice,"volume":volume,"rate":rate})
		active=true
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func _initialize() -> void:
	var director=load("res://ui/announcer_director.gd").new()
	var fake=FakeSpeech.new()
	director.backend=fake
	var settings=load("res://core/game_settings.gd").new()
	director.configure(settings.values)
	director.observe("BETTING",[],0.0,{})
	check(fake.calls.is_empty(),"betting is silent")
	director.observe("RACING",[0,0,0,0,0],0.0,{"first":4,"second":3})
	check(fake.calls.is_empty(),"start signal has exclusive time before speech")
	director.advance(2.8)
	director.observe("RACING",[30,40,50,70,60],0.08,{})
	check(fake.calls.size()==1 and "off" in fake.calls.back().text,"start call follows signal")
	check(not "5" in fake.calls.back().text,"start call never reveals eventual winner")
	var count: int=fake.calls.size()
	director.observe("RACING",[30,40,50,70,60],0.5,{})
	check(fake.calls.size()==count,"speech never overlaps")
	director.close_finish=true
	director.observe("POST",[],1.0,{"first":4,"second":3})
	check("finish" in fake.calls.back().text.to_lower() and not "5" in fake.calls.back().text,"close finish withholds order during runout")
	director.observe("SETTLED",[],1.0,{"first":4,"second":3,"pair":"4-5"})
	check("5 first" in fake.calls.back().text and "4 second" in fake.calls.back().text,"official confirmation gives recorded finish")
	settings.values.race_mute=true
	director.configure(settings.values)
	check(not fake.active,"muting immediately stops current speech")
	count=fake.calls.size()
	director.preview("race")
	check(fake.calls.size()==count,"preview respects mute")
	settings.values.race_mute=false
	settings.values.master_volume=0.5
	settings.values.race_volume=0.4
	settings.values.race_voice="two"
	director.configure(settings.values)
	director.preview("race")
	check(fake.calls.back().volume==20 and fake.calls.back().voice=="two","master and role volume multiply; selected voice is used")
	check(fake.calls.back().rate>1.0 and fake.calls.back().rate<=1.6,"automatic excited delivery stays within its hard cap")
	check(director.resolve_voice("missing")=="one","missing saved voice has a valid fallback")
	director.observe("BETTING",[],0,{})
	director.advance(999)
	director.observe("BETTING",[],0,{})
	check(director.caption.is_empty() and not fake.active,"no repetitive betting prompts")
	check(settings.set_value("race_voice","system-voice-identifier"),"real voice IDs are accepted")
	settings.save_profile("voice-test")
	var restored=load("res://core/game_settings.gd").new()
	check(restored.restore(settings.export_data()) and restored.values.race_voice=="system-voice-identifier","voice choices survive save and restore")
	var seen := {}
	for i in range(8):
		var line: Dictionary=director.library.choose("start")
		check(not seen.has(line.id),"start library avoids recent repeats")
		seen[line.id]=true
	director.free()
	print("ANNOUNCERS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

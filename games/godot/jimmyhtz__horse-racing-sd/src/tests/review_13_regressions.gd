extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
class NotReadySpeech extends RefCounted:
	var calls := 0
	func voices() -> Array: return [{"id":"test","name":"Test","language":"en"}]
	func speaking() -> bool: return false
	func stop() -> void: pass
	func say(_text: String,_voice: String,_volume: int,_rate: float) -> void: calls+=1
	func ready_clip(_text: String,_voice: String,_rate: float) -> bool: return false
	func duration(_text: String,_voice: String,_rate: float) -> float: return 0.5
func _initialize() -> void:
	var backend=load("res://ui/speech_backend.gd").new()
	backend.deferred_clips=[{"text":"queued"}]
	backend.shutdown()
	check(not backend.preparing(),"shutdown clears deferred speech work")
	var director=load("res://ui/announcer_director.gd").new()
	var fake=NotReadySpeech.new()
	director.backend=fake
	director.configure(load("res://core/game_settings.gd").new().values)
	director.phase="RACING"
	director.clock=20
	director.cues=[{"at":1.0,"deadline":30.0,"text":"Horse one leads.","leader":0}]
	director.observe("RACING",[10,9,8,7,6],0.1,{})
	check(fake.calls==0,"uncached live call is dropped instead of playing late")
	director.free()
	print("REVIEW REGRESSIONS: %d failures" % failures)
	quit(1 if failures else 0)

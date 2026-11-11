extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://core/diagnostics.gd"):
		check(false,"cumulative diagnostic recorder exists"); quit(1); return
	var d=load("res://core/diagnostics.gd").new()
	root.add_child(d)
	var id="test"+str(Time.get_ticks_usec())
	d.begin(id)
	d.record("test",{"pin":"1234","credentials":{"password":"2468"},"nested":{"image":"private","bet":3}})
	d.frame(0.016,"BETTING",[],0.0)
	d.record("race_motion",{"columns":["event","round","slot","horse","time","positions"],"ticks":[[1,1,0,3,0.001,[0,0,0,0.1,0]]]})
	d.flush()
	var path="user://diagnostics-test.zip"
	check(d.export_bundle(path,{"credentials":{"operator":"secret"},"round":7}),"export succeeds")
	var zip=ZIPReader.new()
	check(zip.open(path)==OK,"ZIP opens")
	var joined=""
	for file in zip.get_files(): joined+=zip.read_file(file).get_string_from_utf8()
	check(not "1234" in joined and not "2468" in joined and not "private" in joined and not "secret" in joined,"export removes credentials and images")
	check('"bet":3' in joined and 'race_motion' in joined,"events and ticks exported as readable JSON")
	zip.close()
	d.shutdown(); d.free()
	var again=load("res://core/diagnostics.gd").new(); root.add_child(again); again.begin(id)
	again.record("after_restart",{}); again.flush()
	check(again.export_bundle(path,{}),"restart appends same game log")
	zip.open(path); joined=""
	for file in zip.get_files(): joined+=zip.read_file(file).get_string_from_utf8()
	check("race_motion" in joined and "after_restart" in joined,"cumulative export keeps prior run")
	zip.close(); again.shutdown(); again.free()
	var s=load("res://core/game_session.gd").new(); s.fund_demo()
	check(s.export_data().has("game_id"),"save retains log identity")
	print("Diagnostics 15 failures: ",failures); quit(1 if failures else 0)

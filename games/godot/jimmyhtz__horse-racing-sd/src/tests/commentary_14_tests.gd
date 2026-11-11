extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var library=load("res://ui/announcer_phrases.gd").new()
	check(library.has_method("choose_traits"),"independent traits select commentary")
	if library.has_method("choose_traits"):
		var serious={"humor":0.0,"sarcasm":0.0,"energy":0.8,"detail":0.5}
		var vivid={"humor":1.0,"sarcasm":1.0,"energy":0.8,"detail":0.5}
		var overlap:=false
		for i in range(60):
			var line: Dictionary=library.choose_traits("middle",{},serious)
			check(line.get("humor",0.0)==0.0 and line.get("sarcasm",0.0)==0.0,"serious sliders exclude jokes")
			line=library.choose_traits("middle",{},vivid)
			overlap=overlap or (line.get("humor",0.0)>0.0 and line.get("sarcasm",0.0)>0.0)
		check(overlap,"humor and sarcasm can overlap")
	var director=load("res://ui/announcer_director.gd").new()
	root.add_child(director)
	var prefs=load("res://core/game_settings.gd").new()
	director.configure(prefs.values)
	var trace: Array=[]
	for i in range(101): trace.append({"time":float(i),"positions":[i*10.5,i*10.0,i*9.8,i*9.5,i*9.0]})
	director.prepare_race(trace,{"first":0,"second":1,"pair":"1-2","second_time":100.0},60.0,false,"small")
	var second_mentions:=0
	for cue in director.cues:
		if cue.get("second",-1)>=0: second_mentions+=1
	check(second_mentions>=2,"stable race plan covers second place repeatedly")
	check(director.has_method("cue_valid"),"live call validity checks both paying places")
	if director.has_method("cue_valid"):
		check(not director.cue_valid({"leader":0,"second":1},[100,90,95,70,60]),"stale second-place call is rejected")
	var panel=load("res://ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.configure(prefs,func(): pass)
	for role in ["race","house"]:
		for quirk in ["humor","sarcasm","energy","detail"]:
			check(panel.implemented(role+"_"+quirk),"personality slider is connected: "+role+"_"+quirk)
	panel.queue_free()
	director.queue_free()
	await process_frame
	print("COMMENTARY 14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)


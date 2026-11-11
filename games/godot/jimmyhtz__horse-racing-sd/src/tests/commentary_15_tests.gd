extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var director=load("res://ui/announcer_director.gd").new()
	director.backend=load("res://tests/review_14_regressions.gd").Speech.new()
	root.add_child(director)
	director.configure(load("res://core/game_settings.gd").new().values)
	var fixture := [{"time":0.0,"positions":[10,9,8,2,1]},{"time":1.5,"positions":[11,15,14,4,3]}]
	var context=load("res://ui/race_call_plan.gd").new().context(director,fixture,{"second_time":1.5},1.5,1.5,1)
	# B passes A for first while C passes A for second. C never passes B.
	if context.category=="place_move": check(context.replacements.rival==1,"second-place pass identifies the horse actually passed")
	var odds=load("res://core/calibrated_odds.gd").new()
	var report:=[]
	for i in range(8):
		var race=load("res://core/calibrated_race.gd").new(("spoken15-%d" % i).sha256_text(),odds.board(90))
		var trace: Array=[race.snapshot()]
		while not race.finished: race.advance_event(); trace.append(race.snapshot())
		director.prepare_race(trace,race.result(),35.0,false,"small")
		var named:=0
		for cue in director.cues:
			if cue.get("category","")!="start" and "Horse" in cue.text: named+=1
			check(director.duration("race",cue.text)+cue.at<=cue.deadline,"planned line fits speech window")
			if cue.get("historical",false):
				check(cue.has("evidence"),"historical action call includes actual trace evidence")
				if cue.category in ["lead_move","place_move"]:
					var mover: int=cue.replacements.mover-1
					var rival: int=cue.replacements.rival-1
					check(cue.evidence.before[mover]<=cue.evidence.before[rival] and cue.evidence.positions[mover]>=cue.evidence.positions[rival],"named rival was actually passed")
		check(named>=2,"each sample race has specific calls, not generic filler")
		report.append(director.cues.duplicate(true))
	var file=FileAccess.open("res://test-results/commentary15-plans.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  "))
	director.queue_free(); await process_frame
	print("Commentary 15 failures: ",failures); quit(1 if failures else 0)

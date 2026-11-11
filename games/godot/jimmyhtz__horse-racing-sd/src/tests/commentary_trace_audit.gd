extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var odds=load("res://core/calibrated_odds.gd").new()
	var director=load("res://ui/announcer_director.gd").new()
	var speech=load("res://tests/review_14_regressions.gd").Speech.new()
	director.backend=speech
	root.add_child(director)
	director.configure(load("res://core/game_settings.gd").new().values)
	director.library.rng.seed=20261025
	var report:=[]
	var first_covered:=0
	var second_covered:=0
	for i in range(12):
		var race=load("res://core/calibrated_race.gd").new(("commentary-audit-%d" % i).sha256_text(),odds.board(90))
		var trace: Array=[race.snapshot()]
		while not race.finished:
			race.advance_event()
			trace.append(race.snapshot())
		director.prepare_race(trace,race.result(),35.0,false,"small")
		director.stop()
		director.clock=0.0
		director.ended=-100.0
		director.last_call=-100.0
		speech.calls.clear()
		speech.now=0.0
		for frame in range(700):
			director.advance(0.05)
			director.observe("RACING",director.record_position(trace,race.result().second_time*frame/700.0),frame/700.0,{})
		var named:=0
		var second:=0
		var spoken_first:=0
		var spoken_second:=0
		for cue in director.cues:
			if cue.get("leader",-1)>=0 or cue.get("second",-1)>=0: named+=1
			if cue.get("second",-1)>=0: second+=1
			if cue.text in speech.calls:
				if cue.get("leader",-1)>=0: spoken_first+=1
				if cue.get("second",-1)>=0: spoken_second+=1
		if spoken_first>0: first_covered+=1
		if spoken_second>0: second_covered+=1
		report.append({"race":i,"named":named,"second":second,"delivered_first":spoken_first,"delivered_second":spoken_second,"cues":director.cues.duplicate(true),"delivered":speech.calls.duplicate()})
	var file:=FileAccess.open("res://test-results/commentary-trace-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("COMMENTARY TRACE: delivered first/second ",report.map(func(row): return [row.delivered_first,row.delivered_second]))
	var good: bool=first_covered>=8 and second_covered>=8
	if not good: printerr("FAIL: too few recorded test races deliver both paying-place commentary")
	director.queue_free()
	await process_frame
	quit(0 if good else 1)

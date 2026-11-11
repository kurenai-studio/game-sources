extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var odds=load("res://core/calibrated_odds.gd").new()
	var changed_late:=0
	for index in range(3):
		var board: Dictionary=odds.board([80,90,200][index])
		var seed: String=("full-course21-"+str(index)).sha256_text()
		var baseline=load("res://core/calibrated_race.gd").new(seed,board,{})
		var expected: Dictionary=baseline.run()
		var race=load("res://core/calibrated_race.gd").new(seed,board,{"race_spread":1.0,"race_lead_changes":0.5})
		var previous:=0.0
		while not race.finished:
			race.advance_event()
			var event: Dictionary=race.last_event()
			check(event.end_time>previous,"strictly increasing turn times")
			previous=event.end_time
			var moved: float=event.end_positions[event.selected]-event.start_positions[event.selected]
			check(moved>0.0,"every fresh move is positive")
			for h in range(5):
				if h!=event.selected:check(event.end_positions[h]==event.start_positions[h],"only shuffled selected horse moves")
			if event.round>6000 and absf(moved-race._scale)>0.000001 and absf(moved-2.0*race._scale)>0.000001:
				changed_late+=1
		var result: Dictionary=race.result()
		check(result.full_order==expected.full_order,"all five finishers retain exact calibrated order")
		check(result.first==expected.first and result.second==expected.second and result.pair==expected.pair,"horse and pair identity")
	check(changed_late>1000,"full-course stride variation continues through the finish section")
	print("Full-course21 failures=",failures," varied late turns=",changed_late)
	quit(1 if failures else 0)

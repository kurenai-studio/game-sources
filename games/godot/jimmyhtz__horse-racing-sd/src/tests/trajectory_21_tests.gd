extends SceneTree
var failures:=0
var assertions:=0
func check(ok: bool, why: String):
	assertions+=1
	if not ok:failures+=1;printerr("FAIL: "+why)
func _init():
	var catalog: Dictionary=load("res://core/calibrated_odds.gd").internal_catalog()
	for settings in [{},{"race_spread":0.0,"race_lead_changes":1.0},{"race_spread":1.0,"race_lead_changes":0.5},{"race_spread":1.5,"race_lead_changes":1.0}]:
		for percent in [70,80,90,200]:
			var seed: String=("trajectory21-"+str(percent)).sha256_text()
			var race=load("res://core/step_motion.gd").new(seed,catalog,percent,true,settings)
			var result: Dictionary=race.run()
			var original=load("res://core/step_motion.gd").new(seed,catalog,percent,true,{})
			var expected: Dictionary=original.run()
			check(result.full_order==expected.full_order,"same seed preserves every finisher at slider endpoints")
			for crossing in result.crossings:
				check(absf(race.positions_at(crossing.time)[crossing.horse]-1000.0)<0.00000001,"reported crossing matches the linearly recorded physical path")
			for h in range(5):
				check(race._streams[h]._counter==original._streams[h]._counter and race._streams[h]._offset==original._streams[h]._offset,"horse draws consumed at the original turns")
			check(race._scheduler._counter==original._scheduler._counter and race._scheduler._offset==original._scheduler._offset,"scheduler uses the same shuffled rounds")
			var before: Array=[0.0,0.0,0.0,0.0,0.0]
			for sample in range(101):
				var p: Array=race.positions_at(result.crossings[-1].time*sample/100.0)
				for h in range(5):check(p[h]>=before[h],"interpolated position never moves backward")
				before=p
	var board=load("res://core/calibrated_odds.gd").new().board(80,[4,2,0,3,1])
	var race=load("res://core/calibrated_race.gd").new("d".repeat(64),board,{"race_spread":1.0,"race_lead_changes":0.5})
	var result: Dictionary=race.run()
	check(race.post_positions(0)==result.positions,"post-finish starts without a position jump")
	for sample in race._continuation:
		var actual: Array=race.post_positions(sample.time-result.second_time)
		for h in range(5):check(absf(actual[h]-sample.positions[h])<0.00000001,"all five horses continue their recorded trajectory after second crosses")
	print("Trajectory21 assertions=",assertions," failures=",failures)
	quit(1 if failures else 0)

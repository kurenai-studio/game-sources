extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var odds=load("res://core/calibrated_odds.gd").new()
	var settings=[70,80,90,100,150,200]
	for index in range(settings.size()):
		var board: Dictionary=odds.board(settings[index])
		var seed: String=("race-control20-extreme-"+str(index)).sha256_text()
		var original=load("res://core/calibrated_race.gd").new(seed,board,{"race_spread":0.0,"race_lead_changes":0.0})
		var expected: Dictionary=original.run()
		for spread in [1.0,1.25,1.5]:
			var race=load("res://core/calibrated_race.gd").new(seed,board,{"race_spread":spread,"race_lead_changes":1.0})
			for horse_steps in race._control.steps:
				var total:=0.0
				for stride in horse_steps:
					check(stride>=0.125 and stride<=4.5,"all recalculated strides remain positive and bounded")
					total+=stride
				check(total<race._distance,"no horse can finish in the recalculated prefix")
			check(race.run()==expected,"all finish fields and crossing times survive new upper range")
	print("Race control 20: 18 paired outcomes; failures ",failures); quit(1 if failures else 0)

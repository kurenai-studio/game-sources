extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void:
	var engine=load("res://core/calibrated_race.gd")
	var stream=load("res://core/crypto_stream.gd")
	var legacy=load("res://tests/helpers/legacy_race_control18.gd")
	var compared:=0
	for i in range(16):
		var master: String=("control19-%d" % i).sha256_text()
		var board=load("res://core/calibrated_odds.gd").new().board([70,80,83,90,100,120,160,200][i%8])
		var baseline=engine.new(master,board)
		var old_streams: Array=[]
		for h in range(5): old_streams.append(stream.new(master,"payback-v1:horse:%d" % h))
		var old=legacy.new(master,old_streams,baseline._thresholds,10000,{"race_spread":1.0,"race_lead_changes":1.0})
		var midpoint=engine.new(master,board,{"race_spread":0.5,"race_lead_changes":0.5})
		var midpoint_matches:=true
		for h in range(5):
			for turn in range(4999):
				if float(midpoint._control.steps[h][turn])!=float(old.steps[h][turn]): midpoint_matches=false; break
		check(midpoint_matches,"new midpoint exactly reproduces old maximum")
		var original=baseline.run()
		for controls in [{"race_spread":0.5,"race_lead_changes":0.5},{"race_spread":1.0,"race_lead_changes":1.0},{"race_spread":0.75,"race_lead_changes":0.8}]:
			var race=engine.new(master,board,controls)
			var wider:=false
			for h in range(5):
				var total:=0.0
				for step in race._control.steps[h]:
					check(step>0 and step<=3.25,"all strides are positive and bounded")
					total+=step
					wider=wider or step<1 or step>2
				check(total<10000.0 and total==floorf(total),"exact integer distance budget remains before finish")
			if controls.race_spread>0.5: check(wider,"upper range produces stronger actual stride variation")
			check(race.run()==original,"all outcomes, crossing times and payouts remain identical")
			compared+=1
	print("Race Control 19 comparisons: ",compared," failures: ",failures)
	quit(1 if failures else 0)

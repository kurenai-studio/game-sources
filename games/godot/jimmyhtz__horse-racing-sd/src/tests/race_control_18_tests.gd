extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
	if not ok: failures += 1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func sample(master: String, board: Dictionary, controls: Dictionary) -> Dictionary:
	var race = load("res://core/calibrated_race.gd").new(master,board,controls)
	var sample_rows: Array = []
	while not race.finished:
		race.advance_event()
		if race._events%250==0: sample_rows.append(race.snapshot())
	return {"result":race.result(),"rows":sample_rows,"control":race.race_control_summary()}
func metrics(rows: Array) -> Dictionary:
	var spread := 0.0; var count := 0; var last_leader := -1; var passes := 0
	for row in rows:
		if row.time>24.0: break
		var p: Array = row.positions
		var leader: int = p.find(p.max())
		spread += float(p.max())-float(p.min()); count += 1
		# Ignore sub-unit churn while the horses are effectively tied.
		if last_leader<0: last_leader=leader
		elif leader!=last_leader and float(p[leader])-float(p[last_leader])>=2.0:
			passes+=1; last_leader=leader
	return {"spread":spread/maxi(1,count),"passes":passes}
func run() -> void:
	var engine=load("res://core/calibrated_race.gd")
	var board=load("res://core/calibrated_odds.gd").new().board(90)
	var probe=engine.new("race-control-probe".sha256_text(),board)
	check(probe.has_method("race_control_summary"),"movement engine exposes verified Race Control bridge")
	if failures: quit(1); return
	var totals: Array = [{"spread":0.0,"passes":0.0},{"spread":0.0,"passes":0.0},{"spread":0.0,"passes":0.0}]
	var variants := [{"race_spread":1.0,"race_lead_changes":0.0},{"race_spread":1.0,"race_lead_changes":1.0}]
	var compared := 0
	for i in range(24):
		board=load("res://core/calibrated_odds.gd").new().board([70,80,83,90,100,120,160,200][i%8])
		var master := ("race-control-18-%d" % i).sha256_text()
		var original=sample(master,board,{})
		var baseline=metrics(original.rows)
		for key in baseline: totals[0][key]+=baseline[key]
		for v in range(variants.size()):
			var changed=sample(master,board,variants[v]); compared+=1
			for key in ["full_order","crossings","first","second","pair","first_time","second_time","positions","final_positions","events","rounds"]:
				check(original.result[key]==changed.result[key],"exact invariant %s seed %d variant %d" % [key,i,v])
			check(changed.control.rounds*2<changed.control.distance,"no horse can finish inside the modified block")
			var differ := false
			for row in range(original.rows.size()):
				if original.rows[row].time>=changed.control.end_time:
					check(original.rows[row]==changed.rows[row],"entire final trajectory matches baseline")
				elif original.rows[row]!=changed.rows[row]: differ=true
			check(differ,"actual early movement calculations change")
			var measured=metrics(changed.rows)
			for key in measured: totals[v+1][key]+=measured[key]
	# Fixed-seed ensemble verifies useful effects rather than guaranteeing each race looks alike.
	check(totals[1].spread>totals[0].spread*1.5,"spread control visibly increases average separation")
	check(totals[2].passes>totals[1].passes*1.5,"excitement control increases substantial lead changes")
	var report={"comparisons":compared,"totals":totals,"failures":failures,"scope":"Same-seed coupling plus unchanged calibrated suffix, not Monte Carlo recalibration"}
	FileAccess.open("res://test-results/race-control18.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RACE CONTROL 18 ",JSON.stringify(report)); quit(1 if failures else 0)

extends SceneTree
const Effort = preload("res://core/effort_race_engine.gd")
const Legacy = preload("res://core/race_engine.gd")
const Odds = preload("res://core/odds_model.gd")
func metrics(samples: Array, winner: int) -> Dictionary:
	var leader := -1
	var candidate := -1
	var candidate_since := 0
	var changes := 0
	var initial_leader := -1
	var initial_last := -1
	var stayed_last := true
	var span_total := 0.0
	var max_span := 0.0
	var pair_signs := {}
	var overtakes := 0
	for index in range(50,samples.size()):
		var positions: Array = samples[index]
		var order := range(5)
		order.sort_custom(func(a,b): return positions[a] > positions[b])
		var span: float = positions[order[0]]-positions[order[4]]
		span_total += span
		max_span = maxf(max_span,span)
		if initial_last < 0:
			initial_last = order[4]
		stayed_last = stayed_last and order[4] == initial_last
		if leader < 0:
			leader = order[0]
			initial_leader = leader
		if order[0] != leader and positions[order[0]]-positions[order[1]] >= 0.5:
			if candidate != order[0]:
				candidate = order[0]
				candidate_since = index
			elif index-candidate_since >= 10:
				changes += 1
				leader = candidate
				candidate = -1
		else:
			candidate = -1
		for a in range(5):
			for b in range(a+1,5):
				var gap: float = positions[a]-positions[b]
				if absf(gap) < 0.5:
					continue
				var key := a*5+b
				var direction := 1 if gap > 0 else -1
				if pair_signs.has(key) and pair_signs[key] != direction:
					overtakes += 1
				pair_signs[key] = direction
	var late: Array = samples[900]
	return {"lead_changes":changes,"position_changes":overtakes,
		"wire_to_wire_after_opening":changes == 0 and winner == initial_leader,
		"same_last_after_opening":stayed_last,"winner_last_at_90pct":late[winner] == late.min(),
		"mean_span_pct":span_total/(samples.size()-50)/10.0,"max_span_pct":max_span/10.0}

func _initialize() -> void:
	var count := 100
	var output := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--races="):
			count = int(argument.get_slice("=",1))
		elif argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		else:
			printerr("Unknown argument")
			quit(2)
			return
	if count < 1 or count > 200:
		printerr("This comparison is limited to 1-200 races per model.")
		quit(2)
		return
	var report := {"purpose":"Small engineering comparison, not probability calibration.",
		"seeds":[5000,5000+count-1],"races_per_model":count,"calibrated":false,
		"definitions":"1001 evenly spaced recorded samples through second finish; opening 5% excluded. Lead change requires a 0.5-step lead sustained for 1% of race time. Pair overtakes require crossing opposite 0.5-step margins. Span percentages use the 1000-step lap.",
		"first_targets":Odds.new().targets().first,"models":{}}
	for name in ["legacy","effort"]:
		var summary := {"wins":[0,0,0,0,0],"pairs":{},"lead_changes":0,"position_changes":0,
			"wire_to_wire_after_opening":0,"same_last_after_opening":0,"winner_last_at_90pct":0,
			"mean_span_pct":0.0,"mean_max_span_pct":0.0,"races_with_3plus_lead_changes":0}
		var per_race: Array = []
		for seed_value in range(5000,5000+count):
			var samples: Array = []
			var result: Dictionary
			if name == "effort":
				var race := Effort.new(seed_value,{"record_trace":true})
				result = race.run()
				for index in range(1001):
					samples.append(race.positions_at(result.second_time*index/1000.0))
			else:
				var race := Legacy.new(seed_value)
				var records: Array = [race.snapshot()]
				while not race.finished:
					race.advance_event()
					records.append(race.snapshot())
				result = race.result()
				for index in range(1001):
					var time: float = result.second_time*index/1000.0
					var slot := mini(int(floorf(time)),records.size()-2)
					var alpha := clampf((time-records[slot].time)/(records[slot+1].time-records[slot].time),0,1)
					var positions: Array = []
					for horse in range(5):
						positions.append(lerpf(records[slot].positions[horse],records[slot+1].positions[horse],alpha))
					samples.append(positions)
			var observation := metrics(samples,result.first)
			summary.wins[result.first] += 1
			summary.pairs[result.pair] = summary.pairs.get(result.pair,0)+1
			for key in ["lead_changes","position_changes"]:
				summary[key] += observation[key]
			for key in ["wire_to_wire_after_opening","same_last_after_opening","winner_last_at_90pct"]:
				summary[key] += int(observation[key])
			summary.mean_span_pct += observation.mean_span_pct/count
			summary.mean_max_span_pct += observation.max_span_pct/count
			summary.races_with_3plus_lead_changes += int(observation.lead_changes >= 3)
			observation.merge({"seed":seed_value,"first":result.first+1,"second":result.second+1})
			per_race.append(observation)
		summary["mean_lead_changes"] = float(summary.lead_changes)/count
		summary["mean_position_changes"] = float(summary.position_changes)/count
		report.models[name] = {"summary":summary,"races":per_race}
		print(name.to_upper()+": "+JSON.stringify(summary))
	if not output.is_empty():
		var file := FileAccess.open(output,FileAccess.WRITE)
		if file == null:
			printerr("Could not save comparison")
			quit(2)
			return
		file.store_string(JSON.stringify(report,"  "))
	quit(0)

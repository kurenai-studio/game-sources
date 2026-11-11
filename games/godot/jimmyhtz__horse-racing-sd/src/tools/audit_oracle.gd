extends SceneTree
# Actual-engine oracle for the offline statistical runner. No saves or UI are loaded.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected manifest path and output path")
		quit(2)
		return
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var output := FileAccess.open(args[1],FileAccess.WRITE)
	if not manifest is Array or output == null:
		quit(2)
		return
	for fixture in manifest:
		var config: Dictionary = fixture.config.duplicate(true)
		var effort: bool = fixture.model != "legacy"
		if effort: config.record_trace = true
		var engine = load("res://tools/audit_super_seed_experiment.gd" if fixture.model == "super" else ("res://tools/audit_seed_experiment.gd" if fixture.model == "mixed" else ("res://core/effort_race_engine.gd" if effort else "res://core/race_engine.gd")))
		var race = engine.new(str(fixture.seed) if fixture.model == "super" else int(fixture.seed),config)
		var records: Array = [race.snapshot()]
		while not race.finished:
			race.advance_event()
			if not effort: records.append(race.snapshot())
		var result: Dictionary = race.result()
		var samples: Array = []
		for index in range(1001):
			var time: float = result.second_time*index/1000.0
			if effort: samples.append(race.positions_at(time))
			else:
				var slot := mini(int(floorf(time)),records.size()-2)
				var alpha := clampf((time-records[slot].time)/(records[slot+1].time-records[slot].time),0,1)
				var positions: Array = []
				for horse in range(5): positions.append(lerpf(records[slot].positions[horse],records[slot+1].positions[horse],alpha))
				samples.append(positions)
		output.store_line(JSON.stringify({"id":fixture.id,"result":result,"samples":samples}))
	output.close()
	print("ORACLE FIXTURES: %d" % manifest.size())
	quit(0)

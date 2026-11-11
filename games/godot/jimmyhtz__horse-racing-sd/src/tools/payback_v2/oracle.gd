extends SceneTree
const Candidate = preload("res://tools/payback_v2/race_candidate.gd")
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size()==2)
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://test-results/payback-v2/catalog.json"))
	var input := FileAccess.open(args[0],FileAccess.READ)
	var output := FileAccess.open(args[1],FileAccess.WRITE)
	var count := 0
	while not input.eof_reached():
		var line := input.get_line()
		if line.is_empty(): continue
		var fields := line.split(",")
		var race = Candidate.new(fields[1],catalog,int(fields[2]),true)
		var result: Dictionary = race.run()
		var samples: Array = []
		for i in range(1001):
			samples.append(race.positions_at(result.second_time*i/1000.0))
		output.store_line(JSON.stringify({"id":fields[0],"profile":race._profile,"result":result,"samples":samples}))
		count+=1
	output.close()
	print("CANDIDATE ORACLE FIXTURES: %d" % count)
	quit()

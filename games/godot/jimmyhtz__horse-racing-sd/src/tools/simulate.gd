extends SceneTree
const RaceEngine = preload("res://core/race_engine.gd")
const OddsModel = preload("res://core/odds_model.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var count := 100
	var seed_start := 1
	for argument in args:
		if argument.begins_with("--races="):
			count = int(argument.get_slice("=",1))
		elif argument.begins_with("--seed="):
			seed_start = int(argument.get_slice("=",1))
		else:
			printerr("Unknown argument: " + argument)
			quit(2)
			return
	if count < 1 or count > 10000:
		printerr("This foundation harness allows 1 to 10,000 races. Million-race calibration requires its own approved checkpoint and harness upgrade.")
		quit(2)
		return
	var wins := [0,0,0,0,0]
	var pairs := {}
	var ordered := {}
	var exact_ties := 0
	var targets := OddsModel.new().targets()
	for key in targets.pairs:
		pairs[key] = 0
	for key in targets.ordered:
		ordered[key] = 0
	for index in range(count):
		var result := RaceEngine.new(seed_start + index).run()
		wins[result.first] += 1
		pairs[result.pair] += 1
		ordered["%d-%d" % [result.first+1,result.second+1]] += 1
		exact_ties += int(result.exact_tie)
	var comparisons := {}
	for pair in pairs:
		comparisons[pair] = {"target":targets.pairs[pair],"observed":float(pairs[pair])/count,"count":pairs[pair]}
	print(JSON.stringify({"model":RaceEngine.MODEL_VERSION,"races":count,"seed_start":seed_start,"wins":wins,"first_targets":targets.first,"pairs":comparisons,"ordered_counts":ordered,"exact_ties":exact_ties,"calibrated":false,"purpose":"bounded engineering smoke check only; no statistical acceptance claim"},"  "))
	quit(0)

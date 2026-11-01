extends SceneTree
## The AI audit's plan search. A plan sends each of the player's regiments
## to one of the flags, or leaves it to the AI's usual line; the AI then
## fights it out (the standard commander, executing the plan). Searching the
## plans asks how much better than the standard commander a fixed plan can
## do against the enemy AI (the ceiling, and whether the enemy has a blind
## spot), and how far apart good and bad plans land (what a choice of plan
## is worth).
##   Godot --headless --path . -s tests/plans.gd -- --scenario=hold --dice=3 --tries=40
## Prints one PLAN line of JSON per plan tried, then a SUMMARY line.

const GROUP := "plan "


func _initialize() -> void:
	var scenario := "hold"
	var dice := 3
	var tries := 40
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--dice="):
			dice = int(arg.get_slice("=", 1))
		elif arg.begins_with("--tries="):
			tries = int(arg.get_slice("=", 1))
	var spec := Scenarios.resolve(scenario, 1000)
	var units := _player_units(spec)
	var flags: int = Scenarios.make_battle(spec, 1).flags.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var tried := {}
	# The AI's own line for every regiment is the baseline: plan of all "line".
	var line := []
	line.resize(units)
	line.fill(flags)
	var best: Array = line
	var best_score := _score(spec, line, dice, tried)
	for n in tries:
		var plan: Array
		if n < tries / 2:
			plan = []
			for i in units:
				plan.append(rng.randi_range(0, flags))
		else:
			# Climb: change one regiment's flag in the best plan so far.
			plan = best.duplicate()
			plan[rng.randi() % units] = rng.randi_range(0, flags)
		var score := _score(spec, plan, dice, tried)
		if score > best_score:
			best_score = score
			best = plan
	var scores: Array = tried.values().map(func(t): return t.score)
	scores.sort()
	print("SUMMARY ", JSON.stringify({
		"scenario": scenario, "plans": tried.size(), "dice": dice,
		"line": tried[str(line)], "best": tried[str(best)], "best_plan": best,
		"median": scores[scores.size() / 2], "worst": scores[0],
	}))
	quit()


## The player's regiments a plan assigns, the general aside.
func _player_units(spec: Dictionary) -> int:
	var b := Scenarios.make_battle(spec, 1)
	return b.team_regiments(0).filter(func(r): return r.kind != UnitTypes.Kind.GENERAL).size()


## A plan's score over `dice` battles: wins, with the mean margin to break
## ties. Each plan is fought once and remembered.
func _score(spec: Dictionary, plan: Array, dice: int, tried: Dictionary) -> float:
	var key := str(plan)
	if tried.has(key):
		return tried[key].score
	var wins := 0
	var margin := 0.0
	for die in dice:
		var b := Scenarios.make_battle(spec, 7919 * (die + 1))
		_assign(b, plan)
		Fights.fight(b, AI.PERSONAS[spec.persona], "standard")
		wins += 1 if b.winner == 0 else 0
		margin += Measures.margin(b)
	var result := {"plan": plan, "wins": wins, "margin": snappedf(margin / dice, 0.1), "score": wins + margin / dice / 1000.0}
	tried[key] = result
	print("PLAN ", JSON.stringify(result))
	return result.score


## Each regiment with a flag in the plan goes for that flag, alongside the
## others sent to it (a division of its own); a regiment left to the line
## keeps the AI's usual place.
func _assign(b: Battle, plan: Array) -> void:
	var regs := b.team_regiments(0).filter(func(r): return r.kind != UnitTypes.Kind.GENERAL)
	for i in regs.size():
		var flag: int = plan[i]
		if flag < b.flags.size():
			regs[i].objectives = PackedVector2Array([b.flags[flag].pos])
			regs[i].formation = GROUP + str(flag)
